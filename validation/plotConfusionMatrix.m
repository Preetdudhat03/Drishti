function fig = plotConfusionMatrix(cm, classNames, titleStr)
% PLOTCONFUSIONMATRIX Plots high-resolution confusion matrix for DR evaluation
%
% EyeXpert — SIH 2026

    arguments
        cm (:,:) double
        classNames string = ["Level 0", "Level 1", "Level 2", "Level 3", "Level 4"]
        titleStr (1,1) string = "EyeXpert 5-Class DR Confusion Matrix"
    end

    fig = figure('Name', char(titleStr), 'Color', 'w', 'Position', [100, 100, 600, 500]);
    imagesc(cm);
    colormap(flipud(bone));
    colorbar;

    numClasses = size(cm, 1);
    set(gca, 'XTick', 1:numClasses, 'XTickLabel', classNames, ...
             'YTick', 1:numClasses, 'YTickLabel', classNames, ...
             'FontSize', 11, 'FontWeight', 'bold');
    
    xlabel('Predicted DR Level', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Ground Truth DR Level', 'FontSize', 12, 'FontWeight', 'bold');
    title(titleStr, 'FontSize', 14, 'FontWeight', 'bold');

    % Text overlay counts inside cells
    maxVal = max(cm(:));
    for i = 1:numClasses
        for j = 1:numClasses
            val = cm(i, j);
            if val > (maxVal / 2)
                textColor = 'w';
            else
                textColor = 'k';
            end
            text(j, i, num2str(val), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 12, ...
                'FontWeight', 'bold', ...
                'Color', textColor);
        end
    end
end
