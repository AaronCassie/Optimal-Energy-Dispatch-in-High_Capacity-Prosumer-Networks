# Optimal Energy Dispatch in High-Capacity Prosumer Networks

This project develops an energy dispatch policy-testing framework for aggregators or utilities operating in prosumer networks. It is intended to evaluate how a chosen dispatch or fairness policy affects system outcomes, particularly the distribution of payments among prosumers and the equivalent capacity that can be obtained from prosumer participation. That is, the amount of capacity that a utility can then defer investing in conventionally. Therefore, the tool allows the evaluation of a policy to uncover its long-term effects on capacity access, which can then allow utilities to make informed decisions not only about whether to implement the policy, but also how, since the tool allows them to vary key policy parameters and observe the resulting outcomes. These outcomes can then be used in capacity planning and financial projections to support a more informed and deterministic decision regarding policy implementation.

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
- `input_data_5bus.json`

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

## Supported Fairness Policies

The active implementation currently supports only the following four policies:

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

## Detailed Function Descriptions

### `main_run_simulation.m`
This is the main entry point for the project. It collects user inputs required for a run, builds the configuration structure, loads the system and prosumer data, generates profiles, initializes the state variables, runs the full simulation, packages the outputs, and saves the results to a `.mat` file.

### `build_config.m`
This function creates the configuration structure used throughout the simulation. It stores default values for the simulation horizon, policy parameters, pricing settings, solver tolerances, and file names. It also reads system-level settings from the JSON input file and validates the selected policy.

### `read_input_data.m`
This function reads the external JSON file and decodes it into a MATLAB structure. It forms the interface between the external input data and the simulation.

### `load_prosumer_table.m`
This function loads the prosumer data from the JSON file and converts it into the `pros` structure used by the rest of the model. It checks that all required prosumer fields exist and verifies that the bus assignments are consistent with the declared system data.

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
This function implements the active policy logic. It computes the raw fairness signal from realized outcomes and then applies damping and clipping to generate the next fairness adjustment term.

### `compute_daily_metrics.m`
This function computes daily accepted energy and daily payout values after market clearing. It also returns the mean payout value for the day.

### `compute_weekly_metrics.m`
This function computes weekly access-related metrics from the daily accepted-energy totals. These include weekly accepted energy, participation shares, and an underservice-style metric.

### `compute_planning_metrics.m`
This function computes planning-oriented measures from the offered energy outcomes. These include equivalent capacity `C_eq`, avoided capacity, and savings estimates.

### `pack_results.m`
This function gathers all important inputs, outputs, histories, prices, fairness values, and summary metrics into a single results structure for saving and later analysis.

### `plot_prosumer_profiles.m`
This is a standalone helper script used to visualize the daily load and generation profiles of the prosumers defined in the input file.

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

Open MATLAB in the repository folder and run:


main_run_simulation.m






