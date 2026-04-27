# ME3227 Team Project - Inline Speed Reducer

## Project Files

| File | Purpose |
|:---|:---|
| `reducer_design.m` | **Master script** - runs all analysis modules sequentially, outputs complete summary report |
| `InlineSpeedReducer_3Shafts_Profile.m` | **Visualization** - 4-subplot 2D profile (3 detailed shaft sections + 1 assembly overview) |
| `gear_design.m` | AGMA gear design: bending & contact stress, all AGMA factors, safety factors |
| `shaft_stress_analysis.m` | Shaft stress: gear forces, reactions, bending/torsion diagrams, DE-Goodman/Gerber, safety factors |
| `stress_concentration.m` | Stress concentration: Kt/Kf for shoulders, keyways, retaining rings, press fits |
| `key_design.m` | Key design: standard key selection, shear & bearing stress check |
| `bearing_selection.m` | Bearing selection: L10 life, catalog lookup (6200-6220 series) |
| `GearReducer_DesignData.m` | Parameter database: all geometric data for gears, shafts, bearings, keys |

## Running the Project

### Option 1: Full Design Analysis
```matlab
reducer_design
```
Runs the complete analysis chain:
1. Gear design (AGMA bending + contact stress)
2. Shaft stress analysis (3 shafts, DE theory)
3. Stress concentration at all critical features
4. Key strength verification
5. Bearing L10 life selection
6. Summary report with pass/fail verdict

### Option 2: Visualization Only
```matlab
InlineSpeedReducer_3Shafts_Profile
```
Generates the 2D assembly drawing with:
- 3 detailed shaft profiles (segments, bearings, gears, keyways, snap rings, press fits)
- Assembly overview (meshing layout, center distances, speed labels)

### Saving the Figure
```matlab
% Get the figure handle first
fig = gcf;   % Or use the handle returned by the script
print(fig, 'MyGearbox', '-dpng', '-r300');
```

## Key Design Parameters (Editable in reducer_design.m)

| Parameter | Stage 1 | Stage 2 |
|:---|:---|:---|
| Module m (mm) | 2.0 | 2.5 |
| Pinion teeth z1/z3 | 20 | 16 |
| Gear teeth z2/z4 | 60 | 48 |
| Face width (mm) | 20 / 25 | 25 / 30 |
| Ratio | 3.0 | 3.0 |

| Shaft | Length (mm) | Material | Max Dia (mm) |
|:---|:---|:---|:---|
| Shaft 1 (Input) | 170 | 45 steel | 18 |
| Shaft 2 (Intermediate) | 200 | 45 steel | 28 |
| Shaft 3 (Output) | 180 | 40Cr | 32 |

## Adjusting Gear Parameters

Open `reducer_design.m` and modify:
```matlab
p1 = struct('teeth', 20, 'module', 2.0, 'face_width', 20, ...);
g2 = struct('teeth', 60, 'module', 2.0, 'face_width', 25, ...);
```
Then re-run `reducer_design`.

## Requirements
- MATLAB R2014b or newer
- No additional toolboxes required
