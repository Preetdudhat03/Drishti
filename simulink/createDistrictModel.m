function modelName = createDistrictModel(modelName)
% CREATEDISTRICTMODEL Programmatically creates Simulink district screening model
%
% Architecture:
%   Patient Generator -> Image Capture -> Network Delay -> AI Processing Engine -> Queue -> Doctor Review -> Validation Sink
%
% EyeXpert — SIH 2026

    arguments
        modelName (1,1) string = "EyeXpert_DistrictSimulation"
    end

    fprintf('Configuring Simulink district simulation model: %s ...\n', modelName);

    try
        % Check if model is already open
        if bdIsLoaded(char(modelName))
            close_system(char(modelName), 0);
        end

        % Create new Simulink system
        new_system(char(modelName));
        open_system(char(modelName));

        % Add Standard Blocks (Inflow, Latency, Processing, Queue, Review)
        add_block('simulink/Sources/Constant', [char(modelName) '/Patient_Inflow_Rate'], ...
            'Value', '50', 'Position', [50, 100, 120, 140]);

        add_block('simulink/Continuous/Transport Delay', [char(modelName) '/Network_Transmission_Delay'], ...
            'DelayTime', '2.5', 'Position', [180, 100, 240, 140]);

        add_block('simulink/Continuous/Transfer Fcn', [char(modelName) '/AI_Quality_and_Inference_Engine'], ...
            'Numerator', '[1]', 'Denominator', '[1.2 1]', 'Position', [300, 100, 400, 140]);

        add_block('simulink/Math Operations/Gain', [char(modelName) '/Referable_Triage_Filter'], ...
            'Gain', '0.28', 'Position', [450, 100, 500, 140]);

        add_block('simulink/Continuous/Integrator', [char(modelName) '/Doctor_Review_Queue_Accumulator'], ...
            'Position', [560, 100, 610, 140]);

        add_block('simulink/Sinks/Scope', [char(modelName) '/District_Telemedicine_Dashboard'], ...
            'Position', [670, 95, 730, 145]);

        % Connect lines
        add_line(char(modelName), 'Patient_Inflow_Rate/1', 'Network_Transmission_Delay/1');
        add_line(char(modelName), 'Network_Transmission_Delay/1', 'AI_Quality_and_Inference_Engine/1');
        add_line(char(modelName), 'AI_Quality_and_Inference_Engine/1', 'Referable_Triage_Filter/1');
        add_line(char(modelName), 'Referable_Triage_Filter/1', 'Doctor_Review_Queue_Accumulator/1');
        add_line(char(modelName), 'Doctor_Review_Queue_Accumulator/1', 'District_Telemedicine_Dashboard/1');

        % Save system
        save_system(char(modelName), fullfile(fileparts(mfilename('fullpath')), char(modelName) + ".slx"));
        fprintf('Simulink model successfully built and saved to %s.slx\n', modelName);

    catch ME
        fprintf('Simulink programmatic builder note: %s\n', ME.message);
        fprintf('Standalone queuing simulation engine is active via runDistrictSimulation.m\n');
    end
end
