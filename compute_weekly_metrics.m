function [A_week, S_week, u_week] = compute_weekly_metrics(cfg, A_day_week)
% Compute weekly access metrics only.
% Willingness no longer feeds back weekly, recall now daily to repond to dialy changes in dispatch score but these summaries are still useful.

N = size(A_day_week,1);

% Weekly accepted energy per prosumer.
A_week = sum(A_day_week, 2);

% Share of weekly accepted energy.
denom = sum(A_week);
if denom <= 0
    % If nothing cleared all week, define shares as zero.
    S_week = zeros(N,1);
else
    S_week = A_week / denom;
end

% This stays as a descriptive underservice metric only.
u_week = max(0, 1/N - S_week);

end
