function psi_disp = update_daily_willingness(cfg, p_disp_day)
% Compute current-day willingness directly from the dispatch-side price signal.
% Lower dispatch side price means the prosumer is more attractive to clear.

% Prices are constant within the day, so one column is enough here.
p_disp_vec = p_disp_day(:,1);
p_min = min(p_disp_vec);
p_max = max(p_disp_vec);

% Normalize onto [0,1]-like scale, with eps0 preventing divide-by-zero.
psi_disp = 1 - (p_disp_vec - p_min) ./ (p_max - p_min + cfg.eps0);
end
