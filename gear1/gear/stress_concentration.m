% =========================================================================
% stress_concentration.m
% Description: Stress concentration factors Kt and Kf for shafts:
%              shoulders, keyways, retaining rings, press fits, notch sensitivity.
% =========================================================================

function sc_results = stress_concentration(shaft_diam, shoulder_diam, ...
               fillet_radius, material, feature_type, varargin)
% stress_concentration: Calculate Kt and Kf for shaft features
%
% Inputs:
%   shaft_diam    - Smaller diameter d (mm)
%   shoulder_diam - Larger diameter D at shoulder (mm), [] if not shoulder
%   fillet_radius - Fillet radius r (mm)
%   material      - struct with S_ut (MPa), S_y (MPa)
%   feature_type  - 'shoulder_bending', 'shoulder_torsion', 'keyway', 
%                   'retaining_ring', 'press_fit', 'hole'
%   varargin      - Additional parameters depending on feature type
%
% Outputs:
%   sc_results    - struct with Kt, Kf, q, explanation

    fprintf('\n--- Stress Concentration Analysis (%s) ---\n', feature_type);
    
    S_ut = material.S_ut;   % MPa
    S_y = material.S_y;     % MPa
    d = shaft_diam;
    r = fillet_radius;
    
    sc_results.feature_type = feature_type;
    sc_results.d_mm = d;
    sc_results.r_mm = r;
    
    %% ========== 1. THEORETICAL STRESS CONCENTRATION (Kt) ==========
    
    switch feature_type
        
        %% --- (a) Shoulder / Fillet (Shigley Fig A-15-9, A-15-8) ---
        case {'shoulder_bending', 'shoulder_torsion'}
            D = shoulder_diam;
            D_d = D / d;
            r_d = r / d;
            
            sc_results.D_d = D_d;
            sc_results.r_d = r_d;
            
            % Empirical curve-fit for shoulder in bending (Shigley Fig A-15-9)
            % For round bar with shoulder fillet in bending
            Kt = calculate_shoulder_kt(D_d, r_d, feature_type);
            sc_results.Kt = Kt;
            fprintf('  Shoulder: D/d = %.3f, r/d = %.3f\n', D_d, r_d);
            
        %% --- (b) Keyway (Shigley Table 7-1) ---
        case 'keyway'
            % For sled-runner keyway (standard parallel key)
            % Shigley Table 7-1 provides Kt values
            % For bending: Kt ≈ 2.2 (end-milled), 1.6 (sled-runner)
            % For torsion: Kt ≈ 3.0 (end-milled), 2.0 (sled-runner)
            
            keyway_type = 'sled_runner';  % Default
            if ~isempty(varargin) && ischar(varargin{1})
                keyway_type = varargin{1};
            end
            
            if strcmp(keyway_type, 'end_milled')
                Kt_bending = 2.2;
                Kt_torsion = 3.0;
            else  % sled-runner (profile keyway)
                Kt_bending = 2.0;  % Conservative for profile
                Kt_torsion = 2.0;
            end
            
            sc_results.keyway_type = keyway_type;
            sc_results.Kt_bending = Kt_bending;
            sc_results.Kt_torsion = Kt_torsion;
            sc_results.Kt = Kt_bending;  % Primary value
            
            fprintf('  Keyway (%s): Kt_bending = %.2f, Kt_torsion = %.2f\n', ...
                    keyway_type, Kt_bending, Kt_torsion);
            
        %% --- (c) Retaining Ring / Snap Ring Groove (Shigley Table 7-1) ---
        case 'retaining_ring'
            % From Shigley Table 7-1:
            % Kt varies with groove width/depth
            % Typical values: Kt ≈ 3.0 to 5.0 for bending
            % Use global spec data or conservative estimate
            
            groove_width = d * 0.05;  % Typical ~5% of diameter
            if ~isempty(varargin) && isnumeric(varargin{1})
                groove_width = varargin{1};
            end
            
            % Interpolate based on groove geometry
            % Conservative estimate from Shigley data
            Kt = 3.5;  % Conservative for standard retaining ring
            sc_results.Kt = Kt;
            sc_results.groove_width_mm = groove_width;
            fprintf('  Retaining ring groove: Kt = %.2f (conservative)\n', Kt);
            
        %% --- (d) Press Fit (Shigley Table 7-1) ---
        case 'press_fit'
            % For press-fit hubs on shafts (bending)
            % Shigley provides Kf values directly (not Kt)
            % Kf varies with interference and diameter
            % Typical: Kf ≈ 2.0 to 2.8 for press fits
            
            % Use direct Kf values from Shigley Table 7-1
            Kf_press = 2.2;  % Typical for medium interference
            sc_results.Kt = [];  % Not applicable
            sc_results.Kf = Kf_press;
            sc_results.Kf_source = 'Shigley Table 7-1 direct Kf';
            fprintf('  Press fit: Direct Kf = %.2f (from Shigley Table 7-1)\n', Kf_press);
            return;  % Skip notch sensitivity for press fit
            
        %% --- (e) Transverse Hole ---
        case 'hole'
            % For shaft with transverse hole
            % Shigley Fig A-15-7
            if ~isempty(varargin) && isnumeric(varargin{1})
                hole_diameter = varargin{1};
            else
                hole_diameter = d * 0.1;  % Default 10% of shaft
            end
            
            dD = hole_diameter / d;
            % Curve fit for hole in round bar (bending)
            Kt = 2.0 + 0.5 * (dD - 0.1) / 0.4;
            Kt = min(Kt, 3.0);  % Cap at reasonable max
            
            sc_results.Kt = Kt;
            sc_results.hole_d_mm = hole_diameter;
            fprintf('  Transverse hole: d/D = %.3f, Kt = %.2f\n', dD, Kt);
            
        otherwise
            error('Unknown feature type: %s', feature_type);
    end
    
    %% ========== 2. NOTCH SENSITIVITY (q) ==========
    % Shigley Fig 6-20 (bending) and Fig 6-21 (torsion)
    % Empirical fit for notch sensitivity:
    % q = 1 / (1 + a/sqrt(r)) where a is the Neuber constant
    
    if ~strcmp(feature_type, 'press_fit')  % Skip for press fit
        
        % Neuber constant a (mm) from Shigley Fig 6-36 curve fit
        % a depends on S_ut (MPa)
        S_ut_ksi = S_ut / 6.895;  % Convert to ksi for empirical fit
        
        % Shigley Eq. 6-35 style curve fit for notch sensitivity
        % For steels in bending:
        sqrt_a_bending = 0.062 - 2.5e-5 * S_ut;  % mm^(1/2), empirical fit
        sqrt_a_torsion = 0.076 - 3.2e-5 * S_ut;  % Slightly higher for torsion
        
        % Ensure reasonable bounds
        sqrt_a_bending = max(sqrt_a_bending, 0.01);
        sqrt_a_torsion = max(sqrt_a_torsion, 0.012);
        
        q_bending = 1 / (1 + sqrt_a_bending / sqrt(max(r, 0.1)));
        q_torsion = 1 / (1 + sqrt_a_torsion / sqrt(max(r, 0.1)));
        
        sc_results.q_bending = q_bending;
        sc_results.q_torsion = q_torsion;
        sc_results.sqrt_a_bending = sqrt_a_bending;
        sc_results.sqrt_a_torsion = sqrt_a_torsion;
        
        fprintf('  Notch sensitivity: q_bending = %.3f, q_torsion = %.3f\n', ...
                q_bending, q_torsion);
    end
    
    %% ========== 3. FATIGUE STRESS CONCENTRATION (Kf) ==========
    % Shigley Eq. 6-32: Kf = 1 + q(Kt - 1)
    % For torsion: Kfs = 1 + q_shear(Kts - 1)
    
    if ~strcmp(feature_type, 'press_fit')
        
        if isfield(sc_results, 'Kt')
            Kf_bending = 1 + q_bending * (sc_results.Kt - 1);
            sc_results.Kf_bending = Kf_bending;
            fprintf('  Kf_bending = 1 + %.3f*(%.2f - 1) = %.3f\n', ...
                    q_bending, sc_results.Kt, Kf_bending);
        end
        
        % For torsion component
        if strcmp(feature_type, 'shoulder_torsion')
            Kf_torsion = 1 + q_torsion * (sc_results.Kt - 1);
            sc_results.Kf_torsion = Kf_torsion;
            fprintf('  Kf_torsion = 1 + %.3f*(%.2f - 1) = %.3f\n', ...
                    q_torsion, sc_results.Kt, Kf_torsion);
        elseif strcmp(feature_type, 'keyway')
            Kf_torsion = 1 + q_torsion * (sc_results.Kt_torsion - 1);
            sc_results.Kf_torsion = Kf_torsion;
            fprintf('  Kf_torsion = 1 + %.3f*(%.2f - 1) = %.3f\n', ...
                    q_torsion, sc_results.Kt_torsion, Kf_torsion);
        end
    end
    
    fprintf('  Feature analysis complete.\n');
end


%% ====================================================================
% HELPER FUNCTION: Shoulder Kt calculation (Shigley Fig A-15-9 approximation)
%% ====================================================================
function Kt = calculate_shoulder_kt(D_d, r_d, load_type)
    % Curve-fit approximation of Shigley Fig A-15-9 (shoulder fillet)
    % D_d = D/d ratio, r_d = r/d ratio
    %
    % Reference: Shigley Fig A-15-9 (bending) and Fig A-15-8 (torsion)
    
    D_d = min(max(D_d, 1.02), 2.5);  % Clamp to valid range
    r_d = min(max(r_d, 0.02), 0.3);  % Clamp
    
    if strcmp(load_type, 'shoulder_bending')
        % Shigley Fig A-15-9 for round bar with shoulder fillet, bending
        % Multi-variable curve fit
        Kt = 0.452 + 1.348*D_d^0.5 - 0.3*log10(r_d);
        % Refinement for accuracy
        if D_d > 1.5
            Kt = Kt * (1 + 0.1*(D_d - 1.5));
        end
        % Clamp to reasonable range
        Kt = min(max(Kt, 1.3), 3.0);
        
    elseif strcmp(load_type, 'shoulder_torsion')
        % Shigley Fig A-15-8 for shoulder fillet in torsion
        Kt = 0.6 + 1.0*D_d^0.35 - 0.25*log10(r_d);
        Kt = min(max(Kt, 1.2), 2.5);
        
    else
        Kt = 2.0;  % Conservative default
    end
end


%% ====================================================================
% BATCH ANALYSIS: Check all critical sections of a shaft
%% ====================================================================
function all_sc = analyze_shaft_stress_concentration(shaft_config, material)
% Analyze stress concentration at all critical features of a shaft
%
% Inputs:
%   shaft_config - struct with segments, features, keyways, shoulders
%   material     - struct with S_ut, S_y
%
% Output:
%   all_sc - cell array of SC results for each critical section

    fprintf('\n============================================================\n');
    fprintf('  COMPREHENSIVE SC ANALYSIS FOR SHAFT\n');
    fprintf('============================================================\n');
    
    all_sc = {};
    idx = 1;
    
    % Material properties
    S_ut = material.S_ut;
    S_y = material.S_y;
    mat.S_ut = S_ut;
    mat.S_y = S_y;
    
    % (1) Analyze each shoulder transition
    if isfield(shaft_config, 'shoulders')
        fprintf('\n[1] Shoulder Transitions:\n');
        for i = 1:length(shaft_config.shoulders)
            sh = shaft_config.shoulders(i);
            sc = stress_concentration(sh.d_small, sh.d_large, ...
                       sh.fillet_r, mat, 'shoulder_bending');
            sc.location = sh.position;
            sc.label = sh.label;
            all_sc{idx} = sc; idx = idx + 1;
        end
    end
    
    % (2) Analyze each keyway
    if isfield(shaft_config, 'keyways')
        fprintf('\n[2] Keyways:\n');
        for i = 1:length(shaft_config.keyways)
            kw = shaft_config.keyways(i);
            sc = stress_concentration(kw.diameter, [], kw.fillet_r, ...
                       mat, 'keyway', 'sled_runner');
            sc.location = kw.position;
            sc.label = kw.label;
            all_sc{idx} = sc; idx = idx + 1;
        end
    end
    
    % (3) Analyze retaining ring grooves
    if isfield(shaft_config, 'snap_rings')
        fprintf('\n[3] Retaining Ring Grooves:\n');
        for i = 1:length(shaft_config.snap_rings)
            sr = shaft_config.snap_rings(i);
            sc = stress_concentration(sr.diameter, [], sr.groove_r, ...
                       mat, 'retaining_ring');
            sc.location = sr.position;
            sc.label = sr.label;
            all_sc{idx} = sc; idx = idx + 1;
        end
    end
    
    % (4) Analyze press fits
    if isfield(shaft_config, 'press_fits')
        fprintf('\n[4] Press Fits:\n');
        for i = 1:length(shaft_config.press_fits)
            pf = shaft_config.press_fits(i);
            sc = stress_concentration(pf.diameter, [], [], mat, 'press_fit');
            sc.location = pf.position;
            sc.label = pf.label;
            all_sc{idx} = sc; idx = idx + 1;
        end
    end
    
    % Summary table
    fprintf('\n============================================================\n');
    fprintf('  SUMMARY OF STRESS CONCENTRATION FACTORS\n');
    fprintf('============================================================\n');
    fprintf('%-25s %-10s %-8s %-8s %-8s\n', ...
            'Location', 'Type', 'Kt', 'Kf', 'q');
    fprintf('%s\n', repmat('-', 1, 60));
    
    for i = 1:length(all_sc)
        sc = all_sc{i};
        if isfield(sc, 'Kf')
            Kf_val = sc.Kf;
        elseif isfield(sc, 'Kf_bending')
            Kf_val = sc.Kf_bending;
        else
            Kf_val = NaN;
        end
        
        if isfield(sc, 'q_bending')
            q_val = sc.q_bending;
        else
            q_val = NaN;
        end
        
        fprintf('%-25s %-10s %-8.2f %-8.2f %-8.3f\n', ...
                sc.label, sc.feature_type, sc.Kt, Kf_val, q_val);
    end
    
    fprintf('\n');
end


%% ====================================================================
% EXAMPLE / TEST
%% ====================================================================
% mat_test = struct('S_ut', 600, 'S_y', 355);
% 
% % Shoulder example
% sc1 = stress_concentration(30, 36, 1.5, mat_test, 'shoulder_bending');
% 
% % Keyway example  
% sc2 = stress_concentration(30, [], 0.5, mat_test, 'keyway', 'sled_runner');
% 
% % Press fit example
% sc3 = stress_concentration(30, [], [], mat_test, 'press_fit');
