% =========================================================================
% reducer_design.m
% Description: UNIFIED gearbox design script that sequentially calls all
%              analysis modules for a complete 3-shaft inline speed reducer.
%              
%              Analysis chain:
%              1. Gear design (AGMA bending + contact stress, safety factors)
%              2. Shaft stress analysis (bending/torsion diagrams, DE-Goodman)
%              3. Stress concentration (Kt, Kf, notch sensitivity)
%              4. Key design (shear + bearing stress, standard size selection)
%              5. Bearing selection (L10 life, catalog lookup)
%              
%              All methods based on Shigley's Mechanical Engineering Design
%              8th Edition.
% =========================================================================

clear; clc; close all;

fprintf('######################################################################\n');
fprintf('#                                                                    #\n');
fprintf('#   ME3227 Team Project          #\n');
fprintf('#   Complete Gearbox Design Suite        #\n');
fprintf('#                                                                    #\n');
fprintf('######################################################################\n');

%% ========================================================================
% PART 0: DESIGN INPUT SPECIFICATIONS
%% ========================================================================

% --- Global Design Requirements ---
REQ.power_output_kW = 5.5;          % Output power
REQ.n_input_rpm = 1440;             % Input speed
REQ.n_output_rpm = 160;             % Output speed
REQ.i_total = REQ.n_input_rpm / REQ.n_output_rpm;  % Total ratio = 9.0
REQ.L_design_hours = 10000;         % Design life (hours)
REQ.R_reliability = 0.99;           % Reliability target
REQ.n_safety = 2.0;                 % Required safety factor

fprintf('\n');
fprintf('=====================================================================\n');
fprintf('Design Specifications\n');
fprintf('=====================================================================\n');
fprintf('  Output power:       %.2f kW\n', REQ.power_output_kW);
fprintf('  Input speed:        %.0f rpm\n', REQ.n_input_rpm);
fprintf('  Output speed:       %.0f rpm\n', REQ.n_output_rpm);
fprintf('  Total ratio:        %.2f\n', REQ.i_total);
fprintf('  Design life:        %.0f hours\n', REQ.L_design_hours);
fprintf('  Reliability:        %.1f%%\n', REQ.R_reliability*100);
fprintf('  Safety factor:      %.1f\n', REQ.n_safety);

% --- Transmission Ratio Split ---
% Stage 1 (high speed): i1 = 3.0, Stage 2 (low speed): i2 = 3.0
i1 = 3.0;   i2 = 3.0;
n1 = REQ.n_input_rpm;
n2 = n1 / i1;   % = 480 rpm
n3 = n2 / i2;   % = 160 rpm

% Power flow with efficiency
eta_bearing = 0.995;    % Per bearing
eta_gear = 0.98;        % Per mesh
P3 = REQ.power_output_kW;
P2 = P3 / (eta_bearing^2 * eta_gear);
P1 = P2 / (eta_bearing^2 * eta_gear);

fprintf('\n  Stage ratios: i1=%.1f, i2=%.1f\n', i1, i2);
fprintf('  Speeds: n1=%.0f, n2=%.0f, n3=%.0f rpm\n', n1, n2, n3);
fprintf('  Powers: P1=%.3f, P2=%.3f, P3=%.3f kW\n', P1, P2, P3);

%% ========================================================================
% PART 1: GEAR DESIGN (AGMA Method)
%% ========================================================================

fprintf('\n');
fprintf('######################################################################\n');
fprintf('# PART 1: Gear Design (AGMA)                                         #\n');
fprintf('######################################################################\n');

% Material: 40Cr alloy steel, Q&T, 250-280 HB
mat_steel.S_t = 280;        % Bending strength (MPa) at 10^7 cycles
mat_steel.S_c = 900;        % Contact strength (MPa) at 10^7 cycles
mat_steel.hardness_HB = 260;% Brinell hardness
mat_steel.E = 206000;       % Young's modulus (MPa)

app.overload_factor = 1.25;  % Moderate shock (gearbox)
app.reliability = 0.99;
app.design_life_hours = REQ.L_design_hours;

% --- Stage 1: Gear 1 (z=25) meshes with Gear 2 (z=75) ---
p1 = struct('teeth', 25, 'module', 3.0, 'face_width', 35, 'quality', 8, 'backup_ratio', 2.0);
g2 = struct('teeth', 75, 'module', 3.0, 'face_width', 40, 'quality', 8, 'backup_ratio', 2.0);

fprintf('\n--- Stage 1: Pinion z=25, Gear z=75, m=3.0mm ---\n');
stage1 = gear_design(p1, g2, app, mat_steel, mat_steel, P1, n1);

% --- Stage 2: Gear 3 (z=30) meshes with Gear 4 (z=90) ---
p3 = struct('teeth', 30, 'module', 4.0, 'face_width', 50, 'quality', 8, 'backup_ratio', 2.0);
g4 = struct('teeth', 90, 'module', 4.0, 'face_width', 55, 'quality', 8, 'backup_ratio', 2.0);

fprintf('\n--- Stage 2: Pinion z=30, Gear z=90, m=4.0mm ---\n');
stage2 = gear_design(p3, g4, app, mat_steel, mat_steel, P2, n2);

% Store gear parameters for later use
gears(1) = struct('position', 92, 'module', 3.0, 'teeth', 25, 'label', 'Gear 1', 'd', 75.0);
gears(2) = struct('position', 50,  'module', 3.0, 'teeth', 75, 'label', 'Gear 2', 'd', 225.0);
gears(3) = struct('position', 145, 'module', 4.0, 'teeth', 30, 'label', 'Gear 3', 'd', 120.0);
gears(4) = struct('position', 80,  'module', 4.0, 'teeth', 90, 'label', 'Gear 4', 'd', 360.0);

%% ========================================================================
% PART 2: SHAFT STRESS ANALYSIS
%% ========================================================================

fprintf('\n');
fprintf('######################################################################\n');
fprintf('# PART 2: Shaft Stress Analysis (DE Theory)                          #\n');
fprintf('######################################################################\n');

% Material definitions
mat_45 = struct('S_ut', 600, 'S_y', 355, 'S_e_prime', 300, ...
                'surface', 'machined', 'reliability', 0.95, 'n_design', REQ.n_safety);
mat_40Cr = struct('S_ut', 900, 'S_y', 650, 'S_e_prime', 450, ...
                  'surface', 'ground', 'reliability', 0.95, 'n_design', REQ.n_safety);

% --- Shaft 1: Input Shaft ---
config1.length = 170;
config1.diameters = [25, 30, 30, 35, 30, 30, 25];
config1.x_positions = [0, 30, 50, 100, 125, 135, 155, 170];
config1.gears = gears(1);

load1.power = P1;
load1.speed = n1;
load1.K_f = 2.2;    % SC factor (keyway + shoulder)
load1.K_fs = 1.6;

brg1.positions = [40, 145];

fprintf('\n--- SHAFT 1 (Input) ---\n');
results1 = shaft_stress_analysis(1, config1, mat_45, load1, brg1);

% --- Shaft 2: Intermediate Shaft ---
config2.length = 200;
config2.diameters = [40, 45, 45, 55, 60, 45, 55, 40, 40];
config2.x_positions = [0, 25, 35, 85, 105, 115, 155, 165, 190, 200];
config2.gears = [gears(2), gears(3)];

load2.power = P2;
load2.speed = n2;
load2.K_f = 2.5;    % Higher SC at multiple keyways
load2.K_fs = 1.8;

brg2.positions = [12, 177];

fprintf('\n--- SHAFT 2 (Intermediate) ---\n');
results2 = shaft_stress_analysis(2, config2, mat_45, load2, brg2);

% --- Shaft 3: Output Shaft ---
config3.length = 180;
config3.diameters = [45, 50, 50, 60, 65, 50, 45, 45];
config3.x_positions = [0, 30, 42, 92, 107, 119, 144, 160, 180];
config3.gears = gears(4);

load3.power = P3;
load3.speed = n3;
load3.K_f = 2.0;
load3.K_fs = 1.5;

brg3.positions = [15, 131];

fprintf('\n--- SHAFT 3 (Output) ---\n');
results3 = shaft_stress_analysis(3, config3, mat_40Cr, load3, brg3);

%% ========================================================================
% PART 3: STRESS CONCENTRATION ANALYSIS
%% ========================================================================

fprintf('\n');
fprintf('######################################################################\n');
fprintf('# PART 3: Stress Concentration Factors                               #\n');
fprintf('######################################################################\n');

% Shaft 1: Keyway at Gear 1 (d=35mm), Coupling (d=25mm)
fprintf('\n--- Shaft 1 Stress Concentrations ---\n');
sc1_g = stress_concentration(35, [], 0.5, mat_45, 'keyway', 'sled_runner');
sc1_c = stress_concentration(25, [], 0.5, mat_45, 'keyway', 'sled_runner');

% Shoulder at d=35 to d=30
sc1_sh = stress_concentration(30, 35, 1.0, mat_45, 'shoulder_bending');

% Shaft 2: Keyways at Gear 2 (d=40mm), Gear 3 (d=40mm)
fprintf('\n--- Shaft 2 Stress Concentrations ---\n');
sc2_g2 = stress_concentration(40, [], 0.5, mat_45, 'keyway', 'sled_runner');
sc2_g3 = stress_concentration(40, [], 0.5, mat_45, 'keyway', 'sled_runner');

% Shaft 3: Keyway at Gear 4 (d=60mm), Coupling (d=45mm)
fprintf('\n--- Shaft 3 Stress Concentrations ---\n');
sc3_g = stress_concentration(60, [], 0.5, mat_40Cr, 'keyway', 'sled_runner');
sc3_c = stress_concentration(45, [], 0.5, mat_40Cr, 'keyway', 'sled_runner');

% Store key Kf values for summary
Kf_summary(1) = sc1_g.Kf_bending;
Kf_summary(2) = sc2_g2.Kf_bending;
Kf_summary(3) = sc3_g.Kf_bending;

%% ========================================================================
% PART 4: KEY DESIGN
%% ========================================================================

fprintf('\n');
fprintf('######################################################################\n');
fprintf('# PART 4: Parallel Key Design                                        #\n');
fprintf('######################################################################\n');

% Key material (45 steel)
key_mat.S_yt = 355;
key_mat.S_ut = 600;

% Shaft 1: Key at Gear 1 (d=35mm)
T1 = results1.torque_Nm;
key1_g = key_design(35, T1, key_mat, mat_45, 30, REQ.n_safety);

% Shaft 2: Key at Gear 2 (d=40mm) 
T2 = results2.torque_Nm;
key2_g2 = key_design(40, T2, key_mat, mat_45, 45, REQ.n_safety);

% Key at Gear 3 (d=40mm) - same torque (through-shaft)
key2_g3 = key_design(40, T2, key_mat, mat_45, 40, REQ.n_safety);

% Shaft 3: Key at Gear 4 (d=60mm)
T3 = results3.torque_Nm;
key3_g = key_design(60, T3, key_mat, mat_40Cr, 60, REQ.n_safety);

%% ========================================================================
% PART 5: BEARING SELECTION
%% ========================================================================

fprintf('\n');
fprintf('######################################################################\n');
fprintf('# PART 5: Bearing Selection (L10 Life)                               #\n');
fprintf('######################################################################\n');

% Extract bearing loads from shaft analysis results
% Shaft 1 bearings (d=25mm bore)
fprintf('\n--- Shaft 1 Bearings (bore=25mm) ---\n');
R1_L = sqrt(sum(results1.reactions.B1.^2));  % Resultant left bearing load
R1_R = sqrt(sum(results1.reactions.B2.^2));
brg1_L = bearing_selection(1, 'left', R1_L, 0, n1, 25, REQ.L_design_hours, REQ.R_reliability, 1.2);
brg1_R = bearing_selection(1, 'right', R1_R, 0, n1, 25, REQ.L_design_hours, REQ.R_reliability, 1.2);

% Shaft 2 bearings (d=40mm bore)
fprintf('\n--- Shaft 2 Bearings (bore=40mm) ---\n');
R2_L = sqrt(sum(results2.reactions.B1.^2));
R2_R = sqrt(sum(results2.reactions.B2.^2));
brg2_L = bearing_selection(2, 'left', R2_L, 0, n2, 40, REQ.L_design_hours, REQ.R_reliability, 1.2);
brg2_R = bearing_selection(2, 'right', R2_R, 0, n2, 40, REQ.L_design_hours, REQ.R_reliability, 1.2);

% Shaft 3 bearings (d=45mm bore)
fprintf('\n--- Shaft 3 Bearings (bore=45mm) ---\n');
R3_L = sqrt(sum(results3.reactions.B1.^2));
R3_R = sqrt(sum(results3.reactions.B2.^2));
brg3_L = bearing_selection(3, 'left', R3_L, 0, n3, 45, REQ.L_design_hours, REQ.R_reliability, 1.2);
brg3_R = bearing_selection(3, 'right', R3_R, 0, n3, 45, REQ.L_design_hours, REQ.R_reliability, 1.2);

%% ========================================================================
% PART 6: COMPLETE DESIGN SUMMARY
%% ========================================================================

fprintf('\n');
fprintf('######################################################################\n');
fprintf('#                     Design Summary                                 #\n');
fprintf('######################################################################\n');

% --- Gear Summary ---
fprintf('\n[GEAR DESIGN]\n');
fprintf('%-10s %-8s %-8s %-10s %-10s %-8s %-8s\n', ...
        'Stage', 'Module', 'F(mm)', 'sigma_b(MPa)', 'sigma_c(MPa)', 'SF', 'SH');
fprintf('%s\n', repmat('-', 1, 65));
fprintf('%-10s %-8.2f %-8.1f %-10.2f %-10.2f %-8.3f %-8.3f\n', ...
        'Stage 1', stage1.m_mm, stage1.F_mm, stage1.sigma_bending_p_MPa, ...
        stage1.sigma_contact_MPa, stage1.SF_p, stage1.SH_p);
fprintf('%-10s %-8.2f %-8.1f %-10.2f %-10.2f %-8.3f %-8.3f\n', ...
        'Stage 2', stage2.m_mm, stage2.F_mm, stage2.sigma_bending_p_MPa, ...
        stage2.sigma_contact_MPa, stage2.SF_p, stage2.SH_p);

% --- Shaft Summary ---
fprintf('\n[SHAFT ANALYSIS]\n');
fprintf('%-10s %-12s %-12s %-10s %-10s %-10s\n', ...
        'Shaft', 'M_max(N·m)', 'sigma_a''(MPa)', 'n_Goodman', 'n_Gerber', 'n_yield');
fprintf('%s\n', repmat('-', 1, 60));
fprintf('%-10s %-12.3f %-12.2f %-10.3f %-10.3f %-10.3f\n', ...
        'Shaft 1', results1.max_bending_Nmm/1000, results1.sigma_a_prime_MPa, ...
        results1.n_goodman, results1.n_gerber, results1.n_yield);
fprintf('%-10s %-12.3f %-12.2f %-10.3f %-10.3f %-10.3f\n', ...
        'Shaft 2', results2.max_bending_Nmm/1000, results2.sigma_a_prime_MPa, ...
        results2.n_goodman, results2.n_gerber, results2.n_yield);
fprintf('%-10s %-12.3f %-12.2f %-10.3f %-10.3f %-10.3f\n', ...
        'Shaft 3', results3.max_bending_Nmm/1000, results3.sigma_a_prime_MPa, ...
        results3.n_goodman, results3.n_gerber, results3.n_yield);

% --- Bearing Summary ---
fprintf('\n[BEARING SELECTION]\n');
fprintf('%-10s %-12s %-10s %-10s %-10s %-10s\n', ...
        'Bearing', 'Model', 'C10(kN)', 'L10(h)', 'Ratio', 'Status');
fprintf('%s\n', repmat('-', 1, 55));

all_brg = {brg1_L, brg1_R, brg2_L, brg2_R, brg3_L, brg3_R};
labels = {'S1-Left', 'S1-Right', 'S2-Left', 'S2-Right', 'S3-Left', 'S3-Right'};
for i = 1:length(all_brg)
    b = all_brg{i};
    if ~isempty(b.selected)
        status = conditional(b.is_adequate, 'PASS', 'MARGINAL');
        fprintf('%-10s %-12s %-10.2f %-10.0f %-10.2f %-10s\n', ...
                labels{i}, b.selected.model, b.selected.C10_kN, ...
                b.L10_hours, b.life_ratio, status);
    end
end

% --- Key Summary ---
fprintf('\n[KEY DESIGN]\n');
fprintf('%-15s %-8s %-8s %-8s %-8s %-8s\n', ...
        'Key', 'w(mm)', 'h(mm)', 'L(mm)', 'n_shear', 'n_bear');
fprintf('%s\n', repmat('-', 1, 50));
fprintf('%-15s %-8.1f %-8.1f %-8.1f %-8.3f %-8.3f\n', ...
        'S1-Gear1', key1_g.key_width_mm, key1_g.key_height_mm, ...
        key1_g.key_length_mm, key1_g.n_shear_key, key1_g.n_bearing);
fprintf('%-15s %-8.1f %-8.1f %-8.1f %-8.3f %-8.3f\n', ...
        'S2-Gear2', key2_g2.key_width_mm, key2_g2.key_height_mm, ...
        key2_g2.key_length_mm, key2_g2.n_shear_key, key2_g2.n_bearing);
fprintf('%-15s %-8.1f %-8.1f %-8.1f %-8.3f %-8.3f\n', ...
        'S2-Gear3', key2_g3.key_width_mm, key2_g3.key_height_mm, ...
        key2_g3.key_length_mm, key2_g3.n_shear_key, key2_g3.n_bearing);
fprintf('%-15s %-8.1f %-8.1f %-8.1f %-8.3f %-8.3f\n', ...
        'S3-Gear4', key3_g.key_width_mm, key3_g.key_height_mm, ...
        key3_g.key_length_mm, key3_g.n_shear_key, key3_g.n_bearing);

% --- Final Verdict ---
fprintf('\n');
fprintf('=====================================================================\n');
fprintf('  Final Design Verdict\n');
fprintf('=====================================================================\n');

% Check all criteria
all_pass = true;

% Gear check
if min(stage1.SF_p, stage2.SF_p) < 1.0 || min(stage1.SH_p, stage2.SH_p) < 1.0
    fprintf('  [X] GEAR: FAIL (SF or SH < 1.0)\n');
    all_pass = false;
else
    fprintf('  [OK] Gear: PASS (SF>1.0, SH>1.0)\n');
end

% Shaft check  
if results1.n_goodman < REQ.n_safety || results2.n_goodman < REQ.n_safety || ...
   results3.n_goodman < REQ.n_safety
    fprintf('  [X] SHAFT: FAIL (n < %.1f)\n', REQ.n_safety);
    all_pass = false;
else
    fprintf('  [OK] Shaft: PASS (n >= %.1f)\n', REQ.n_safety);
end

% Bearing check
brg_ok = true;
for i = 1:length(all_brg)
    if ~all_brg{i}.is_adequate, brg_ok = false; break; end
end
if ~brg_ok
    fprintf('  [X] BEARING: Some bearings marginal\n');
    all_pass = false;
else
    fprintf('  [OK] Bearing: PASS (all meet L10 life)\n');
end

% Key check
key_ok = key1_g.is_adequate && key2_g2.is_adequate && key2_g3.is_adequate && key3_g.is_adequate;
if ~key_ok
    fprintf('  [X] KEY: Some keys fail\n');
    all_pass = false;
else
    fprintf('  [OK] Key: PASS (all meet strength)\n');
end

fprintf('\n');
if all_pass
    fprintf('  >>> OVERALL: DESIGN IS SATISFACTORY <<<\n');
else
    fprintf('  >>> OVERALL: DESIGN REQUIRES REVISION <<<\n');
end

fprintf('=====================================================================\n');

%% ========================================================================
% HELPER
%% ========================================================================
function out = conditional(cond, a, b)
    if cond, out = a; else, out = b; end
end
