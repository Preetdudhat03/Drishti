function sampleManifest = generateSampleFundusData(outputDir)
% GENERATESAMPLEFUNDUSDATA Generates realistic synthetic fundus benchmark images
%
% Creates a test suite of fundus images spanning:
% - Good quality (Levels 0, 1, 2, 4)
% - Borderline illumination (tested by CLAHE enhancement)
% - Ungradable blur (tested by Quality Gate rejection)
% - Ungradable underexposure (tested by Quality Gate rejection)
%
% EyeXpert — SIH 2026

    arguments
        outputDir (1,1) string = fullfile(fileparts(mfilename('fullpath')), 'sample_demo')
    end

    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    rng(42); % Fixed seed for deterministic benchmark generation
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

    % Helper to add optic disc (bright yellowish-white disc at nasal side)
    function rgb = addOpticDisc(rgb, discX, discY, discR)
        dDisc = sqrt((X - discX).^2 + (Y - discY).^2);
        dMask = dDisc <= discR;
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
        % Arch patterns
        vessel1 = abs(sin(theta * 2) .* r - 60) < 3.5 & (r > 20) & (r < 200) & retinaMask;
        vessel2 = abs(cos(theta * 2.5) .* r - 110) < 2.5 & (r > 30) & (r < 210) & retinaMask;
        vessel3 = abs(sin(theta * 1.5 + 0.5) .* r - 150) < 2.0 & (r > 40) & (r < 200) & retinaMask;
        allVessels = vessel1 | vessel2 | vessel3;
        % Vessels are dark red / attenuated green
        rgb(:,:,1) = rgb(:,:,1) - 0.20 * allVessels;
        rgb(:,:,2) = rgb(:,:,2) - 0.28 * allVessels;
        rgb(:,:,3) = rgb(:,:,3) - 0.10 * allVessels;
        rgb = max(0, rgb);
    end

    % Helper to add microaneurysms (small red dots)
    function rgb = addMicroaneurysms(rgb, numDots)
        for k = 1:numDots
            dx = centerX + (rand() - 0.5) * 220;
            dy = centerY + (rand() - 0.5) * 220;
            if sqrt((dx - centerX)^2 + (dy - centerY)^2) < 180
                d = sqrt((X - dx).^2 + (Y - dy).^2);
                dotMask = d <= (1.8 + rand());
                rgb(:,:,1) = rgb(:,:,1) - 0.25 * dotMask;
                rgb(:,:,2) = rgb(:,:,2) - 0.35 * dotMask; % strong absorption in green
                rgb(:,:,3) = rgb(:,:,3) - 0.15 * dotMask;
            end
        end
        rgb = max(0, rgb);
    end

    % Helper to add hard exudates (bright yellowish lipid deposits)
    function rgb = addExudates(rgb, numClusters)
        for k = 1:numClusters
            cx = centerX + (rand() - 0.5) * 160;
            cy = centerY + (rand() - 0.5) * 160;
            if sqrt((cx - centerX)^2 + (cy - centerY)^2) < 160
                d = sqrt((X - cx).^2 + (Y - cy).^2);
                exMask = d <= (4.0 + 3.0 * rand());
                rgb(:,:,1) = rgb(:,:,1) + 0.40 * exMask;
                rgb(:,:,2) = rgb(:,:,2) + 0.38 * exMask;
                rgb(:,:,3) = rgb(:,:,3) + 0.15 * exMask;
            end
        end
        rgb = min(1.0, rgb);
    end

    % 1. Sample Normal (Level 0 - Non-referable, Good Quality)
    img0 = cat(3, baseR, baseG, baseB);
    img0 = addOpticDisc(img0, 160, 256, 32);
    img0 = addVessels(img0, 160, 256);
    img0 = imnoise(img0, 'gaussian', 0, 0.0002);
    imwrite(uint8(img0 * 255), fullfile(outputDir, 'sample_good_normal.png'));

    % 2. Sample Mild NPDR (Level 1 - Non-referable, Good Quality)
    img1 = cat(3, baseR, baseG, baseB);
    img1 = addOpticDisc(img1, 160, 256, 32);
    img1 = addVessels(img1, 160, 256);
    img1 = addMicroaneurysms(img1, 8);
    img1 = imnoise(img1, 'gaussian', 0, 0.0002);
    imwrite(uint8(img1 * 255), fullfile(outputDir, 'sample_good_npdr_mild.png'));

    % 3. Sample Moderate NPDR (Level 2 - Referable DR, Good Quality)
    img2 = cat(3, baseR, baseG, baseB);
    img2 = addOpticDisc(img2, 160, 256, 32);
    img2 = addVessels(img2, 160, 256);
    img2 = addMicroaneurysms(img2, 35);
    img2 = addExudates(img2, 12);
    img2 = imnoise(img2, 'gaussian', 0, 0.0003);
    imwrite(uint8(img2 * 255), fullfile(outputDir, 'sample_good_npdr_moderate.png'));

    % 4. Sample Proliferative DR (Level 4 - Referable DR, Good Quality)
    img4 = cat(3, baseR, baseG, baseB);
    img4 = addOpticDisc(img4, 160, 256, 32);
    img4 = addVessels(img4, 160, 256);
    img4 = addMicroaneurysms(img4, 60);
    img4 = addExudates(img4, 25);
    % Add extensive neovascular tufts
    nvMask = abs(sin(X/12 + Y/14)) > 0.85 & distFromCenter < 140 & retinaMask;
    img4(:,:,1) = max(0, img4(:,:,1) - 0.25 * nvMask);
    img4(:,:,2) = max(0, img4(:,:,2) - 0.35 * nvMask);
    img4 = imnoise(img4, 'gaussian', 0, 0.0004);
    imwrite(uint8(img4 * 255), fullfile(outputDir, 'sample_good_pdr_severe.png'));

    % 5. Sample Borderline Illumination (Low contrast, uneven lighting)
    imgBorder = img2 * 0.55; % attenuated contrast
    % Add non-uniform gradient
    gradientShade = 0.5 + 0.5 * (X / imgSize(2));
    imgBorder = imgBorder .* gradientShade;
    imgBorder(~retinaMask) = 0;
    imwrite(uint8(imgBorder * 255), fullfile(outputDir, 'sample_borderline_illum.png'));

    % 6. Sample Ungradable Blur (Severe motion blur)
    hMotion = fspecial('motion', 35, 45);
    imgBlur = imfilter(img2, hMotion, 'replicate');
    imgBlur(~retinaMask) = 0;
    imwrite(uint8(imgBlur * 255), fullfile(outputDir, 'sample_ungradable_blur.png'));

    % 7. Sample Ungradable Dark (Severe underexposure)
    imgDark = img2 * 0.12;
    imgDark(~retinaMask) = 0;
    imwrite(uint8(imgDark * 255), fullfile(outputDir, 'sample_ungradable_dark.png'));

    % Create manifest CSV
    manifestData = {
        'sample_good_normal', 0, 'No Diabetic Retinopathy', 'GOOD', 'NORMAL';
        'sample_good_npdr_mild', 1, 'Mild NPDR', 'GOOD', 'NORMAL';
        'sample_good_npdr_moderate', 2, 'Moderate NPDR', 'GOOD', 'NORMAL';
        'sample_good_pdr_severe', 4, 'Proliferative DR', 'GOOD', 'NORMAL';
        'sample_borderline_illum', 2, 'Moderate NPDR (Low Contrast)', 'BORDERLINE', 'LOW_CONTRAST';
        'sample_ungradable_blur', 2, 'Moderate NPDR (Motion Blur)', 'UNGRADABLE', 'BLUR';
        'sample_ungradable_dark', 2, 'Moderate NPDR (Severe Underexposure)', 'UNGRADABLE', 'DARK'
    };

    manifestTable = cell2table(manifestData, ...
        'VariableNames', {'id_code', 'diagnosis', 'clinical_description', 'expected_quality', 'artifact_type'});
    
    csvPath = fullfile(outputDir, 'sample_labels.csv');
    writetable(manifestTable, csvPath);

    sampleManifest = struct();
    sampleManifest.Directory = outputDir;
    sampleManifest.CsvPath = csvPath;
    sampleManifest.Table = manifestTable;
    sampleManifest.Count = height(manifestTable);

    fprintf('Generated %d benchmark sample fundus images in: %s\n', sampleManifest.Count, outputDir);
end
