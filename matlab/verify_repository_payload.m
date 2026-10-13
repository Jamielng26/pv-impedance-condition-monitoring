function verify_repository_payload()
%VERIFY_REPOSITORY_PAYLOAD Basic preflight for the public project repository.
%
% Run from anywhere:
%   verify_repository_payload
%
% This checks that the curated raw-data archive, current master log,
% environmental tracker, validated crosswalk and key final scripts exist.

thisFile = mfilename('fullpath');
scriptDir = fileparts(thisFile);
repoRoot = fileparts(scriptDir);

required = { ...
    fullfile(repoRoot,'data','raw','Raw_Data_2026_Clean.zip'), ...
    fullfile(repoRoot,'data','metadata','PV_Lab_Master_Log.xlsx'), ...
    fullfile(repoRoot,'data','metadata','PV_Environmental_Rig_Characterisation_Tracker.xlsx'), ...
    fullfile(repoRoot,'data','metadata','PV_Validated_FRA_Crosswalk_20260917.xlsx'), ...
    fullfile(repoRoot,'matlab','figure_generation','generate_chapter4_shading_figures.m'), ...
    fullfile(repoRoot,'matlab','figure_generation','generate_Fig4_18_hotspot_exploratory.m'), ...
    fullfile(repoRoot,'matlab','figure_generation','Figure_4_12_Rp_vs_Rdiff_FIXED_v2.m') ...
    };

missing = {};
for k = 1:numel(required)
    if ~isfile(required{k})
        missing{end+1} = required{k}; %#ok<AGROW>
    end
end

fprintf('PV impedance repository preflight\n');
fprintf('Repository root: %s\n\n',repoRoot);

if ~isempty(missing)
    fprintf(2,'Missing %d required file(s):\n',numel(missing));
    for k = 1:numel(missing)
        fprintf(2,'  %s\n',missing{k});
    end
    error('Repository payload is incomplete.');
end

masterLog = fullfile(repoRoot,'data','metadata','PV_Lab_Master_Log.xlsx');
try
    sheets = sheetnames(masterLog);
    if ~any(strcmpi(sheets,'Run Log'))
        error('The master log does not contain a "Run Log" sheet.');
    end
catch ME
    error('Master-log validation failed: %s',ME.message);
end

fprintf('All required files found.\n');
fprintf('Master log contains the expected "Run Log" sheet.\n');
fprintf('Payload preflight PASSED.\n');
end
