% =========================================================================
% bearing_selection.m
% Description: Bearing selection based on L10 rated life:
%              catalog deep-groove ball bearings, equivalent load,
%              design life verification, reliability check.
% =========================================================================

function bearing_results = bearing_selection(shaft_no, position, radial_load, ...
               axial_load, shaft_speed, shaft_diameter, design_life_hours, ...
               required_reliability, application_factor)
% bearing_selection: Select a deep-groove ball bearing from standard catalog
%
% Inputs:
%   shaft_no          - Shaft number (1/2/3) for labeling
%   position          - 'left' or 'right' bearing label
%   radial_load       - Radial load Fr (N) - from shaft stress analysis
%   axial_load        - Axial load Fa (N) - from gear forces
%   shaft_speed       - Shaft speed (rpm)
%   shaft_diameter    - Required bore diameter (mm)
%   design_life_hours - Required design life (hours)
%   required_reliability - Target reliability (0-1)
%   application_factor - a_f (1.0-3.0 depending on application)
%
% Output:
%   bearing_results   - Selected bearing with full verification

    if nargin < 10 || isempty(application_factor)
        application_factor = 1.2;  % Gearbox moderate shock
    end
    if nargin < 9 || isempty(required_reliability)
        required_reliability = 0.99;
    end
    if nargin < 8 || isempty(design_life_hours)
        design_life_hours = 10000;  % 10 kh typical for industrial
    end
    
    fprintf('\n============================================================\n');
    fprintf('  BEARING SELECTION - Shaft %d (%s)\n', shaft_no, position);
    fprintf('============================================================\n');
    
    Fr = abs(radial_load);  % N
    Fa = abs(axial_load);   % N
    n = shaft_speed;        % rpm
    d_bore = shaft_diameter;% mm
    L_D = design_life_hours;% hours
    a_f = application_factor;
    R_target = required_reliability;
    
    fprintf('Radial load:  Fr = %.1f N\n', Fr);
    fprintf('Axial load:   Fa = %.1f N\n', Fa);
    fprintf('Shaft speed:  n  = %.0f rpm\n', n);
    fprintf('Bore needed:  d  = %.0f mm\n', d_bore);
    fprintf('Design life:  L  = %.0f hours\n', L_D);
    fprintf('Reliability:  R  = %.2f%%\n', R_target * 100);
    fprintf('Application factor: a_f = %.2f\n', a_f);
    
    %% ========== 1. EQUIVALENT RADIAL LOAD (Shigley Sec 11-6) ==========
    fprintf('\n--- Equivalent Radial Load ---\n');
    
    % For deep-groove ball bearings: Fe = X*V*Fr + Y*Fa
    % V = 1 (inner ring rotates - typical for shaft-mounted bearings)
    V = 1;
    
    % X and Y depend on Fa/C0 ratio (C0 = basic static load rating)
    % Initial guess: assume Fa is small, X=1, Y=0
    % Will iterate after selecting bearing
    
    if Fa / Fr <= 0.35
        X = 1.0; Y = 0.0;
        Fe = X * V * Fr + Y * Fa;
        fprintf('Fa/Fr = %.3f <= 0.35: X=%.2f, Y=%.2f\n', Fa/Fr, X, Y);
    else
        % Need to determine from catalog after selection
        X = 0.56; Y = 1.8;  % Initial estimate for moderate Fa/Fr
        Fe = X * V * Fr + Y * Fa;
        fprintf('Fa/Fr = %.3f > 0.35: Initial X=%.2f, Y=%.2f\n', Fa/Fr, X, Y);
    end
    
    fprintf('Equivalent radial load: Fe = %.1f N\n', Fe);
    
    bearing_results.F_equivalent_N = Fe;
    bearing_results.X = X;
    bearing_results.Y = Y;
    
    %% ========== 2. DESIGN LIFE (Shigley Eq. 11-3, 11-7) ==========
    fprintf('\n--- Design Life Calculation ---\n');
    
    % Rating life multiplier x_D = L_D / L_R
    % L_R = 10^6 revolutions (standard catalog rating)
    L_R = 1e6;  % rev
    L_D_rev = 60 * L_D * n;  % Design life in revolutions
    x_D = L_D_rev / L_R;
    
    fprintf('Design life in rev: L_D = 60 * %.0f * %.0f = %.2e rev\n', L_D, n, L_D_rev);
    fprintf('Life ratio: x_D = L_D/L_R = %.2f\n', x_D);
    
    bearing_results.L_design_rev = L_D_rev;
    bearing_results.x_D = x_D;
    
    %% ========== 3. REQUIRED CATALOG RATING (Shigley Eq. 11-9) ==========
    fprintf('\n--- Required Basic Dynamic Load Rating ---\n');
    
    % For ball bearings: a = 3 (exponent in load-life relation)
    a = 3;
    
    % Required C10 rating
    % Include reliability factor based on Weibull parameters
    x0 = 0.02;
    theta = 4.439;
    beta = 1.483;
    x_R = ((x_D - x0)/(theta - x0))^beta / (-log(R_target));
    C10_required = a_f * Fe * x_R^(1/a);  % N
    
    fprintf('For ball bearing (a=3):\n');
    fprintf('C10_required = a_f * Fe * x_R^(1/a)\n');
    fprintf('             = %.1f N = %.2f kN\n', C10_required, C10_required/1000);
    
    bearing_results.C10_required_N = C10_required;
    bearing_results.C10_required_kN = C10_required / 1000;
    
    %% ========== 4. SELECT FROM CATALOG ==========
    fprintf('\n--- Catalog Selection ---\n');
    
    % Load standard deep-groove ball bearing catalog (02-series)
    catalog = load_bearing_catalog();
    
    % Filter by minimum bore diameter
    candidates = catalog;
    nCat = size(catalog, 1);
    nCand = 0;
    for i = 1:nCat
        if catalog{i, 2} >= d_bore * 0.95
            nCand = nCand + 1;
            candidates{nCand, 1} = catalog{i, 1};  % model
            candidates{nCand, 2} = catalog{i, 2};  % bore
            candidates{nCand, 3} = catalog{i, 3};  % OD
            candidates{nCand, 4} = catalog{i, 4};  % width
            candidates{nCand, 5} = catalog{i, 5};  % C10_kN
            candidates{nCand, 6} = catalog{i, 6};  % C0_kN
        end
    end
    
    % Find smallest bearing that meets C10 requirement
    selected = [];
    for i = 1:nCand
        if candidates{i, 5} * 1000 >= C10_required
            selected.model = candidates{i, 1};
            selected.bore = candidates{i, 2};
            selected.OD = candidates{i, 3};
            selected.width = candidates{i, 4};
            selected.C10_kN = candidates{i, 5};
            selected.C0_kN = candidates{i, 6};
            break;
        end
    end
    
    if isempty(selected)
        fprintf('WARNING: No bearing in catalog meets requirement!\n');
        maxC10 = 0;
        for i = 1:nCand, maxC10 = max(maxC10, candidates{i, 5}); end
        fprintf('Minimum available C10 = %.1f kN\n', maxC10);
        bearing_results.selected = [];
        bearing_results.is_adequate = false;
    else
        bearing_results.selected = selected;
        fprintf('Selected: %s\n', selected.model);
        fprintf('  Bore:    %.0f mm\n', selected.bore);
        fprintf('  OD:      %.0f mm\n', selected.OD);
        fprintf('  Width:   %.0f mm\n', selected.width);
        fprintf('  C10:     %.2f kN\n', selected.C10_kN);
        fprintf('  C0:      %.2f kN\n', selected.C0_kN);
    end
    
    %% ========== 5. VERIFY L10 LIFE WITH SELECTED BEARING ==========
    if ~isempty(selected)
        fprintf('\n--- L10 Life Verification ---\n');
        
        C10 = selected.C10_kN * 1000;  % N
        
        % L10 life at catalog rating: L10 = (C10/Fe)^a * L_R
        L10_rev = (C10 / Fe)^a * L_R;
        L10_hours = L10_rev / (60 * n);
        
        fprintf('L10 = (%.0f / %.1f)^3 * 10^6 = %.2e rev\n', C10, Fe, L10_rev);
        fprintf('L10 = %.0f hours\n', L10_hours);
        fprintf('Design life: %.0f hours\n', L_D);
        fprintf('Life ratio: L10/L_design = %.2f\n', L10_hours / L_D);
        
        bearing_results.L10_rev = L10_rev;
        bearing_results.L10_hours = L10_hours;
        bearing_results.life_ratio = L10_hours / L_D;
        
        %% ========== 6. RELIABILITY VERIFICATION ==========
        fprintf('\n--- Reliability Check ---\n');
        
        % Shigley Eq. 11-21 for reliability
        % R_D = 1 - 4.48 * f_T * f_v * (C10/(a_f*Fe))^10/3 * x_D^(3/2)
        % Simplified: using Weibull parameters
        
        x0 = 0.02;       % Minimum life parameter
        theta = 4.439;   % Characteristic parameter
        beta = 1.483;    % Shape parameter (Weibull)
        
        % Reliability at design life
        R_actual = exp(-((x_D - x0)/(theta - x0))^beta * ...
                      (a_f * Fe / C10)^a);
        
        fprintf('Actual reliability at design life: R = %.4f (%.2f%%)\n', ...
                R_actual, R_actual * 100);
        fprintf('Target reliability: R = %.4f (%.2f%%)\n', ...
                R_target, R_target * 100);
        
        bearing_results.R_actual = R_actual;
        bearing_results.R_target = R_target;
        bearing_results.is_adequate = (R_actual >= R_target);
        
        if bearing_results.is_adequate
            fprintf('>> BEARING ADEQUATE\n');
        else
            fprintf('>> BEARING MARGINAL - Consider next size\n');
        end
    end
    
    fprintf('============================================================\n');
end


%% ====================================================================
% LOAD STANDARD BEARING CATALOG (Deep Groove Ball Bearings, 02-series)
%% ====================================================================
function catalog = load_bearing_catalog()
% Return table of standard deep-groove ball bearings (metric, SKF 62-series style)
% Format: model, bore(mm), OD(mm), width(mm), C10(kN), C0(kN)

    data = {
        % Model,    Bore,  OD,   Width, C10,   C0
        '6200',     10,    30,   9,     5.07,  2.32;
        '6201',     12,    32,   10,    6.89,  3.10;
        '6202',     15,    35,   11,    7.80,  3.75;
        '6203',     17,    40,   12,    9.56,  4.75;
        '6204',     20,    47,   14,    12.80, 6.60;
        '6205',     25,    52,   15,    14.00, 7.85;
        '6206',     30,    62,   16,    19.50, 11.30;
        '6207',     35,    72,   17,    25.50, 15.30;
        '6208',     40,    80,   18,    30.70, 19.00;
        '6209',     45,    85,   19,    33.20, 21.60;
        '6210',     50,    90,   20,    35.10, 23.20;
        '6211',     55,    100,  21,    43.60, 29.00;
        '6212',     60,    110,  22,    52.00, 36.00;
        '6213',     65,    120,  23,    57.20, 40.00;
        '6214',     70,    125,  24,    62.00, 44.00;
        '6215',     75,    130,  25,    66.30, 49.00;
        '6216',     80,    140,  26,    72.80, 55.00;
        '6217',     85,    150,  28,    83.20, 64.00;
        '6218',     90,    160,  30,    96.10, 72.00;
        '6219',     95,    170,  32,    108.00, 81.50;
        '6220',     100,   180,  34,    124.00, 93.00;
    };

    % Return as cell array: {model, bore, OD, width, C10_kN, C0_kN}
    catalog = data;
end


%% ====================================================================
% BATCH: Select bearings for all shafts
%% ====================================================================
function all_bearings = select_all_bearings(shaft_list, design_life, R_target, a_f)
% Select bearings for all shafts in the gearbox
%
% Input: shaft_list - array of structs with loads, speeds, diameters

    fprintf('\n############################################################\n');
    fprintf('#         BEARING SELECTION FOR ALL SHAFTS                 #\n');
    fprintf('############################################################\n');
    
    all_bearings = {};
    
    for i = 1:length(shaft_list)
        s = shaft_list(i);
        
        % Left bearing
        fprintf('\n>>> SHAFT %d - Left Bearing <<<\n', s.shaft_no);
        brg_L = bearing_selection(s.shaft_no, 'left', s.Fr_left, s.Fa_left, ...
                    s.speed, s.diameter, design_life, R_target, a_f);
        all_bearings{end+1} = brg_L;
        
        % Right bearing
        fprintf('\n>>> SHAFT %d - Right Bearing <<<\n', s.shaft_no);
        brg_R = bearing_selection(s.shaft_no, 'right', s.Fr_right, s.Fa_right, ...
                    s.speed, s.diameter, design_life, R_target, a_f);
        all_bearings{end+1} = brg_R;
    end
    
    % Summary table
    fprintf('\n============================================================\n');
    fprintf('  BEARING SELECTION SUMMARY\n');
    fprintf('============================================================\n');
    fprintf('%-8s %-8s %-10s %-8s %-10s %-10s %-10s\n', ...
            'Shaft', 'Pos', 'Model', 'Bore', 'C10(kN)', 'L10(h)', 'Status');
    fprintf('%s\n', repmat('-', 1, 65));
    
    for i = 1:length(all_bearings)
        b = all_bearings{i};
        if ~isempty(b.selected)
            status = conditional(b.is_adequate, 'PASS', 'MARGINAL');
            fprintf('%-8d %-8s %-10s %-8.0f %-10.2f %-10.0f %-10s\n', ...
                    b.selected.bore, b.position, b.selected.model, ...
                    b.selected.bore, b.selected.C10_kN, b.L10_hours, status);
        end
    end
end

function out = conditional(cond, a, b)
    if cond, out = a; else, out = b; end
end


%% ====================================================================
% EXAMPLE / TEST
%% ====================================================================
% result = bearing_selection(1, 'left', 800, 200, 1440, 15, 10000, 0.99, 1.2);
