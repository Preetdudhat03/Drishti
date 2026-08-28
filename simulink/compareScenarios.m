function [baselineRes, optimizedRes, fig] = compareScenarios()
% COMPARESCENARIOS Compares Baseline vs Optimized EyeXpert District Triage
%
% Demonstrates how EyeXpert AI triage eliminates doctor backlog for 100k+ patients/year.
%
% EyeXpert — SIH 2026

    fprintf('\n>>> Running Baseline Scenario (Manual Screening)...\n');
    baselineRes = runDistrictSimulation('BASELINE');

    fprintf('\n>>> Running Optimized EyeXpert Scenario (AI Gated Triage)...\n');
    optimizedRes = runDistrictSimulation('OPTIMIZED');

    % Comparative Visualization Figure
    fig = figure('Name', 'EyeXpert District Simulation: Baseline vs Optimized', ...
        'Color', 'w', 'Position', [100, 100, 1000, 600]);

    % Subplot 1: Queue Length Comparison over Time
    subplot(2, 2, 1);
    plot(baselineRes.TimeVectorHours, baselineRes.DoctorQueueLength, 'r-', 'LineWidth', 1.8);
    hold on;
    plot(optimizedRes.TimeVectorHours, optimizedRes.DoctorQueueLength, 'g-', 'LineWidth', 2.0);
    grid on;
    xlabel('Operating Hours (1 Month = 200 hrs)', 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Ophthalmologist Queue (Cases)', 'FontSize', 10, 'FontWeight', 'bold');
    title('Backlog Queue Accumulation', 'FontSize', 11, 'FontWeight', 'bold');
    legend({'Baseline (Manual 100%)', 'EyeXpert (AI-Triaged 28%)'}, 'Location', 'NorthWest');

    % Subplot 2: Turnaround Waiting Time
    subplot(2, 2, 2);
    plot(baselineRes.TimeVectorHours, baselineRes.WaitingTimeMinutes / 60.0, 'r--', 'LineWidth', 1.5);
    hold on;
    plot(optimizedRes.TimeVectorHours, optimizedRes.WaitingTimeMinutes, 'b-', 'LineWidth', 1.8);
    grid on;
    xlabel('Operating Hours', 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Wait Time (Baseline: Hours / EyeXpert: Mins)', 'FontSize', 10, 'FontWeight', 'bold');
    title('Patient Turnaround Wait Time', 'FontSize', 11, 'FontWeight', 'bold');
    legend({'Baseline (Hours)', 'EyeXpert (Minutes)'}, 'Location', 'NorthWest');

    % Subplot 3: Doctor Utilization Bar Comparison
    subplot(2, 2, 3);
    utilData = [baselineRes.DoctorUtilization * 100, optimizedRes.DoctorUtilization * 100];
    b = bar(utilData, 'FaceColor', 'flat');
    b.CData(1,:) = [0.85 0.2 0.2]; % Red
    b.CData(2,:) = [0.2 0.7 0.3]; % Green
    set(gca, 'XTickLabel', {'Baseline (Manual)', 'EyeXpert (AI Assisted)'}, 'FontWeight', 'bold');
    ylabel('Doctor Utilization (%)', 'FontSize', 10, 'FontWeight', 'bold');
    title('Ophthalmologist Workload Utilization', 'FontSize', 11, 'FontWeight', 'bold');
    ylim([0 120]);
    grid on;
    yline(100, 'k--', 'Capacity Limit (100%)', 'LineWidth', 1.2);

    % Subplot 4: Summary Key Metrics Table Box
    subplot(2, 2, 4);
    axis off;
    summaryText = sprintf([ ...
        '\\bf DISTRICT SCALE COMPARATIVE SUMMARY (120,000 pts/yr)\\rm\n\n' ...
        '\\bf Metric                       Baseline       EyeXpert AI\\rm\n' ...
        '-------------------------------------------------------------\n' ...
        'Cases Sent to Doctor:    100%% (50/hr)   28%% (14/hr)\n' ...
        'Doctor Capacity:         48 cases/hr    48 cases/hr\n' ...
        'Doctor Utilization:      %5.1f%%         %5.1f%%\n' ...
        'Average Queue Length:    %5.1f cases     %5.1f cases\n' ...
        'Average Wait Time:       %5.1f hours     %5.1f mins\n' ...
        'System Stability:        OVERLOADED     BALANCED\n\n' ...
        '\\it Note: EyeXpert safely routes non-referable normal cases\n' ...
        'for routine tracking, freeing doctors for referable DR.\\rm' ...
    ], baselineRes.DoctorUtilization * 100, optimizedRes.DoctorUtilization * 100, ...
       baselineRes.AvgQueueLength, optimizedRes.AvgQueueLength, ...
       baselineRes.AvgWaitTimeHours, mean(optimizedRes.WaitingTimeMinutes));

    text(0.05, 0.5, summaryText, 'FontSize', 10, 'FontName', 'FixedWidth', 'VerticalAlignment', 'middle');

    sgtitle('EyeXpert Telemedicine District-Scale Workflow Simulation', 'FontSize', 14, 'FontWeight', 'bold');
end
