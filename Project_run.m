clear; clc; close all;
rng(42);

% Add new structured folders to MATLAB path
addpath('data');
addpath('src');
addpath('assets');
%% ================= 1. SETUP & DATA =================
resDir = 'Results'; 
figDir = fullfile(resDir,'Figures'); 
txtDir = fullfile(resDir,'Text');
csvDir = fullfile(resDir,'CSV'); % New CSV folder

if ~exist(figDir,'dir'), mkdir(figDir); end
if ~exist(txtDir,'dir'), mkdir(txtDir); end
if ~exist(csvDir,'dir'), mkdir(csvDir); end

% Load Data (or generate dummy if missing)
if exist('load_profile.mat','file')
    load load_profile.mat; load solar_profile.mat; 
    load cost_data.mat; load diesel_generator_data.mat;
else
    warning('Data files not found. Using generated dummy data.');
    Load_kW = 10 + 5*sin(linspace(0,100,8760)'); 
    Solar_Irradiance = max(0, 1000*sin(linspace(0,100,8760)'));
    Cost_PV_per_kW = 500; Cost_Battery_per_kWh = 300; 
    Cost_DG_per_kW = 800; Fuel_Cost_per_Liter = 1.2;
end

% Prepare Time Series
t = (0:length(Load_kW)-1)'; 
Load_TS = [t, Load_kW(:)]; 
Solar_TS = [t, Solar_Irradiance(:)];

assignin('base','Load_TS',Load_TS); 
assignin('base','Solar_TS',Solar_TS); 
assignin('base','Load_kW',Load_kW);
assignin('base','Cost_PV_per_kW',Cost_PV_per_kW);
assignin('base','Cost_Battery_per_kWh',Cost_Battery_per_kWh);
assignin('base','Cost_DG_per_kW',Cost_DG_per_kW);
assignin('base','Fuel_Cost_per_Liter',Fuel_Cost_per_Liter);

% Build Model
build_hybrid_microgrid;

%% ================= 2. PSO OPTIMIZATION =================
lb = [300 500 20]; 
ub = [2500 6000 600]; 

opts = optimoptions('particleswarm',...
    'SwarmSize', 25,... 
    'MaxIterations', 30,...
    'Display','iter',...
    'OutputFcn',@pso_detailed_tracker); % Updated Tracker Function

fprintf('Starting PSO Optimization...\n');
[xopt, ~] = particleswarm(@pso_fitness,3,lb,ub,opts);

%% ================= 3. FINAL PROCESSING =================
PV_Size_kW = xopt(1); Battery_Size_kWh = xopt(2); DG_Size_kW = xopt(3);
assignin('base','PV_Size_kW',PV_Size_kW); 
assignin('base','Battery_Size_kWh',Battery_Size_kWh); 
assignin('base','DG_Size_kW',DG_Size_kW);

% Run Final High-Fidelity Simulation
simOut = sim('hybrid_microgrid_model','FastRestart','off');

% Extract and Trim Data
DG_Power = simOut.get('DG_Power_Log'); DG_Power = DG_Power(1:length(t));
SOC_Data = simOut.get('SOC_Log');      SOC_Data = SOC_Data(1:length(t));
Unmet    = simOut.get('Unmet_Load_Log'); Unmet    = Unmet(1:length(t));
Last     = evalin('base','LastObjectives');

% --- METRICS CALCULATION ---
% 1. Calculate Basic Sums (Totals)
Total_Load_kWh  = sum(Load_kW);
Total_DG_kWh    = sum(DG_Power);
Total_Unmet_kWh = sum(Unmet);   

% 2. Calculate TOTAL Potential Generation (For reference/plots)
Potential_PV_Gen_Profile = (PV_Size_kW/1000) * Solar_Irradiance; 
Total_Potential_PV_kWh   = sum(Potential_PV_Gen_Profile);

% 3. Calculate USEFUL PV Energy (The energy that actually went to Load/Battery)
% Useful PV = Total Load - Energy supplied by Diesel
Useful_PV_kWh = Total_Load_kWh - Total_DG_kWh; 

% 4. Calculate Shares based on LOAD (Corrected for Table 3)
PV_Share = (Useful_PV_kWh / Total_Load_kWh) * 100;
DG_Share = (Total_DG_kWh / Total_Load_kWh) * 100;

% 5. Battery Stats
Min_SOC = min(SOC_Data); 
Max_SOC = max(SOC_Data); 
Avg_SOC = mean(SOC_Data);

% 6. DG Stats
DG_Indices = DG_Power > 1e-3;
DG_Hours   = sum(DG_Indices);
Avg_DG_Out = mean(DG_Power(DG_Indices));
if isnan(Avg_DG_Out), Avg_DG_Out = 0; end


%% ================= 4. CSV & TABLE GENERATION =================
% Table 1: Sizing
T1 = table({'PV Capacity';'Battery Capacity';'DG Capacity';'Annualized Cost'}, ...
           [PV_Size_kW; Battery_Size_kWh; DG_Size_kW; Last.AnnualCost], ...
           {'kW';'kWh';'kW';'USD'}, ...
           'VariableNames',{'Parameter','Value','Unit'});
writetable(T1, fullfile(csvDir, 'Table1_SystemSizing.csv'));

% Table 2: Reliability (Now Total_Unmet_kWh is defined)
T2 = table({'Total Load Energy';'Total Unmet Energy';'LPSP'}, ...
           [Total_Load_kWh; Total_Unmet_kWh; Last.LPSP], ...
           {'kWh';'kWh';'-'}, ...
           'VariableNames',{'Metric','Value','Unit'});
writetable(T2, fullfile(csvDir, 'Table2_Reliability.csv'));

% Table 3: Energy Breakdown (Using USEFUL Energy)
T3 = table({'Solar PV (Useful)';'Diesel Generator';'Total Load'}, ...
           [Useful_PV_kWh; Total_DG_kWh; Total_Load_kWh], ...
           [PV_Share; DG_Share; 100.00], ...
           'VariableNames',{'Source','Energy_Supplied_kWh','Share_Percent'});
writetable(T3, fullfile(csvDir, 'Table3_EnergyContribution.csv'));

% Table 4: Battery Stats
T4 = table({'Minimum SOC';'Maximum SOC';'Average SOC'}, ...
           [Min_SOC; Max_SOC; Avg_SOC], ...
           {'kWh';'kWh';'kWh'}, ...
           'VariableNames',{'Parameter','Value','Unit'});
writetable(T4, fullfile(csvDir, 'Table4_BatteryStats.csv'));

% Table 5: DG Stats
T5 = table({'DG Operating Hours';'DG Energy Supplied';'Average DG Output'}, ...
           [DG_Hours; Total_DG_kWh; Avg_DG_Out], ...
           {'Hours';'kWh';'kW'}, ...
           'VariableNames',{'Metric','Value','Unit'});
writetable(T5, fullfile(csvDir, 'Table5_DGStats.csv'));

% Table 6: PSO History
if evalin('base','exist(''PSO_Detail_History'',''var'')')
    HistData = evalin('base','PSO_Detail_History');
    T6 = array2table(HistData, 'VariableNames', {'Iteration','F_Count','Best_f_x','Mean_f_x','Stall_Iterations'});
    writetable(T6, fullfile(csvDir, 'Table6_PSO_Iteration_History.csv'));
end

%% ================= 5. TEXT REPORT GENERATION =================
fid = fopen(fullfile(txtDir,'optimization_results.txt'),'w');

% 1. Print the Exact Block you want
fprintf(fid, 'Optimal PV: %.2f kW\n', PV_Size_kW);
fprintf(fid, 'Optimal Battery: %.2f kWh\n', Battery_Size_kWh);
fprintf(fid, 'Optimal DG: %.2f kW\n', DG_Size_kW);
fprintf(fid, 'Cost: %.2f\n', Last.AnnualCost);
fprintf(fid, 'LPSP: %.4f\n', Last.LPSP);
fprintf(fid, 'RE Share: %.2f%%\n', Last.RenewableShare*100);

fprintf(fid, 'TABLE 6 — PSO Iteration History:\n');
fprintf(fid, '| %-5s | %-7s | %-12s | %-12s | %-5s |\n', 'Iter', 'f-count', 'Best f(x)', 'Mean f(x)', 'Stall');
fprintf(fid, '|-------|---------|--------------|--------------|-------|\n');
if exist('HistData','var')
    for k = 1:size(HistData,1)
        fprintf(fid, '| %-5d | %-7d | %-12.4f | %-12.4f | %-5d |\n', ...
            HistData(k,1), HistData(k,2), HistData(k,3), HistData(k,4), HistData(k,5));
    end
end
fclose(fid);

fprintf('Optimal PV: %.2f kW\n', PV_Size_kW);
fprintf('Optimal Battery: %.2f kWh\n', Battery_Size_kWh);
fprintf('Optimal DG: %.2f kW\n', DG_Size_kW);
fprintf('Cost: %.2f\n', Last.AnnualCost);
fprintf('LPSP: %.4f\n', Last.LPSP);
fprintf('RE Share: %.2f%%\n', Last.RenewableShare*100);

%% ================= 6. PLOTS (PNG + FIG) =================

% 1. Diesel Dispatch
figure('Color','w'); 
plot(t, DG_Power,'r'); title('Diesel Generator Dispatch'); 
xlabel('Time (h)'); ylabel('Power (kW)'); grid on;
exportgraphics(gcf,fullfile(figDir,'DG_dispatch.png'));
savefig(gcf, fullfile(figDir,'DG_dispatch.fig')); % Save FIG

% 2. Battery SOC
figure('Color','w'); 
plot(t, SOC_Data,'b'); title('Battery State of Charge'); 
xlabel('Time (h)'); ylabel('Energy (kWh)'); grid on;
yline(Battery_Size_kWh*0.2, 'r--', 'Min SOC Limit');
exportgraphics(gcf,fullfile(figDir,'Battery_SOC.png'));
savefig(gcf, fullfile(figDir,'Battery_SOC.fig')); % Save FIG

% 3. Energy Mix
figure('Color','w'); 
bar([Useful_PV_kWh, Total_DG_kWh]);
exportgraphics(gcf,fullfile(figDir,'Energy_Mix.png'));
savefig(gcf, fullfile(figDir,'Energy_Mix.fig')); % Save FIG

% 4. Convergence
if exist('HistData','var')
    figure('Color','w'); 
    % Plot Best vs Mean
    plot(HistData(:,1), HistData(:,3), '-o', 'DisplayName', 'Best f(x)'); hold on;
    plot(HistData(:,1), HistData(:,4), '--x', 'DisplayName', 'Mean f(x)');
    title('PSO Convergence Metrics'); xlabel('Iteration'); ylabel('Objective Value');
    legend show; grid on;
    exportgraphics(gcf,fullfile(figDir,'PSO_Convergence.png'));
    savefig(gcf, fullfile(figDir,'PSO_Convergence.fig')); % Save FIG
end

% 5. Unmet Load
figure('Color','w');
plot(t, Unmet, 'm'); title('Unmet Load Profile');
xlabel('Time (h)'); ylabel('Unmet Power (kW)'); grid on;
exportgraphics(gcf,fullfile(figDir,'Unmet_Load.png'));
savefig(gcf, fullfile(figDir,'Unmet_Load.fig')); % Save FIG

disp('✅ Optimization Complete.');
disp('✅ CSV files saved in Results/CSV');
disp('✅ PNG and FIG files saved in Results/Figures');

%% ================= 7. DETAILED PSO TRACKER =================
function stop = pso_detailed_tracker(optimValues,state)
    stop = false; 
    persistent fullHistory
    if strcmp(state,'init')
        fullHistory = [];
    elseif strcmp(state,'iter')
        % Capture: Iteration | f-count | Best f(x) | Mean f(x) | Stall
        newRow = [optimValues.iteration, optimValues.funccount, ...
                  optimValues.bestfval, optimValues.meanfval, optimValues.stalliterations];
        fullHistory = [fullHistory; newRow];
        assignin('base','PSO_Detail_History',fullHistory); 
    end
end