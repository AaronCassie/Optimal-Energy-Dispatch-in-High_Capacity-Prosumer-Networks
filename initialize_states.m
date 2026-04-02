function state0 = initialize_states(cfg, pros)
% Initialize fairness and day-1 storage state.
% The rest of the dynamic state is built inside the main simulation loop.

N = cfg.N;
D = cfg.D;

% Fairness adjustments start from   neutral.
phi_fair = zeros(N, D+1);

E_init_day = zeros(N,1);
% Start storage halfway full so the first day is not artificially depleted or full.
E_init_day(pros.hasStorage) = 0.5 * pros.Emax(pros.hasStorage);

state0 = struct();
state0.phi_fair = phi_fair;
state0.E_init_day = E_init_day;

end
