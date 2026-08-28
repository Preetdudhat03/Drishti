classdef EyeXpertApp < matlab.apps.AppBase
% EYEXPERTTAPP EyeXpert App Designer GUI Application (SIH 2026)
%
% Explainable AI-Based Diabetic Retinopathy Screening & Decision Support Prototype
%
% Features:
% - Quality Assessment Gate (GOOD / BORDERLINE / UNGRADABLE)
% - Adaptive CLAHE Enhancement with before/after comparison
% - 5-Level DR Inference (ResNet Transfer Learning)
% - Referable DR Determination (Level >= 2)
% - Grad-CAM Explainability Heatmap & Evidence Overlay
% - Human-in-the-Loop Clinician Validation / Override / Ungradable Marking
% - Structured Screening Report Export (Text/HTML)
% - Telemedicine District Simulation Launcher
%
% EyeXpert — SIH 2026

    % UI Components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        HeaderPanel                  matlab.ui.container.Panel
        TitleLabel                   matlab.ui.control.Label
        SubtitleLabel                matlab.ui.control.Label
        DisclaimerLabel              matlab.ui.control.Label
        
        LeftPanel                    matlab.ui.container.Panel
        UploadButton                 matlab.ui.control.Button
        DemoSampleDropDown           matlab.ui.control.DropDown
        OriginalAxes                 matlab.ui.control.UIAxes
        ImageInfoLabel               matlab.ui.control.Label
        
        CenterPanel                  matlab.ui.container.Panel
        QualityStatusBadge           matlab.ui.control.Label
        QualityScoreLabel            matlab.ui.control.Label
        QualityMetricsLabel          matlab.ui.control.Label
        RecaptureFeedbackLabel       matlab.ui.control.Label
        EnhancedAxes                 matlab.ui.control.UIAxes
        
        RightPanel                   matlab.ui.container.Panel
        DRLevelBadge                 matlab.ui.control.Label
        ReferableBadge               matlab.ui.control.Label
        ProbabilityLabel             matlab.ui.control.Label
        ProbAxes                     matlab.ui.control.UIAxes
        RecommendationLabel          matlab.ui.control.Label
        
        BottomPanel                  matlab.ui.container.Panel
        GradCAMAxes                  matlab.ui.control.UIAxes
        OverlayAxes                  matlab.ui.control.UIAxes
        ExplainabilityNoticeLabel    matlab.ui.control.Label
        
        HumanReviewPanel             matlab.ui.container.Panel
        HumanStatusBadge             matlab.ui.control.Label
        ValidateButton               matlab.ui.control.Button
        OverrideButton               matlab.ui.control.Button
        MarkUngradableButton         matlab.ui.control.Button
        OverrideDropDown             matlab.ui.control.DropDown
        ClinicianNotesField          matlab.ui.control.EditField
        ExportReportButton           matlab.ui.control.Button
        SimulinkSimButton            matlab.ui.control.Button
        
        StatusProgressBar            matlab.ui.control.Label
    end

    % State Properties
    properties (Access = private)
        CurrentState (1,1) string = "IDLE"
        LoadedImageRGB (:,:,3) uint8 = uint8.empty
        LoadedImageName (1,1) string = ""
        QualityResult struct = struct()
        PreprocResult struct = struct()
        InferenceResult struct = struct()
        CAMHeatmap (:,:) double = []
        OverlayImage (:,:,3) uint8 = uint8.empty
        HumanValidationData struct = struct('Status', "PENDING", 'ClinicianId', "Dr. Reviewer", 'Notes', "Awaiting review")
        TrainedModel = []
    end

    methods (Access = private)

        % State Transition & UI Reset (Prevents Stale Data UX Issue)
        function setState(app, newState, messageText)
            app.CurrentState = newState;
            if nargin < 3
                messageText = "";
            end

            switch newState
                case "IDLE"
                    app.StatusProgressBar.Text = "Ready. Please upload or select a fundus image.";
                    app.StatusProgressBar.BackgroundColor = [0.94 0.95 0.96];
                    app.clearResults();

                case "IMAGE_LOADED"
                    app.StatusProgressBar.Text = "Image loaded: " + app.LoadedImageName + ". Initiating quality gate...";
                    app.StatusProgressBar.BackgroundColor = [0.85 0.92 1.0];
                    app.clearResults();

                case "QUALITY_ASSESSMENT"
                    app.StatusProgressBar.Text = "Assessing sharpness, illumination, and retinal field coverage...";
                    app.StatusProgressBar.BackgroundColor = [1.0 0.95 0.8];
                    drawnow;

                case "ENHANCING"
                    app.StatusProgressBar.Text = "Image is Borderline. Applying adaptive CLAHE & illumination normalization...";
                    app.StatusProgressBar.BackgroundColor = [1.0 0.9 0.7];
                    drawnow;

                case "ANALYZING"
                    app.StatusProgressBar.Text = "Analyzing retinal structures and running DR deep learning inference...";
                    app.StatusProgressBar.BackgroundColor = [0.85 0.92 1.0];
                    drawnow;

                case "RESULT_READY"
                    app.StatusProgressBar.Text = "Analysis complete. Awaiting human ophthalmologist review.";
                    app.StatusProgressBar.BackgroundColor = [0.85 0.96 0.85];

                case "UNGRADABLE"
                    app.StatusProgressBar.Text = "Image UNGRADABLE. Automated DR classification halted for clinical safety.";
                    app.StatusProgressBar.BackgroundColor = [1.0 0.85 0.85];

                case "ERROR"
                    app.StatusProgressBar.Text = "Error: " + messageText;
                    app.StatusProgressBar.BackgroundColor = [1.0 0.8 0.8];
            end
            drawnow;
        end

        function clearResults(app)
            % Resets all analytical outputs
            app.QualityStatusBadge.Text = "QUALITY: --";
            app.QualityStatusBadge.BackgroundColor = [0.9 0.9 0.9];
            app.QualityScoreLabel.Text = "Quality Score: --";
            app.QualityMetricsLabel.Text = "Sharpness: -- | Illumination: -- | FOV: --";
            app.RecaptureFeedbackLabel.Text = "Recapture feedback: None";
            
            cla(app.EnhancedAxes);
            cla(app.ProbAxes);
            cla(app.GradCAMAxes);
            cla(app.OverlayAxes);
            
            app.DRLevelBadge.Text = "DR LEVEL: --";
            app.DRLevelBadge.BackgroundColor = [0.9 0.9 0.9];
            app.ReferableBadge.Text = "REFERABLE DR: --";
            app.ReferableBadge.BackgroundColor = [0.9 0.9 0.9];
            app.ProbabilityLabel.Text = "Model Probability: -- | Calibrated Conf: --";
            app.RecommendationLabel.Text = "Clinical Recommendation: Awaiting analysis.";
            
            app.HumanStatusBadge.Text = "STATUS: PENDING";
            app.HumanStatusBadge.BackgroundColor = [1.0 0.9 0.6];
            app.HumanValidationData = struct('Status', "PENDING", 'ClinicianId', "Dr. Reviewer", 'Notes', "Awaiting review");
        end

        % Execute End-to-End Pipeline on Loaded Image
        function processCurrentImage(app)
            if isempty(app.LoadedImageRGB)
                return;
            end

            app.setState("QUALITY_ASSESSMENT");

            % 1. Quality Assessment Gate
            qReport = assessImageQuality(app.LoadedImageRGB);
            app.QualityResult = qReport;

            % Update Quality UI
            app.QualityScoreLabel.Text = sprintf('Quality Score: %.2f / 1.00', qReport.OverallScore);
            app.QualityMetricsLabel.Text = sprintf('Sharpness: %.2f | Illumination: %.2f | FOV: %.2f', ...
                qReport.Sharpness.NormalizedScore, qReport.Illumination.NormalizedScore, qReport.FOV.NormalizedScore);

            if qReport.Status == "GOOD"
                app.QualityStatusBadge.Text = "QUALITY: GOOD";
                app.QualityStatusBadge.BackgroundColor = [0.2 0.75 0.3]; % Green
                app.QualityStatusBadge.FontColor = [1 1 1];
            elseif qReport.Status == "BORDERLINE"
                app.QualityStatusBadge.Text = "QUALITY: BORDERLINE";
                app.QualityStatusBadge.BackgroundColor = [0.95 0.65 0.1]; % Amber
                app.QualityStatusBadge.FontColor = [1 1 1];
            else
                app.QualityStatusBadge.Text = "QUALITY: UNGRADABLE";
                app.QualityStatusBadge.BackgroundColor = [0.85 0.2 0.2]; % Red
                app.QualityStatusBadge.FontColor = [1 1 1];
            end

            if ~isempty(qReport.RecaptureFeedback)
                app.RecaptureFeedbackLabel.Text = strjoin(qReport.RecaptureFeedback, " ");
            else
                app.RecaptureFeedbackLabel.Text = "Image passed quality gate.";
            end

            % Check Gate Rejection
            if qReport.Status == "UNGRADABLE"
                app.setState("UNGRADABLE");
                imshow(app.LoadedImageRGB, 'Parent', app.EnhancedAxes);
                title(app.EnhancedAxes, 'Ungradable Image (Rejected)', 'FontSize', 9);
                return;
            end

            % 2. Preprocessing & Enhancement
            if qReport.Status == "BORDERLINE"
                app.setState("ENHANCING");
                [procImg, pMeta] = preprocessFundus(app.LoadedImageRGB, 'ApplyEnhancement', true, 'TargetSize', [224, 224]);
            else
                [procImg, pMeta] = preprocessFundus(app.LoadedImageRGB, 'ApplyEnhancement', false, 'TargetSize', [224, 224]);
            end
            app.PreprocResult = pMeta;

            % Display Enhanced Image
            imshow(pMeta.EnhancedImage, 'Parent', app.EnhancedAxes);
            if pMeta.EnhancementApplied
                title(app.EnhancedAxes, 'Adaptive CLAHE Enhanced', 'FontSize', 9, 'Color', [0 0.4 0.8]);
            else
                title(app.EnhancedAxes, 'Preprocessed Retinal Disc', 'FontSize', 9);
            end

            % 3. Model Inference
            app.setState("ANALYZING");
            
            % Model loading check
            if isempty(app.TrainedModel)
                try
                    [app.TrainedModel, ~] = loadDRModel();
                catch
                    % If drModel.mat is not present yet, train a quick self-contained model or warn
                    app.setState("ERROR", "drModel.mat not found. Please run trainDRModel.m.");
                    return;
                end
            end

            [predRes, ~] = classifyDR(app.LoadedImageRGB, app.TrainedModel);
            app.InferenceResult = predRes;

            if predRes.Status ~= "SUCCESS"
                app.setState("ERROR", "Inference could not be completed.");
                return;
            end

            % 4. Display AI Results
            app.DRLevelBadge.Text = sprintf('DR LEVEL: %d', predRes.PredictedLevel);
            if predRes.PredictedLevel == 0
                app.DRLevelBadge.BackgroundColor = [0.2 0.7 0.3]; % Green
            elseif predRes.PredictedLevel == 1
                app.DRLevelBadge.BackgroundColor = [0.3 0.6 0.8]; % Blue
            elseif predRes.PredictedLevel == 2
                app.DRLevelBadge.BackgroundColor = [0.95 0.65 0.1]; % Orange
            else
                app.DRLevelBadge.BackgroundColor = [0.85 0.2 0.2]; % Red
            end
            app.DRLevelBadge.FontColor = [1 1 1];

            if predRes.IsReferable
                app.ReferableBadge.Text = "REFERABLE DR: YES";
                app.ReferableBadge.BackgroundColor = [0.85 0.15 0.15];
            else
                app.ReferableBadge.Text = "REFERABLE DR: NO";
                app.ReferableBadge.BackgroundColor = [0.2 0.7 0.3];
            end
            app.ReferableBadge.FontColor = [1 1 1];

            app.ProbabilityLabel.Text = sprintf('Model Probability: %.1f%%  |  Calibrated Conf: %.1f%%', ...
                predRes.ModelProbability * 100, predRes.CalibratedConfidence * 100);
            app.RecommendationLabel.Text = "Recommendation: " + string(predRes.ClinicalRecommendation);

            % Class Probabilities Bar Chart
            bar(app.ProbAxes, 0:4, predRes.ClassProbabilities * 100, 'FaceColor', [0.2 0.5 0.8]);
            set(app.ProbAxes, 'XTick', 0:4, 'XTickLabel', {'L0', 'L1', 'L2', 'L3', 'L4'}, 'FontSize', 8);
            ylabel(app.ProbAxes, 'Prob (%)', 'FontSize', 8);
            ylim(app.ProbAxes, [0 100]);
            title(app.ProbAxes, '5-Class Probability Distribution', 'FontSize', 9);

            % 5. Explainability (Grad-CAM & Evidence Overlay)
            cam = generateGradCAM(app.TrainedModel, procImg);
            app.CAMHeatmap = cam;

            [overlay, ~] = createEvidenceOverlay(pMeta.EnhancedImage, cam);
            app.OverlayImage = overlay;

            % Display CAM & Overlay
            imagesc(app.GradCAMAxes, cam);
            colormap(app.GradCAMAxes, turbo);
            axis(app.GradCAMAxes, 'image');
            axis(app.GradCAMAxes, 'off');
            title(app.GradCAMAxes, 'Grad-CAM Heatmap', 'FontSize', 9);

            imshow(overlay, 'Parent', app.OverlayAxes);
            title(app.OverlayAxes, 'Evidence Attention Overlay', 'FontSize', 9);

            app.setState("RESULT_READY");
        end

        % Human-in-the-Loop Callbacks
        function onValidate(app)
            if app.CurrentState ~= "RESULT_READY" && app.CurrentState ~= "HUMAN_REVIEW"
                return;
            end
            app.HumanValidationData.Status = "VALIDATED_BY_CLINICIAN";
            app.HumanValidationData.Notes = string(app.ClinicianNotesField.Value);
            app.HumanStatusBadge.Text = "STATUS: VALIDATED";
            app.HumanStatusBadge.BackgroundColor = [0.2 0.7 0.3];
            app.HumanStatusBadge.FontColor = [1 1 1];
            app.StatusProgressBar.Text = "AI screening result validated and signed off by clinician.";
        end

        function onOverride(app)
            if app.CurrentState ~= "RESULT_READY" && app.CurrentState ~= "HUMAN_REVIEW"
                return;
            end
            chosenLevel = str2double(app.OverrideDropDown.Value);
            app.HumanValidationData.Status = sprintf('OVERRIDDEN_TO_LEVEL_%d', chosenLevel);
            app.HumanValidationData.Notes = string(app.ClinicianNotesField.Value);
            app.HumanStatusBadge.Text = sprintf('STATUS: OVERRIDDEN (L%d)', chosenLevel);
            app.HumanStatusBadge.BackgroundColor = [0.9 0.4 0.1];
            app.HumanStatusBadge.FontColor = [1 1 1];
            app.StatusProgressBar.Text = sprintf('Clinician overrode result to Level %d. Reason logged.', chosenLevel);
        end

        function onMarkUngradable(app)
            app.HumanValidationData.Status = "CLINICIAN_MARKED_UNGRADABLE";
            app.HumanValidationData.Notes = string(app.ClinicianNotesField.Value);
            app.HumanStatusBadge.Text = "STATUS: MARKED UNGRADABLE";
            app.HumanStatusBadge.BackgroundColor = [0.85 0.2 0.2];
            app.HumanStatusBadge.FontColor = [1 1 1];
            app.StatusProgressBar.Text = "Clinician rejected image as ungradable. Recapture requested.";
        end

        function onExportReport(app)
            if isempty(app.InferenceResult) || ~isfield(app.InferenceResult, 'PredictedLevel')
                uialert(app.UIFigure, 'Please analyze an image before exporting a report.', 'No Report Data');
                return;
            end

            report = generateScreeningReport(app.LoadedImageName, app.InferenceResult, app.HumanValidationData);
            reportPath = exportReport(report, fullfile(pwd, 'reports'), 'html');
            uialert(app.UIFigure, "Screening report successfully exported to:\n" + reportPath, "Report Exported");
        end

        function onRunSimulation(app)
            compareScenarios();
        end

        function onUploadImage(app)
            [filename, pathname] = uigetfile({'*.png;*.jpg;*.jpeg;*.tif', 'Fundus Image Files (*.png, *.jpg, *.jpeg, *.tif)'});
            if isequal(filename, 0)
                return;
            end

            fullPath = fullfile(pathname, filename);
            app.LoadedImageName = string(filename);
            app.LoadedImageRGB = imread(fullPath);

            imshow(app.LoadedImageRGB, 'Parent', app.OriginalAxes);
            title(app.OriginalAxes, 'Uploaded Fundus Image', 'FontSize', 9);
            app.ImageInfoLabel.Text = sprintf('File: %s | Size: %dx%d', filename, size(app.LoadedImageRGB, 2), size(app.LoadedImageRGB, 1));

            app.setState("IMAGE_LOADED");
            app.processCurrentImage();
        end

        function onDemoSampleSelected(app)
            val = app.DemoSampleDropDown.Value;
            if val == "Select Sample Benchmark..."
                return;
            end

            sampleDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'sample_demo');
            if ~isfolder(sampleDir)
                generateSampleFundusData(sampleDir);
            end

            imgPath = fullfile(sampleDir, char(val) + ".png");
            if ~isfile(imgPath)
                generateSampleFundusData(sampleDir);
            end

            app.LoadedImageName = string(val);
            app.LoadedImageRGB = imread(imgPath);

            imshow(app.LoadedImageRGB, 'Parent', app.OriginalAxes);
            title(app.OriginalAxes, 'Benchmark Fundus Image', 'FontSize', 9);
            app.ImageInfoLabel.Text = sprintf('Sample: %s', val);

            app.setState("IMAGE_LOADED");
            app.processCurrentImage();
        end
    end

    % App Initialization & Layout
    methods (Access = public)

        function app = EyeXpertApp()
            % Create main window
            app.UIFigure = uifigure('Name', 'EyeXpert — Explainable AI Diabetic Retinopathy Screening (SIH 2026)', ...
                'Position', [50, 50, 1280, 800], 'Color', [0.96, 0.97, 0.98]);

            % 1. Header Panel
            app.HeaderPanel = uipanel(app.UIFigure, 'Position', [10, 720, 1260, 70], ...
                'BackgroundColor', [0.08, 0.18, 0.32], 'BorderType', 'none');
            
            app.TitleLabel = uilabel(app.HeaderPanel, 'Position', [15, 36, 600, 28], ...
                'Text', 'EYEXPERT — RETINAL SCREENING & CLINICAL DECISION SUPPORT', ...
                'FontSize', 18, 'FontWeight', 'bold', 'FontColor', [1 1 1]);

            app.SubtitleLabel = uilabel(app.HeaderPanel, 'Position', [15, 12, 700, 20], ...
                'Text', 'Explainable AI-Based Diabetic Retinopathy Gated Screening Prototype | SIH 2026', ...
                'FontSize', 12, 'FontColor', [0.8 0.9 1.0]);

            app.DisclaimerLabel = uilabel(app.HeaderPanel, 'Position', [750, 10, 500, 48], ...
                'Text', sprintf('SAFETY NOTICE: Prototype for screening decision support.\nMandates ophthalmologist validation before clinical action.'), ...
                'FontSize', 10, 'FontColor', [1.0 0.85 0.6], 'HorizontalAlignment', 'right');

            % 2. Left Panel (Upload & Original Image)
            app.LeftPanel = uipanel(app.UIFigure, 'Position', [10, 360, 300, 350], ...
                'Title', '1. Fundus Image Acquisition', 'FontWeight', 'bold', 'BackgroundColor', 'w');

            app.UploadButton = uibutton(app.LeftPanel, 'push', 'Position', [15, 280, 120, 32], ...
                'Text', 'Upload Fundus', 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn, event) app.onUploadImage());

            app.DemoSampleDropDown = uidropdown(app.LeftPanel, 'Position', [145, 280, 140, 32], ...
                'Items', {'Select Sample Benchmark...', 'sample_good_normal', 'sample_good_npdr_mild', ...
                          'sample_good_npdr_moderate', 'sample_good_pdr_severe', 'sample_borderline_illum', ...
                          'sample_ungradable_blur', 'sample_ungradable_dark'}, ...
                'ValueChangedFcn', @(dd, event) app.onDemoSampleSelected());

            app.OriginalAxes = uiaxes(app.LeftPanel, 'Position', [15, 45, 270, 220]);
            axis(app.OriginalAxes, 'off');
            title(app.OriginalAxes, 'Original Fundus Image', 'FontSize', 9);

            app.ImageInfoLabel = uilabel(app.LeftPanel, 'Position', [15, 10, 270, 25], ...
                'Text', 'No image loaded.', 'FontSize', 10, 'FontColor', [0.4 0.4 0.4]);

            % 3. Center Panel (Quality Assessment & Enhancement)
            app.CenterPanel = uipanel(app.UIFigure, 'Position', [320, 360, 380, 350], ...
                'Title', '2. Quality Assessment & Adaptive Enhancement', 'FontWeight', 'bold', 'BackgroundColor', 'w');

            app.QualityStatusBadge = uilabel(app.CenterPanel, 'Position', [15, 280, 170, 32], ...
                'Text', 'QUALITY: --', 'FontSize', 12, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'BackgroundColor', [0.9 0.9 0.9]);

            app.QualityScoreLabel = uilabel(app.CenterPanel, 'Position', [195, 280, 170, 32], ...
                'Text', 'Quality Score: --', 'FontSize', 11, 'FontWeight', 'bold');

            app.QualityMetricsLabel = uilabel(app.CenterPanel, 'Position', [15, 250, 350, 22], ...
                'Text', 'Sharpness: -- | Illumination: -- | FOV: --', 'FontSize', 10);

            app.RecaptureFeedbackLabel = uilabel(app.CenterPanel, 'Position', [15, 215, 350, 32], ...
                'Text', 'Recapture feedback: None', 'FontSize', 10, 'FontColor', [0.7 0.2 0.2]);

            app.EnhancedAxes = uiaxes(app.CenterPanel, 'Position', [15, 15, 350, 195]);
            axis(app.EnhancedAxes, 'off');
            title(app.EnhancedAxes, 'Preprocessed / Enhanced Retina', 'FontSize', 9);

            % 4. Right Panel (AI Screening Results & Probability)
            app.RightPanel = uipanel(app.UIFigure, 'Position', [710, 360, 560, 350], ...
                'Title', '3. AI Retinal Screening Result', 'FontWeight', 'bold', 'BackgroundColor', 'w');

            app.DRLevelBadge = uilabel(app.RightPanel, 'Position', [15, 280, 170, 35], ...
                'Text', 'DR LEVEL: --', 'FontSize', 13, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'BackgroundColor', [0.9 0.9 0.9]);

            app.ReferableBadge = uilabel(app.RightPanel, 'Position', [195, 280, 200, 35], ...
                'Text', 'REFERABLE DR: --', 'FontSize', 12, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'BackgroundColor', [0.9 0.9 0.9]);

            app.ProbabilityLabel = uilabel(app.RightPanel, 'Position', [15, 245, 530, 25], ...
                'Text', 'Model Probability: -- | Calibrated Conf: --', 'FontSize', 11, 'FontWeight', 'bold');

            app.ProbAxes = uiaxes(app.RightPanel, 'Position', [15, 75, 530, 160]);

            app.RecommendationLabel = uilabel(app.RightPanel, 'Position', [15, 10, 530, 55], ...
                'Text', 'Clinical Recommendation: Awaiting analysis.', 'FontSize', 11, ...
                'FontWeight', 'bold', 'FontColor', [0.1 0.3 0.6]);

            % 5. Bottom Panel (Explainability: Grad-CAM & Evidence)
            app.BottomPanel = uipanel(app.UIFigure, 'Position', [10, 80, 780, 270], ...
                'Title', '4. Explainable AI (Grad-CAM & Focal Retinal Attention)', 'FontWeight', 'bold', 'BackgroundColor', 'w');

            app.GradCAMAxes = uiaxes(app.BottomPanel, 'Position', [20, 45, 260, 190]);
            axis(app.GradCAMAxes, 'off');
            title(app.GradCAMAxes, 'Grad-CAM Heatmap', 'FontSize', 9);

            app.OverlayAxes = uiaxes(app.BottomPanel, 'Position', [300, 45, 260, 190]);
            axis(app.OverlayAxes, 'off');
            title(app.OverlayAxes, 'Evidence Attention Overlay', 'FontSize', 9);

            app.ExplainabilityNoticeLabel = uilabel(app.BottomPanel, 'Position', [20, 10, 740, 25], ...
                'Text', 'NOTICE: Heatmap highlights model attention regions contributing to prediction. Interpretability tool — not a lesion detector.', ...
                'FontSize', 9, 'FontColor', [0.4 0.4 0.4], 'FontAngle', 'italic');

            % 6. Human Review & Decision Support Panel
            app.HumanReviewPanel = uipanel(app.UIFigure, 'Position', [800, 80, 470, 270], ...
                'Title', '5. Human-in-the-Loop Ophthalmologist Review', 'FontWeight', 'bold', 'BackgroundColor', 'w');

            app.HumanStatusBadge = uilabel(app.HumanReviewPanel, 'Position', [15, 205, 210, 28], ...
                'Text', 'STATUS: PENDING', 'FontSize', 11, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'BackgroundColor', [1.0 0.9 0.6]);

            app.ValidateButton = uibutton(app.HumanReviewPanel, 'push', 'Position', [240, 205, 210, 28], ...
                'Text', '✔ Validate Result', 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.95 0.85], ...
                'ButtonPushedFcn', @(btn, event) app.onValidate());

            app.OverrideButton = uibutton(app.HumanReviewPanel, 'push', 'Position', [15, 165, 140, 28], ...
                'Text', '⚠ Override DR:', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.onOverride());

            app.OverrideDropDown = uidropdown(app.HumanReviewPanel, 'Position', [160, 165, 65, 28], ...
                'Items', {'0', '1', '2', '3', '4'}, 'Value', '0');

            app.MarkUngradableButton = uibutton(app.HumanReviewPanel, 'push', 'Position', [240, 165, 210, 28], ...
                'Text', '✖ Mark Ungradable', 'FontWeight', 'bold', 'BackgroundColor', [1.0 0.9 0.9], ...
                'ButtonPushedFcn', @(btn, event) app.onMarkUngradable());

            uilabel(app.HumanReviewPanel, 'Position', [15, 130, 120, 20], 'Text', 'Clinician Notes:', 'FontSize', 10);
            app.ClinicianNotesField = uieditfield(app.HumanReviewPanel, 'text', 'Position', [15, 100, 435, 28], ...
                'Value', 'Validated by ophthalmologist. Findings consistent with clinical grade.');

            app.ExportReportButton = uibutton(app.HumanReviewPanel, 'push', 'Position', [15, 55, 210, 32], ...
                'Text', '📄 Export Screening Report', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.onExportReport());

            app.SimulinkSimButton = uibutton(app.HumanReviewPanel, 'push', 'Position', [240, 55, 210, 32], ...
                'Text', '📊 District Telemedicine Simulation', 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, event) app.onRunSimulation());

            % 7. Status / Progress Bar
            app.StatusProgressBar = uilabel(app.UIFigure, 'Position', [10, 15, 1260, 50], ...
                'Text', 'EyeXpert initialized. Ready for retinal screening.', ...
                'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.92 0.94 0.96], ...
                'HorizontalAlignment', 'center');
        end
    end
end
