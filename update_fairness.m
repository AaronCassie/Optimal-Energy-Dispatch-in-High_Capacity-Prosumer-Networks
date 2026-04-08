function [phi_next, f_fair, phi_preclip] = update_fairness(cfg, policy, phi_curr, a_day, q_offer_day, ell, L_day, bus, Nb, s_raw_day, c_day, dch_day)
% Compute raw fairness signal
% then apply the existing damping and clipping block.

N = numel(phi_curr);

% Delivered accepted energy after loss adjustment.
delivered_accept = (1 - ell(:)) .* sum(a_day, 2);

% Delivered offered energy after loss adjustment.
delivered_opp = (1 - ell(:)) .* sum(q_offer_day, 2);

% Access ratio relative to what was actually offered.
access_ratio = delivered_accept ./ max(delivered_opp, cfg.eps_q);
mean_access_ratio = mean(access_ratio);

% Shares based on accepted and offered delivered energy.
real_share = delivered_accept / max(sum(delivered_accept), cfg.eps_q);
opp_share = delivered_opp / max(sum(delivered_opp), cfg.eps_q);

% Opportunity-based capacity uses pre-willingness feasible export capability.
q_cap_day = max(s_raw_day + dch_day - c_day, 0) * cfg.dt;
delivered_opp_cap = (1 - ell(:)) .* sum(q_cap_day, 2);
access_ratio_cap = delivered_accept ./ max(delivered_opp_cap, cfg.eps_q);
mean_access_ratio_cap = mean(access_ratio_cap);

% Share of feasible delivered opportunity.
opp_share_cap = delivered_opp_cap / max(sum(delivered_opp_cap), cfg.eps_q);

% Each policy only changes the raw fairness signal.
switch policy
    case 'geographical_balance_input_file'
        % This route evaluates the policy directly from the external definition.
        policyDef = cfg.policy_input_definition;
        f_fair = evaluate_input_policy(policyDef, cfg, access_ratio, bus, Nb);

    case 'geographical_balance'
        % Compare each bus against the mean bus-level access ratio.
        bus_access = zeros(Nb, 1);
        for m = 1:Nb
            idx = (bus(:) == m);
            bus_access(m) = mean(access_ratio(idx));
        end
        mean_bus_access = mean(bus_access);
        f_fair = -max(0, mean_bus_access - bus_access(bus(:))) ./ max(mean_bus_access, cfg.eps0);

    case 'income_priority_opportunity'
        % Same poverty gating as income_priority, but normalize by feasible opportunity.
        daily_load = sum(L_day, 2) * cfg.dt;
        p = cfg.poverty_quantile;
        sorted_load = sort(daily_load);
        k = max(1, min(N, ceil(p * N)));
        theta = sorted_load(k);
        eligible = double(daily_load <= theta);
        vulnerability = eligible ./ max(daily_load, cfg.eps_q);
        vulnerability_sum = sum(vulnerability);
        if vulnerability_sum > 0
            income_weight = vulnerability / vulnerability_sum;
        else
            income_weight = zeros(N,1);
        end
        shortfall = max(0, mean_access_ratio_cap - access_ratio_cap) ./ max(mean_access_ratio_cap, cfg.eps0);
        f_fair = -income_weight .* shortfall;

    case 'anti_monopoly'
        % Penalize any prosumer whose accepted share exceeds the anti-monopoly threshold.
        accepted_share = delivered_accept / max(sum(delivered_accept), cfg.eps_q);
        s_max = 0.20 + cfg.anti_monopoly_delta;
        f_fair = max(0, accepted_share - s_max);

    case 'none'
        % Full no-policy mode: zero signal and zero carried fairness adjustment.
        f_fair = zeros(N,1);
        phi_preclip = zeros(N,1);
        phi_next = zeros(N,1);
        return;

    otherwise
        error('Unknown fairness policy: %s', policy);
end

% The same damping and clipping rule is used for every policy.
phi_preclip = (1 - cfg.beta_forget) * phi_curr + cfg.eta_fair * f_fair;
phi_next = min(max(phi_preclip, -cfg.phi_max), cfg.phi_max);

end

function f_fair = evaluate_input_policy(policyDef, cfg, access_ratio, bus, Nb)
% Evaluate a user-defined fairness rule from the input policy file.
% For now this supports the group-gap structure used by the demo file.

switch policyDef.rule_type
    case 'group_gap_support'
        if ~isfield(policyDef, 'group_metric') || ~strcmp(policyDef.group_metric, 'access_ratio')
            error('Unsupported input-policy group_metric.');
        end
        if ~isfield(policyDef, 'group_by') || ~strcmp(policyDef.group_by, 'bus')
            error('Unsupported input-policy group_by.');
        end
        if ~isfield(policyDef, 'reference_type') || ~strcmp(policyDef.reference_type, 'mean_group_value')
            error('Unsupported input-policy reference_type.');
        end
        if ~isfield(policyDef, 'gap_direction') || ~strcmp(policyDef.gap_direction, 'reference_minus_group')
            error('Unsupported input-policy gap_direction.');
        end
        if ~isfield(policyDef, 'rectifier') || ~strcmp(policyDef.rectifier, 'positive_part')
            error('Unsupported input-policy rectifier.');
        end
        if ~isfield(policyDef, 'normalizer') || ~strcmp(policyDef.normalizer, 'reference_value')
            error('Unsupported input-policy normalizer.');
        end
        if ~isfield(policyDef, 'output_sign')
            error('Input policy is missing output_sign.');
        end

        groupValue = zeros(Nb, 1);
        for m = 1:Nb
            idx = (bus(:) == m);
            groupValue(m) = mean(access_ratio(idx));
        end

        referenceValue = mean(groupValue);
        rawGap = referenceValue - groupValue(bus(:));
        f_fair = policyDef.output_sign * max(0, rawGap) ./ max(referenceValue, cfg.eps0);

    otherwise
        error('Unknown input-file rule_type: %s', policyDef.rule_type);
end
end
