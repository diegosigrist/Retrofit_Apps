function [I_tot_roof,I_tot_walls] = solar_calc(input_file,day_0,n_days,longitude,latitude,TZ,or_walls)
% Calculates the solar irradiance at an arbitrarily tilted and oriented surface according to ISO 52010

%% Read input
t_shift = TZ-longitude/15;
n = 1;
days = xlsread(input_file,1,'A2:A8761');
hours = xlsread(input_file,1,'B2:B8761');
BNI = xlsread(input_file,1,'C2:C8761');
DHI = xlsread(input_file,1,'D2:D8761');

%% Start calculations
for i=(day_0*24-23):((day_0+n_days-1)*24)
    % Solar declination (in degrees)
    sol_decl(i) = 0.33281-22.984*cos(pi/180*360/365*days(i))-0.3499*cos(pi/180*2*360/365*days(i))-0.1398*cos(pi/180*3*360/365*days(i))+3.7872*sin(pi/180*360/365*days(i))+0.03205*sin(pi/180*2*360/365*days(i))+0.07187*sin(pi/180*3*360/365*days(i));
    % Equation of time (in minutes)
    if days(i)<21
        t_eq(i) = 2.6+0.44*days(i);
    elseif days(i)<136
        t_eq(i) = 5.2+9*cos((days(i)-43)*0.0357);
    elseif days(i)<241
        t_eq(i) = 1.4-5*cos((days(i)-135)*0.0449);
    elseif days(i)<336
        t_eq(i) = -6.3-10*cos((days(i)-306)*0.036);
    else
        t_eq(i) = 0.45*(days(i)-359);
    end
    % Solar time (in hours)
    t_sol(i) = hours(i)-t_eq(i)/60-t_shift;
    % Solar hour angle (in degrees)
    sol_h_angle(i) = 180/12*(12.5-t_sol(i));
    if sol_h_angle(i)>180
        sol_h_angle(i) = sol_h_angle(i)-360;
    elseif sol_h_angle(i)<-180
        sol_h_angle(i) = sol_h_angle(i)+360;
    end
    % Solar altitude angle (in degrees)
    sol_alt_angle(i) = 180/pi*asin(sin(pi/180*sol_decl(i))*sin(pi/180*latitude)+cos(pi/180*sol_decl(i))*cos(pi/180*latitude)*cos(pi/180*sol_h_angle(i)));
    if sol_alt_angle(i)<0.0001
        sol_alt_angle(i) = 0;
    end
    % Solar zenith angle (in degrees)
    sol_zen_angle(i) = 90-sol_alt_angle(i);
    % Solar azimuth angle (in degrees)
    sin_sol_aux_1 = cos(pi/180*sol_decl(i))*sin(pi/180*(180-sol_h_angle(i)))/(cos(asin(sin(pi/180*sol_alt_angle(i)))));
    cos_sol_aux_1 = (cos(pi/180*latitude)*sin(pi/180*sol_decl(i))+sin(pi/180*latitude)*cos(pi/180*sol_decl(i))*cos(pi/180*(180-sol_h_angle(i))))/cos(asin(sin(pi/180*sol_alt_angle(i))));
    sol_aux_2 = 180/pi*asin(cos(pi/180*sol_decl(i))*sin(pi/180*(180-sol_h_angle(i))))/cos(asin(sin(pi/180*sol_alt_angle(i))));
    if (sin_sol_aux_1>=0) && (cos_sol_aux_1>0)
        sol_azi_angle(i) = abs(180-sol_aux_2);
    elseif cos_sol_aux_1<0
        sol_azi_angle(i) = sol_aux_2;
    else
        sol_azi_angle(i) = -1*(180+sol_aux_2);
    end
    % Solar angle of incidence on inclined surfaces (in degrees)
    for j=1:4
        sol_angle_walls(i,j) = 180/pi*acos(sin(pi/180*sol_decl(i))*sin(pi/180*latitude)*cos(pi/180*90)-sin(pi/180*sol_decl(i))*cos(pi/180*latitude)*sin(pi/180*90)*cos(pi/180*or_walls(j))+cos(pi/180*sol_decl(i))*cos(pi/180*latitude)*cos(pi/180*90)*cos(pi/180*sol_h_angle(i))+cos(pi/180*sol_decl(i))*sin(pi/180*latitude)*sin(pi/180*90)*cos(pi/180*or_walls(j))*cos(pi/180*sol_h_angle(i))+cos(pi/180*sol_decl(i))*sin(pi/180*90)*sin(pi/180*or_walls(j))*sin(pi/180*sol_h_angle(i)));
    end
    sol_angle_roof(i) = 180/pi*acos(sin(pi/180*sol_decl(i))*sin(pi/180*latitude)*cos(0)-sin(pi/180*sol_decl(i))*cos(pi/180*latitude)*sin(0)*cos(0)+cos(pi/180*sol_decl(i))*cos(pi/180*latitude)*cos(0)*cos(pi/180*sol_h_angle(i))+cos(pi/180*sol_decl(i))*sin(pi/180*latitude)*sin(0)*cos(0)*cos(pi/180*sol_h_angle(i))+cos(pi/180*sol_decl(i))*sin(0)*sin(0)*sin(pi/180*sol_h_angle(i)));
    % Direct irradiance (in W/m2)
    for k=1:4
        I_dir_walls(i,k) = max([0, BNI(i)*cos(pi/180*sol_angle_walls(i,k))]);
    end
    I_dir_roof(i) = max([0, BNI(i)*cos(pi/180*sol_angle_roof(i))]);
    % Diffuse irradiance (in W/m2)
    if sol_alt_angle(i)<10
        m(i) = 1/(sin(pi/180*sol_alt_angle(i))+0.15*(sol_alt_angle(i)+3.885)^-1.253);
    else
        m(i) = 1/sin(pi/180*sol_alt_angle(i));
    end
    I_ext(i) = 1370*(1+0.033*cos(pi/180*360/365*days(i)));
    if DHI(i)==0
        eps(i) = 999;
    else
        eps(i) = ((DHI(i)+BNI(i))/DHI(i)+1.014*(pi/180*sol_alt_angle(i))^3)/(1+1.014*(pi/180*sol_alt_angle(i))^3);
    end
    if eps(i)<1.065
        f_11 = -0.008; f_12 = 0.588; f_13 = -0.062; f_21 = -0.060; f_22 = 0.072; f_23 = -0.022;
    elseif eps(i)<1.23
        f_11 = 0.130; f_12 = 0.683; f_13 = -0.151; f_21 = -0.019; f_22 = 0.066; f_23 = -0.029;
    elseif eps(i)<1.5
        f_11 = 0.330; f_12 = 0.487; f_13 = -0.221; f_21 = 0.055; f_22 = -0.064; f_23 = -0.026;
    elseif eps(i)<1.95
        f_11 = 0.568; f_12 = 0.187; f_13 = -0.295; f_21 = 0.109; f_22 = -0.152; f_23 = -0.014;
    elseif eps(i)<2.8
        f_11 = 0.873; f_12 = -0.392; f_13 = -0.362; f_21 = 0.226; f_22 = -0.462; f_23 = 0.001;
    elseif eps(i)<4.5
        f_11 = 1.132; f_12 = -1.237; f_13 = -0.412; f_21 = 0.288; f_22 = -0.823; f_23 = 0.056;
    elseif eps(i)<6.2
        f_11 = 1.060; f_12 = -1.6; f_13 = -0.359; f_21 = 0.264; f_22 = -1.127; f_23 = 0.131;
    else
        f_11 = 0.678; f_12 = -0.327; f_13 = -0.250; f_21 = 0.156; f_22 = -1.377; f_23 = 0.251;
    end
    sky_bri(i) = m(i)*DHI(i)/I_ext(i);
    F_1(i) = max([0,f_11+f_12*sky_bri(i)+f_13*pi*sol_zen_angle(i)/180]);
    F_2(i) = f_21+f_22*sky_bri(i)+f_23*pi*sol_zen_angle(i)/180;
    for l=1:4
        a_walls(i,l) = max([0, cos(pi/180*sol_angle_walls(i,l))]);
        b_walls(i,l) = max([cos(pi/180*85),cos(pi/180*sol_zen_angle(i))]);
        I_dif_walls(i,l) = DHI(i)*((1-F_1(i))*(1+cos(pi/180*90))/2+F_1(i)*a_walls(i,l)/b_walls(i,l)+F_2(i)*sin(pi/180*90));
        I_circum_walls(i,l) = DHI(i)*F_1(i)*a_walls(i,l)/b_walls(i,l);
    end
     a_roof(i) = max([0, cos(pi/180*sol_angle_roof(i))]);
     b_roof(i) = max([cos(pi/180*85),cos(pi/180*sol_zen_angle(i))]);
     I_dif_roof(i) = DHI(i)*((1-F_1(i))*(1+cos(0))/2+F_1(i)*a_roof(i)/b_roof(i)+F_2(i)*sin(0));
     I_circum_roof(i) = DHI(i)*F_1(i)*a_roof(i)/b_roof(i);
    % Diffuse irradiance due to ground reflection (in W/m2)
    I_dif_grnd_walls(i) = (DHI(i)+BNI(i)*sin(pi/180*sol_alt_angle(i)))*0.2*(1-cos(pi/180*90))/2;
    I_dif_grnd_roof(i) = (DHI(i)+BNI(i)*sin(pi/180*sol_alt_angle(i)))*0.2*(1-cos(0))/2;
    % WALLS: Total direct and diffuse solar irradiance (in W/m2)
    for m=1:4
        I_dir_tot_walls(i,m) = I_dir_walls(i,m)+I_circum_walls(i,m);
        I_dif_tot_walls(i,m) = I_dif_walls(i,m)-I_circum_walls(i,m)+I_dif_grnd_walls(i);
        I_tot_walls(n,m) = I_dir_tot_walls(i,m)+I_dif_tot_walls(i,m);
    end
    % ROOF: Total direct and diffuse solar irradiance (in W/m2)
    I_dir_tot_roof(i) = I_dir_roof(i)+I_circum_roof(i);
    I_dif_tot_roof(i) = I_dif_roof(i)-I_circum_roof(i)+I_dif_grnd_roof(i);
    I_tot_roof(n) = I_dir_tot_roof(i)+I_dif_tot_roof(i);
    n = n+1;
end
end

