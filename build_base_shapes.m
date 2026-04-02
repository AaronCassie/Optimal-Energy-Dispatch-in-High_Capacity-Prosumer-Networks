function base = build_base_shapes()
% Base daily shapes used for every run.
% The shapes are just a base shape here, they can be scaled and shifted in the input dat.

% Daily load shape: quiet overnight, climbing through the day, then easing off.
base.load = [0.62,0.60,0.58,0.56,0.55,0.57,0.63,0.72,0.80,0.84,0.86,0.87, ...
             0.88,0.89,0.90,0.92,0.96,1.00,0.98,0.95,0.90,0.84,0.76,0.68];

% Daily solar shape: zero at night, peak around midday.
base.solar = [0,0,0,0,0,0,0.05,0.15,0.32,0.52,0.72,0.88, ...
              0.97,1.00,0.94,0.80,0.58,0.32,0.12,0.02,0,0,0,0];

% Daily wind shape: available all day with a smoother profile than solar.
base.wind = [0.58,0.55,0.52,0.50,0.48,0.50,0.54,0.60,0.66,0.70,0.72,0.74, ...
             0.73,0.71,0.69,0.72,0.79,0.86,0.92,0.95,0.90,0.82,0.72,0.64];

end
