function fig = plotROC(rocStruct, aucVal, titleStr)
% PLOTROC Plots Receiver Operating Characteristic (ROC) curve with AUC
%
% EyeXpert — SIH 2026

    arguments
        rocStruct (1,1) struct
        aucVal (1,1) double
        titleStr (1,1) string = "EyeXpert Referable DR ROC Curve"
    end

    fig = figure('Name', char(titleStr), 'Color', 'w', 'Position', [150, 150, 600, 500]);
    plot(rocStruct.FPR, rocStruct.TPR, 'b-', 'LineWidth', 2.5);
    hold on;
    plot([0, 1], [0, 1], 'k--', 'LineWidth', 1.2); % Chance diagonal line
    grid on;

    xlabel('False Positive Rate (1 - Specificity)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('True Positive Rate (Sensitivity)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('%s (AUC = %.3f)', titleStr, aucVal), 'FontSize', 14, 'FontWeight', 'bold');
    xlim([0 1]);
    ylim([0 1.02]);
    legend({sprintf('EyeXpert Model (AUC = %.3f)', aucVal), 'Random Chance'}, 'Location', 'SouthEast', 'FontSize', 11);
    set(gca, 'FontSize', 11);
end
