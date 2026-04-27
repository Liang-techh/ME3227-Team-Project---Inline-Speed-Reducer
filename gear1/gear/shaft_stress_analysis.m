% =========================================================================
% shaft_stress_analysis.m
% Description: Complete shaft stress analysis and safety factor check
%              using Shigley's Mechanical Engineering Design (8th Ed) methods.
%              Includes: gear force calculation, bending/torsion diagrams,
%              von Mises equivalent stress, multiple fatigue criteria.
% =========================================================================

function results = shaft_stress_analysis(shaftNo, config, material, loading, bearings)
% shaft_stress_analysis: Comprehensive shaft design analysis
% 
% Inputs:
%   shaftNo   - shaft number (1/2/3)
%   config    - struct with: length, segments, gears, keys, diameters
%   material  - struct with: S_ut, S_y, S_e_prime, heat_treatment, surface
%   loading   - struct with: power(kW), speed(rpm), gear_forces
%   bearings  - struct with: positions [x1, x2]
%
% Outputs:
%   results   - struct with all calculated stresses, safety factors, 
%               required diameters, bending/torsion diagrams

    fprintf('\n============================================================\n');
    fprintf('  SHAFT %d STRESS ANALYSIS (Shigley Method)\n', shaftNo);
    fprintf('============================================================\n');
    
    %% ========== 1. EXTRACT INPUTS ==========
    L = config.length;              % Total shaft length (mm)
    d = config.diameters;           % Segment diameters (mm)  
    x_pos = config.x_positions;     % Segment positions (mm)
    gears = config.gears;           % Gear positions and properties
    
    % Build segments matrix from x_positions and diameters
    % segments: [x0, length, diameter]
    nSeg = length(d);
    segments = zeros(nSeg, 3);
    for i = 1:nSeg
        segments(i,1) = x_pos(i);               % start x
        segments(i,2) = x_pos(i+1) - x_pos(i);  % length
        segments(i,3) = d(i);                   % diameter
    end
    n = loading.speed;              % Speed (rpm)
    P = loading.power * 1000;       % Power (W)
    bearing_pos = bearings.positions; % Bearing support positions
    
    % Material properties
    S_ut = material.S_ut;           % Ultimate tensile strength (MPa)
    S_y = material.S_y;             % Yield strength (MPa)
    
    fprintf('Material: S_ut = %.0f MPa, S_y = %.0f MPa\n', S_ut, S_y);
    fprintf('Operating: P = %.2f kW, n = %.0f rpm\n', P/1000, n);
    
    %% ========== 2. TORQUE CALCULATION ==========
    T = (P * 60) / (2 * pi * n);    % Torque (N·m)
    fprintf('\n--- Torque: T = %.3f N·m = %.1f N·mm\n', T, T*1000);
    
    %% ========== 3. GEAR FORCES (Shigley Chap 13) ==========
    fprintf('\n--- Gear Forces ---\n');
    
    % For spur gears with pressure angle phi = 20°
    phi = 20 * pi / 180;            % Pressure angle (rad)
    
    gear_forces = [];
    for i = 1:length(gears)
        g = gears(i);
        m = g.module;               % Module (mm)
        z = g.teeth;                % Number of teeth
        d_g = m * z;                % Pitch diameter (mm)
        r_g = d_g / 2000;           % Pitch radius (m)
        
        % Tangential force: W_t = T / r (N)
        W_t = T / r_g;
        % Radial force: W_r = W_t * tan(phi) (N)
        W_r = W_t * tan(phi);
        % Axial force: W_a = 0 (for spur gears)
        W_a = 0;
        
        gear_forces(i).position = g.position;   % x position (mm)
        gear_forces(i).diameter = d_g;          % Pitch diameter (mm)
        gear_forces(i).W_t = W_t;               % Tangential force (N)
        gear_forces(i).W_r = W_r;               % Radial force (N)
        gear_forces(i).W_a = W_a;               % Axial force (N)
        gear_forces(i).label = g.label;
        
        fprintf('  %s (d=%.1fmm): W_t=%.1f N, W_r=%.1f N, W_a=%.1f N\n', ...
                g.label, d_g, W_t, W_r, W_a);
    end
    
    %% ========== 4. BEARING REACTIONS (Static Equilibrium) ==========
    fprintf('\n--- Bearing Reactions ---\n');
    
    % For a 2-bearing shaft with gear loads
    % Resolve forces in vertical (y) and horizontal (z) planes
    % Tangential forces act in one plane, radial in the perpendicular plane
    
    B1 = bearing_pos(1);    % Bearing 1 position
    B2 = bearing_pos(2);    % Bearing 2 position
    span = B2 - B1;
    
    % Sum moments about B1 to find reactions at B2
    % In tangential force plane (y-direction)
    sum_M_y = 0;  % Moments from W_t
    sum_F_y = 0;  % Sum of W_t forces
    
    for i = 1:length(gear_forces)
        x_g = gear_forces(i).position;
        W_t = gear_forces(i).W_t;
        sum_M_y = sum_M_y + W_t * (x_g - B1);
        sum_F_y = sum_F_y + W_t;
    end
    
    R_B2_y = sum_M_y / span;    % Reaction at B2 (tangential direction)
    R_B1_y = sum_F_y - R_B2_y;  % Reaction at B1 (tangential direction)
    
    % In radial force plane (z-direction)
    sum_M_z = 0;
    sum_F_z = 0;
    
    for i = 1:length(gear_forces)
        x_g = gear_forces(i).position;
        W_r = gear_forces(i).W_r;
        sum_M_z = sum_M_z + W_r * (x_g - B1);
        sum_F_z = sum_F_z + W_r;
    end
    
    R_B2_z = sum_M_z / span;
    R_B1_z = sum_F_z - R_B2_z;
    
    fprintf('  Bearing 1: R_y = %.2f N (tangential), R_z = %.2f N (radial)\n', ...
            R_B1_y, R_B1_z);
    fprintf('  Bearing 2: R_y = %.2f N (tangential), R_z = %.2f N (radial)\n', ...
            R_B2_y, R_B2_z);
    
    reactions.B1 = [R_B1_y, R_B1_z];
    reactions.B2 = [R_B2_y, R_B2_z];
    
    %% ========== 5. BENDING MOMENT DIAGRAMS ==========
    fprintf('\n--- Bending Moment Calculation ---\n');
    
    % Fine grid for moment calculation
    x_grid = linspace(0, L, 500);
    M_y = zeros(size(x_grid));   % From tangential forces
    M_z = zeros(size(x_grid));   % From radial forces
    
    for i = 1:length(x_grid)
        x = x_grid(i);
        
        % Shear from left bearing reaction
        if x >= B1
            M_y(i) = R_B1_y * (x - B1);
            M_z(i) = R_B1_z * (x - B1);
        end
        
        % Subtract moments from each gear force
        for j = 1:length(gear_forces)
            x_g = gear_forces(j).position;
            if x >= x_g
                M_y(i) = M_y(i) - gear_forces(j).W_t * (x - x_g);
                M_z(i) = M_z(i) - gear_forces(j).W_r * (x - x_g);
            end
        end
        
        % Subtract right bearing reaction
        if x >= B2
            M_y(i) = M_y(i) - R_B2_y * (x - B2);
            M_z(i) = M_z(i) - R_B2_z * (x - B2);
        end
    end
    
    % Combined bending moment
    M_combined = sqrt(M_y.^2 + M_z.^2);  % N·mm
    
    % Find maximum moment and location
    [M_max, idx_max] = max(abs(M_combined));
    x_Mmax = x_grid(idx_max);
    
    fprintf('  Maximum bending moment: M_max = %.1f N·m at x = %.1f mm\n', ...
            M_max/1000, x_Mmax);
    
    %% ========== 6. ENDURANCE LIMIT CALCULATION (Shigley Eq. 6-18) ==========
    fprintf('\n--- Endurance Limit (Marin Factors) ---\n');
    
    S_e_prime = material.S_e_prime;  % Rotating-beam specimen endurance limit
    
    % Surface factor k_a
    if strcmpi(material.surface, 'ground')
        a_surf = 1.58; b_surf = -0.085;
    elseif strcmpi(material.surface, 'machined')
        a_surf = 4.51; b_surf = -0.265;
    elseif strcmpi(material.surface, 'hot_rolled')
        a_surf = 57.7; b_surf = -0.718;  % MPa units
    elseif strcmpi(material.surface, 'forged')
        a_surf = 272; b_surf = -0.995;   % MPa units
    else  % Default machined
        a_surf = 4.51; b_surf = -0.265;
    end
    
    k_a = a_surf * (S_ut)^b_surf;
    fprintf('  Surface factor k_a = %.3f (%s)\n', k_a, material.surface);
    
    % Size factor k_b (depends on diameter)
    % For round shafts in rotating bending, Eq. 6-20
    d_avg = mean(d);  % Average diameter (mm)
    if d_avg <= 51
        k_b = (d_avg / 7.62)^(-0.107);  % mm
    else
        k_b = 1.51 * (d_avg)^(-0.157);   % mm
    end
    fprintf('  Size factor k_b = %.3f (d_avg = %.2f mm)\n', k_b, d_avg);
    
    % Load factor k_c (for combined loading, start with 1)
    k_c = 1;  % Will be adjusted later
    
    % Temperature factor k_d (assume room temp)
    k_d = 1;
    
    % Reliability factor k_e
    if material.reliability == 0.5
        k_e = 1.0;
    elseif material.reliability == 0.9
        k_e = 0.897;
    elseif material.reliability == 0.95
        k_e = 0.868;
    elseif material.reliability == 0.99
        k_e = 0.814;
    elseif material.reliability == 0.999
        k_e = 0.753;
    else
        k_e = 0.897;  % Default 90%
    end
    fprintf('  Reliability factor k_e = %.3f (R=%.2f%%)\n', k_e, material.reliability*100);
    
    % Miscellaneous factor k_f
    k_f = 1;
    
    % Modified endurance limit
    S_e = k_a * k_b * k_c * k_d * k_e * k_f * S_e_prime;
    fprintf('  Modified endurance limit S_e = %.1f MPa\n', S_e);
    
    %% ========== 7. VON MISES STRESS AT CRITICAL SECTIONS ==========
    fprintf('\n--- Equivalent von Mises Stress ---\n');
    
    % For rotating shaft: bending is fully reversed (M_a = M, M_m = 0)
    % Torsion is typically steady (T_a = 0, T_m = T)
    T_val = T * 1000;  % Convert to N·mm
    
    % Fatigue stress concentration factors (will be refined by stress_concentration.m)
    K_f = loading.K_f;
    K_fs = loading.K_fs;
    
    fprintf('Using K_f = %.2f, K_fs = %.2f\n', K_f, K_fs);
    
    % Calculate at maximum moment section
    % Find which segment contains x_Mmax, return its diameter
    d_at_max = d(1);  % Default
    for j = 1:size(segments, 1)
        if x_Mmax >= segments(j,1) && x_Mmax <= segments(j,1)+segments(j,2)
            d_at_max = segments(j,3);
            break;
        end
    end
    
    % Alternating stress component (from bending only)
    sigma_a_prime = sqrt((32*K_f*M_max/(pi*d_at_max^3))^2 + ...
                          3*(16*K_fs*0/(pi*d_at_max^3))^2);  % T_a = 0
    
    % Mean stress component (from torsion only)          
    sigma_m_prime = sqrt((32*K_f*0/(pi*d_at_max^3))^2 + ...
                          3*(16*K_fs*T_val/(pi*d_at_max^3))^2);  % M_m = 0
    
    fprintf('At critical section (d = %.1f mm):\n', d_at_max);
    fprintf('  Alternating stress sigma_a'' = %.2f MPa\n', sigma_a_prime);
    fprintf('  Mean stress sigma_m'' = %.2f MPa\n', sigma_m_prime);
    
    %% ========== 8. SAFETY FACTOR CHECK ==========
    fprintf('\n--- Safety Factor Analysis ---\n');
    
    % (a) DE-Goodman (Eq. 7-7)
    n_goodman = 1 / (sigma_a_prime/S_e + sigma_m_prime/S_ut);
    fprintf('  DE-Goodman: n = %.3f\n', n_goodman);
    
    % (b) DE-Gerber (Eq. 7-9)
    A_val = sqrt(4*(K_f*M_max)^2 + 3*(K_fs*0)^2);  % T_a = 0
    B_val = sqrt(4*(K_f*0)^2 + 3*(K_fs*T_val)^2);   % M_m = 0
    
    n_gerber = (pi * d_at_max^3 * S_e / (8*A_val)) * ...
               (1 + sqrt(1 + (2*B_val*S_e/(A_val*S_ut))^2))^(-1);
    fprintf('  DE-Gerber:  n = %.3f\n', n_gerber);
    
    % (c) First-cycle yield check (Eq. 7-15)
    sigma_max_prime = sqrt((32*K_f*M_max/(pi*d_at_max^3))^2 + ...
                            3*(16*K_fs*T_val/(pi*d_at_max^3))^2);
    n_yield = S_y / sigma_max_prime;
    fprintf('  First-cycle yield: n_y = %.3f (sigma_max'' = %.2f MPa)\n', n_yield, sigma_max_prime);
    
    %% ========== 9. REQUIRED MINIMUM DIAMETER ==========
    fprintf('\n--- Required Diameter Check ---\n');
    
    n_required = material.n_design;
    
    % Using DE-Goodman for design (conservative)
    A_design = sqrt(4*(K_f*M_max)^2 + 3*(K_fs*0)^2);
    B_design = sqrt(4*(K_f*0)^2 + 3*(K_fs*T_val)^2);
    
    d_required_goodman = ((16*n_required/pi) * ...
                          ((2*A_design/S_e)^(1/2) + (2*B_design/S_ut)^(1/2)))^(1/3);
    
    fprintf('  Current diameter at critical section: d = %.2f mm\n', d_at_max);
    fprintf('  Required diameter (Goodman, n=%.1f): d_min = %.2f mm\n', ...
            n_required, d_required_goodman);
    
    if d_at_max >= d_required_goodman
        fprintf('  >> SHAFT ADEQUATE: d_actual (%.2f) >= d_required (%.2f)\n', ...
                d_at_max, d_required_goodman);
    else
        fprintf('  >> WARNING: d_actual (%.2f) < d_required (%.2f)\n', ...
                d_at_max, d_required_goodman);
    end
    
    %% ========== 10. PLOT BENDING & TORSION DIAGRAMS ==========
    figure('Name', sprintf('Shaft %d - Load Diagrams', shaftNo), ...
           'Position', [100, 100, 1000, 700]);
    
    % (a) Shaft geometry
    subplot(4, 1, 1);
    for i = 1:length(x_pos)-1
        dx = x_pos(i+1) - x_pos(i);
        dy = d(i);
        rectangle('Position', [x_pos(i), -dy/2, dx, dy], ...
                  'FaceColor', [0.85 0.85 0.85], 'EdgeColor', 'k');
    end
    xlim([0 L]);
    title(sprintf('Shaft %d Geometry', shaftNo));
    ylabel('Diameter (mm)');
    axis equal;
    grid on;
    
    % (b) Torque diagram
    subplot(4, 1, 2);
    plot([0, L], [T_val, T_val], 'b-', 'LineWidth', 2);
    hold on;
    plot([0, L], [-T_val, -T_val], 'b-', 'LineWidth', 2);
    fill([0, L, L, 0], [0, 0, T_val, T_val], 'b', 'FaceAlpha', 0.1);
    xlim([0 L]);
    title(sprintf('Torque Diagram (T = %.2f N·mm)', T_val));
    ylabel('Torque (N·mm)');
    grid on;
    
    % (c) Combined bending moment
    subplot(4, 1, 3);
    plot(x_grid, M_combined, 'r-', 'LineWidth', 1.5);
    hold on;
    plot(x_Mmax, M_max, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    text(x_Mmax+5, M_max, sprintf('M_{max}=%.0f N·mm', M_max), ...
         'FontSize', 9, 'Color', 'r');
    xlim([0 L]);
    title('Combined Bending Moment');
    ylabel('Moment (N·mm)');
    grid on;
    
    % (d) Equivalent von Mises stress along shaft
    subplot(4, 1, 4);
    sigma_vM = zeros(size(x_grid));
    for i = 1:length(x_grid)
        % Find diameter at this x position by searching segments
        d_i = d(1);
        for j = 1:size(segments, 1)
            if x_grid(i) >= segments(j,1) && x_grid(i) <= segments(j,1)+segments(j,2)
                d_i = segments(j,3);
                break;
            end
        end
        d_i = max(d_i, 1);  % Prevent division by zero
        M_i = M_combined(i);
        sigma_vM(i) = sqrt((32*K_f*M_i/(pi*d_i^3))^2 + ...
                            3*(16*K_fs*T_val/(pi*d_i^3))^2);
    end
    plot(x_grid, sigma_vM, 'g-', 'LineWidth', 1.5);
    hold on;
    plot([0 L], [S_e, S_e], 'r--', 'LineWidth', 1.5);
    plot([0 L], [S_y, S_y], 'm--', 'LineWidth', 1.5);
    legend('von Mises \sigma''', sprintf('S_e = %.0f MPa', S_e), ...
           sprintf('S_y = %.0f MPa', S_y), 'Location', 'best');
    xlim([0 L]);
    title('Equivalent von Mises Stress');
    ylabel('Stress (MPa)');
    xlabel('Shaft Position x (mm)');
    grid on;
    
    % Use annotation for MATLAB versions before R2018b
    axes('Position', [0 0.97 1 0.03], 'Visible', 'off');
    text(0.5, 0.5, sprintf('Shaft %d Complete Load Analysis', shaftNo), ...
         'FontSize', 13, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'Units', 'normalized');
    
    %% ========== 11. COMPILE RESULTS ==========
    results.shaftNo = shaftNo;
    results.torque_Nm = T;
    results.max_bending_Nmm = M_max;
    results.x_Mmax_mm = x_Mmax;
    results.sigma_a_prime_MPa = sigma_a_prime;
    results.sigma_m_prime_MPa = sigma_m_prime;
    results.sigma_max_prime_MPa = sigma_max_prime;
    results.S_e_MPa = S_e;
    results.n_goodman = n_goodman;
    results.n_gerber = n_gerber;
    results.n_yield = n_yield;
    results.d_actual_mm = d_at_max;
    results.d_required_mm = d_required_goodman;
    results.gear_forces = gear_forces;
    results.reactions = reactions;
    results.x_grid = x_grid;
    results.M_combined = M_combined;
    results.sigma_vM = sigma_vM;
    
    fprintf('\n=== Shaft %d Analysis Complete ===\n', shaftNo);
end

% Call this function from a script or command line:
%   results = shaft_stress_analysis(shaftNo, config, material, loading, bearings);
