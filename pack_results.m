function results = pack_results(cfg, pros, profiles, demand, sim)
% Collect outputs in a single struct for saving and later analysis.
% The goal is to keep both the main outputs and enough diagnostics to debug runs.

results = struct();

% Save the resolved config and scenario definton.
results.cfg = cfg;
results.prosumers = pros;

% Save the exogenous profiles that drove the run.
results.L = profiles.L;
results.Gsol = profiles.Gsol;
results.Gwind = profiles.Gwind;
results.G = profiles.G;
results.s_raw = profiles.s_raw;

% Save the exogenous demand pieces.
results.D_tilde = demand.D_tilde;
results.Dhat = demand.Dhat;
results.D_base = demand.D_base;

% Core outputs used most often in later analysis.
results.q_offer_star = sim.q_offer_star;
results.a_star = sim.a_star;

% Explicit hourly accepted-energy tensor (N x T x D), kWh.
results.accepted_hourly = sim.a_star;

% Hourly state of charge tensor (N x T x D), kWh; start-of-hour SoC.
results.soc_hourly = sim.E_star(:,1:end-1,:);

% Storage trajectories.
results.E = sim.E_star;
results.c = sim.c_star;
results.dch = sim.dch_star;

% Daily summaries.
results.A_day = sim.A_day;
results.R_day = sim.R_day;
results.R_mean = sim.R_mean;

% Weekly summaries and planning metrics.
results.A_week = sim.A_week;
results.S_week = sim.S_week;
results.u_week = sim.u_week;
results.R_week = sim.R_week;
results.R_grid_week = sim.R_grid_week;

results.C_eq = sim.C_eq;
results.C_avoided = sim.C_avoided;
results.Savings = sim.Savings;
% Pricing and fairness state history.
results.p_pay = sim.p_pay;
results.p_disp = sim.p_disp;
results.phi_fair = sim.phi_fair;
results.f_fair = sim.f_fair;
results.phi_preclip = sim.phi_preclip;
results.psi_disp = sim.psi_disp;

% Keep the rest for debugging or deeper checks.
results.q_offer_hist = sim.q_offer_hist;
results.a_hist = sim.a_hist;
results.E_hist = sim.E_hist;
results.c_hist = sim.c_hist;
results.dch_hist = sim.dch_hist;
results.z_hist = sim.z_hist;
results.D_feas_hist = sim.D_feas_hist;
results.k_star_by_day = sim.k_star_by_day;
results.ibr_offer_res = sim.ibr_offer_res;
results.ibr_acc_res = sim.ibr_acc_res;
results.A_offer_week = sim.A_offer_week;

end
