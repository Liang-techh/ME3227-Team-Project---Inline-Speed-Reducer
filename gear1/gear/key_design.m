% =========================================================================
% key_design.m
% Description: Parallel key design and strength check:
%              standard key selection, shear and bearing stress, safety factor.
% =========================================================================

function key_results = key_design(shaft_diam, torque, material_key, material_shaft, ...
                                  key_length_override, safety_factor_required)
% key_design: Design or check a parallel key for shaft-gear connection
%
% Inputs:
%   shaft_diam          - Shaft diameter at key location (mm)
%   torque              - Transmitted torque (N·m)
%   material_key        - Key material struct: S_yt (yield), S_ut (MPa)
%   material_shaft      - Shaft/hub material struct: S_yt (MPa) 
%   key_length_override - Optional: specify key length (mm), [] for auto
%   safety_factor_required - Required safety factor (default 2.0)
%
% Output:
%   key_results - Complete design results struct

    if nargin < 6 || isempty(safety_factor_required)
        safety_factor_required = 2.0;
    end
    
    fprintf('\n============================================================\n');
    fprintf('  PARALLEL KEY DESIGN (Shigley Method)\n');
    fprintf('============================================================\n');
    fprintf('Shaft diameter: d = %.2f mm\n', shaft_diam);
    fprintf('Transmitted torque: T = %.3f N·m\n', torque);
    
    %% ========== 1. SELECT STANDARD KEY SIZE ==========
    % Based on shaft diameter - Shigley Table 7-6 (metric standard keys)
    fprintf('\n--- Standard Key Selection ---\n');
    
    [key_width, key_height, keyseat_shaft, keyseat_hub] = ...
        select_standard_key(shaft_diam);
    
    fprintf('  Standard key (from d=%.1f mm):\n', shaft_diam);
    fprintf('    Key width  w = %.1f mm\n', key_width);
    fprintf('    Key height h = %.1f mm\n', key_height);
    fprintf('    Keyseat depth (shaft) = %.2f mm\n', keyseat_shaft);
    fprintf('    Keyseat depth (hub)   = %.2f mm\n', keyseat_hub);
    
    key_results.key_width_mm = key_width;
    key_results.key_height_mm = key_height;
    key_results.keyseat_shaft_mm = keyseat_shaft;
    key_results.keyseat_hub_mm = keyseat_hub;
    
    %% ========== 2. DETERMINE KEY LENGTH ==========
    fprintf('\n--- Key Length Determination ---\n');
    
    % Force on key: F = 2T/d (tangential force at shaft surface)
    F = 2 * torque * 1000 / shaft_diam;   % N (torque in N·mm, d in mm)
    key_results.force_N = F;
    fprintf('  Tangential force: F = 2T/d = %.1f N\n', F);
    
    if ~isempty(key_length_override) && key_length_override > 0
        key_length = key_length_override;
        fprintf('  Specified key length: L = %.1f mm\n', key_length);
    else
        % Determine minimum key length based on strength
        % Key length should be 1.0 to 1.5 times shaft diameter
        key_length = 1.25 * shaft_diam;
        fprintf('  Auto key length: L = 1.25*d = %.1f mm\n', key_length);
    end
    
    key_results.key_length_mm = key_length;
    
    %% ========== 3. SHEAR STRESS CHECK ==========
    % Shigley Eq. for key shear:
    % tau = F / (w * L)  --- shear area = w * L
    fprintf('\n--- Shear Stress Analysis ---\n');
    
    shear_area = key_width * key_length;    % mm^2
    tau_key = F / shear_area;               % MPa (N/mm^2)
    
    fprintf('  Shear area: A_shear = w * L = %.1f * %.1f = %.2f mm^2\n', ...
            key_width, key_length, shear_area);
    fprintf('  Shear stress in key: tau = F/A = %.2f MPa\n', tau_key);
    
    % Allowable shear stress (key material)
    % Distortion energy theory: tau_allow = S_yt / (n * sqrt(3))
    S_y_key = material_key.S_yt;
    tau_allow_key = S_y_key / (safety_factor_required * sqrt(3));
    
    fprintf('  Key yield strength: S_y = %.0f MPa\n', S_y_key);
    fprintf('  Allowable shear: tau_allow = S_y/(n*sqrt(3)) = %.2f MPa\n', tau_allow_key);
    
    n_shear_key = tau_allow_key / tau_key;
    fprintf('  Safety factor (key shear): n = %.3f\n', n_shear_key);
    
    key_results.tau_key_MPa = tau_key;
    key_results.tau_allow_key_MPa = tau_allow_key;
    key_results.n_shear_key = n_shear_key;
    
    %% ========== 4. BEARING (CRUSHING) STRESS CHECK ==========
    % Shigley: sigma_b = F / (t_eff * L)
    % For key, t_eff = key_height/2 (the part embedded in shaft)
    fprintf('\n--- Bearing (Crushing) Stress Analysis ---\n');
    
    t_eff = key_height / 2;  % mm (effective height in keyseat)
    bearing_area = t_eff * key_length;    % mm^2
    sigma_bearing = F / bearing_area;     % MPa
    
    fprintf('  Effective height: t_eff = h/2 = %.2f mm\n', t_eff);
    fprintf('  Bearing area: A_b = t_eff * L = %.2f mm^2\n', bearing_area);
    fprintf('  Bearing stress: sigma_b = F/A_b = %.2f MPa\n', sigma_bearing);
    
    % Allowable bearing stress - use the WEAKER of key or shaft/hub material
    % Support both S_y and S_yt field names
    if isfield(material_shaft, 'S_yt')
        S_y_shaft = material_shaft.S_yt;
    else
        S_y_shaft = material_shaft.S_y;
    end
    S_y_allow = min(S_y_key, S_y_shaft);  % Conservative: use min yield
    
    sigma_b_allow = S_y_allow / safety_factor_required;
    
    fprintf('  Shaft/Hub yield: S_y = %.0f MPa, Key yield: S_y = %.0f MPa\n', ...
            S_y_shaft, S_y_key);
    fprintf('  Allowable bearing stress: sigma_b_allow = %.2f MPa\n', sigma_b_allow);
    
    n_bearing = sigma_b_allow / sigma_bearing;
    fprintf('  Safety factor (bearing): n = %.3f\n', n_bearing);
    
    key_results.sigma_bearing_MPa = sigma_bearing;
    key_results.sigma_b_allow_MPa = sigma_b_allow;
    key_results.n_bearing = n_bearing;
    
    %% ========== 5. SHAFT KEYSEAT CHECK ==========
    % Check if the keyseat weakens the shaft excessively
    fprintf('\n--- Shaft Keyseat Effect ---\n');
    
    % Shaft diameter reduction due to keyseat
    d_effective = shaft_diam - 2 * keyseat_shaft;
    area_reduction = (2 * keyseat_shaft) / shaft_diam * 100;
    
    fprintf('  Effective shaft diameter at keyseat: d_eff = %.2f mm\n', d_effective);
    fprintf('  Diameter reduction: %.1f%%\n', area_reduction);
    
    % Torsional stress in shaft at keyseat section
    J = pi * d_effective^4 / 32;   % Polar moment of inertia (mm^4)
    tau_shaft = torque * 1000 * (d_effective/2) / J;   % MPa
    
    tau_allow_shaft = S_y_shaft / (safety_factor_required * sqrt(3));
    n_shaft_torsion = tau_allow_shaft / tau_shaft;
    
    fprintf('  Torsional stress at keyseat: tau = %.2f MPa\n', tau_shaft);
    fprintf('  Safety factor (shaft torsion at keyseat): n = %.3f\n', n_shaft_torsion);
    
    key_results.d_effective_mm = d_effective;
    key_results.tau_shaft_keyseat_MPa = tau_shaft;
    key_results.n_shaft_torsion = n_shaft_torsion;
    
    %% ========== 6. OVERALL VERDICT ==========
    fprintf('\n--- Design Verdict ---\n');
    
    n_min = min([n_shear_key, n_bearing, n_shaft_torsion]);
    key_results.n_min = n_min;
    key_results.is_adequate = (n_min >= safety_factor_required);
    
    fprintf('  Minimum safety factor: n_min = %.3f\n', n_min);
    fprintf('  Required safety factor: n_req = %.2f\n', safety_factor_required);
    
    if key_results.is_adequate
        fprintf('  >> KEY DESIGN ADEQUATE (n_min >= n_req)\n');
    else
        fprintf('  >> KEY DESIGN INSUFFICIENT (n_min < n_req)\n');
        
        % Suggest remedy
        if n_shear_key < safety_factor_required
            fprintf('  >> SUGGESTION: Increase key length to %.1f mm\n', ...
                    key_length * safety_factor_required / n_shear_key);
        elseif n_bearing < safety_factor_required
            fprintf('  >> SUGGESTION: Use larger key section or longer key\n');
        end
    end
    
    fprintf('============================================================\n');
end


%% ====================================================================
% HELPER: Select standard key size based on shaft diameter
%% ====================================================================
function [w, h, t1, t2] = select_standard_key(d)
% Select standard parallel key dimensions per ISO/GB for metric system
% Input: d = shaft diameter (mm)
% Output: w = key width, h = key height (mm)
%         t1 = keyseat depth in shaft, t2 = keyseat depth in hub
%
% Standard metric key sizes (GB/T 1095 or ISO 3912):
%  d > 8-10:  3x3
%  d > 10-12: 4x4
%  d > 12-17: 5x5
%  d > 17-22: 6x6
%  d > 22-30: 8x7
%  d > 30-38: 10x8
%  d > 38-44: 12x8
%  d > 44-50: 14x9
%  d > 50-58: 16x10
%  d > 58-65: 18x11
%  d > 65-75: 20x12
%  d > 75-85: 22x14
%  d > 85-95: 25x14
%  d > 95-110: 28x16

    if d <= 10
        w = 3; h = 3; t1 = 1.8; t2 = 1.4;
    elseif d <= 12
        w = 4; h = 4; t1 = 2.5; t2 = 1.8;
    elseif d <= 17
        w = 5; h = 5; t1 = 3.0; t2 = 2.3;
    elseif d <= 22
        w = 6; h = 6; t1 = 3.5; t2 = 2.8;
    elseif d <= 30
        w = 8; h = 7; t1 = 4.0; t2 = 3.3;
    elseif d <= 38
        w = 10; h = 8; t1 = 5.0; t2 = 3.3;
    elseif d <= 44
        w = 12; h = 8; t1 = 5.0; t2 = 3.3;
    elseif d <= 50
        w = 14; h = 9; t1 = 5.5; t2 = 3.8;
    elseif d <= 58
        w = 16; h = 10; t1 = 6.0; t2 = 4.3;
    elseif d <= 65
        w = 18; h = 11; t1 = 7.0; t2 = 4.4;
    elseif d <= 75
        w = 20; h = 12; t1 = 7.5; t2 = 4.9;
    elseif d <= 85
        w = 22; h = 14; t1 = 9.0; t2 = 5.4;
    elseif d <= 95
        w = 25; h = 14; t1 = 9.0; t2 = 5.4;
    else
        w = 28; h = 16; t1 = 10.0; t2 = 6.4;
    end
end


%% ====================================================================
% BATCH: Design all keys for a multi-gear shaft
%% ====================================================================
function all_keys = design_shaft_keys(shaft_data, material_key, material_shaft, n_req)
% Design all keys for a given shaft
%
% Inputs:
%   shaft_data - struct array: diameter, torque, position, label for each key
%   material_key, material_shaft - material structs
%   n_req - required safety factor

    fprintf('\n############################################################\n');
    fprintf('#           KEY DESIGN FOR COMPLETE SHAFT                   #\n');
    fprintf('############################################################\n');
    
    all_keys = {};
    
    for i = 1:length(shaft_data)
        sd = shaft_data(i);
        fprintf('\n--- Key %d: %s ---\n', i, sd.label);
        
        kr = key_design(sd.diameter, sd.torque, material_key, material_shaft, ...
                        sd.key_length, n_req);
        kr.label = sd.label;
        kr.position_mm = sd.position;
        all_keys{i} = kr;
    end
    
    % Summary table
    fprintf('\n============================================================\n');
    fprintf('  KEY DESIGN SUMMARY\n');
    fprintf('============================================================\n');
    fprintf('%-20s %6s %6s %8s %8s %8s %8s\n', ...
            'Key', 'w(mm)', 'h(mm)', 'L(mm)', 'n_shear', 'n_bear', 'n_shaft');
    fprintf('%s\n', repmat('-', 1, 70));
    
    for i = 1:length(all_keys)
        kr = all_keys{i};
        fprintf('%-20s %6.1f %6.1f %8.1f %8.3f %8.3f %8.3f\n', ...
                kr.label, kr.key_width_mm, kr.key_height_mm, ...
                kr.key_length_mm, kr.n_shear_key, kr.n_bearing, ...
                kr.n_shaft_torsion);
    end
    
    % Overall verdict
    all_adequate = true;
    for i = 1:length(all_keys)
        if ~all_keys{i}.is_adequate
            all_adequate = false;
            break;
        end
    end
    
    fprintf('\nOverall: %s\n', conditional(all_adequate, 'ALL KEYS PASS', 'SOME KEYS FAIL'));
end


%% ====================================================================
% HELPER
%% ====================================================================
function out = conditional(cond, a, b)
    if cond, out = a; else, out = b; end
end


%% ====================================================================
% EXAMPLE / TEST
%% ====================================================================
% key_mat = struct('S_yt', 350, 'S_ut', 550);    % 45 steel key
% shaft_mat = struct('S_yt', 355, 'S_ut', 600);  % 45 steel shaft
% 
% % Design a key for 20mm shaft transmitting 40 N·m
% result = key_design(18, 40, key_mat, shaft_mat, [], 2.0);
