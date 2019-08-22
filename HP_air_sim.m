function [E_hp,SPF_h,SPF_dhw] = HP_air_sim(T_supply_hour,P_h_hour,Q_dhw,T_dhw)
% Hourly simulation of air-to-water heat pump operation
% References: WPesti, SIA 384/3

% COP data of Alpha Innotec LW 310A
T_source_data = [-20,-20,-20,-15,-15,-15,-10,-10,-10,-5,-5,-5,0,0,0,5,5,5,10,10,10,15,15,15,20,20,20,25,25,25,30,30,30,35,35,35];
T_supply_data = [35,42.5,50,35,42.5,50,35,42.5,50,35,42.5,50,35,42.5,50,35,42.5,50,35,42.5,50,35,42.5,50,35,42.5,50,35,42.5,50,35,42.5,50,35,42.5,50];
COP = [2,1.75,1.5,2.3,2.025,1.75,2.7,2.35,2,3,2.625,2.25,3.3,2.9,2.5,3.75,3.25,2.75,4.1,3.6,3.1,4.45,3.875,3.3,4.75,4.15,3.55,5.1,4.475,3.85,5.45,4.825,4.2,5.8,5.075,4.35];

% COP function of air-to-water heat pump
fitType = 'poly22'; 
COP_HP_air = fit([T_source_data.',T_supply_data.'],COP.',fitType);
coeff = coeffvalues(COP_HP_air);

% Input: Outdoor temperature of reference year
input_file = 'input_data.xlsx';
T_source = xlsread(input_file,2,'C2:C8761');

% Calculation of SCOP (for heating and dhw)
COP_hour = zeros(8760,1);
E_h_hour = zeros(8760,1);
for i=1:8760
    if P_h_hour(i)>0
        COP_hour(i) = coeff(1)+coeff(2)*T_source(i)+coeff(3)*T_supply_hour(i)+coeff(4)*T_source(i)^2+coeff(5)*T_source(i)*T_supply_hour(i)+coeff(6)*T_supply_hour(i)^2;
        E_h_hour(i) = P_h_hour(i)/COP_hour(i);
    else
        COP_hour(i) = 0;
        E_h_hour(i) = 0;
    end
end
SCOP_h = sum(P_h_hour)/sum(E_h_hour);
SCOP_dhw = coeff(1)+coeff(2)*mean(T_source)+coeff(3)*T_dhw+coeff(4)*mean(T_source)^2+coeff(5)*mean(T_source)*T_dhw+coeff(6)*T_dhw^2;

% Efficiency of heat pump
loss_storage = 0.02;                % Storage heat losses [-] (according to WPesti)
loss_cycling = 0.02;                % Losses due to (on and off) cycling of heat pump [-] (according to WPesti)
n_hp = 1-loss_storage-loss_cycling; % Total efficiency of heat pump

% Auxiliary energy
E_pump_h = 2300*50/1000;                     % Electricity consumption of charging pump for space heating [kWh/a] (full load hours * power demand)
E_pump_dhw = 400*50/1000;                    % Electricity consumption of charging pump for DHW [kWh/a] (full load hours * power demand)
E_legionella = 52*300*5*4.190*0.99/3600;     % Electricity needed to heat up 300l of water from 55°C to 60°C once per week [kWh/a]

% Calculation of SPF (for heating and dhw)
Q_h_year = sum(P_h_hour)/1000;               % Heating demand [kWh/a]
SPF_h = n_hp/(1/SCOP_h+E_pump_h/Q_h_year);
SPF_dhw = n_hp/(1/SCOP_dhw+(E_pump_dhw+E_legionella)/Q_dhw);

% Final energy demand for space heating and DHW [kWh/a]
E_hp = Q_h_year/SPF_h+Q_dhw/SPF_dhw;

end

