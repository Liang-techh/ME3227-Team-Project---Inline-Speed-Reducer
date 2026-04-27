% =========================================================================
% ME3227 Team Project - 3-Shaft Speed Reducer 2D Visualization
% =========================================================================

clear; clc; close all;

%% Global Settings
fig = figure('Name', 'ME3227 Team Project - Gearbox 2D Profile', ...
             'Position', [80, 50, 1200, 850], 'Color', 'w');

% Color scheme
colors.shaft      = [0.80 0.80 0.82];    % shaft body
colors.shaftEdge  = [0.30 0.30 0.32];   % shaft edge
colors.gear1      = [0.90 0.35 0.15];   % gear 1 / input
colors.gear2      = [0.15 0.50 0.80];   % gear 2 / intermediate large
colors.gear3      = [0.20 0.65 0.40];   % gear 3 / intermediate small
colors.gear4      = [0.65 0.20 0.70];   % gear 4 / output large
colors.coupling   = [0.95 0.60 0.15];   % coupling
colors.bearing    = [0.40 0.40 0.42];   % bearing
colors.key        = [0.25 0.25 0.28];   % keyway
colors.snapRing   = [0.10 0.10 0.12];   % snap ring
colors.centerLine = [0.50 0.50 0.50];   % center line
colors.dimLine    = [0.35 0.35 0.37];   % dimension line
colors.pressFit   = [0.85 0.30 0.30];   % press fit zone

% Gear mesh center distances
% Gear 1 (D40) meshes with Gear 2 (D70) -> center distance = (40+70)/2 = 55
% Gear 3 (D40) meshes with Gear 4 (D80) -> center distance = (40+80)/2 = 60
centerDist_12 = (40 + 70) / 2;  % shaft 1-2 center dist
centerDist_23 = (40 + 80) / 2;  % shaft 2-3 center dist

%% Shaft 1: Input Shaft
% Layout: coupling - L bearing - body - Gear 1 - R bearing
% Segments: [x0(mm), L(mm), d(mm), type]
% Type: 0=body, 1=bearing, 2=gear, 3=coupling, 4=seal
s1_segments = [
    0,   30,  15,  3;   % left coupling extension
    30,  20,  20,  1;   % L bearing (ID20, OD47)
    50,  50,  20,  0;   % body transition
    100, 25,  25,  2;   % Gear 1 mount (bore 25, OD 50)
    125, 10,  20,  0;   % spacer
    135, 20,  20,  1;   % R bearing
    155, 15,  15,  4;   % seal extension
];

% Features: [center x, width, OD, type, label idx]
% type: gear/coupling
s1_features = [
    15,  20,  22,  1,  1;   % input coupling (x=15, w=20, OD=22)
    92,  25,  50,  2,  2;   % Gear 1 (x=92, w=25, OD=50)
];

% Keyways: [center x, width, depth, length, feature idx]
s1_keys = [
    15,  5,  2.5, 16,  1;   % coupling keyway
    92,  6,  3,   20,  2;   % Gear 1 keyway
];

% Snap rings: [center x, groove width, depth, feature idx]
s1_snapRings = [
    82,  2,  1.5, 2;   % Gear 1 L snap ring
    102, 2,  1.5, 2;   % Gear 1 R snap ring
];

% Bearings: [center x, width, ID, OD, type]
% 1=deep groove ball, 2=cylindrical roller
s1_bearings = [
    40,  16,  20,  47,  1;   % L bearing 6204
    145, 16,  20,  47,  1;   % R bearing 6204
];

% Press fit zones: [x0, x1]
s1_pressFit = [
    30,  50;
    100, 125;
    135, 155;
];

%% Shaft 2: Intermediate Shaft
% Layout: L bearing - Gear 2 - body - Gear 3 - R bearing
% Total L=200mm, stepped shaft
s2_segments = [
    0,   25,  25,  1;   % L bearing (ID25, OD52)
    25,  10,  28,  0;   % locating shoulder
    35,  50,  28,  2;   % Gear 2 mount (large, OD 35*2.5 tip)
    85,  20,  35,  0;   % center body
    105, 10,  38,  0;   % center shoulder
    115, 40,  28,  2;   % Gear 3 mount (small, OD 48)
    155, 10,  35,  0;   % locating shoulder
    165, 25,  25,  1;   % R bearing
    190, 10,  22,  4;   % seal
];

% Features: [center x, width, OD, type, label idx]
% OD is the feature OD, not pitch diameter
s2_features = [
    50,  30,  75,  2,  3;   % Gear 2 (large, x=50, w=30, tipD~78)
    145, 30,  48,  2,  4;   % Gear 3 (small, x=145, w=30, OD=48)
];

% Keyways
s2_keys = [
    60,  6,  3,  20,  3;   % Gear 2 keyway
    145, 8,  3.5,  25,  4;   % Gear 3 keyway
];

% Snap rings
s2_snapRings = [
    25,  2,  1.8,  3;   % Gear 2 L snap ring
    85,  2,  1.8,  3;   % Gear 2 R snap ring
    125, 2,  1.8,  4;   % Gear 3 L snap ring
    180, 2,  1.8,  4;   % Gear 3 R snap ring
];

% Bearings
s2_bearings = [
    12,  20,  20,  42,  1;   % L bearing
    177, 20,  20,  42,  1;   % R bearing
];

% Press fit zones
s2_pressFit = [
    0,   25;
    35,  85;
    115, 155;
    165, 190;
];

%% Shaft 3: Output Shaft
% Layout: L bearing - Gear 4 - body - R bearing - coupling
% Total L=180mm
s3_segments = [
    0,   30,  30,  1;   % L bearing (ID30, OD62)
    30,  12,  35,  0;   % locating shoulder
    42,  50,  42,  2;   % Gear 4 mount
    92,  15,  42,  0;   % center body
    107, 12,  45,  0;   % R shoulder
    119, 25,  35,  1;   % R bearing
    144, 16,  30,  4;   % seal
    160, 20,  30,  3;   % output coupling (L=180)
];

% Features
s3_features = [
    80,  40,  90,  2,  5;   % Gear 4 (x=80, w=40, tipD~90)
    170, 20,  24,  1,  6;   % output coupling (x=170, w=20, OD=24)
];

% Keyways
s3_keys = [
    80,  10, 4.0,  35,  5;   % Gear 4 keyway
    170, 8,  3.5,  25,  6;   % coupling keyway
];

% Snap rings
s3_snapRings = [
    42,  2,  2.0,  5;   % Gear 4 L snap ring
    100, 2,  2.0,  5;   % Gear 4 R snap ring
    160, 2,  1.8,  6;   % coupling L snap ring
];

% Bearings
s3_bearings = [
    15,  24,  30,  62,  1;   % L bearing 6206
    131, 24,  35,  72,  1;   % R bearing 6207
];

% Press fit zones
s3_pressFit = [
    0,   30;
    42,  92;
    119, 144;
];

%% ================= Labels =================
featureLabels = {'Input Coupling', 'Gear 1 (z1)', ...
                 'Gear 2 (z2)', 'Gear 3 (z3)', ...
                 'Gear 4 (z4)', 'Output Coupling'};

%% Plot Generation
% 4x1 layout: 3 detailed shafts + 1 assembly overview
% Use annotation for MATLAB versions before R2018b (sgtitle requires R2018b+)
annotation('textbox', [0.15, 0.97, 0.7, 0.02], 'String', ...
           'Inline Speed Reducer - Complete 2D Shaft Assembly', ...
           'FontSize', 16, 'FontWeight', 'bold', 'Color', [0.15 0.15 0.15], ...
           'EdgeColor', 'none', 'HorizontalAlignment', 'center');

% --- Subplot 1: Input shaft ---
ax1 = subplot(4, 1, 1);
draw_shaft_detailed(ax1, 'Shaft 1 (Input) - n_1 = 1440 rpm', ...
    s1_segments, s1_features, s1_bearings, s1_keys, s1_snapRings, s1_pressFit, ...
    featureLabels, colors, 1);

% --- Subplot 2: Intermediate shaft ---
ax2 = subplot(4, 1, 2);
draw_shaft_detailed(ax2, 'Shaft 2 (Intermediate) - n_2 = 480 rpm', ...
    s2_segments, s2_features, s2_bearings, s2_keys, s2_snapRings, s2_pressFit, ...
    featureLabels, colors, 2);

% --- Subplot 3: Output shaft ---
ax3 = subplot(4, 1, 3);
draw_shaft_detailed(ax3, 'Shaft 3 (Output) - n_3 = 160 rpm', ...
    s3_segments, s3_features, s3_bearings, s3_keys, s3_snapRings, s3_pressFit, ...
    featureLabels, colors, 3);

% --- Subplot 4: Assembly overview ---
ax4 = subplot(4, 1, 4);
draw_assembly_overview(ax4, 'Assembly Overview - Gear Meshing & Shaft Arrangement', ...
    colors, centerDist_12, centerDist_23);

%% ================= Save Image =================
% Auto-save (uncomment next line to enable)
% print(fig, 'SpeedReducer_3Shafts_2D', '-dpng', '-r300');

fprintf('=== Drawing Complete ===\n');
fprintf('To save manually, use: print(fig, ''MyGearbox'', ''-dpng'', ''-r300'')\n');
fprintf('(Do NOT use gcf -- it may target the wrong figure window)\n');
fprintf('Gear meshing center distances:\n');
fprintf('  Shaft 1-2: a_12 = %.1f mm (Gear1 D%d + Gear2 D%d)\n', centerDist_12, 40, 70);
fprintf('  Shaft 2-3: a_23 = %.1f mm (Gear3 D%d + Gear4 D%d)\n', centerDist_23, 40, 80);
fprintf('Total reduction ratio: i = (70/40) × (80/40) = %.2f\n', (70/40)*(80/40));

%% =========================================================================
% ========================== Helper Functions ==========================
%% =========================================================================

function draw_shaft_detailed(ax, title_str, segments, features, bearings, ...
                           keys, snapRings, pressFit, labels, colors, shaftIdx)
% draw_shaft_detailed: detailed 2D shaft section view
%   ax        - axis handle
%   title_str - title string
%   segments  - [x0, length, diameter, type]
%   features  - [center x, width, OD, type, label idx]
%   bearings  - [center x, width, ID, OD, type]
%   keys      - [center x, width, depth, length, feature idx]
%   snapRings - [center x, groove width, depth, feature idx]
%   pressFit  - [start x, end x, note]
%   labels    - feature labels cell array
%   colors    - color struct
%   shaftIdx  - shaft number (1/2/3)

    axes(ax); hold on; box on;
    
    % compute total shaft length
    totalL = max(segments(:,1) + segments(:,2));
    maxD = max(segments(:,3));
    
    %% 1. Draw shaft segments (stepped profile)
    % fill for solid shaft section
    nSeg = size(segments, 1);
    for i = 1:nSeg
        x0 = segments(i, 1);
        L  = segments(i, 2);
        d  = segments(i, 3);
        type = segments(i, 4);
        
        % slightly different fill per segment type
        if type == 1      % bearing segment
            faceColor = colors.shaft * 0.95;
        elseif type == 2  % gear segment
            faceColor = colors.shaft * 1.0;
        elseif type == 3  % coupling segment
            faceColor = colors.shaft * 1.02;
        else
            faceColor = colors.shaft;
        end
        
        % draw segment rectangle (upper half)
        rectangle('Position', [x0, 0, L, d/2], ...
                  'FaceColor', faceColor, 'EdgeColor', colors.shaftEdge, ...
                  'LineWidth', 1.2);
        % draw lower half
        rectangle('Position', [x0, -d/2, L, d/2], ...
                  'FaceColor', faceColor, 'EdgeColor', colors.shaftEdge, ...
                  'LineWidth', 1.2);
    end
    
    %% 2. Draw chamfers at shoulders
    for i = 1:nSeg-1
        x1_end = segments(i, 1) + segments(i, 2);
        d1 = segments(i, 3);
        d2 = segments(i+1, 3);
        x2_start = segments(i+1, 1);
        
        % if diameter changes at shoulder
        if abs(d1 - d2) > 0.5 && abs(x1_end - x2_start) < 0.1
            % draw chamfer mark
            chamfer = min(2, abs(d1-d2)/4);
            if d2 > d1
                % shoulder: larger dia on right
                plot([x1_end-chamfer, x1_end], [d1/2, d1/2], 'Color', colors.shaftEdge, 'LineWidth', 1);
                plot([x1_end-chamfer, x1_end], [-d1/2, -d1/2], 'Color', colors.shaftEdge, 'LineWidth', 1);
            end
        end
    end
    
    %% 3. Draw bearings (detailed)
    for i = 1:size(bearings, 1)
        bx = bearings(i, 1);        % center x
        bw = bearings(i, 2);        % width
        bd_in = bearings(i, 3);     % ID
        bd_out = bearings(i, 4);   % OD
        btype = bearings(i, 5);     % type
        
        xL = bx - bw/2;
        xR = bx + bw/2;
        
        % bearing outer ring
        rectangle('Position', [xL, -bd_out/2, bw, bd_out], ...
                  'FaceColor', colors.bearing, 'EdgeColor', [0.2 0.2 0.2], ...
                  'LineWidth', 1.5, 'FaceAlpha', 0.3);
        
        % bearing inner ring (white fill)
        rectangle('Position', [xL+2, -bd_in/2-0.5, bw-4, bd_in+1], ...
                  'FaceColor', 'w', 'EdgeColor', colors.shaftEdge, 'LineWidth', 1);
        
        % roller elements (diagonal lines)
        nRollers = 7;
        rollerX = linspace(xL+3, xR-3, nRollers);
        for r = 1:nRollers
            plot([rollerX(r)-1, rollerX(r)+1], ...
                 [bd_in/2+1, bd_out/2-1], 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
            plot([rollerX(r)-1, rollerX(r)+1], ...
                 [-bd_in/2-1, -bd_out/2+1], 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);
        end
        
        % bearing label
        text(bx, bd_out/2 + 8, sprintf('B%d\nØ%d×Ø%d', i, bd_in, bd_out), ...
             'HorizontalAlignment', 'center', 'FontSize', 7, ...
             'Color', [0.3 0.3 0.3]);
    end
    
    %% 4. Draw gears/couplings (with teeth)
    featureColors = {colors.coupling, colors.gear1, colors.gear2, ...
                     colors.gear3, colors.gear4, colors.coupling};
    
    for i = 1:size(features, 1)
        fx = features(i, 1);      % center x
        fw = features(i, 2);       % width
        fd = features(i, 3);       % OD (pitch/tip dia)
        ftype = features(i, 4);   % type
        fidx = features(i, 5);     % label idx
        
        xL = fx - fw/2;
        c = featureColors{fidx};
        
        % for gears, draw teeth effect
        if ftype == 2
            % gear body (semi-transparent)
            rectangle('Position', [xL, -fd/2, fw, fd], ...
                      'FaceColor', c, 'EdgeColor', c*0.7, ...
                      'LineWidth', 1.5, 'FaceAlpha', 0.25);
            
            % teeth indication (tip and root circles)
            dedendum = fd * 0.05;  % dedendum estimate
            addendum = fd * 0.05;  % addendum estimate
            rootD = fd - 2*dedendum;
            tipD = fd + 2*addendum;
            
            % tip circle
            rectangle('Position', [xL, -tipD/2, fw, tipD], ...
                      'FaceColor', 'none', 'EdgeColor', c*0.5, ...
                      'LineWidth', 1, 'LineStyle', '--');
            
            % root circle (dotted)
            rectangle('Position', [xL+1, -rootD/2, fw-2, rootD], ...
                      'FaceColor', 'none', 'EdgeColor', c*0.6, ...
                      'LineWidth', 0.8, 'LineStyle', ':');
            
            % vertical tooth lines across face width
            nTeeth = 5;
            toothX = linspace(xL+2, xL+fw-2, nTeeth);
            for t = 1:nTeeth
                plot([toothX(t), toothX(t)], [fd/2, fd/2+addendum], ...
                     'Color', c*0.6, 'LineWidth', 1.2);
                plot([toothX(t), toothX(t)], [-fd/2, -fd/2-addendum], ...
                     'Color', c*0.6, 'LineWidth', 1.2);
            end
        else
            % coupling (solid)
            rectangle('Position', [xL, -fd/2, fw, fd], ...
                      'FaceColor', c, 'EdgeColor', c*0.7, ...
                      'LineWidth', 1.5, 'FaceAlpha', 0.35);
        end
        
        % feature center line (keyway pos)
        plot([fx, fx], [-fd/2-2, fd/2+2], 'Color', c*0.8, 'LineWidth', 1.5, 'LineStyle', '-.');
        
        % text label
        labelY = fd/2 + 12;
        if ftype == 2
            text(fx, labelY, sprintf('%s\nD=%dmm', labels{fidx}, fd), ...
                 'HorizontalAlignment', 'center', 'FontSize', 8, ...
                 'Color', c*0.7, 'FontWeight', 'bold');
        else
            text(fx, labelY, sprintf('%s\nD=%dmm', labels{fidx}, fd), ...
                 'HorizontalAlignment', 'center', 'FontSize', 8, ...
                 'Color', c*0.7, 'FontWeight', 'bold');
        end
    end
    
    %% 5. Draw keyways
    for i = 1:size(keys, 1)
        kx = keys(i, 1);
        kw = keys(i, 2);   % key width
        kd = keys(i, 3);   % key depth (on shaft)
        kL = keys(i, 4);   % key length
        % kfeat = keys(i, 5); % parent feature (unused)
        
        xL = kx - kL/2;
        
        % keyway section (drawn on shaft surface)
        % find shaft dia at keyway location
        shaftD_atKey = maxD;
        for j = 1:size(segments, 1)
            if kx >= segments(j,1) && kx <= segments(j,1)+segments(j,2)
                shaftD_atKey = segments(j, 3);
                break;
            end
        end
        
        % draw keyway outline (rect groove)
        keyY = shaftD_atKey/2 - kd;
        rectangle('Position', [xL, keyY, kL, kd], ...
                  'FaceColor', colors.key, 'EdgeColor', 'k', ...
                  'LineWidth', 1, 'FaceAlpha', 0.7);
        rectangle('Position', [xL, -keyY-kd, kL, kd], ...
                  'FaceColor', colors.key, 'EdgeColor', 'k', ...
                  'LineWidth', 1, 'FaceAlpha', 0.7);
        
        % keyway label
        text(kx, shaftD_atKey/2 + 4, sprintf('Key\n%d×%d', kw, kd), ...
             'HorizontalAlignment', 'center', 'FontSize', 6.5, ...
             'Color', colors.key);
    end
    
    %% 6. Draw Snap Rings
    for i = 1:size(snapRings, 1)
        sx = snapRings(i, 1);
        sw = snapRings(i, 2);   % groove width
        sd = snapRings(i, 3);   % groove depth
        % sfeat = snapRings(i, 4);% parent feature
        
        % find shaft dia at this location
        shaftD_atSnap = maxD;
        for j = 1:size(segments, 1)
            if sx >= segments(j,1) && sx <= segments(j,1)+segments(j,2)
                shaftD_atSnap = segments(j, 3);
                break;
            end
        end
        
        % snap ring groove (rect)
        grooveR = shaftD_atSnap/2 - sd;
        rectangle('Position', [sx-sw/2, grooveR, sw, sd], ...
                  'FaceColor', colors.snapRing, 'EdgeColor', 'k', ...
                  'LineWidth', 1, 'FaceAlpha', 0.9);
        rectangle('Position', [sx-sw/2, -grooveR-sd, sw, sd], ...
                  'FaceColor', colors.snapRing, 'EdgeColor', 'k', ...
                  'LineWidth', 1, 'FaceAlpha', 0.9);
    end
    
    %% 7. Draw press fit marks (red hatch)
    for i = 1:size(pressFit, 1)
        px0 = pressFit(i, 1);
        px1 = pressFit(i, 2);
        % pdesc = pressFit{i, 3}; % description text
        
        % find shaft dia in this zone
        pD = 15;  % default value
        for j = 1:size(segments, 1)
            segEnd = segments(j,1) + segments(j,2);
            if px0 >= segments(j,1) && px0 <= segEnd
                pD = segments(j, 3);
                break;
            end
        end
        
        % red diagonal hatching for press fit
        nHatch = 8;
        hatchX = linspace(px0+1, px1-1, nHatch);
        for h = 1:nHatch
            plot([hatchX(h), hatchX(h)+2], [pD/2-1, -pD/2+1], ...
                 'Color', colors.pressFit, 'LineWidth', 1.2, 'LineStyle', '-');
        end
    end
    
    %% 8. Draw center line (dash-dot)
    xRange = [-15, totalL + 30];
    plot(xRange, [0, 0], 'Color', colors.centerLine, 'LineWidth', 1, 'LineStyle', '-.');
    
    %% 9. Draw dimension lines (total length)
    dimY = -maxD/2 - 20;
    % total length dim
    draw_dimension_line(0, totalL, dimY, sprintf('L=%d', totalL), colors.dimLine);
    
    % segment dimensions
    for i = 1:size(segments, 1)
        if segments(i, 2) >= 15  % only label longer segments
            dimY_local = dimY - 8 - mod(i,2)*8;  % staggered to avoid overlap
            x0 = segments(i,1);
            x1 = x0 + segments(i,2);
            draw_dimension_line(x0, x1, dimY_local, sprintf('%d', segments(i,2)), colors.dimLine);
        end
    end
    
    %% 10. Axis Setup and Title
    xlim([-20, totalL + 40]);
    ylim([-maxD/2 - 35, maxD/2 + 35]);
    axis equal;
    title(title_str, 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
    ylabel('Radius (mm)', 'FontSize', 9, 'Color', [0.4 0.4 0.4]);
    grid on;
    set(gca, 'GridLineStyle', ':', 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.5);
    set(gca, 'FontSize', 8, 'Color', 'w');
    xlabel('Axial Position x (mm)', 'FontSize', 9, 'Color', [0.4 0.4 0.4]);
end

%% -------------------------------------------------------------------------
function draw_dimension_line(x1, x2, y, label, color)
% draw dimension with arrow boundaries
    % vertical boundary lines
    plot([x1, x1], [y-2, y+2], 'Color', color, 'LineWidth', 1);
    plot([x2, x2], [y-2, y+2], 'Color', color, 'LineWidth', 1);
    % horizontal dim line
    plot([x1, x2], [y, y], 'Color', color, 'LineWidth', 0.8);
    % text
    midX = (x1 + x2) / 2;
    text(midX, y - 4, label, 'HorizontalAlignment', 'center', ...
         'FontSize', 7, 'Color', color, 'VerticalAlignment', 'top');
end

%% -------------------------------------------------------------------------
function draw_assembly_overview(ax, title_str, colors, a12, a23)
% draw_assembly_overview: simplified assembly layout
%   show 3 shafts, meshing, center distances, bearings
    axes(ax); hold on; box on;
    
    % Y positions for 3 shafts
    yShaft1 = 60;
    yShaft2 = 0;
    yShaft3 = -55;
    
    % shaft 1: input (top)
    draw_shaft_symbolic(yShaft1, 170, 15, ...
        [40, 20, 22, 1; 112, 20, 40, 2], ...     % features: [center, width, OD, type]
        [40, 145], ...                            % bearing positions
        colors, '1');
    
    % shaft 2: intermediate (middle)
    draw_shaft_symbolic(yShaft2, 200, 25, ...
        [50, 25, 70, 2; 150, 20, 40, 2], ...
        [20, 180], ...
        colors, '2');
    
    % shaft 3: output (bottom)
    draw_shaft_symbolic(yShaft3, 180, 30, ...
        [70, 30, 80, 2; 155, 20, 22, 1], ...
        [20, 160], ...
        colors, '3');
    
    % draw center distance lines
    % a12 (shaft 1-2)
    xRef = 100;  % reference X position
    plot([xRef+80, xRef+80], [yShaft1, yShaft2], 'Color', [0.5 0.5 0.5], ...
         'LineWidth', 1, 'LineStyle', '--');
    text(xRef+85, (yShaft1+yShaft2)/2, sprintf('a_{12}=%.1f', a12), ...
         'FontSize', 9, 'Color', [0.4 0.4 0.4], 'Rotation', 90, ...
         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');
    
    % a23 (shaft 2-3)
    plot([xRef+120, xRef+120], [yShaft2, yShaft3], 'Color', [0.5 0.5 0.5], ...
         'LineWidth', 1, 'LineStyle', '--');
    text(xRef+125, (yShaft2+yShaft3)/2, sprintf('a_{23}=%.1f', a23), ...
         'FontSize', 9, 'Color', [0.4 0.4 0.4], 'Rotation', 90, ...
         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');
    
    % draw meshing lines
    % Gear 1-2 mesh point
    meshX1 = 110;  % Gear 1 center
    meshX2 = 50;   % Gear 2 center
    % theoretical mesh line
    plot([meshX1, meshX1], [yShaft1, yShaft2], 'Color', colors.gear1*0.6+0.4, ...
         'LineWidth', 2, 'LineStyle', ':');
    
    % Gear 3-4 mesh point
    meshX3 = 150;  % Gear 3 center
    meshX4 = 70;   % Gear 4 center
    plot([meshX3, meshX3], [yShaft2, yShaft3], 'Color', colors.gear3*0.6+0.4, ...
         'LineWidth', 2, 'LineStyle', ':');
    
    % speed / ratio labels
    text(220, yShaft1, 'n_1=1440rpm', 'FontSize', 9, 'Color', colors.gear1);
    text(220, yShaft2, 'n_2=480rpm', 'FontSize', 9, 'Color', colors.gear2);
    text(220, yShaft3, 'n_3=160rpm', 'FontSize', 9, 'Color', colors.gear4);
    text(220, (yShaft2+yShaft3)/2, sprintf('i_{total}=%.1f', (70/40)*(80/40)), ...
         'FontSize', 9, 'Color', [0.3 0.3 0.3], 'FontWeight', 'bold');
    
    % rotation direction arrows
    annotation('arrow', [0.28 0.30], [0.78 0.78], 'Color', colors.gear1);
    annotation('arrow', [0.28 0.26], [0.60 0.60], 'Color', colors.gear2);
    annotation('arrow', [0.28 0.30], [0.42 0.42], 'Color', colors.gear4);
    
    % legend items
    legend_items = {
        rectangle('Position', [0 0 1 1], 'FaceColor', colors.shaft, 'EdgeColor', 'k');
        rectangle('Position', [0 0 1 1], 'FaceColor', colors.gear2, 'EdgeColor', 'k', 'FaceAlpha', 0.3);
        rectangle('Position', [0 0 1 1], 'FaceColor', colors.bearing, 'EdgeColor', 'k', 'FaceAlpha', 0.3);
    };
    
    % gearbox housing outline
    boxX = -10; boxY = -75; boxW = 260; boxH = 160;
    rectangle('Position', [boxX, boxY, boxW, boxH], ...
              'FaceColor', 'none', 'EdgeColor', [0.6 0.6 0.6], ...
              'LineWidth', 1.5, 'LineStyle', '-.');
    text(boxX + boxW/2, boxY + boxH + 5, 'Gearbox Housing (schematic)', ...
         'HorizontalAlignment', 'center', 'FontSize', 9, ...
         'Color', [0.5 0.5 0.5]);
    
    % axis setup
    xlim([-20, 280]);
    ylim([-85, 85]);
    axis equal;
    set(gca, 'Visible', 'off');  % hide axes for schematic look
    title(title_str, 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);
end

%% -------------------------------------------------------------------------
function draw_shaft_symbolic(yCenter, shaftLength, baseD, features, bPos, colors, label)
% draw_shaft_symbolic: simplified shaft in assembly view
    
    % shaft center line
    plot([-10, shaftLength+10], [yCenter, yCenter], 'Color', colors.centerLine, ...
         'LineWidth', 1, 'LineStyle', '-.');
    
    % shaft body (simplified)
    rectangle('Position', [0, yCenter-baseD/2, shaftLength, baseD], ...
              'FaceColor', colors.shaft, 'EdgeColor', colors.shaftEdge, 'LineWidth', 1.5);
    
    % bearing (X mark)
    for i = 1:length(bPos)
        bx = bPos(i);
        % draw X mark
        offset = 8;
        plot([bx-3, bx+3], [yCenter-offset, yCenter+offset], 'k-', 'LineWidth', 1.5);
        plot([bx-3, bx+3], [yCenter+offset, yCenter-offset], 'k-', 'LineWidth', 1.5);
        % bearing outline
        rectangle('Position', [bx-4, yCenter-10, 8, 20], ...
                  'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 1);
    end
    
    % features (gears/couplings)
    for i = 1:size(features, 1)
        fx = features(i, 1);
        fw = features(i, 2);
        fd = features(i, 3);
        ftype = features(i, 4);
        
        xL = fx - fw/2;
        if ftype == 2
            c = colors.gear2;  % gear uses blue
            % small high-speed gear uses green
            if fd < 50
                c = colors.gear3;
            end
            % large low-speed gear uses purple
            if fd > 60
                c = colors.gear4;
            end
        else
            c = colors.coupling;  % coupling
        end
        
        rectangle('Position', [xL, yCenter-fd/2, fw, fd], ...
                  'FaceColor', c, 'EdgeColor', c*0.7, ...
                  'LineWidth', 1.5, 'FaceAlpha', 0.35);
        
        % keyway mark
        plot([fx, fx], [yCenter-baseD/2-2, yCenter+baseD/2+2], ...
             'Color', colors.key, 'LineWidth', 2.5);
    end
    
    % shaft number label
    text(-8, yCenter, label, 'FontSize', 11, 'FontWeight', 'bold', ...
         'Color', [0.2 0.2 0.2], 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle');
end
