function policyDef = input_policy_geographical_balance_demo()
% Demo policy input file.
% The idea is to show users how a policy can be described outside the core solver.

policyDef = struct();

% Friendly name for menus and saved output labels.
policyDef.policy_name = 'geographical_balance_input_file';

% This mode tells the solver which built-in rule to mirror.
% Users could swap this later if they want to experiment with a new idea.
policyDef.policy_mode = 'bus_mean_access_shortfall';

% Short notes for anyone reading the file.
policyDef.policy_notes = [ ...
    "Compute access ratio by bus, compare each bus to the mean bus access, " + ...
    "and apply support to buses that fall below the mean."];

% For this demo version, the input-file policy is meant to match the
% current built-in geographical_balance policy exactly.
policyDef.match_builtin_policy = 'geographical_balance';

end
