# Optimal Energy Dispatch in High-Capacity Prosumer Networks

This project develops an energy dispatch policy-testing framework for aggregators or utilities operating in prosumer networks. It is intended to evaluate how a chosen dispatch or fairness policy affects system outcomes, particularly the distribution of payments among prosumers and the equivalent capacity that can be obtained from prosumer participation. That is, the amount of capacity that a utility can build from prosumers and then defer investing in conventionally. Therefore, the tool allows the evaluation of a policy to uncover its long-term effects on capacity access, which can then allow utilities to make informed decisions not only about whether to implement the policy, but also how, since the tool allows them to vary key policy parameters and observe the resulting outcomes. These outcomes can then be used in capacity planning and financial projections to support a more informed and deterministic decision regarding policy implementation.

## Project Summary

The repository contains the MATLAB implementation of a local energy dispatch model used to study how different policy choices influence:

- offered energy
- accepted energy
- prosumer payments
- total grid payout
- equivalent capacity
- participation patterns over time

The model is currently demonstrated using a 5-bus, 5-prosumer test system defined in the input file, but the code structure is intended as a general policy-testing framework rather than a model limited in principle to that single case.

## Repository Structure

### Main simulation files

- `main_run_simulation.m`
- `run_outer_simulation.m`

### Configuration and input handling

- `build_config.m`
- `read_input_data.m`
- `load_prosumer_table.m`
- `load_policy_definition.m`
- `input_data_5bus.json`
- `input_policy_geographical_balance_demo.m`

### Profiles and state initialization

- `build_base_shapes.m`
- `generate_profiles.m`
- `initialize_states.m`

### Optimization and market clearing

- `solve_follower_day_milp.m`
- `solve_leader_hour_lp.m`
- `compute_feasible_demand.m`
- `check_ibr_convergence.m`

### Pricing, fairness, and metrics

- `compute_daily_price.m`
- `update_daily_willingness.m`
- `update_fairness.m`
- `compute_daily_metrics.m`
- `compute_weekly_metrics.m`
- `compute_planning_metrics.m`

### Output handling and plotting

- `pack_results.m`

## Input File

The model reads its system and prosumer data from:

- `input_data_5bus.json`

This file contains:

- system-level data
- prosumer-level data

The fairness policy is selected at run time in MATLAB and is not stored in the JSON file.

The repository also includes a separate external policy-definition file:

- `input_policy_geographical_balance_demo.m`

This file is a demonstration of how a fairness policy can be described outside the core solver using a structured MATLAB input file.

## Supported Fairness Policies

The active implementation currently supports the following selectable policies:

- `geographical_balance_input_file`
- `geographical_balance`
- `income_priority_opportunity`
- `anti_monopoly`
- `none`

## Outputs

Each run saves a `.mat` file containing:

- accepted energy
- offered energy
- charging and discharging schedules
- battery trajectories
- prices
- fairness adjustments
- daily and weekly metrics
- planning metrics such as `C_eq`, `C_avoided`, and `Savings`
- total offered energy per day over the horizon
- total payout per prosumer over the horizon

## Detailed Function Descriptions

### `main_run_simulation.m`

This is the main entry point for the project. It collects user inputs required for a run, builds the configuration structure, loads the system and prosumer data, generates profiles, initializes the state variables, runs the full simulation, packages the outputs, and saves the results to a `.mat` file.

### `build_config.m`

This function creates the configuration structure used throughout the simulation. It stores default values for the simulation horizon, policy parameters, pricing settings, solver tolerances, and file names. It also reads system-level settings from the JSON input file, loads the external policy definition file, and validates the selected policy.

### `read_input_data.m`

This function reads the external JSON file and decodes it into a MATLAB structure. It forms the interface between the external input data and the simulation.

### `load_prosumer_table.m`

This function loads the prosumer data from the JSON file and converts it into the `pros` structure used by the rest of the model. It checks that all required prosumer fields exist and verifies that the bus assignments are consistent with the declared system data.

### `load_policy_definition.m`

This function reads the external policy-definition MATLAB file and returns the policy structure used by the input-file policy path. It is used to support externally defined fairness-policy components outside the core solver code.

### `build_base_shapes.m`

This function defines the normalized 24-hour base profiles for load, solar generation, and wind generation. These profiles serve as the templates that are scaled and shifted for each prosumer.

### `generate_profiles.m`

This function builds the actual load and renewable generation profiles for each prosumer by applying scaling and time shifts to the base shapes. It also constructs the exogenous system demand profile and computes raw renewable surplus.

### `initialize_states.m`

This function initializes the state variables used at the beginning of the simulation. In the current implementation, it sets the fairness adjustment history to zero and initializes battery state-of-charge values.

### `run_outer_simulation.m`

This is the main simulation engine. It loops over weeks and days, and within each day executes the outer iterative best-response procedure. In each iteration, prosumer offers are computed, feasible demand is updated, the leader clearing problem is solved, convergence is checked, and fairness terms are updated once the day-level solution is fixed.

### `solve_follower_day_milp.m`

This function solves the day-level prosumer optimization problem. For prosumers with storage, the decision problem is formulated as a mixed-integer linear program that determines energy offers, charging, discharging, and battery trajectories over the day. For non-storage cases, it reduces to a simpler offer calculation.

### `solve_leader_hour_lp.m`

This function solves the hourly grid-clearing problem as a linear program. It determines how much of each prosumer’s offered energy is accepted, subject to demand satisfaction, loss adjustment, and offer bounds.

### `compute_feasible_demand.m`

This function computes the feasible demand used in the leader problem. In the current implementation, feasible demand is the minimum of exogenous demand and total loss-adjusted offered energy.

### `check_ibr_convergence.m`

This function checks whether the outer iterative best-response loop has converged. It compares the largest changes in offers and accepted allocations between consecutive iterations.

### `compute_daily_price.m`

This function computes the payment price and dispatch price for each prosumer for the day. These values depend on pricing margins, loss factors, retail rate inputs, and the current fairness adjustment.

### `update_daily_willingness.m`

This function converts the dispatch-side price signal into a daily willingness value for each prosumer. Lower dispatch price leads to higher willingness.

### `update_fairness.m`

This function implements the active policy logic. It computes the raw fairness signal from realized outcomes and then applies damping and clipping to generate the next fairness adjustment term. It supports both built-in policy branches and the external input-file policy path.

### `compute_daily_metrics.m`

This function computes daily accepted energy and daily payout values after market clearing. It also returns the mean payout value for the day.

### `compute_weekly_metrics.m`

This function computes weekly access-related metrics from the daily accepted-energy totals. These include weekly accepted energy, participation shares, and an underservice-style metric.

### `compute_planning_metrics.m`

This function computes planning-oriented measures from the offered energy outcomes. These include equivalent capacity `C_eq`, avoided capacity, and savings estimates.

### `pack_results.m`

This function gathers all important inputs, outputs, histories, prices, fairness values, and summary metrics into a single results structure for saving and later analysis. This includes convenience outputs such as total offered energy per day and total payout per prosumer over the full horizon.


## Test System

The current input file defines a 5-bus test system with one prosumer assigned to each bus. The prosumers differ in:

- load scale
- solar scale
- wind scale
- time shifts
- battery capacity
- charging and discharging limits
- network loss factor

This test system is used to demonstrate the framework and compare policy outcomes.


## How to Run
Ensure Optimization Toolbox is installed on MATLAB.
Open MATLAB in the repository folder and run:


main_run_simulation.m



## Defining a New Input-File Fairness Policy

The repository includes an example external policy definition in `input_policy_geographical_balance_demo.m`. This file shows how a policy can be described outside the main solver by writing a structured set of rule components that the fairness updater can read.


### Constructing the fairness signal

When defining a new policy, the key design choice is the sign and size of the raw fairness signal `f_fair`, because this is what feeds into the daily fairness adjustment and therefore affects later pricing and acceptance.

In this framework, a **negative** fairness signal acts as support, while a **positive** fairness signal acts as a penalty.

This is because the fairness adjustment enters the daily price terms, and the grid then clears energy using the dispatch-side price. A lower future dispatch-side price makes a prosumer more attractive in clearing, while a higher future dispatch-side price makes a prosumer less attractive.

So, in practical terms:

- if the policy is intended to **help** a prosumer or group directly, then the fairness signal for that prosumer or group should be made **more negative**
- if the policy is intended to **penalize** a prosumer or group directly, then the fairness signal for that prosumer or group should be made **more positive**

This means that a supportive policy should assign the largest negative fairness signals to those participants the grid wants to benefit, while a penalizing policy should assign the largest positive fairness signals to those participants the grid wants to restrain.

The raw fairness signal does not act on its own; it feeds into the daily fairness adjustment update, which is then used in the next day’s pricing step. Therefore, when defining a policy, the user should think of `f_fair` as the directional policy signal that tells the model who should be supported and who should be penalized in future clearing.

### How it works
An input-file policy is defined in two parts:

1. The policy input file  
   This file declares the policy name and the rule components, such as:
   - the rule type
   - the metric being evaluated
   - how prosumers are grouped
   - the reference used for comparison
   - the gap direction
   - the rectifier
   - the output sign
   - the normalizer

2. The evaluator in `update_fairness.m`  
   The evaluator reads those fields and converts them into the actual fairness calculation used by the simulation.

### Meaning of the key terms
- `reference level`  
  This means the benchmark value that a prosumer or group is being compared against. In the geographical policy example, the reference level is the mean bus access across all buses.


- `gap_direction`  
  This tells the code how to form the difference between the reference and the group value.

- `rectifier`  
  This tells the code which part of the gap to keep.

- `normalizer`  
  This tells the code what to divide by so the fairness signal is scaled consistently.

### Geographical policy example

The built-in `geographical_balance` policy already uses these ideas, even though they were originally written directly as one formula.

For `gap_direction`, the policy compares each bus against the overall mean bus access by computing `mean_bus_access - bus_access(bus(:))`, so the gap is defined as the reference level minus the bus’s own level. That means a bus below the mean gets a positive gap, while a bus at or above the mean gets zero or negative gap.

For `rectifier`, the code then applies `max(0, ...)`, which means it keeps only the positive part of that gap. So the policy only reacts to under-served buses; it does not penalize buses that are already above the mean.

For `normalizer`, the code divides by `max(mean_bus_access, cfg.eps0)`. This scales the signal relative to the size of the reference itself, so the fairness adjustment is based on proportional shortfall rather than raw absolute difference. That makes the signal more stable and comparable across runs or operating conditions.

### Important 

 A user can change the policy definition freely, but if they introduce a brand-new label or rule component that the evaluator does not already recognize, then `update_fairness.m` must also be extended so the code knows how to interpret it.

For example, if a user wants to introduce:
- a new grouping method
- a new fairness metric
- a new reference calculation
- a new gap rule
- a new normalizer

then the evaluator must be updated accordingly.

### Workflow for adding a new policy

1. Create or edit an input policy file  
   Use `input_policy_geographical_balance_demo.m` as a template.

2. Add the rule labels to the input file  
   Define the policy structure by setting fields such as:
   - `rule_type`
   - `group_metric`
   - `group_by`
   - `reference_type`
   - `gap_direction`
   - `rectifier`
   - `output_sign`
   - `normalizer`

3. Extend the evaluator in `update_fairness.m` if needed  
   If the policy uses only labels that are already supported, no further logic changes are needed. If the policy introduces a new rule label or a new type of calculation, then `update_fairness.m` must be extended so the code knows what that new label means and how to compute it.

4. Register the policy in the run-time selection flow if needed  
   This step is only needed if the new policy should appear as a selectable option when the user runs the simulation manually. In that case, add it to:
   - `main_run_simulation.m`, so it appears in the policy selection menu
   - `build_config.m`, so it is treated as a valid policy during configuration checks

If the policy is only being used internally or called directly through code, this step may not be necessary.

### Clarified

So the input file defines **what** policy structure is intended, while `update_fairness.m` defines **how** each declared option is actually computed. If a user stays within the currently supported labels, only the input file needs to be edited. If a user wants a genuinely new policy structure, both the input file and the evaluator must be updated.



