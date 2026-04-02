function [profiles, demand] = generate_profiles(cfg, pros, base)
% Generate repeated daily exogenous profiles and the base exogenous demand shape.

N = cfg.N;
T = cfg.T;
D = cfg.D;

% Start with one-day templates before repeating them over the horizon.
L_day = zeros(N,T);
Gsol_day = zeros(N,T);
Gwind_day = zeros(N,T);

for i = 1:N
    % Each prosumer gets the same base shape, then its own scale and shift.
    L_day(i,:) = pros.L_scale(i) * circshift(base.load, [0, pros.shiftL(i)]);
    Gsol_day(i,:) = pros.Gsol_scale(i) * circshift(base.solar, [0, pros.shiftSol(i)]);
    Gwind_day(i,:) = pros.Gwind_scale(i) * circshift(base.wind, [0, pros.shiftWind(i)]);
end

% Profiles repeat by day in the current setup.
L = repmat(L_day, 1, 1, D);
Gsol = repmat(Gsol_day, 1, 1, D);
Gwind = repmat(Gwind_day, 1, 1, D);
G = Gsol + Gwind;

% Raw renewable surplus is what remains after local load is served.
s_raw = max(G - L, 0);

profiles = struct();
profiles.L = L;
profiles.Gsol = Gsol;
profiles.Gwind = Gwind;
profiles.G = G;
profiles.s_raw = s_raw;

% Smooth daily demand profile used by the leader.
t = 1:T;
D_tilde = 0.55 + 0.18*exp(-((t-9).^2)/(2*(2.5^2))) + 0.32*exp(-((t-18).^2)/(2*(3^2)));
Dhat = D_tilde / max(D_tilde);
D_base = cfg.lambda_D * Dhat;

% Package the demand pieces separately so later code is easier to read.
demand = struct();
demand.D_tilde = D_tilde(:);
demand.Dhat = Dhat(:);
demand.D_base = D_base(:);

end
