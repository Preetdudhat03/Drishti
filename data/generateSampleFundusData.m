function sampleManifest = generateSampleFundusData(outputDir)
% GENERATESAMPLEFUNDUSDATA Generates software test fixtures for pipeline verification
%
% IMPORTANT DISCLAIMER:
%   These images are SOFTWARE UNIT-TEST FIXTURES — NOT CLINICAL DATA.
%   They exist solely to test computational filters (Laplacian kernels, 
%   contrast adjustment, image sizing, and UI error handling).
%   They MUST NOT be used as clinical evidence or for clinical validation.
%
% EyeXpert — SIH 2026

    arguments
        outputDir (1,1) string = fullfile(fileparts(mfilename('fullpath')), 'sample_demo')
    end

    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    rng(42); % Fixed seed for deterministic test fixture generation
    imgSize = [512, 512];
    [Y, X] = ndgrid(1:imgSize(1), 1:imgSize(2));
    centerX = imgSize(2) / 2;
    centerY = imgSize(1) / 2;
    radius = 220;

    distFromCenter = sqrt((X - centerX).^2 + (Y - centerY).^2);
    retinaMask = distFromCenter <= radius;

    % Base retinal background: warm orange-red fundus appearance
    baseR = 0.82 - 0.25 * (distFromCenter / radius).^1.5;
    baseG = 0.42 - 0.20 * (distFromCenter / radius).^1.2;
    baseB = 0.12 - 0.08 * (distFromCenter / radius);

    baseR(~retinaMask) = 0;
    baseG(~retinaMask) = 0;
    baseB(~retinaMask) = 0;

    % Helper to add optic disc
    function rgb = addOpticDisc(rgb, discX, discY, discR)
        dDisc = sqrt((X - discX).^2 + (Y - discY).^2);
        falloff = max(0, 1 - dDisc/discR);
        rgb(:,:,1) = rgb(:,:,1) + 0.35 * falloff .* retinaMask;
        rgb(:,:,2) = rgb(:,:,2) + 0.32 * falloff .* retinaMask;
        rgb(:,:,3) = rgb(:,:,3) + 0.15 * falloff .* retinaMask;
        rgb = min(1.0, rgb);
    end

    % Helper to add vessel-like arches
    function rgb = addVessels(rgb, discX, discY)
        theta = atan2(Y - discY, X - discX);
        r = sqrt((X - discX).^2 + (Y - discY).^2);
        vessel1 = abs(sin(theta * 2) .* r - 60) < 3.5 & (r > 20) & (r < 200) & retinaMask;
        vessel2 = abs(cos(theta * 2.5) .* r - 110) < 2.5 & (r > 30) & (r < 210) & retinaMask;
        allVessels = vessel1 | vessel2;
        rgb(:,:,1) = rgb(:,:,1) - 0.20 * allVessels;
        rgb(:,:,2) = rgb(:,:,2) - 0.28 * allVessels;
        rgb(:,:,3) = rgb(:,:,3) - 0.10 * allVessels;
        rgb = max(0, rgb);
    end

    % Helper to add simulated dots
    function rgb = addSyntheticDots(rgb, numDots)
        for k = 1:numDots
            dx = centerX + (rand() - 0.5) * 220;
            dy = centerY + (rand() - 0.5) * 220;
            if sqrt((dx - centerX)^2 + (dy - centerY)^2) < 180
                d = sqrt((X - dx).^2 + (Y - dy).^2);
                dotMask = d <= (1.8 + rand());
                rgb(:,:,1) = rgb(:,:,1) - 0.25 * dotMask;
                rgb(:,:,2) = rgb(:,:,2) - 0.35 * dotMask;
            end
        end
        rgb = max(0, rgb);
    end

    % 1. Fixture: Sharp Baseline Image
    img0 = cat(3, baseR, baseG, baseB);
    img0 = addOpticDisc(img0, 160, 256, 32);
    img0 = addVessels(img0, 160, 256);
    imwrite(uint8(img0 * 255), fullfile(outputDir, 'sample_good_normal.png'));

    % 2. Fixture: Mild Feature Test Pattern
    img1 = addSyntheticDots(img0, 8);
    imwrite(uint8(img1 * 255), fullfile(outputDir, 'sample_good_npdr_mild.png'));

    % 3. Fixture: Moderate Feature Test Pattern
    img2 = addSyntheticDots(img0, 35);
    imwrite(uint8(img2 * 255), fullfile(outputDir, 'sample_good_npdr_moderate.png'));

    % 4. Fixture: Dense Feature Test Pattern
    img4 = addSyntheticDots(img0, 65);
    imwrite(uint8(img4 * 255), fullfile(outputDir, 'sample_good_pdr_severe.png'));

    % 5. Fixture: Borderline Low Contrast
    grad = (0.5 + 0.5 * (X / imgSize(2)));
    imgBorder = img2 * 0.55 .* grad;
    imgBorder(~retinaMask) = 0;
    imwrite(uint8(min(255, max(0, imgBorder * 255))), fullfile(outputDir, 'sample_borderline_illum.png'));

    % 6. Fixture: Motion Blur (Filter Unit Test)
    hMotion = fspecial('motion', 35, 45);
    imgBlur = imfilter(img2, hMotion, 'replicate');
    imgBlur(~retinaMask) = 0;
    imwrite(uint8(min(255, max(0, imgBlur * 255))), fullfile(outputDir, 'sample_ungradable_blur.png'));

    % 7. Fixture: Underexposure (Filter Unit Test)
    imgDark = img2 * 0.10;
    imgDark(~retinaMask) = 0;
    imwrite(uint8(min(255, max(0, imgDark * 255))), fullfile(outputDir, 'sample_ungradable_dark.png'));

    % Manifest CSV explicitly marked as software test fixtures
    manifestData = {
        'sample_good_normal', 0, 'Software Unit Test Fixture (Normal)', 'GOOD', 'UNIT_TEST_FIXTURE';
        'sample_good_npdr_mild', 1, 'Software Unit Test Fixture (Mild)', 'GOOD', 'UNIT_TEST_FIXTURE';
        'sample_good_npdr_moderate', 2, 'Software Unit Test Fixture (Moderate)', 'GOOD', 'UNIT_TEST_FIXTURE';
        'sample_good_pdr_severe', 4, 'Software Unit Test Fixture (Dense)', 'GOOD', 'UNIT_TEST_FIXTURE';
        'sample_borderline_illum', 2, 'Software Unit Test Fixture (Low Contrast)', 'BORDERLINE', 'CLAHE_FILTER_TEST';
        'sample_ungradable_blur', 2, 'Software Unit Test Fixture (Motion Blur)', 'UNGRADABLE', 'BLUR_FILTER_TEST';
        'sample_ungradable_dark', 2, 'Software Unit Test Fixture (Underexposed)', 'UNGRADABLE', 'DARK_FILTER_TEST'
    };

    manifestTable = cell2table(manifestData, ...
        'VariableNames', {'id_code', 'diagnosis', 'fixture_description', 'expected_quality', 'data_role'});
    
    csvPath = fullfile(outputDir, 'sample_labels.csv');
    writetable(manifestTable, csvPath);

    sampleManifest = struct();
    sampleManifest.Directory = outputDir;
    sampleManifest.CsvPath = csvPath;
    sampleManifest.Table = manifestTable;
    sampleManifest.Count = height(manifestTable);
    sampleManifest.DataRole = "SOFTWARE_UNIT_TEST_FIXTURES_ONLY";

    fprintf('Generated %d software unit test fixtures in: %s\n', sampleManifest.Count, outputDir);
    fprintf('NOTICE: These fixtures are for pipeline code testing only — NOT clinical validation.\n');
end
