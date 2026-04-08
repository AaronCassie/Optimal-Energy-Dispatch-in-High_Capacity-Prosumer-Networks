function policyDef = input_policy_geographical_balance_demo()
% Demo policy input file.
% The idea is to show users how a policy can be described outside the core solver.

policyDef = struct();

% Friendly name for menus and saved output labels.
policyDef.policy_name = 'geographical_balance_input_file';

% The rule type tells the fairness updater what general calculation to do.
% Here we group prosumers by bus and work with bus-average access.
policyDef.rule_type = 'group_gap_support';

% Choose the metric that gets averaged within each group.
policyDef.group_metric = 'access_ratio';

% This says which grouping to use when forming averages.
policyDef.group_by = 'bus';

% Each group is compared against the mean across all groups.
policyDef.reference_type = 'mean_group_value';

% A positive gap means the group sits below the reference and should be supported.
policyDef.gap_direction = 'reference_minus_group';

% Keep only under-served groups. Anything already above the reference gets no push.
policyDef.rectifier = 'positive_part';

% Negative sign means support lowers the future fairness price term.
policyDef.output_sign = -1;

% Normalize by the same reference level used in the built-in geographical policy.
policyDef.normalizer = 'reference_value';

% Short notes for anyone reading the file.
policyDef.policy_notes = [ ...
    "Compute access ratio by bus, compare each bus to the mean bus access, " + ...
    "and apply support to buses that fall below the mean."];

end
