# Optimal Sizing of a Hybrid Microgrid using Particle Swarm Optimization (PSO)

> **Final Year Project** — Designed by **Isaac-great** for a client of Deethunder Nexus

---

## Abstract

This project presents the design and simulation of an optimization system for determining the optimal sizing of a hybrid microgrid. The microgrid consists of three main generation and storage components: a Solar Photovoltaic (PV) System, a Battery Energy Storage System (BESS), and a Diesel Generator (DG). 

The system leverages **Particle Swarm Optimization (PSO)** modelled within **MATLAB** to determine the optimal capacities (`PV_Size_kW`, `Battery_Size_kWh`, and `DG_Size_kW`). The objective evaluates technical and economic parameters to minimize the annualized cost while maximizing reliability (minimizing Loss of Power Supply Probability - LPSP). The optimized model is then simulated in a dynamically generated **Simulink** architecture.

---

## System Architecture

The diagram below shows the high-level system optimization strategy:

![System Architecture](docs/system%20block%20diagram.png)

---

## Project Structure

```text
📦 hybrid-microgrid-optimization
 ├── 📄 Project_run.m              # Main entry point for the simulation and PSO optimization
 ├── 📄 .gitignore                 # GitHub ignore properties
 ├── 📄 README.md                  # Project documentation
 ├── 📁 data/                      # Simulation profiles (.mat)
 │    ├── 📄 battery_data.mat
 │    ├── 📄 cost_data.mat
 │    ├── 📄 diesel_generator_data.mat
 │    ├── 📄 load_profile.mat
 │    └── 📄 solar_profile.mat
 ├── 📁 src/                       # Supporting MATLAB execution scripts
 │    ├── 📄 build_hybrid_microgrid.m
 │    └── 📄 pso_fitness.m
 ├── 📁 docs/                      # Core algorithm documentation
 │    ├── 📄 PSO FLOWCHART.drawio
 │    ├── 🖼️ PSO FLOWCHART.drawio.png
 │    └── 📄 Pso Algorithm.txt
 ├── 📁 assets/                    # Presentation / Model Images
 │    ├── 🖼️ battery.jpg
 │    ├── 🖼️ gen.jpg
 │    ├── 🖼️ load.png
 │    └── 🖼️ solar.jpg
 └── 📁 Results/                   # Auto-generated CSVs and visual plots
```

## How It Works

### 1. Data Initialization & Setup
The project first loads environmental condition time-series data such as load profiles and solar irradiance from the `data/` directory.

### 2. PSO Optimization Engine (`pso_fitness.m`)
The PSO engine utilizes upper and lower bounds to search for the best sizing configuration for Solar PV, Battery, and Diesel Generator capacity. The algorithm iterates through swarm particles evaluating the fitness configuration using cost metrics and returns the global best configuration.

### 3. Simulink Model Building (`build_hybrid_microgrid.m`)
A Simulink model is programmatically constructed using the sizes specified by the PSO framework. It models state of charge (SOC), total system thresholds, un-met loads, and dispatch logic (e.g., the DG starts if SOC falls below minimum thresholds). 

### 4. Post-Processing & Metrics
Outputs are evaluated into a robust financial and operational report detailing Annual Cost, Component Share, and Output metrics which are saved directly into the `Results/` folder.

---

## Running the Simulation

### Prerequisites
- MATLAB (R2020a or newer recommended)
- Simulink
- Global Optimization Toolbox (required for `particleswarm`)

### Batch Simulation Execution

```matlab
% Open MATLAB, navigate to the project folder, then run:
Project_run
```

Runs the simulation and saves generation metrics to:
- `Results/CSV/` (numerical data and sizing tables)
- `Results/Figures/` (battery SOC, diesel power generation charts, and energy mix visualizations)
- `Results/Text/optimization_results.txt` (text summary report)

---

## Project Credits

This project was done by **Deethunder Nexus ventures**.

- **Website:** [www.deethundernexus.org](https://deethundernexus.org/)
- **Email:** info@deethundernexus.org

---

## License

**Proprietary / All Rights Reserved Custom License**

This project was developed as an academic final-year submission. All intellectual property rights are strictly reserved by the respective institution and the student developer.

### Copyright & Usage Restrictions
- **No Reproduction or Legal Use:** This codebase, models, and associated documentation may not be copied, reproduced, distributed, or repurposed for any commercial, non-commercial, or legal use.
- **Client Confidentiality:** Due to strict client confidentiality privileges, any request for reproduction, reference, or access to proprietary assets must be formally directed to the organization.

For permissions and inquiries, please contact **Deethunder Nexus ventures** prior to any intended usage.
