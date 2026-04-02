# Optimal Energy Dispatch in High-Capacity Prosumer Networks

This repository contains the MATLAB implementation of a fairness-aware local energy dispatch model for a 5-bus prosumer network. The model represents a local energy-sharing system in which storage-enabled prosumers determine how much energy to offer and how to operate their batteries, while the grid clears accepted energy subject to system demand and network losses.

The test system used is a 5-bus, 5-prosumer system and is used to compare dispatch outcomes under four policy settings:

- `geographical_balance`
- `income_priority_opportunity`
- `anti_monopoly`
- `none`

## Project Purpose

The project studies how fairness mechanisms influence:

- offered energy
- accepted energy
- prosumer payments
- total grid payout
- equivalent capacity, that is how much capacity an aggregator can build from prosumers, and hence defer investing in conventionally
- participation patterns over time

The simulation is solved using an outer iterative best-response framework in which prosumer decisions and grid clearing are updated repeatedly until convergence.

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
