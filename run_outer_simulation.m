function sim = run_outer_simulation(cfg, pros, profiles, demand, state0)
% Core simulation loop: weeks -> days -> outer IBR.
% This is the main driver for follower solves, leader clearing, and policy updates.

N = cfg.N;
T = cfg.T;
D = cfg.D;
Kmax = cfg.Kmax;
W = cfg.W;
numTol = 1e-6;

% Full iteration history for debugging.
q_offer_hist = zeros(N,T,Kmax,D);
a_hist = zeros(N,T,Kmax,D);

% Storage histories.
c_hist = zeros(N,T,Kmax,D);
dch_hist = zeros(N,T,Kmax,D);
z_hist = zeros(N,T,Kmax,D);
E_hist = zeros(N,T+1,Kmax,D);

% Converged daily outputs.
q_offer_star = zeros(N,T,D);
a_star = zeros(N,T,D);
c_star = zeros(N,T,D);
dch_star = zeros(N,T,D);
E_star = zeros(N,T+1,D);

% Feasible demand and pricing history.
D_feas_hist = zeros(T,D,Kmax);
p_pay_all = zeros(N,T,D);
p_disp_all = zeros(N,T,D);
k_star_by_day = zeros(D,1);
ibr_offer_res = nan(D,Kmax);
ibr_acc_res = nan(D,Kmax);

% Daily summaries.
A_day = zeros(N,D);
R_day = zeros(N,D);
R_mean = zeros(1,D);

% Fairness and willingness-equivalent daily signal.
phi_fair = state0.phi_fair;
psi_disp = zeros(N,D);
f_fair = zeros(N,D);
phi_preclip = zeros(N,D+1);

% Weekly summaries.
A_week = zeros(N,W);
S_week = zeros(N,W);
u_week = zeros(N,W);
R_week = zeros(N,W);
R_grid_week = zeros(1,W);
A_offer_week = zeros(1,W);
C_eq = zeros(1,W);
C_avoided = zeros(1,W);
Savings = zeros(1,W);

% Day 1 starts from the initialized SoC.
E_init_day = state0.E_init_day;

for w = 1:W
    % Pull the absolute day indices for this week.
    days = cfg.days_of_week(w,:);

    for idd = 1:numel(days)
        d = days(idd);

        % Prices and willingness are fixed for the whole day before the IBR loop starts.
        [p_pay_day, p_disp_day] = compute_daily_price(cfg, pros, phi_fair(:,d));
        p_pay_all(:,:,d) = p_pay_day;
        p_disp_all(:,:,d) = p_disp_day;
        psi_disp(:,d) = update_daily_willingness(cfg, p_disp_day);

        % Unless we converge early, the last iterate becomes the daily solution.
        k_star = Kmax;

        for k = 1:Kmax
            for i = 1:N
                s_day = squeeze(profiles.s_raw(i,:,d));
                p_row = squeeze(p_pay_day(i,:));

                % Each prosumer solves its own day-level best response.
                fol = solve_follower_day_milp(cfg, pros, i, s_day, p_row, psi_disp(i,d), E_init_day(i));

                % Clean tiny negative solver noise before passing anything downstream.
                qtmp = max(fol.q_offer, 0);
                ctmp = max(fol.c, 0);
                dtmp = max(fol.dch, 0);
                Etmp = max(fol.E, 0);
                ztmp = fol.z;

                qtmp(qtmp < 0 & qtmp > -numTol) = 0;
                ctmp(ctmp < 0 & ctmp > -numTol) = 0;
                dtmp(dtmp < 0 & dtmp > -numTol) = 0;
                Etmp(Etmp < 0 & Etmp > -numTol) = 0;

                q_offer_hist(i,:,k,d) = qtmp;
                c_hist(i,:,k,d) = ctmp;
                dch_hist(i,:,k,d) = dtmp;
                E_hist(i,:,k,d) = Etmp;
                z_hist(i,:,k,d) = ztmp;
            end

            % Clamp demand to what can actually be delivered from the current offers.
            D_feas = compute_feasible_demand(demand.D_base, q_offer_hist(:,:,k,d), pros.ell);
            D_feas_hist(:,d,k) = D_feas;

            % The leader clears hour by hour using the current offers.
            for t = 1:T
                a_t = solve_leader_hour_lp(cfg, p_disp_day(:,t), q_offer_hist(:,t,k,d), pros.ell, D_feas(t));
                a_hist(:,t,k,d) = a_t;
            end

            if k > 1
                % Compare against the previous iterate to see whether the day has settled.
                [isConv, offerRes, accRes] = check_ibr_convergence( ...
                    q_offer_hist(:,:,k,d), q_offer_hist(:,:,k-1,d), ...
                    a_hist(:,:,k,d), a_hist(:,:,k-1,d), cfg.eps_IBR);

                ibr_offer_res(d,k) = offerRes;
                ibr_acc_res(d,k) = accRes;

                if isConv
                    k_star = k;
                    break;
                end
            end
        end

        % If it never converges within Kmax, keep the last iterate.
        k_star_by_day(d) = k_star;

        % Freeze the converged daily quantities.
        q_offer_star(:,:,d) = q_offer_hist(:,:,k_star,d);
        a_star(:,:,d) = a_hist(:,:,k_star,d);
        c_star(:,:,d) = c_hist(:,:,k_star,d);
        dch_star(:,:,d) = dch_hist(:,:,k_star,d);
        E_star(:,:,d) = E_hist(:,:,k_star,d);

        % Carry the end-of-day battery state into the next day.
        E_init_day = E_star(:,T+1,d);
        E_init_day(~pros.hasStorage) = 0;

        % Build daily metrics from the converged accepted energy.
        [A_day(:,d), R_day(:,d), R_mean(d)] = compute_daily_metrics(a_star(:,:,d), p_pay_day);

        % Update the bounded fairness state for tomorrow.
        [phi_fair(:,d+1), f_fair(:,d), phi_preclip(:,d+1)] = update_fairness( ...
            cfg, cfg.fairness_policy, phi_fair(:,d), a_star(:,:,d), q_offer_star(:,:,d), pros.ell, profiles.L(:,:,d), pros.bus, cfg.Nb, profiles.s_raw(:,:,d), c_star(:,:,d), dch_star(:,:,d));
    end

    % Weekly summaries use the converged daily outputs from this week.
    [A_week(:,w), S_week(:,w), u_week(:,w)] = compute_weekly_metrics(cfg, A_day(:,days));
    R_week(:,w) = sum(R_day(:,days), 2);
    R_grid_week(w) = sum(R_week(:,w));
    [A_offer_week(w), C_eq(w), C_avoided(w), Savings(w)] = compute_planning_metrics(cfg, q_offer_star(:,:,days));
end

% Package the run outputs for saving.
sim = struct();
sim.q_offer_hist = q_offer_hist;
sim.a_hist = a_hist;
sim.c_hist = c_hist;
sim.dch_hist = dch_hist;
sim.z_hist = z_hist;
sim.E_hist = E_hist;

sim.q_offer_star = q_offer_star;
sim.a_star = a_star;
sim.c_star = c_star;
sim.dch_star = dch_star;
sim.E_star = E_star;

sim.D_feas_hist = D_feas_hist;
sim.p_pay = p_pay_all;
sim.p_disp = p_disp_all;
sim.k_star_by_day = k_star_by_day;
sim.ibr_offer_res = ibr_offer_res;
sim.ibr_acc_res = ibr_acc_res;

sim.A_day = A_day;
sim.R_day = R_day;
sim.R_mean = R_mean;

sim.phi_fair = phi_fair;
sim.f_fair = f_fair;
sim.phi_preclip = phi_preclip;
sim.psi_disp = psi_disp;

sim.A_week = A_week;
sim.S_week = S_week;
sim.u_week = u_week;
sim.R_week = R_week;
sim.R_grid_week = R_grid_week;
sim.A_offer_week = A_offer_week;
sim.C_eq = C_eq;
sim.C_avoided = C_avoided;
sim.Savings = Savings;

end
