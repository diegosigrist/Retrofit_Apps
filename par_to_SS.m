function [A,B,C,D] = par_to_SS(H_se_env,H_ce_win,H_se_gf,H_ci_env,H_ci_win,...
    H_ci_gf,H_1_env,H_2_env,H_win,H_1_gf,H_2_gf,H_h,H_est,H_im,C_env,C_gf,C_h,C_im,C_i,Ts)
% Creates a state-space model with R and C parameters

%% Calculation of state matrix A
A = [((-1)*H_1_env*H_se_env/(H_1_env+H_se_env)-H_ci_env*H_2_env/(H_ci_env+H_2_env))/C_env, 0, 0, 0, H_ci_env*H_2_env/(C_env*(H_ci_env+H_2_env));
    0, ((-1)*H_1_gf*H_se_gf/(H_1_gf+H_se_gf)-H_ci_gf*H_2_gf/(H_ci_gf+H_2_gf))/C_gf, 0, 0, H_ci_gf*H_2_gf/(C_gf*(H_ci_gf+H_2_gf));
    0, 0, (-1)*H_h/C_h, 0, H_h/C_h;
    0, 0, 0, (-1)*H_im/C_im, H_im/C_im;
    H_ci_env*H_2_env/(C_i*(H_ci_env+H_2_env)), H_ci_gf*H_2_gf/(C_i*(H_ci_gf+H_2_gf)), H_h/C_i, H_im/C_i, (-1)*(H_ci_env*H_2_env/(H_ci_env+H_2_env)+...
    H_ci_win*H_win*H_ce_win/(H_ci_win*H_win+H_win*H_ce_win+H_ci_win*H_ce_win)+H_ci_gf*H_2_gf/(H_ci_gf+H_2_gf)+H_h+H_est+H_im)/C_i];
   
%% Calculation of input-to-state matrix B
B = [H_1_env*H_se_env/(C_env*(H_1_env+H_se_env)), H_1_env/(C_env*(H_1_env+H_se_env)), 0, 0, 0;
    0, 0, H_1_gf*H_se_gf/(C_gf*(H_1_gf+H_se_gf)), 0, 0;
    0, 0, 0, 0, 1/C_h;
    0, 0, 0, 1/C_im, 0;
    H_ci_win*H_win*H_ce_win/(C_i*(H_ci_win*H_win+H_win*H_ce_win+H_ci_win*H_ce_win))+H_est/C_i, 0, 0, 0, 0];

%% Calculation of state-to-output matric C
C = [0, 0, 0, 0, 1];

%% Calculation of feedthrough matrix D
D = zeros(1,5);
end

 