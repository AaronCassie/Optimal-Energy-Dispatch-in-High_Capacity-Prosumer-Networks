function [isConv, offerRes, accRes] = check_ibr_convergence(q_curr, q_prev, a_curr, a_prev, epsIBR)
% Convergence is based on the largest change in offers and acceptances.
% This keeps the stopping rule easy to interpret.

% Largest absolute change in offers between consecutive iterates.
offerRes = max(abs(q_curr(:) - q_prev(:)));

% Largest absolute change in acceptances between consecutive iterates.
accRes = max(abs(a_curr(:) - a_prev(:)));

% Both have to settle before the day is treated as converged.
isConv = (offerRes < epsIBR) && (accRes < epsIBR);

end
