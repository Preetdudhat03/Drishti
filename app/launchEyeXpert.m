function appInstance = launchEyeXpert()
% LAUNCHEYEXPERT Starts the EyeXpert GUI Application
%
% EyeXpert — SIH 2026

    % Add project paths
    rootPath = fullfile(fileparts(mfilename('fullpath')), '..');
    addpath(genpath(rootPath));

    % Generate sample benchmark data if not yet present
    sampleDir = fullfile(rootPath, 'data', 'sample_demo');
    if ~isfolder(sampleDir)
        fprintf('Generating benchmark fundus samples in data/sample_demo ...\n');
        generateSampleFundusData(sampleDir);
    end

    % Launch App Designer application
    fprintf('Launching EyeXpert GUI Application...\n');
    appInstance = EyeXpertApp();
end
