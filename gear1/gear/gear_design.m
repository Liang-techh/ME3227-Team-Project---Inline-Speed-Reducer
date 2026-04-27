% =========================================================================
% gear_design.m
% Description: Spur gear design with AGMA method:
%              bending and contact stress, all AGMA factors, safety factors.
% =========================================================================

function gear_results = gear_design(pinion_data, gear_data, application, ...
                                    material_pinion, material_gear, power, speed_pinion)
% gear_design: Complete AGMA spur gear design analysis
%
% Inputs:
%   pinion_data      - struct: teeth(z), module(m), face_width(mm), quality
%   gear_data        - struct: teeth(z), face_width(mm) [module same as pinion]
%   application      - struct: overload_factor, reliability, design_life_hours
%   material_pinion  - struct: S_t, S_c, hardness_HB, grade
%   material_gear    - struct: S_t, S_c, hardness_HB, grade
%   power            - Transmitted power (kW)
%   speed_pinion     - Pinion speed (rpm)
%
% Output:
%   gear_results     - Complete design results with safety factors

    fprintf('\n============================================================\n');
    fprintf('  Spur Gear Design - AGMA Method\n');
    fprintf('============================================================\n');
    
    %% ========== 1. BASIC GEOMETRY ==========
    fprintf('\n--- Gear Geometry ---\n');
    
    z_p = pinion_data.teeth;       % Pinion teeth
    z_g = gear_data.teeth;         % Gear teeth
    m = pinion_data.module;        % Module (mm)
    F_p = pinion_data.face_width;  % Pinion face width (mm)
    F_g = gear_data.face_width;    % Gear face width (mm)
    F = min(F_p, F_g);             % Use minimum face width for calculation
    phi = 20;                      % Pressure angle (deg)
    
    % Pitch diameters
    d_p = m * z_p;                 % Pinion pitch diameter (mm)
    d_g = m * z_g;                 % Gear pitch diameter (mm)
    
    % Center distance
    a_center = (d_p + d_g) / 2;
    
    % Addendum, dedendum
    h_a = 1.0 * m;                 % Standard addendum
    h_f = 1.25 * m;                % Standard dedendum
    
    % Outside diameters
    d_a_p = d_p + 2*h_a;           % Tip diameter pinion
    d_a_g = d_g + 2*h_a;           % Tip diameter gear
    
    % Base diameters
    d_b_p = d_p * cosd(phi);
    d_b_g = d_g * cosd(phi);
    
    fprintf('  Pinion: z=%d, d=%.2f mm, d_a=%.2f mm\n', z_p, d_p, d_a_p);
    fprintf('  Gear:   z=%d, d=%.2f mm, d_a=%.2f mm\n', z_g, d_g, d_a_g);
    fprintf('  Module: m=%.2f mm, Face width: F=%.1f mm\n', m, F);
    fprintf('  Center distance: a=%.2f mm\n', a_center);
    
    gear_results.z_p = z_p; gear_results.z_g = z_g;
    gear_results.m_mm = m; gear_results.F_mm = F;
    gear_results.d_p_mm = d_p; gear_results.d_g_mm = d_g;
    gear_results.a_center_mm = a_center;
    
    %% ========== 2. KINEMATICS & FORCE ==========
    fprintf('\n--- Kinematics & Forces ---\n');
    
    n_p = speed_pinion;
    P = power * 1000;              % Watts
    
    % Pitch line velocity (m/s)
    V = pi * d_p * n_p / 60000;    % m/s
    V_fpm = V * 196.85;            % ft/min (for Kv calculation)
    
    fprintf('  Pinion speed: n=%.0f rpm\n', n_p);
    fprintf('  Pitch line velocity: V=%.3f m/s = %.1f ft/min\n', V, V_fpm);
    
    % Torque on pinion
    T_p = P / (2*pi*n_p/60);       % N·m
    fprintf('  Torque: T=%.3f N·m\n', T_p);
    
    % Tangential force
    W_t = 2 * T_p * 1000 / d_p;    % N
    fprintf('  Tangential force: W_t=%.2f N\n', W_t);
    
    gear_results.V_ms = V;
    gear_results.W_t_N = W_t;
    gear_results.T_p_Nm = T_p;
    
    %% ========== 3. AGMA FACTORS ==========
    fprintf('\n--- AGMA Factors ---\n');
    
    % (a) Overload factor Ko
    Ko = application.overload_factor;
    fprintf('  K_o (overload) = %.2f\n', Ko);
    
    % (b) Dynamic factor Kv (Shigley Eq. 14-27)
    % Based on AGMA quality number Q_v
    Q_v = pinion_data.quality;  % AGMA transmission accuracy level (5-11)
    B_kv = 0.25 * (12 - Q_v)^(2/3);
    A_kv = 50 + 56*(1 - B_kv);
    Kv = ((A_kv + sqrt(V_fpm)) / A_kv)^B_kv;
    fprintf('  K_v (dynamic) = %.3f (Q_v=%d, B=%.3f, A=%.1f)\n', Kv, Q_v, B_kv, A_kv);
    
    % (c) Size factor Ks
    % Shigley: For spur gears, Ks = 1 for normal sizes
    Ks = 1.0;
    if m > 5
        Ks = 1.0 + 0.02*(m - 5);
    end
    fprintf('  K_s (size) = %.3f\n', Ks);
    
    % (d) Load distribution factor Km
    % Shigley Eq. 14-30 / 14-31
    % Simplified for straddle-mounted, face width <= 2*d_p
    if F / d_p <= 2.0
        C_mc = 1.0;  % Uncrowned teeth
        C_pf = F / (10*d_p) - 0.025;
        C_pf = max(C_pf, 0.025);
        
        % Commercial enclosed unit
        C_ma = 0.127 + 0.0158*F - 1.093e-4*F^2;
        
        C_pm = 1.0;   % Straddle mounted
        C_e = 1.0;    % Mesh alignment adjustment
        
        Km = 1 + C_mc * (C_pf * C_pm + C_ma * C_e);
    else
        Km = 1.5;  % Conservative for wide face
    end
    Km = min(Km, 2.0);  % Cap at 2.0
    fprintf('  K_m (load distribution) = %.3f\n', Km);
    
    % (e) Rim thickness factor KB
    m_B = gear_data.backup_ratio;  % rim thickness / tooth depth
    if m_B >= 1.2
        KB = 1.0;
    else
        KB = 1.6 * log(2.242 / m_B);
    end
    fprintf('  K_B (rim thickness) = %.3f (m_B=%.2f)\n', KB, m_B);
    
    % (f) Geometry factor J (bending strength)
    % From Shigley Fig 14-6 or AGMA 2001-D04
    % Approximate curve fit for 20° full depth
    J_p = estimate_J_factor(z_p, z_g, phi);
    J_g = estimate_J_factor(z_g, z_p, phi);  % For gear (driven)
    fprintf('  J (bending) pinion=%.4f, gear=%.4f\n', J_p, J_g);
    
    % (g) Geometry factor I (pitting resistance)
    % Shigley Eq. 14-23
    rho_p = sqrt((d_p*sind(phi)/2)^2 - (d_b_p/2)^2);  % Radius of curvature pinion
    % Simplified I calculation
    m_G = z_g / z_p;  % Gear ratio
    I = cosd(phi) * sind(phi) / 2 * m_G / (m_G + 1);
    fprintf('  I (contact geometry) = %.5f\n', I);
    
    % Store factors
    gear_results.Ko = Ko; gear_results.Kv = Kv;
    gear_results.Ks = Ks; gear_results.Km = Km;
    gear_results.KB = KB; gear_results.J_p = J_p;
    gear_results.J_g = J_g; gear_results.I = I;
    
    %% ========== 4. BENDING STRESS (AGMA Eq. 14-15) ==========
    fprintf('\n--- Bending Stress Analysis ---\n');
    
    % Bending stress: sigma = W_t * Ko * Kv * Ks * (1/(F*m)) * (Km*KB/J)
    % For metric units (module m in mm, F in mm, W_t in N)
    sigma_bp = W_t * Ko * Kv * Ks * (1/(F*m)) * (Km * KB / J_p);  % MPa
    sigma_bg = W_t * Ko * Kv * Ks * (1/(F*m)) * (Km * KB / J_g);  % MPa
    
    fprintf('  Bending stress (pinion): sigma_b = %.2f MPa\n', sigma_bp);
    fprintf('  Bending stress (gear):   sigma_b = %.2f MPa\n', sigma_bg);
    
    gear_results.sigma_bending_p_MPa = sigma_bp;
    gear_results.sigma_bending_g_MPa = sigma_bg;
    
    %% ========== 5. CONTACT STRESS (AGMA Eq. 14-16) ==========
    fprintf('\n--- Contact (Pitting) Stress Analysis ---\n');
    
    % Elastic coefficient Cp (MPa^0.5)
    % Steel on steel: Cp ≈ 191 sqrt(MPa)
    E_p = material_pinion.E;   % Young's modulus (MPa)
    E_g = material_gear.E;
    nu = 0.3;  % Poisson's ratio
    Cp = sqrt(1 / (pi * ((1-nu^2)/E_p + (1-nu^2)/E_g)));
    fprintf('  C_p (elastic coeff) = %.1f sqrt(MPa)\n', Cp);
    
    % Contact stress (AGMA Eq. 14-16, SI units: N, mm, MPa)
    % Cp = 191 sqrt(MPa) for steel; d_p and F in mm; W_t in N
    sigma_c_p = Cp * sqrt(W_t * Ko * Kv * Ks * Km / (d_p * F * I));  % MPa
    fprintf('  Contact stress: sigma_c = %.2f MPa\n', sigma_c_p);
    
    gear_results.sigma_contact_MPa = sigma_c_p;
    gear_results.Cp = Cp;
    
    %% ========== 6. ALLOWABLE STRESSES ==========
    fprintf('\n--- Allowable Stresses ---\n');
    
    % Bending endurance strength S_t (from material data)
    S_t_p = material_pinion.S_t;   % MPa
    S_t_g = material_gear.S_t;     % MPa
    fprintf('  Bending strength (pinion): S_t = %.1f MPa\n', S_t_p);
    fprintf('  Bending strength (gear):   S_t = %.1f MPa\n', S_t_g);
    
    % Contact endurance strength S_c
    S_c_p = material_pinion.S_c;   % MPa
    S_c_g = material_gear.S_c;     % MPa
    fprintf('  Contact strength (pinion): S_c = %.1f MPa\n', S_c_p);
    fprintf('  Contact strength (gear):   S_c = %.1f MPa\n', S_c_g);
    
    %% ========== 7. LIFE FACTORS ==========
    fprintf('\n--- Life Factors ---\n');
    
    % Number of cycles
    L_hours = application.design_life_hours;
    N_cycles_p = L_hours * 60 * n_p;       % Pinion cycles
    N_cycles_g = N_cycles_p / m_G;          % Gear cycles (fewer)
    
    fprintf('  Design life: %.0f hours\n', L_hours);
    fprintf('  Pinion cycles: %.3e\n', N_cycles_p);
    fprintf('  Gear cycles:   %.3e\n', N_cycles_g);
    
    % Bending life factor YN (Shigley Fig 14-14)
    YN_p = calculate_YN(N_cycles_p);
    YN_g = calculate_YN(N_cycles_g);
    fprintf('  Y_N (bending life): pinion=%.3f, gear=%.3f\n', YN_p, YN_g);
    
    % Contact life factor ZN (Shigley Fig 14-15)
    ZN_p = calculate_ZN(N_cycles_p);
    ZN_g = calculate_ZN(N_cycles_g);
    fprintf('  Z_N (contact life): pinion=%.3f, gear=%.3f\n', ZN_p, ZN_g);
    
    % Temperature factor
    KT = 1.0;  % Assume < 120°C
    fprintf('  K_T (temperature) = %.1f\n', KT);
    
    % Reliability factor KR (Shigley Table 14-10)
    R = application.reliability;
    if R == 0.99
        KR = 1.0;
    elseif R == 0.999
        KR = 1.25;
    elseif R == 0.90
        KR = 0.85;
    else
        KR = 1.0;  % Default 0.99
    end
    fprintf('  K_R (reliability R=%.3f) = %.3f\n', R, KR);
    
    gear_results.N_cycles_p = N_cycles_p;
    gear_results.YN_p = YN_p; gear_results.YN_g = YN_g;
    gear_results.ZN_p = ZN_p; gear_results.ZN_g = ZN_g;
    gear_results.KT = KT; gear_results.KR = KR;
    
    %% ========== 8. SAFETY FACTORS ==========
    fprintf('\n--- Safety Factors ---\n');
    
    % Bending safety factor: S_F = (S_t * YN / (KT*KR)) / sigma_b
    SF_p = (S_t_p * YN_p / (KT * KR)) / sigma_bp;
    SF_g = (S_t_g * YN_g / (KT * KR)) / sigma_bg;
    
    fprintf('  Bending safety factor (pinion): S_F = %.3f\n', SF_p);
    fprintf('  Bending safety factor (gear):   S_F = %.3f\n', SF_g);
    
    % Contact safety factor: S_H = sqrt((S_c * ZN / (KT*KR)) / sigma_c)
    % Note: S_H is compared as (S_H)^2 to account for stress^2 relationship
    SH_p = sqrt((S_c_p * ZN_p / (KT * KR)) / sigma_c_p);
    SH_g = sqrt((S_c_g * ZN_g / (KT * KR)) / sigma_c_p);
    
    fprintf('  Contact safety factor (pinion): S_H = %.3f\n', SH_p);
    fprintf('  Contact safety factor (gear):   S_H = %.3f\n', SH_g);
    
    gear_results.SF_p = SF_p; gear_results.SF_g = SF_g;
    gear_results.SH_p = SH_p; gear_results.SH_g = SH_g;
    
    % Overall verdict
    SF_min = min(SF_p, SF_g);
    SH_min = min(SH_p, SH_g);
    
    fprintf('\n--- Verdict ---\n');
    fprintf('  Minimum bending SF: %.3f (pinion)\n', SF_min);
    fprintf('  Minimum contact SF: %.3f (pinion)\n', SH_min);
    
    if SF_min >= 1.0 && SH_min >= 1.0
        fprintf('  >> GEAR DESIGN ADEQUATE\n');
    else
        fprintf('  >> GEAR DESIGN INSUFFICIENT\n');
        if SF_min < 1.0
            fprintf('     Bending insufficient: increase face width or module\n');
        end
        if SH_min < 1.0
            fprintf('     Contact insufficient: increase diameter or hardness\n');
        end
    end
    
    fprintf('============================================================\n');
end


%% ====================================================================
% HELPER: Estimate J factor (bending geometry factor)
%% ====================================================================
function J = estimate_J_factor(z, z_mate, phi_deg)
% Approximate J factor curve fit for 20° full-depth spur gears
% Based on Shigley Fig 14-6 trends
    
    z = max(z, 12);  % Clamp minimum teeth
    
    % Empirical fit: J increases with z, approaches ~0.5
    % Also depends on mating gear teeth
    z_ratio = z_mate / z;
    
    % Base J for pinion (self-mating approximation)
    J_base = 0.22 + 0.08 * log(z/12) / log(3);
    J_base = min(J_base, 0.45);
    
    % Adjustment for mating gear (more teeth = higher J)
    J = J_base * (1 + 0.05 * (z_ratio - 1));
    J = min(max(J, 0.20), 0.55);
end


%% ====================================================================
% HELPER: Bending life factor YN
%% ====================================================================
function YN = calculate_YN(N_cycles)
% Shigley Fig 14-14 curve fit for bending life factor
    if N_cycles <= 1e4
        YN = 2.5;
    elseif N_cycles < 3e6
        YN = 2.5 * (3e6 / N_cycles)^0.1;
    else
        YN = 1.0 * (1e7 / N_cycles)^0.05;
    end
    YN = min(max(YN, 0.7), 2.5);
end


%% ====================================================================
% HELPER: Contact life factor ZN
%% ====================================================================
function ZN = calculate_ZN(N_cycles)
% Shigley Fig 14-15 curve fit for contact (pitting) life factor
    if N_cycles <= 1e4
        ZN = 1.5;
    elseif N_cycles < 1e7
        ZN = 1.5 * (1e7 / N_cycles)^0.06;
    else
        ZN = 1.0 * (1e10 / N_cycles)^0.02;
    end
    ZN = min(max(ZN, 0.8), 1.5);
end


%% ====================================================================
% BATCH: Design all gear pairs in gearbox
%% ====================================================================
function all_gears = design_all_gears(gear_pairs, power_pinion, speed_pinion, ...
                                      app_data, mat_steel)
% Design all gear pairs in the reducer

    fprintf('\n############################################################\n');
    fprintf('#         GEAR DESIGN FOR ALL STAGES                       #\n');
    fprintf('############################################################\n');
    
    all_gears = {};
    
    for i = 1:length(gear_pairs)
        gp = gear_pairs(i);
        
        fprintf('\n\n>>> GEAR STAGE %d: z_p=%d, z_g=%d <<<\n', ...
                i, gp.pinion.teeth, gp.gear.teeth);
        
        % Same material for both (steel)
        mat_p = mat_steel;
        mat_g = mat_steel;
        
        gr = gear_design(gp.pinion, gp.gear, app_data, ...
                         mat_p, mat_g, power_pinion(i), speed_pinion(i));
        gr.stage = i;
        all_gears{i} = gr;
    end
    
    % Summary
    fprintf('\n============================================================\n');
    fprintf('  GEAR DESIGN SUMMARY\n');
    fprintf('============================================================\n');
    fprintf('%-8s %-8s %-8s %-10s %-10s %-10s %-10s\n', ...
            'Stage', 'm(mm)', 'F(mm)', 'sigma_b(MPa)', 'sigma_c(MPa)', 'S_F', 'S_H');
    fprintf('%s\n', repmat('-', 1, 60));
    
    for i = 1:length(all_gears)
        g = all_gears{i};
        fprintf('%-8d %-8.2f %-8.1f %-10.2f %-10.2f %-10.3f %-10.3f\n', ...
                g.stage, g.m_mm, g.F_mm, g.sigma_bending_p_MPa, ...
                g.sigma_contact_MPa, g.SF_p, g.SH_p);
    end
end


%% ====================================================================
% EXAMPLE / TEST
%% ====================================================================
% pinion1 = struct('teeth', 20, 'module', 2.0, 'face_width', 20, 'quality', 8, 'backup_ratio', 2.0);
% gear1 = struct('teeth', 60, 'module', 2.0, 'face_width', 25, 'quality', 8, 'backup_ratio', 2.0);
% app = struct('overload_factor', 1.25, 'reliability', 0.99, 'design_life_hours', 10000);
% mat_steel = struct('S_t', 250, 'S_c', 850, 'hardness_HB', 200, 'E', 206000);
% 
% result = gear_design(pinion1, gear1, app, mat_steel, mat_steel, 6.0, 1440);
