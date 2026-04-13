function build_hybrid_microgrid
model = 'hybrid_microgrid_model';
if bdIsLoaded(model), close_system(model,0); end
new_system(model);

set_param(model,'Solver','FixedStepDiscrete','FixedStep','1','StopTime','8760');

% Sources
add_block('simulink/Sources/From Workspace',[model '/Load_In'],'VariableName','Load_TS','Position',[50 150 120 180]);
add_block('simulink/Sources/From Workspace',[model '/Solar_In'],'VariableName','Solar_TS','Position',[50 50 120 80]);

% PV and Net Load
add_block('simulink/Math Operations/Gain',[model '/PV_Gain'],'Gain','PV_Size_kW/1000','Position',[200 50 260 80]);
add_block('simulink/Math Operations/Sum',[model '/NetLoad'],'Inputs','+-','Position',[320 120 350 160]);

% Battery SOC (Limits 20% to 100%)
add_block('simulink/Discrete/Discrete-Time Integrator',[model '/SOC'],...
    'LimitOutput','on','UpperSaturationLimit','Battery_Size_kWh',...
    'LowerSaturationLimit','Battery_Size_kWh*0.2','InitialCondition','Battery_Size_kWh*0.8',...
    'Position',[420 110 480 160]);

% Logic
add_block('simulink/Sources/Constant',[model '/Threshold'],'Value','Battery_Size_kWh*0.25','Position',[350 250 450 270]);
add_block('simulink/Commonly Used Blocks/Relational Operator',[model '/Compare'],'Operator','<=','Position',[520 230 550 260]);
add_block('simulink/Signal Routing/Switch',[model '/DG_Switch'],'Threshold','0.5','Position',[650 120 700 170]);
add_block('simulink/Sources/Constant',[model '/Zero'],'Value','0','Position',[600 180 630 200]);
add_block('simulink/Discontinuities/Saturation', [model '/DG_Limit'], 'UpperLimit','DG_Size_kW','LowerLimit','0','Position',[750 120 800 150]);

% Sinks (CRITICAL: Decimation = 1)
add_block('simulink/Sinks/To Workspace',[model '/DG_Log'],'VariableName','DG_Power_Log','SaveFormat','Array','Decimation','1','Position',[850 120 920 150]);
add_block('simulink/Sinks/To Workspace',[model '/SOC_Log'],'VariableName','SOC_Log','SaveFormat','Array','Decimation','1','Position',[600 40 670 70]);
add_block('simulink/Sinks/To Workspace',[model '/Unmet_Log'],'VariableName','Unmet_Load_Log','SaveFormat','Array','Decimation','1','Position',[850 200 920 230]);

% Connections
add_line(model,'Solar_In/1','PV_Gain/1');
add_line(model,'Load_In/1','NetLoad/1');
add_line(model,'PV_Gain/1','NetLoad/2');
add_line(model,'NetLoad/1','SOC/1');
add_line(model,'SOC/1','SOC_Log/1');
add_line(model,'SOC/1','Compare/1');
add_line(model,'Threshold/1','Compare/2');
add_line(model,'Compare/1','DG_Switch/2');
add_line(model,'NetLoad/1','DG_Switch/1');
add_line(model,'Zero/1','DG_Switch/3');
add_line(model,'DG_Switch/1','DG_Limit/1');
add_line(model,'DG_Limit/1','DG_Log/1');
add_line(model,'DG_Limit/1','Unmet_Log/1');

save_system(model);
end