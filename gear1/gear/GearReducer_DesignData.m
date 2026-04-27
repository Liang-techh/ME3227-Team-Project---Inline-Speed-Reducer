% =========================================================================
% GearReducer_DesignData.m
% Gearbox design parameters and engineering calculations
% Includes: gear params, shaft dims, bearing selection, key specs
% All data available for visualization scripts
% =========================================================================

%% 1. Design Input Parameters
% Application requirements
P_out = 5.5;          % output power (kW)
n_in = 1440;          % input speed (rpm)
n_out = 160;          % output speed (rpm)

% total gear ratio
i_total = n_in / n_out;   % i = 9.0

% Two-stage ratio split (equal strength)
i_1 = 3.0;            % stage 1 ratio (Gear 1 -> Gear 2)
i_2 = 3.0;            % stage 2 ratio (Gear 3 -> Gear 4)

% verify
n_1 = n_in;           % shaft 1 speed
n_2 = n_1 / i_1;      % shaft 2 speed ≈ 480 rpm
n_3 = n_2 / i_2;      % shaft 3 speed ≈ 160 rpm

%% 2. Gear Parameter Design
% Gear material: 40Cr Q&T, hardness 250-280 HBS
% Standard spur gears, module m (straight teeth)

% --- Stage 1 (high speed) ---
% Module selection
m_1 = 2.5;            % stage 1 module (mm)

% Teeth count (avoid undercut, z_min >= 17)
z1 = 20;              % Gear 1 teeth (high speed pinion)
z2 = round(z1 * i_1); % Gear 2 teeth = 60

% pitch diameter
d1 = m_1 * z1;        % Gear 1 pitch dia = 50 mm
d2 = m_1 * z2;        % Gear 2 pitch dia = 150 mm

% center distance
a_12 = (d1 + d2) / 2; % stage 1 center distance = 80 mm

% face width
b1 = 25;              % Gear 1 face width (mm)
b2 = 30;              % Gear 2 face width (mm)

% tip diameter
da1 = d1 + 2 * m_1;   % Gear 1 tip dia = 55 mm
da2 = d2 + 2 * m_1;   % Gear 2 tip dia = 155 mm

% root diameter
df1 = d1 - 2.5 * m_1; % Gear 1 root dia = 43.75 mm
df2 = d2 - 2.5 * m_1; % Gear 2 root dia = 143.75 mm

% --- Stage 2 (low speed) ---
m_2 = 3.0;            % stage 2 module (mm)

z3 = 16;              % Gear 3 teeth (low speed pinion)
z4 = round(z3 * i_2); % Gear 4 teeth = 48

% pitch diameter
d3 = m_2 * z3;        % Gear 3 pitch dia = 48 mm
d4 = m_2 * z4;        % Gear 4 pitch dia = 144 mm

a_23 = (d3 + d4) / 2; % stage 2 center distance = 80 mm

b3 = 30;              % Gear 3 face width (mm)
b4 = 35;              % Gear 4 face width (mm)

da3 = d3 + 2 * m_2;   % Gear 3 tip dia = 54 mm
da4 = d4 + 2 * m_2;   % Gear 4 tip dia = 150 mm

df3 = d3 - 2.5 * m_2; % Gear 3 root dia = 40.5 mm
df4 = d4 - 2.5 * m_2; % Gear 4 root dia = 136.5 mm

% Gear parameter summary
fprintf('=== Gear Parameter Summary ===\n');
fprintf('%-8s %4s %8s %12s %12s %12s %12s %10s\n', 'Name', 'Z', 'Module', 'PitchDia', 'TipDia', 'RootDia', 'FaceWidth', 'Speed');
fprintf('%s\n', repmat('-', 1, 75));
fprintf('%-8s %4d %8.2f %12.2f %12.2f %12.2f %12d %10.0f\n', 'Gear1', z1, m_1, d1, da1, df1, b1, n_1);
fprintf('%-8s %4d %8.2f %12.2f %12.2f %12.2f %12d %10.0f\n', 'Gear2', z2, m_1, d2, da2, df2, b2, n_2);
fprintf('%-8s %4d %8.2f %12.2f %12.2f %12.2f %12d %10.0f\n', 'Gear3', z3, m_2, d3, da3, df3, b3, n_3);
fprintf('%-8s %4d %8.2f %12.2f %12.2f %12.2f %12d %10.0f\n', 'Gear4', z4, m_2, d4, da4, df4, b4, n_3);
fprintf('\n');

%% 3. Shaft Structure Design
% Shaft material: 45 steel, yield σ_y ≈ 355 MPa
% Estimate dia by torsion, then check combined stress

% Torsional shear: d >= A0 * (P/n)^(1/3)
% A0 = 110 for 45 steel
A0 = 110;

% --- Shaft 1 ---
% Power (with efficiencies)
eta_b = 0.99; eta_g = 0.97;
P1 = P_out / (eta_b^3 * eta_g^2);   % input power ≈ 6.0 kW
T1 = 9550 * P1 / n_1;               % input torque (N.m)
d1_est = A0 * (P1 / n_1)^(1/3);     % min shaft dia estimate ≈ 12-15 mm

% Shaft 1 dimensions (structural design)
s1.length_total = 150;      % total length (mm)
s1.d_bearing = 20;          % bearing dia (for 6204, ID 20mm)
s1.d_gear = 18;             % gear mount dia
s1.d_coupling = 15;         % coupling dia
s1.d_seal = 15;             % seal dia

% segments: [x0, length, dia, type code]
% type: 0=body, 1=bearing, 2=gear, 3=coupling, 4=seal
s1.segments = [
    0,   30,  s1.d_coupling,  3;   % left coupling extension
    30,  20,  s1.d_bearing,    1;   % left bearing
    50,  50,  s1.d_bearing,    0;   % body
    100, 25,  s1.d_gear,       2;   % Gear1
    125, 10,  s1.d_bearing,    0;   % locating
    135, 20,  s1.d_bearing,    1;   % right bearing
    155, 15,  s1.d_seal,       4;   % seal extension
];

% features: [center x, width, OD, type, label idx]
s1.features = [
    15,  20,  22,  1,  1;   % input coupling
    112, 20,  da1, 2,  2;   % Gear 1
];

% keys: [center x, width, depth, length, feature]
% standard keys: coupling 4x4x14, gear 5x5x16
s1.keys = [
    15,  4,  2.0,  14,  1;   % coupling key
    112, 5,  2.5,  16,  2;   % Gear 1 key
];

% snap rings: [center x, groove w, depth, feature]
s1.snapRings = [
    92,  2,  1.2,  2;   % Gear 1 left loc
    132, 2,  1.2,  2;   % Gear 1 right loc
];

% bearings: [center x, width, ID, OD, type]
s1.bearings = [
    40,  16,  15,  32,  1;   % left bearing 6202
    145, 16,  15,  32,  1;   % right bearing 6202
];

% press fit: [x0, x1]
s1.pressFit = [
    30,  50;   % left bearing fit
    100, 125;  % Gear 1 fit
    135, 155;  % right bearing fit
];

% --- Shaft 2 ---
P2 = P1 * eta_b * eta_g;    % intermediate shaft power
T2 = 9550 * P2 / n_2;       % intermediate torque (N.m)
d2_est = A0 * (P2 / n_2)^(1/3);  % estimated dia ≈ 18-22 mm

s2.length_total = 200;
s2.d_bearing = 25;          % for 6205 bearing (ID 25)
s2.d_gear2 = 28;            % Gear 2 mount
s2.d_body = 35;             % center body
s2.d_gear3 = 28;            % Gear 3 mount

s2.segments = [
    0,   25,  s2.d_bearing,   1;   % left bearing
    25,  10,  s2.d_gear2+2,  0;   % shoulder
    35,  50,  s2.d_gear2,    2;   % Gear 2
    85,  20,  s2.d_body,     0;   % center body
    105, 10,  s2.d_body+3,   0;   % center shoulder
    115, 40,  s2.d_gear3,    2;   % Gear 3
    155, 10,  s2.d_body,     0;   % shoulder
    165, 25,  s2.d_bearing,   1;   % right bearing
    190, 10,  18,            4;   % seal
];

s2.features = [
    60,  30,  da2, 2,  3;   % Gear 2 (large)
    135, 25,  da3, 2,  4;   % Gear 3 (small)
];

% keys: Gear 2 6x6x20, Gear 3 5x5x18
s2.keys = [
    60,  6,  3.0,  20,  3;
    135, 5,  2.5,  18,  4;
];

s2.snapRings = [
    25,  2,  1.5,  3;
    95,  2,  1.5,  3;
    115, 2,  1.5,  4;
    170, 2,  1.5,  4;
];

s2.bearings = [
    12,  20,  20,  42,  1;   % 6204
    177, 20,  20,  42,  1;   % 6204
];

s2.pressFit = [
    0,   25;
    35,  85;
    115, 155;
    165, 190;
];

% --- Shaft 3 ---
P3 = P2 * eta_b * eta_g;    % output shaft power ≈ P_out
T3 = 9550 * P3 / n_3;       % output torque (N.m) ≈ 328
d3_est = A0 * (P3 / n_3)^(1/3);  % estimated dia ≈ 25-30 mm

s3.length_total = 180;
s3.d_bearing = 30;          % for 6206 bearing (ID 30)
s3.d_gear4 = 42;            % Gear 4 mount
s3.d_body = 42;            % body
s3.d_coupling = 30;         % output coupling

s3.segments = [
    0,   30,  s3.d_bearing,   1;   % left bearing
    30,  12,  s3.d_gear4+2,  0;   % shoulder
    42,  50,  s3.d_gear4,    2;   % Gear 4
    92,  15,  s3.d_body,     0;   % body
    107, 12,  s3.d_body+2,   0;   % shoulder
    119, 25,  s3.d_bearing,   1;   % right bearing
    144, 16,  22,            4;   % seal
    160, 20,  s3.d_coupling,  3;   % output coupling (L=180)
];

s3.features = [
    70,  40,  da4, 2,  5;   % Gear 4 (large)
    187, 30,  24,  1,  6;   % output coupling
];

% keys: Gear 4 8x7x28, coupling 6x6x24
s3.keys = [
    70,  8,  3.5,  28,  5;
    187, 6,  3.0,  24,  6;
];

s3.snapRings = [
    35,  2,  1.8,  5;
    99,  2,  1.8,  5;
    170, 2,  1.5,  6;
];

s3.bearings = [
    15,  24,  25,  52,  1;   % 6205
    139, 24,  25,  52,  1;   % 6205
];

s3.pressFit = [
    0,   30;
    42,  97;
    124, 154;
];

%% 4. Bearing Parameter Summary
% Deep groove ball bearing params
fprintf('\n=== Bearing Selection Summary ===\n');
fprintf('%-12s %6s %8s %10s %10s %8s\n', 'Position', 'Shaft', 'Model', 'InnerDia', 'OuterDia', 'Width');
fprintf('%s\n', repmat('-', 1, 55));
bearing_names = {'Left_B1'; 'Right_B1'; 'Left_B2'; 'Right_B2'; 'Left_B3'; 'Right_B3'};
bearing_shaft = [1; 1; 2; 2; 3; 3];
bearing_model = {'6204'; '6204'; '6205'; '6205'; '6206'; '6207'};
bearing_inner = [20; 20; 25; 25; 30; 35];
bearing_outer = [47; 47; 52; 52; 62; 72];
bearing_width = [16; 16; 20; 20; 24; 25];
for i = 1:6
    fprintf('%-12s %6d %8s %10d %10d %8d\n', bearing_names{i}, bearing_shaft(i), ...
            bearing_model{i}, bearing_inner(i), bearing_outer(i), bearing_width(i));
end
fprintf('\n');

%% 5. Key Parameter Summary
fprintf('\n=== Parallel Key Specification ===\n');
fprintf('%-15s %6s %10s %10s %10s\n', 'Position', 'Shaft', 'KeyWidth', 'KeyHeight', 'KeyLength');
fprintf('%s\n', repmat('-', 1, 55));
key_names = {'S1_Coupling'; 'S1_Gear1'; 'S2_Gear2'; 'S2_Gear3'; 'S3_Gear4'; 'S3_Coupling'};
key_shaft = [1; 1; 2; 2; 3; 3];
key_w = [5; 6; 8; 8; 10; 8];
key_h = [5; 6; 7; 7; 8; 7];
key_L = [16; 20; 25; 25; 35; 28];
for i = 1:6
    fprintf('%-15s %6d %10d %10d %10d\n', key_names{i}, key_shaft(i), key_w(i), key_h(i), key_L(i));
end
fprintf('\n');

%% 6. Torque and Speed Summary
fprintf('\n=== Shaft Power & Torque Summary ===\n');
fprintf('%-10s %10s %10s %12s %10s\n', 'Shaft', 'Speed(rpm)', 'Power(kW)', 'Torque(Nm)', 'EstDia(mm)');
fprintf('%s\n', repmat('-', 1, 55));
fprintf('%-10s %10.0f %10.3f %12.3f %10.2f\n', 'Shaft_1', n_1, P1, T1, d1_est);
fprintf('%-10s %10.0f %10.3f %12.3f %10.2f\n', 'Shaft_2', n_2, P2, T2, d2_est);
fprintf('%-10s %10.0f %10.3f %12.3f %10.2f\n', 'Shaft_3', n_3, P3, T3, d3_est);
fprintf('\n');

%% 7. Center Distance and Ratio Summary
fprintf('\n=== Kinematic Summary ===\n');
fprintf('Total reduction ratio:     i_total = %.2f (target: %.2f)\n', i_total, n_in/n_out);
fprintf('Stage 1 ratio (Gear1-2):   i_1 = %.2f, a_12 = %.1f mm\n', i_1, a_12);
fprintf('Stage 2 ratio (Gear3-4):   i_2 = %.2f, a_23 = %.1f mm\n', i_2, a_23);
fprintf('Speeds: n1=%.0f, n2=%.0f, n3=%.0f rpm\n', n_1, n_2, n_3);

%% 8. Save as Struct
% Package all data into reducerData struct
reducerData.designInput.P_out = P_out;
reducerData.designInput.n_in = n_in;
reducerData.designInput.n_out = n_out;
reducerData.designInput.i_total = i_total;
reducerData.designInput.i_1 = i_1;
reducerData.designInput.i_2 = i_2;

reducerData.gear.summary.names = {'Gear1'; 'Gear2'; 'Gear3'; 'Gear4'};
reducerData.gear.summary.z = [z1; z2; z3; z4];
reducerData.gear.summary.m = [m_1; m_2; m_2; m_2];
reducerData.gear.summary.d = [d1; d2; d3; d4];
reducerData.gear.m = [m_1; m_2];
reducerData.gear.z = [z1, z2, z3, z4];
reducerData.gear.d = [d1, d2, d3, d4];
reducerData.gear.da = [da1, da2, da3, da4];
reducerData.gear.df = [df1, df2, df3, df4];
reducerData.gear.a = [a_12, a_23];

reducerData.shaft1 = s1;
reducerData.shaft2 = s2;
reducerData.shaft3 = s3;

reducerData.bearing.names = bearing_names;
reducerData.bearing.shaftNo = bearing_shaft;
reducerData.bearing.model = bearing_model;
reducerData.key.names = key_names;
reducerData.key.shaftNo = key_shaft;
reducerData.shaft.speeds = [n_1, n_2, n_3];
reducerData.shaft.powers = [P1, P2, P3];
reducerData.shaft.torques = [T1, T2, T3];

% Save to .mat for loading by visualization scripts
save('ReducerDesignData.mat', 'reducerData');
fprintf('\n>>> Data saved to ReducerDesignData.mat\n');
fprintf('>>> Run InlineSpeedReducer_3Shafts_Profile.m to visualize.\n');
