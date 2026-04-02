# Optimal Energy Dispatch in High-Capacity Prosumer Networks

This project develops an energy dispatch policy-testing framework for aggregators or utilities operating prosumer networks. It is intended to evaluate how a chosen dispatch or fairness policy affects system outcomes, particularly the distribution of payments among prosumers and the equivalent capacity that can be obtained from prosumer participation. That is, the amount of capacity that a utility can then defer investing in conventionally. Therefore, the tool allows the evaluation of a policy to uncover its long-term effects on capacity access, which can then allow utilities to make informed decisions not only about whether to implement the policy, but also how, since the tool allows them to vary key policy parameters and observe the resulting outcomes. These outcomes can then be used in capacity planning and financial projections to support a more informed and deterministic decision regarding policy implementation.

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
- `plot_prosumer_profiles.m`

## How to Run

Open MATLAB in the repository folder and run:

```matlab
results = main_run_simulation();
