function [A_offer_week, C_eq, C_avoided, Savings] = compute_planning_metrics(cfg, q_offer_star_week)
% q_offer_star_week: N x T x 7

% These are planning-style summaries, not part of the clearing itself.
% They treat weekly offered access as a capacity-like contribution.

% Total offered energy across the whole week.
A_offer_week = sum(q_offer_star_week(:));

% Hours in one simulated week.
H_week = 7 * cfg.T * cfg.dt;

% Convert total weekly offered energy into an equivalent average capacity.
C_eq = A_offer_week / H_week;

% Avoided capacity cannot exceed the planning need cap.
C_avoided = min(C_eq, cfg.C_need);

% Translate avoided capacity into a simple value proxy.
Savings = cfg.c_cap * C_avoided;

end
