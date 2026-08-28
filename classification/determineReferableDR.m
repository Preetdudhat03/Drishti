function [isReferable, severityText, recommendation, clinicalInfo] = determineReferableDR(drLevel)
% DETERMINEREFERABLEDR Maps DR Level (0-4) to Referable DR screening decision
%
% SIH 2026 Screening Rule:
%   Level 0 -> No Diabetic Retinopathy          [Non-Referable]
%   Level 1 -> Mild Non-Proliferative DR        [Non-Referable]
%   Level 2 -> Moderate Non-Proliferative DR    [REFERABLE DR]
%   Level 3 -> Severe Non-Proliferative DR      [REFERABLE DR]
%   Level 4 -> Proliferative Diabetic Retinopathy[REFERABLE DR]
%
% EyeXpert — SIH 2026

    arguments
        drLevel (1,1) double
    end

    intLevel = round(drLevel);

    switch intLevel
        case 0
            isReferable = false;
            severityText = "Level 0 — No Diabetic Retinopathy";
            recommendation = "Routine annual rescreening as per clinical protocol.";
            clinicalFindings = "No microaneurysms or retinal hemorrhages detected.";
            urgency = "ROUTINE";

        case 1
            isReferable = false;
            severityText = "Level 1 — Mild Non-Proliferative DR (Mild NPDR)";
            recommendation = "Follow-up rescreening in 6 to 12 months with glycemic control.";
            clinicalFindings = "Isolated microaneurysms only. No macular edema or severe NPDR signs.";
            urgency = "FOLLOW_UP_6_12_MONTHS";

        case 2
            isReferable = true;
            severityText = "Level 2 — Moderate Non-Proliferative DR (Moderate NPDR)";
            recommendation = "Ophthalmologist referral recommended within 4 to 8 weeks for detailed fundus evaluation.";
            clinicalFindings = "Multiple microaneurysms, blot hemorrhages, or hard exudates present.";
            urgency = "REFERRAL_4_8_WEEKS";

        case 3
            isReferable = true;
            severityText = "Level 3 — Severe Non-Proliferative DR (Severe NPDR)";
            recommendation = "Prompt ophthalmologist referral required within 2 to 4 weeks.";
            clinicalFindings = "Extensive intraretinal hemorrhages (4-2-1 rule), venous beading, or IRMA.";
            urgency = "PROMPT_REFERRAL_2_4_WEEKS";

        case 4
            isReferable = true;
            severityText = "Level 4 — Proliferative Diabetic Retinopathy (PDR)";
            recommendation = "Urgent ophthalmologist referral required within 1 to 2 weeks for possible laser/anti-VEGF intervention.";
            clinicalFindings = "Neovascularization of the disc/retina (NVD/NVE) or preretinal/vitreous hemorrhage.";
            urgency = "URGENT_REFERRAL";

        otherwise
            isReferable = false;
            severityText = "Invalid DR Level";
            recommendation = "Invalid classification level. Recapture or manual clinical assessment required.";
            clinicalFindings = "Undefined";
            urgency = "UNKNOWN";
    end

    clinicalInfo = struct();
    clinicalInfo.DRLevel = intLevel;
    clinicalInfo.IsReferable = isReferable;
    clinicalInfo.SeverityText = severityText;
    clinicalInfo.Recommendation = recommendation;
    clinicalInfo.ClinicalFindings = clinicalFindings;
    clinicalInfo.Urgency = urgency;
end
