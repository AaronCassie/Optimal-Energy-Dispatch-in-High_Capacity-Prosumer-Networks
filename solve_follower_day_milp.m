function out = solve_follower_day_milp(cfg, pros, i, s_day, p_row, alpha_i, E_init_i)
% Solve one prosumer's day    follower problem for one outer iteration.
% Storage prosumers solve a MILP or non-storage prosumers solve a simpler LP.

T = cfg.T;
coeff = p_row(:);
numTol = 1e-6;

if ~pros.hasStorage(i)
    %   Non-storage prosumers still optimize, but with a simpler LP and no binary/storage variables.
    q_cap = max(s_day(:), 0);
    lb_lp = zeros(T,1);
    ub_lp = alpha_i * q_cap;
    f_lp = -coeff;

    % Revenue maximization is written as minimization of the negative objective.
    [q_offer, ~, exitflag] = linprog(f_lp, [], [], [], [], lb_lp, ub_lp, cfg.linprog_options);
    if exitflag <= 0
        error('Follower LP failed for non-storage prosumer %d (exitflag=%d).', i, exitflag);
    end

    % Clean tiny negative numerical noise before returning.
    q_offer(q_offer < 0 & q_offer > -numTol) = 0;
    out.q_offer = max(q_offer, 0)';
    out.c = zeros(1,T);
    out.dch = zeros(1,T);
    out.E = zeros(1,T+1);
    out.z = zeros(1,T);
    return;
end

Pch = pros.PchMax(i);
Pdis = pros.PdisMax(i);
Emax = pros.Emax(i);
eta_ch = cfg.eta_ch;
eta_dis = cfg.eta_dis;

% Variable counts for the packed MILP vector.
nQ = T; nC = T; nD = T; nQcap = T; nX = T; nE = T+1; nZ = T; nY = T;

% Pack all variables into one long vector for intlinprog.
idx.q = 1:nQ;
idx.c = idx.q(end) + (1:nC);
idx.d = idx.c(end) + (1:nD);
idx.qcap = idx.d(end) + (1:nQcap);
idx.x = idx.qcap(end) + (1:nX);
idx.E = idx.x(end) + (1:nE);
idx.z = idx.E(end) + (1:nZ);
idx.y = idx.z(end) + (1:nY);
nVar = idx.y(end);

% Binary variables are the charge/discharge mode and the qcap max-linearization flag.
intcon = [idx.z, idx.y];

lb = zeros(nVar,1);
ub = inf(nVar,1);

% Big-M term for the piecewise-linear export-capability block.
M = s_day(:) + Pdis * cfg.dt;

% Basic upper bounds.
lb(idx.x) = -Pch * cfg.dt;
ub(idx.q) = alpha_i * M;
ub(idx.c) = Pch;
ub(idx.d) = Pdis;
ub(idx.qcap) = M;
ub(idx.x) = M;
ub(idx.E) = Emax;
ub(idx.z) = 1;
ub(idx.y) = 1;

A = [];
b = [];
Aeq = [];
beq = [];

% No simultaneous charging/ discharging via binary z.
A1 = zeros(T, nVar);
for t = 1:T
    A1(t, idx.c(t)) = 1;
    A1(t, idx.z(t)) = -Pch;
end
A = [A; A1];
b = [b; zeros(T,1)];

% If z = 1, discharge is forced down; if z = 0, charge is forced down.
A2 = zeros(T, nVar);
for t = 1:T
    A2(t, idx.d(t)) = 1;
    A2(t, idx.z(t)) = Pdis;
end
A = [A; A2];
b = [b; Pdis*ones(T,1)];

% Net export before the offer cap.
Aeq_x = zeros(T, nVar);
beq_x = s_day(:);
for t = 1:T
    Aeq_x(t, idx.x(t)) = 1;
    Aeq_x(t, idx.d(t)) = -1;
    Aeq_x(t, idx.c(t)) = 1;
end
Aeq = [Aeq; Aeq_x];
beq = [beq; beq_x];

% qcap >= x  -> x - qcap <= 0
A3 = zeros(T, nVar);
for t = 1:T
    A3(t, idx.x(t)) = 1;
    A3(t, idx.qcap(t)) = -1;
end
A = [A; A3];
b = [b; zeros(T,1)];

% qcap <= x + M(1-y) -> qcap - x + M*y <= M
A4 = zeros(T, nVar);
for t = 1:T
    A4(t, idx.qcap(t)) = 1;
    A4(t, idx.x(t)) = -1;
    A4(t, idx.y(t)) = M(t);
end
A = [A; A4];
b = [b; M];

% qcap <= M*y -> qcap - M*y <= 0
A5 = zeros(T, nVar);
for t = 1:T
    A5(t, idx.qcap(t)) = 1;
    A5(t, idx.y(t)) = -M(t);
end
A = [A; A5];
b = [b; zeros(T,1)];

% Current-day willingness scales the export cap into the actual offer.
A6 = zeros(T, nVar);
for t = 1:T
    A6(t, idx.q(t)) = 1;
    A6(t, idx.qcap(t)) = -alpha_i;
end
A = [A; A6];
b = [b; zeros(T,1)];

% SoC dynamics.
Aeq_soc = zeros(T, nVar);
beq_soc = zeros(T,1);
for t = 1:T
    Aeq_soc(t, idx.E(t+1)) = 1;
    Aeq_soc(t, idx.E(t)) = -1;
    Aeq_soc(t, idx.c(t)) = -eta_ch * cfg.dt;
    Aeq_soc(t, idx.d(t)) = (1/eta_dis) * cfg.dt;
end
Aeq = [Aeq; Aeq_soc];
beq = [beq; beq_soc];

% Initial SoC is fixed from the previous day carryover.
Aeq_init = zeros(1, nVar);
Aeq_init(1, idx.E(1)) = 1;
Aeq = [Aeq; Aeq_init];
beq = [beq; E_init_i];

% Revenue maximization becomes minimization after the sign flip below.
f = zeros(nVar,1);
f(idx.q) = -coeff;

[xsol, ~, exitflag] = intlinprog(f, intcon, A, b, Aeq, beq, lb, ub, cfg.intlinprog_options);
if exitflag <= 0
    error('Follower MILP failed for prosumer %d (exitflag=%d).', i, exitflag);
end

% Unpack the solution pieces we care about.
q_offer = xsol(idx.q);
c = xsol(idx.c);
dch = xsol(idx.d);
E = xsol(idx.E);

% small negative numerical noise before returning.
q_offer(q_offer < 0 & q_offer > -numTol) = 0;
c(c < 0 & c > -numTol) = 0;
dch(dch < 0 & dch > -numTol) = 0;
E(E < 0 & E > -numTol) = 0;

out.q_offer = max(q_offer, 0)';
out.c = max(c, 0)';
out.dch = max(dch, 0)';
out.E = max(E, 0)';
out.z = xsol(idx.z)';

end
