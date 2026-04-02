function [p_pay_day, p_disp_day] = compute_daily_price(cfg, pros, phi_fair_day)
% Compute the daily-constant settlement prices and dispatch scores.
% Both stay fixed through the whole day once phi_fair(:,d) is known.

% Settlement price pays the prosumer and keeps the minimum payment floor.
p_pay_base = pros.r + cfg.e_margin - cfg.r_low * pros.ell + phi_fair_day;
p_pay_floor = pros.r + cfg.e_min;
p_pay_i = max(p_pay_base, p_pay_floor);

% Dispatch score is the leader-side price signal and does not use the floor.
p_disp_i = pros.r + cfg.e_margin + cfg.r_low * pros.ell + phi_fair_day;

% Repeat the daily-constant scalar prices across all 24 hours.
p_pay_day = repmat(p_pay_i, 1, cfg.T);
p_disp_day = repmat(p_disp_i, 1, cfg.T);

end
