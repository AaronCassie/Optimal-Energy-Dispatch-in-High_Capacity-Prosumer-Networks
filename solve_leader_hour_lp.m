function a_t = solve_leader_hour_lp(cfg, p_t, q_offer_t, ell, D_feas_t)
% Solve one hourly leader clearing problem as a linear program.
% In the active code path rho = 0, so the upper problem is linear.

N = numel(p_t);
numTol = 1e-6;

% Leader objective is just the dispatch-side price score times acceptance.
f = p_t(:);
Aeq = (1 - ell(:))';

lb = zeros(N,1);
ub = q_offer_t(:);

% Numerical cleanup only: remove negative upper bounds from solver noise.
ub(ub < 0 & ub > -numTol) = 0;
if any(ub < -numTol)
    error('Leader LP received materially negative offer bound(s).');
end

beq = D_feas_t;
if beq < 0 && abs(beq) <= numTol
    beq = 0;
end

% Tiny tolerance guards help when the feasible demand lands on the boundary.
maxDeliverable = Aeq * ub;
if beq > maxDeliverable && (beq - maxDeliverable) <= numTol
    beq = maxDeliverable;
end

% First try the exact equality form.
[a_t, ~, exitflag] = linprog(f, [], [], Aeq, beq, lb, ub, cfg.linprog_options);

if exitflag <= 0
    % Small relaxation as a fallback for numerical edge cases.
    tol = 1e-6;
    A = [Aeq; -Aeq];
    b = [beq + tol; -beq + tol];
    [a_t, ~, exitflag] = linprog(f, A, b, [], [], lb, ub, cfg.linprog_options);
    if exitflag <= 0
        error('Leader LP failed (exitflag=%d).', exitflag);
    end
end

end
