import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/screening_case_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/utils/formatters.dart';

class ReportService {
  static Future<Uint8List> generatePdfReport(ScreeningCaseModel screeningCase) async {
    final pdf = pw.Document();

    final pred = screeningCase.prediction;
    final quality = screeningCase.quality;
    final review = screeningCase.review;
    final isReferable = pred?.referable ?? false;
    final severity = pred != null ? DRSeverity.fromLevel(pred.drLevel) : null;

    // Load fonts or use standard BaseFont to ensure 100% clean rendering
    pw.Font? fontRegular;
    pw.Font? fontBold;
    try {
      fontRegular = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
    } catch (_) {
      // Fallback to standard PDF Helvetica
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DRISHTI SCREENING REPORT',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'AI Retinal Screening & Tele-Ophthalmology Network | SIH 2026',
                        style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: isReferable ? PdfColors.red50 : PdfColors.green50,
                      border: pw.Border.all(
                        color: isReferable ? PdfColors.red700 : PdfColors.green700,
                        width: 1.2,
                      ),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      isReferable ? 'REFERABLE DR - YES' : 'NON-REFERABLE',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9.5,
                        color: isReferable ? PdfColors.red900 : PdfColors.green900,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // 2. PATIENT & SCREENING INFORMATION
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfInfoCol('PATIENT ID', screeningCase.patient.patientId),
                    _pdfInfoCol('SCREENING ID', screeningCase.screeningId),
                    _pdfInfoCol('EXAMINATION EYE', '${screeningCase.patient.eye} (${screeningCase.patient.eye == "OD" ? "Right Eye" : "Left Eye"})'),
                    _pdfInfoCol('AGE / GENDER', '${screeningCase.patient.age ?? "N/A"}Y / ${screeningCase.patient.gender ?? "N/A"}'),
                    _pdfInfoCol('DATE', AppFormatters.formatDateTime(screeningCase.createdAt)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 3. OPTICAL QUALITY ASSESSMENT
              pw.Text(
                '1. OPTICAL IMAGE QUALITY ASSESSMENT',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Overall Status: ${quality?.status.label ?? "GOOD"} (${AppFormatters.formatPercent(quality?.overallScore)})',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Focus: ${quality?.sharpness.status ?? "GOOD"}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Illumination: ${quality?.illumination.status ?? "GOOD"}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Field of View: ${quality?.fieldOfView.status ?? "ADEQUATE"}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 4. AI RETINOPATHY CLASSIFICATION
              pw.Text(
                '2. AI RETINOPATHY CLASSIFICATION',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: isReferable ? PdfColors.red50 : PdfColors.green50,
                  border: pw.Border.all(
                    color: isReferable ? PdfColors.red300 : PdfColors.green300,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          pred != null
                              ? 'Level ${pred.drLevel}: ${severity?.fullName ?? pred.severityLabel}'
                              : 'AI Prediction Blocked (Ungradable Image Quality)',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: isReferable ? PdfColors.red900 : PdfColors.green900,
                          ),
                        ),
                        if (pred != null)
                          pw.Text(
                            'Model Probability: ${AppFormatters.formatProbability(pred.modelProbability)}',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Clinical Recommendation: ${pred?.recommendation ?? "Recapture retinal fundus photograph."}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 5. CLINICIAN DECISION RECORD
              pw.Text(
                '3. CLINICIAN REVIEW & AUDIT LOG',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: review != null ? PdfColors.blue50 : PdfColors.amber50,
                  border: pw.Border.all(
                    color: review != null ? PdfColors.blue300 : PdfColors.amber300,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: review != null
                    ? pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Status: ${review.action.label.toUpperCase()}',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900)),
                              pw.Text('Reviewer: ${review.clinicianName ?? "Authorized Ophthalmologist"}',
                                  style: const pw.TextStyle(fontSize: 9.5)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Clinical Notes: ${review.clinicalNotes}',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 2),
                          pw.Text('Timestamp: ${AppFormatters.formatDateTime(review.reviewedAt)}',
                              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        ],
                      )
                    : pw.Row(
                        children: [
                          pw.Text(
                            'Status: AI TRIAGE (Awaiting Ophthalmologist Review & Confirmation)',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9.5,
                              color: PdfColors.amber900,
                            ),
                          ),
                        ],
                      ),
              ),
              pw.SizedBox(height: 12),

              // 6. MODEL TRACEABILITY
              pw.Text(
                '4. MODEL PROVENANCE & TRACEABILITY',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Architecture: ResNet-18 (Transfer Learning) | Training Dataset: APTOS 2019 Blindness Detection | Target Layer: layer4[1].conv2',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),

              pw.Spacer(),

              // 7. REGULATORY DISCLAIMER
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  AppConstants.standardDisclaimer,
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfInfoCol(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 1),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static Future<void> printReport(ScreeningCaseModel screeningCase) async {
    final pdfData = await generatePdfReport(screeningCase);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Drishti_Report_${screeningCase.screeningId}.pdf',
    );
  }

  static Future<void> shareReport(ScreeningCaseModel screeningCase) async {
    final pdfData = await generatePdfReport(screeningCase);
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Drishti_Report_${screeningCase.screeningId}.pdf',
    );
  }
}

