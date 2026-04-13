function J = pso_fitness(x)
PV_Size_kW       = x(1);
Battery_Size_kWh = x(2);
DG_Size_kW       = x(3);

assignin('base','PV_Size_kW',PV_Size_kW);
assignin('base','Battery_Size_kWh',Battery_Size_kWh);
assignin('base','DG_Size_kW',DG_Size_kW);

persistent P
if isempty(P)
    P.Load  = evalin('base','Load_kW');
    P.Cpv   = evalin('base','Cost_PV_per_kW');
    P.Cbat  = evalin('base','Cost_Battery_per_kWh');
    P.Cdg   = evalin('base','Cost_DG_per_kW');
    P.Cfuel = evalin('base','Fuel_Cost_per_Liter');
end

try
    simOut = sim('hybrid_microgrid_model','FastRestart','on');
    DG = simOut.get('DG_Power_Log');   
    Un = simOut.get('Unmet_Load_Log'); 
    
    % Ensure vectors are column vectors and match sizes
    DG = DG(:); Un = Un(:);
    
    Load_E = sum(P.Load);
    DG_E   = sum(DG);
    LPSP   = sum(Un) / (Load_E + eps);

    % Economic calculation
    CAPEX = PV_Size_kW*P.Cpv + Battery_Size_kWh*P.Cbat + DG_Size_kW*P.Cdg;
    CRF = 0.08*(1.08)^20 / ((1.08)^20 - 1);
    AnnualCost = CAPEX*CRF + (DG_E * 0.3 * P.Cfuel); % Simplified Fuel Cost

    RenewableShare = (Load_E - DG_E) / (Load_E + eps);

    % Revised Objective: Better scaling to avoid f(x)=0
    % J = (Cost / 500k) + (LPSP * 100) + (1 - RE) * 10
    %J = (AnnualCost/500000) + (LPSP * 50) + (1 - RenewableShare) * 5;
% Change the weights: 0.7 for Cost, 0.2 for LPSP, 0.1 for RE
J = 0.7*(AnnualCost/200000) + 0.2*(LPSP * 50) + 0.1*(1 - RenewableShare);
    assignin('base','LastObjectives',struct('AnnualCost',AnnualCost,'LPSP',LPSP,'RenewableShare',RenewableShare));
catch
    J = 1e6; 
end
end