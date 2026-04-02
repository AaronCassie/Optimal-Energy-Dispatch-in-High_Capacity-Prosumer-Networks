% plot_prosumer_profiles.m
% Standalone visualization/debugging script.
% Plots 24-hour load and generation profiles for all prosumers (stacked).

clear; clc;

% Use the current project utilities so the plot always matches the active data setup.
cfg = build_config(struct('W', 1));
pros = load_prosumer_table(cfg);
cfg.N = numel(pros.i);
cfg.Nb = numel(unique(pros.bus));
cfg.Np_per_bus = max(accumarray(pros.bus, 1, [cfg.Nb, 1]));
base = build_base_shapes();
[profiles, ~] = generate_profiles(cfg, pros, base);

N = cfg.N;
T = cfg.T;
hours = 1:T;

% Day 1 is enough here because the exogenous profiles repeat every day.
L_day1 = squeeze(profiles.L(:,:,1));
G_day1 = squeeze(profiles.G(:,:,1));

figure('Name', 'Prosumer Daily Load vs Generation Profiles', 'Color', 'w');
tl = tiledlayout(N, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'Daily 24-hour Profiles by Prosumer (Load and Generation)');

for i = 1:N
    ax = nexttile;
    % Plot load and total renewable generation on the same axes for quick comparison.
    plot(hours, L_day1(i,:), 'LineWidth', 1.1, 'Color', [0.85 0.2 0.2]);
    hold on;
    plot(hours, G_day1(i,:), 'LineWidth', 1.1, 'Color', [0.15 0.35 0.85]);
    hold off;
    grid(ax, 'on');
    xlim([1 T]);

    if i < N
        set(ax, 'XTickLabel', []);
    else
        xlabel('Hour of day');
    end

    ylabel('kW');
    if pros.hasStorage(i)
        sTxt = 'storage';
    else
        sTxt = 'no storage';
    end
    title(sprintf('Prosumer %d (Bus %d, %s)', i, pros.bus(i), sTxt), 'FontWeight', 'normal', 'FontSize', 9);

    if i == 1
        legend({'Load', 'Generation'}, 'Location', 'northeastoutside');
    end
end
