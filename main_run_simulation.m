function results = main_run_simulation(userConfig)
% Main entrypoint for the bilevel dispatch simulation.
% Usage:
%   results = main_run_simulation();
%   results = main_run_simulation(struct('W', 2, 'fairness_policy', 'anti_monopoly'));

if nargin < 1
    userConfig = struct();
end

% Resolve any interactive settings before the heavy work starts.
userConfig = prompt_run_settings(userConfig);
cfg = build_config(userConfig);
pros = load_prosumer_table(cfg);
cfg = sync_config_with_prosumers(cfg, pros);

% Everything after this point uses the resolved config and loaded input data.
baseShapes = build_base_shapes();
[profiles, demand] = generate_profiles(cfg, pros, baseShapes);
state0 = initialize_states(cfg, pros);

% Run the simulation, then package the outputs for saving and later analysis.
simOut = run_outer_simulation(cfg, pros, profiles, demand, state0);
results = pack_results(cfg, pros, profiles, demand, simOut);

cfg.output_file = make_output_filename(cfg);
results.cfg = cfg;

% Save the result struct directly into a MAT file with named fields.
save(cfg.output_file, '-struct', 'results');
fprintf('Saved results to %s\n', cfg.output_file);
end

function userConfig = prompt_run_settings(userConfig)
% Prompt interactively only for settings not already provided.
% This keeps scripted runs working while still making manual runs easy.

policyOptions = {'geographical_balance', 'income_priority_opportunity', 'anti_monopoly', 'none'};
userConfig.scenario_name = '5 prosumer system';
fileDefaults = build_config(struct());

if ~isfield(userConfig, 'fairness_policy') || isempty(userConfig.fairness_policy)
    % Policy selection still happens here rather than in the JSON file.
    fprintf('Select fairness policy:\n');
    fprintf('  1. geographical_balance\n');
    fprintf('  2. income_priority_opportunity\n');
    fprintf('  3. anti_monopoly\n');
    fprintf('  4. none\n');

    while true
        policyChoice = input('Enter 1, 2, 3, or 4: ', 's');
        switch strtrim(policyChoice)
            case '1'
                userConfig.fairness_policy = policyOptions{1};
                break;
            case '2'
                userConfig.fairness_policy = policyOptions{2};
                break;
            case '3'
                userConfig.fairness_policy = policyOptions{3};
                break;
            case '4'
                userConfig.fairness_policy = policyOptions{4};
                break;
            otherwise
                fprintf('Invalid selection. Please enter 1, 2, 3, or 4.\n');
        end
    end
end

if ~isfield(userConfig, 'W') || isempty(userConfig.W)
    % Weeks have to be a positive integer because the rest of the code assumes full weeks.
    while true
        weekChoice = input('Enter number of weeks to simulate: ', 's');
        weekValue = str2double(strtrim(weekChoice));
        if isfinite(weekValue) && weekValue >= 1 && mod(weekValue, 1) == 0
            userConfig.W = weekValue;
            break;
        end
        fprintf('Invalid input. Please enter a positive integer.\n');
    end
end

% lambda_D is fixed by the code default now, not prompted at run start.
if ~isfield(userConfig, 'lambda_D') || isempty(userConfig.lambda_D)
    userConfig.lambda_D = fileDefaults.lambda_D;
end

% Only prompt for the policy parameters the chosen policy actually uses.
switch userConfig.fairness_policy
    case {'geographical_balance', 'income_priority_opportunity', 'anti_monopoly'}
        if ~isfield(userConfig, 'phi_max') || isempty(userConfig.phi_max)
            userConfig.phi_max = prompt_numeric_with_recommended('phi_max', fileDefaults.phi_max, 'cap on the fairness price adjustment');
        end
        if ~isfield(userConfig, 'eta_fair') || isempty(userConfig.eta_fair)
            userConfig.eta_fair = prompt_numeric_with_recommended('eta_fair', fileDefaults.eta_fair, 'step size that scales the raw fairness signal');
        end
        if ~isfield(userConfig, 'beta_forget') || isempty(userConfig.beta_forget)
            userConfig.beta_forget = prompt_numeric_with_recommended('beta_forget', fileDefaults.beta_forget, 'memory decay on yesterday''s fairness adjustment');
        end
end

switch userConfig.fairness_policy
    case 'income_priority_opportunity'
        if ~isfield(userConfig, 'poverty_quantile') || isempty(userConfig.poverty_quantile)
            userConfig.poverty_quantile = prompt_numeric_with_recommended('poverty_quantile', fileDefaults.poverty_quantile, 'fraction of lowest-load prosumers eligible for support');
        end

    case 'anti_monopoly'
        if ~isfield(userConfig, 'anti_monopoly_delta') || isempty(userConfig.anti_monopoly_delta)
            userConfig.anti_monopoly_delta = prompt_numeric_with_recommended('anti_monopoly_delta', fileDefaults.anti_monopoly_delta, 'tolerance added on top of the 20%% accepted-share threshold');
        end
end

fprintf('Run parameter summary:\n');
fprintf('  lambda_D = %.12g\n', userConfig.lambda_D);
fprintf('  fairness_policy = %s\n', userConfig.fairness_policy);
if isfield(userConfig, 'phi_max')
    fprintf('  phi_max = %.12g\n', userConfig.phi_max);
end
if isfield(userConfig, 'eta_fair')
    fprintf('  eta_fair = %.12g\n', userConfig.eta_fair);
end
if isfield(userConfig, 'beta_forget')
    fprintf('  beta_forget = %.12g\n', userConfig.beta_forget);
end
if isfield(userConfig, 'poverty_quantile')
    fprintf('  poverty_quantile = %.12g\n', userConfig.poverty_quantile);
end
if isfield(userConfig, 'anti_monopoly_delta')
    fprintf('  anti_monopoly_delta = %.12g\n', userConfig.anti_monopoly_delta);
end
end

function value = prompt_numeric_with_recommended(name, recommendedValue, explanation)
% Hitting enter keeps the recommended value shown in the prompt.
while true
    promptText = sprintf('Enter %s [recommended/current: %.12g] - %s: ', name, recommendedValue, explanation);
    rawValue = input(promptText, 's');
    if isempty(strtrim(rawValue))
        value = recommendedValue;
        return;
    end

    value = str2double(strtrim(rawValue));
    if isfinite(value)
        return;
    end

    fprintf('Invalid input. Please enter a numeric value.\n');
end
end

function cfg = sync_config_with_prosumers(cfg, pros)
% Derive dimensions from the active prosumer table.
% This keeps the code consistent even if the JSON scenario changes size.

cfg.N = numel(pros.i);
cfg.Nb = numel(unique(pros.bus));
busCounts = accumarray(pros.bus, 1, [cfg.Nb, 1]);
cfg.Np_per_bus = max(busCounts);
end

function outputFile = make_output_filename(cfg)
% Output name is based on the policy and horizon so runs do not overwrite quietly.
policyName = regexprep(lower(cfg.fairness_policy), '[^a-z0-9]+', '_');
scenarioName = regexprep(lower(cfg.scenario_name), '[^a-z0-9]+', '_');
outputFile = sprintf('results_%s_%dw_%s.mat', policyName, cfg.W, scenarioName);
end
