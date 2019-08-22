function [E_hp,SPF_h,SPF_dhw,length] = HP_geothermal_sim(hload_max,T_supply_average,T_supply_hour,P_h_hour,Q_h_year,Q_dhw,T_dhw)
% Hourly simulation of geothermal heat pump operation
% (= Brine-to-water heat pump with geothermal probes)
% References: WPesti, SIA 384/3, Leistungsgarantie Gebäudetechnik

% COP data of CTA Optiheat 1-22e
T_source_data = [-5,-5,-5,0,0,0,5,5,5,10,10,10,15,15,15,20,20,20,25,25,25];
T_supply_data = [35,45,55,35,45,55,35,45,55,35,45,55,35,45,55,35,45,55,35,45,55];
COP = [4,3.1,2.45,4.5,3.4,2.7,5,3.8,3.05,5.5,4.3,3.4,6.1,4.75,3.8,6.75,5.25,4.2,7.6,5.9,4.8];

% COP function of geothermal heat pump: Formation of polynomials using
% standard measuring points (according to SIA 384/3)
fitType = 'poly22'; 
COP_HP_geothermal = fit([T_source_data.',T_supply_data.'],COP.',fitType);
coeff = coeffvalues(COP_HP_geothermal);

% Design of geothermal probe (according to SIA 384/6)
P_spec = 35;                                                                                                                                        % Specific abstraction capacity [W/m]
P_probe = hload_max-hload_max/(coeff(1)+coeff(2)*5+coeff(3)*T_supply_average+coeff(4)*5^2+coeff(5)*5*T_supply_average+coeff(6)*T_supply_average^2); % Assumption: T_source = 5°C, T_supply = T_supply_average
length = P_probe/P_spec;                                                                                                                            % Length of geothermal probe [m]

% Simulation of source temperature (according to WPesti)
t_op = (Q_h_year+Q_dhw)/(hload_max/1000);                                               % Annual operating time (full load hours) of heat pump [h]
COP_norm = coeff(1)+coeff(2)*0+coeff(3)*35+coeff(4)*0^2+coeff(5)*0*35+coeff(6)*35^2;    % COP at B0/W35
T_source = 283.15-(0.055+t_op/100*0.006)*hload_max/length*(COP_norm-1)/COP_norm+2-273.15;

% Calculation of SCOP (for heating and dhw)
COP_hour = zeros(8760,1);
E_h_hour = zeros(8760,1);
for i=1:8760
    if P_h_hour(i)>0
        COP_hour(i) = coeff(1)+coeff(2)*T_source+coeff(3)*T_supply_hour(i)+coeff(4)*T_source^2+coeff(5)*T_source*T_supply_hour(i)+coeff(6)*T_supply_hour(i)^2;
        E_h_hour(i) = P_h_hour(i)/COP_hour(i);
    else
        COP_hour(i) = 0;
        E_h_hour(i) = 0;
    end
end
SCOP_h = sum(P_h_hour)/sum(E_h_hour);
SCOP_dhw = coeff(1)+coeff(2)*T_source+coeff(3)*T_dhw+coeff(4)*T_source^2+coeff(5)*T_source*T_dhw+coeff(6)*T_dhw^2;

% Efficiency of heat pump
loss_storage = 0.02;                % Storage heat losses [-] (according to WPesti)
loss_cycling = 0.02;                % Losses due to (on and off) cycling of heat pump [-] (according to WPesti)
n_hp = 1-loss_storage-loss_cycling; % Total efficiency of heat pump

% Auxiliary energy
E_pump_h = 2300*106/1000+2300*50/1000;                      % Electricity consumption of source and charging pump for space heating [kWh/a] (full load hours * power demand)
E_pump_dhw = 400*106/1000+400*50/1000;                      % Electricity consumption of source and charging pump for DHW [kWh/a] (full load hours * power demand)
E_legionella = 52*300*5*4.190*0.99/3600;                    % Electricity needed to heat up 300l of water from 55°C to 60°C once per week [kWh/a]

% Calculation of SPF (for heating and dhw)
Q_h_year = sum(P_h_hour)/1000;               % Heating demand [kWh/a]
SPF_h = n_hp/(1/SCOP_h+E_pump_h/Q_h_year);
SPF_dhw = n_hp/(1/SCOP_dhw+(E_pump_dhw+E_legionella)/Q_dhw);

% Final energy demand for space heating and DHW [kWh/a]
E_hp = Q_h_year/SPF_h+Q_dhw/SPF_dhw;

end

