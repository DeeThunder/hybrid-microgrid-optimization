# Optimal Sizing of a Hybrid Microgrid using PSO

This project contains a MATLAB and Simulink simulation for optimizing the sizing of a hybrid microgrid. The microgrid consists of three main generation/storage components:
- Solar PV System
- Battery Energy Storage System (BESS)
- Diesel Generator (DG)

The system uses Particle Swarm Optimization (PSO) to determine the optimal sizes (`PV_Size_kW`, `Battery_Size_kWh`, and `DG_Size_kW`) that minimize annualized cost while ensuring reliable load supply (minimizing Unmet Load / Loss of Power Supply Probability - LPSP).

## Project Flowchart
![PSO Flowchart](docs/PSO%20FLOWCHART.drawio.png)

## Prerequisites
- **MATLAB** (R2020a or newer recommended)
- **Simulink**
- **Global Optimization Toolbox** (needed for `particleswarm` function)

## Usage Instructions

1. **Run the Main Script**: Open and simply run the `Project_run.m` file in MATLAB.
2. **Simulation Process**:
   * The script automatically adds required paths (`data/`, `src/`, `assets/`).
   * It loads the environmental data (`load_profile.mat`, `solar_profile.mat`, etc.).
   * The `build_hybrid_microgrid.m` function runs to automatically generate the Simulink block architecture.
   * A Particle Swarm Optimization routine starts running in the Command Window, iterating up to 30 times.
3. **View Results**:
   * Output values (costs, LPSP, renewable share) are displayed in the MATLAB Command Window.
   * CSV Data Tables and Figures are automatically generated and saved directly into the `Results/` folder.

## Repository Structure

```text
/
├── Project_run.m              # Main entry point for the simulation
├── .gitignore                 # GitHub ignore properties
├── README.md                  # This file
│
├── data/                      # Simulation profiles (.mat)
│   ├── battery_data.mat
│   ├── cost_data.mat
│   ├── diesel_generator_data.mat
│   ├── load_profile.mat
│   └── solar_profile.mat
│
├── src/                       # Supporting MATLAB execution scripts
│   ├── build_hybrid_microgrid.m
│   └── pso_fitness.m
│
├── docs/                      # Core algorithm documentation
│   ├── PSO FLOWCHART.drawio
│   ├── PSO FLOWCHART.drawio.png
│   └── Pso Algorithm.txt
│
├── assets/                    # Presentation / Model Images
│   ├── battery.jpg
│   ├── gen.jpg
│   ├── load.png
│   └── solar.jpg
│
└── Results/                   # Auto-generated CSVs and visual plots
```
