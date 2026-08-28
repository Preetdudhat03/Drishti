function simResults = runDistrictSimulation(scenarioType, customParams)
% RUNDISTRICTSIMULATION District-scale telemedicine queuing simulation
%
% Simulates 100,000+ patients/year retinal screening workflow:
%   Patient Arrival -> Capture -> Network Upload -> AI Triage -> Review Queue -> Doctor Validation
%
% Syntax:
%   simResults = runDistrictSimulation('BASELINE')
%   simResults = runDistrictSimulation('OPTIMIZED')
%   simResults = runDistrictSimulation('OPTIMIZED', customParamsStruct)
%
% EyeXpert — SIH 2026

    arguments
        scenarioType (1,1) string = "OPTIMIZED"
        customParams struct = struct()
    end

    % Default Simulation Configuration (Annual Scale: 120,000 patients)
    params = struct();
    params.AnnualPatients = 120000;
    params.WorkingDaysPerYear = 300;
    params.WorkingHoursPerDay = 8;
    params.AvgImageSizeMB = 2.5;
    params.NetworkBandwidthMbps = 8.0; % Rural 4G/Broadband uplink
    params.AIProcessingTimeSec = 1.2;  % AI quality + inference time per image
    params.NumAIServers = 2;
    params.DoctorReviewTimeMin = 2.5;  % Clinician review time per referable case
    params.NumDoctors = 2;             % District-level ophthalmologists

    % Scenario specific adjustments
    if upper(scenarioType) == "BASELINE"
        params.ScenarioName = "Baseline (100% Manual Doctor Review - No AI Triage)";
        params.PctRequiringDoctorReview = 1.00; % Every single image must be manually graded
        params.AIAssistedTriage = false;
    else
        params.ScenarioName = "Optimized (EyeXpert AI Triage + Gated Telemedicine)";
        % In EyeXpert: Level 0 non-referable images (~72%) get automated routine reports
        % Only Referable DR (Levels 2-4) and Borderline/Uncertain cases (~28%) require ophthalmologist review
        params.PctRequiringDoctorReview = 0.28;
        params.AIAssistedTriage = true;
    end

    % Override with any user custom params
    fn = fieldnames(customParams);
    for k = 1:numel(fn)
        params.(fn{k}) = customParams.(fn{k});
    end

    % Calculations
    totalWorkingHours = params.WorkingDaysPerYear * params.WorkingHoursPerDay;
    arrivalRatePerHour = params.AnnualPatients / totalWorkingHours;
    arrivalRatePerSec = arrivalRatePerHour / 3600;

    % Network transmission latency (in seconds)
    networkLatencySec = (params.AvgImageSizeMB * 8) / params.NetworkBandwidthMbps;

    % AI Service Capacity
    aiCapacityPerSec = params.NumAIServers / params.AIProcessingTimeSec;
    aiUtilization = min(1.0, arrivalRatePerSec / aiCapacityPerSec);

    % Doctor Service Capacity
    doctorReviewRatePerHour = 60.0 / params.DoctorReviewTimeMin; % cases per hour per doctor
    totalDoctorCapacityPerHour = params.NumDoctors * doctorReviewRatePerHour;
    doctorArrivalRatePerHour = arrivalRatePerHour * params.PctRequiringDoctorReview;
    doctorUtilization = min(1.0, doctorArrivalRatePerHour / max(eps, totalDoctorCapacityPerHour));

    % Discrete-Event Queuing Simulation over 1 representative month (25 working days = 200 hours)
    simHours = 200;
    dtMin = 1.0; % 1-minute time steps
    numSteps = round((simHours * 60) / dtMin);
    
    timeVectorHours = linspace(0, simHours, numSteps);
    doctorQueueLength = zeros(numSteps, 1);
    waitingTimeMinutes = zeros(numSteps, 1);
    processedPatients = 0;

    currentQueue = 0;
    lambdaPerMin = arrivalRatePerHour * params.PctRequiringDoctorReview / 60.0;
    muPerMin = totalDoctorCapacityPerHour / 60.0;

    rng(42); % Deterministic simulation run
    for t = 1:numSteps
        % Poisson patient arrivals to doctor queue
        newArrivals = poissrnd(lambdaPerMin);
        currentQueue = currentQueue + newArrivals;

        % Cases processed by doctors
        capacityThisStep = muPerMin * (1.0 + 0.1 * (rand() - 0.5)); % slight variation
        processedThisStep = min(currentQueue, capacityThisStep);
        currentQueue = max(0, currentQueue - processedThisStep);

        doctorQueueLength(t) = currentQueue;
        % Little's Law / estimated wait time in hours -> converted to minutes/hours
        if totalDoctorCapacityPerHour > 0
            waitingTimeMinutes(t) = (currentQueue / (totalDoctorCapacityPerHour / 60.0));
        end
        processedPatients = processedPatients + processedThisStep;
    end

    simResults = struct();
    simResults.ScenarioName = params.ScenarioName;
    simResults.Params = params;
    simResults.ArrivalRatePerHour = arrivalRatePerHour;
    simResults.NetworkLatencySec = networkLatencySec;
    simResults.AIUtilization = aiUtilization;
    simResults.DoctorUtilization = doctorUtilization;
    simResults.AvgQueueLength = mean(doctorQueueLength);
    simResults.MaxQueueLength = max(doctorQueueLength);
    simResults.AvgWaitTimeHours = mean(waitingTimeMinutes) / 60.0;
    simResults.MaxWaitTimeHours = max(waitingTimeMinutes) / 60.0;
    simResults.TimeVectorHours = timeVectorHours;
    simResults.DoctorQueueLength = doctorQueueLength;
    simResults.WaitingTimeMinutes = waitingTimeMinutes;
    simResults.IsBottlenecked = (doctorArrivalRatePerHour > totalDoctorCapacityPerHour);

    fprintf('=====================================================\n');
    fprintf('  SIMULATION SCENARIO: %s\n', params.ScenarioName);
    fprintf('=====================================================\n');
    fprintf('Annual Patient Volume:      %d patients/year\n', params.AnnualPatients);
    fprintf('Arrival Rate:               %.1f patients/hour\n', arrivalRatePerHour);
    fprintf('Network Upload Delay:       %.2f seconds/image\n', networkLatencySec);
    fprintf('AI Server Utilization:      %5.1f%%\n', aiUtilization * 100);
    fprintf('Doctor Review Demand:       %.1f cases/hour (%d%% volume)\n', doctorArrivalRatePerHour, round(params.PctRequiringDoctorReview * 100));
    fprintf('Total Doctor Capacity:      %.1f cases/hour (%d ophthalmologists)\n', totalDoctorCapacityPerHour, params.NumDoctors);
    fprintf('Doctor Utilization:         %5.1f%%\n', doctorUtilization * 100);
    fprintf('Average Review Queue:       %.1f cases\n', simResults.AvgQueueLength);
    fprintf('Average Wait Time:          %.2f hours (%.1f mins)\n', simResults.AvgWaitTimeHours, mean(waitingTimeMinutes));
    fprintf('Maximum Wait Time:          %.2f hours\n', simResults.MaxWaitTimeHours);
    fprintf('System Bottleneck Status:   %s\n', ternary(simResults.IsBottlenecked, "OVERLOADED / ACCUMULATING BACKLOG", "STABLE & BALANCED"));
    fprintf('=====================================================\n');
end

function val = ternary(cond, a, b)
    if cond
        val = a;
    else
        val = b;
    end
end
