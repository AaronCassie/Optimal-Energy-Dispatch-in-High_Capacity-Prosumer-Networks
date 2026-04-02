function cfg = build_config(userConfig)
% Build the run configuration.
% This is the central place where defaults live before prompts/overrides apply.

% Default input source.
cfg.input_file = 'input_data_5bus.json';
cfg.scenario_name = '5 prosumer system';

% Baseline dimensions. These can be overwritten later by the loaded data.
cfg.Nb = 5;
cfg.Np_per_bus = 1;
cfg.N = 5;
cfg.T = 24;
cfg.dt = 1;

% Horizon settings.
cfg.W = 2;                     % user-settable
cfg.D = 7 * cfg.W;
cfg.Kmax = 20;

% Default fairness policy.
cfg.fairness_policy = 'geographical_balance';  % user-settable

% Fairness / policy parameters.
cfg.eta_fair = 0.8;
cfg.eps_q = 1e-6;
cfg.eps0 = 1e-9;
cfg.eps_IBR = 1e-3;
cfg.delta = 0.02;
cfg.anti_monopoly_delta = 0.1;
cfg.beta_forget = 0.15;
cfg.phi_max = 0.05;
cfg.poverty_quantile = 0.4;

% Demand and planning parameters.
cfg.lambda_D = 12;              % scenario default / user-settable
cfg.C_need = 100000;
cfg.c_cap = 1000;

% Storage efficiency parameters.
cfg.eta_ch = 0.95;
cfg.eta_dis = 0.95;

% Pricing constants.
cfg.e_margin = 0.075;
cfg.e_min = 0.0165;
cfg.r_low = 0.045;

% Legacy default output name. main_run_simulation builds the descriptive filename.
cfg.output_file = 'simulation_results.mat';

% Keep solver options centralized so version-specific fixes stay in one place.
cfg.intlinprog_options = optimoptions('intlinprog');
cfg.intlinprog_options = set_option_if_supported(cfg.intlinprog_options, 'Display', 'off');
cfg.intlinprog_options = set_option_if_supported(cfg.intlinprog_options, 'MaxTime', 30);

% The leader is linear in the active implementation, but we keep linprog options explicit.
cfg.linprog_options = optimoptions('linprog');
cfg.linprog_options = set_option_if_supported(cfg.linprog_options, 'Display', 'off');
cfg.linprog_options = set_option_if_supported(cfg.linprog_options, 'OptimalityTolerance', 1e-8);
cfg.linprog_options = set_option_if_supported(cfg.linprog_options, 'ConstraintTolerance', 1e-8);

% Let the caller swap input files without editing this function.
if nargin > 0 && ~isempty(userConfig) && isfield(userConfig, 'input_file')
    cfg.input_file = userConfig.input_file;
end

% Pull system-level defaults from the JSON file before applying explicit overrides.
inputData = read_input_data(cfg.input_file);
if isfield(inputData, 'system')
    cfg = apply_system_data(cfg, inputData.system);
end

% Anything passed in explicitly should win over defaults and JSON values.
if nargin > 0 && ~isempty(userConfig)
    fns = fieldnames(userConfig);
    for k = 1:numel(fns)
        cfg.(fns{k}) = userConfig.(fns{k});
    end
end

% Recompute total days after the final week count is known.
cfg.D = 7 * cfg.W;

% Keep policy validation in one place so bad inputs fail early.
validPolicies = {'geographical_balance','income_priority_opportunity','anti_monopoly','none'};
if ~any(strcmp(cfg.fairness_policy, validPolicies))
    error('Invalid fairness_policy. Use geographical_balance, income_priority_opportunity, anti_monopoly, or none.');
end

% Prebuild the day-to-week mapping the rest of the simulation uses.
cfg.days_of_week = reshape(1:cfg.D, 7, cfg.W)';

end

function cfg = apply_system_data(cfg, systemData)
% Pull a small set of known fields from the input file.
if nargin < 2 || isempty(systemData)
    return;
end

% These are the pieces we actually need from the input file.
if isfield(systemData, 'scenario_name')
    cfg.scenario_name = systemData.scenario_name;
end
if isfield(systemData, 'num_buses')
    cfg.Nb = systemData.num_buses;
end
if isfield(systemData, 'hours_per_day')
    cfg.T = systemData.hours_per_day;
end
if isfield(systemData, 'time_step_hours')
    cfg.dt = systemData.time_step_hours;
end
if isfield(systemData, 'default_weeks')
    cfg.W = systemData.default_weeks;
end
if isfield(systemData, 'base_demand_scale')
    cfg.lambda_D = systemData.base_demand_scale;
end
end

function opts = set_option_if_supported(opts, name, value)
% Some option names differ across MATLAB versions, so guard the assignment.
if isprop(opts, name)
    opts.(name) = value;
end
end
