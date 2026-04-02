function [A_day, R_day, R_mean] = compute_daily_metrics(a_star_day, p_day)
% a_star_day: N x T, p_day: N x T
% Build a compact daily summary once the hourly clearing for the day is fixed.

% Daily accepted energy per prosumer.
A_day = sum(a_star_day, 2);

% Daily revenue uses the settlement price, not the dispatch score.
R_day = sum(p_day .* a_star_day, 2);

% Mean daily revenue is used by some fairness policies.
R_mean = mean(R_day);

end
