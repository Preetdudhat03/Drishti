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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EyeXpert Screening Report',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900,
                        ),
                      ),
                      pw.Text(
                        'Explainable AI Diabetic Retinopathy Screening',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: isReferable ? PdfColors.red50 : PdfColors.green50,
                      border: pw.Border.all(
                        color: isReferable ? PdfColors.red800 : PdfColors.green800,
                      ),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      isReferable ? 'REFERABLE DR — YES' : 'NON-REFERABLE',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: isReferable ? PdfColors.red900 : PdfColors.green900,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),

              // Patient & Session Info Table
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfInfoCol('Patient ID', screeningCase.patient.patientId),
                    _pdfInfoCol('Screening ID', screeningCase.screeningId),
                    _pdfInfoCol('Eye Evaluated', AppFormatters.formatEye(screeningCase.patient.eye)),
                    _pdfInfoCol('Date', AppFormatters.formatDateTime(screeningCase.createdAt)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Image Quality Section
              pw.Text('1. Image Quality Assessment',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Overall Status: ${quality?.status.label ?? "N/A"} (${AppFormatters.formatPercentage(quality?.overallScore)})'),
                  pw.Text('Focus: ${quality?.sharpness.status ?? "N/A"}'),
                  pw.Text('Illumination: ${quality?.illumination.status ?? "N/A"}'),
                  pw.Text('Retinal Field: ${quality?.fieldOfView.status ?? "N/A"}'),
                ],
              ),
              pw.SizedBox(height: 14),

              // AI Screening Result Section
              pw.Text('2. AI Screening Result',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          pred != null
                              ? 'Level ${pred.drLevel} — ${pred.severityLabel}'
                              : 'AI Prediction Blocked (Ungradable Quality)',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                        ),
                        if (pred != null)
                          pw.Text(
                            'Model Probability: ${AppFormatters.formatProbability(pred.modelProbability)}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Recommendation: ${pred?.recommendation ?? "Recapture retinal image."}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Clinician Review Section
              pw.Text('3. Clinician Final Decision',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: review != null ? PdfColors.blue50 : PdfColors.amber50,
                  border: pw.Border.all(
                      color: review != null ? PdfColors.blue300 : PdfColors.amber300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: review != null
                    ? pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Action: ${review.action.label}',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
                              pw.Text('Reviewer: ${review.clinicianName ?? "Ophthalmologist"}',
                                  style: const pw.TextStyle(fontSize: 10)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Clinical Notes: ${review.clinicalNotes}',
                              style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 2),
                          pw.Text('Reviewed At: ${AppFormatters.formatDateTime(review.reviewedAt)}',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                      )
                    : pw.Text(
                        'Human Validation State: PENDING OPHTHALMOLOGIST REVIEW',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: PdfColors.amber900),
                      ),
              ),
              pw.SizedBox(height: 14),

              // Model Provenance
              pw.Text('4. Model Provenance & Traceability',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 2),
              pw.Text(
                'Model: EyeXpert DR Classifier (ResNet-18) | Dataset: APTOS 2019 Blindness Detection | Target Layer: layer4[1].conv2',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),

              pw.Spacer(),

              // Statutory Disclaimer
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
      crossContent: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static Future<void> printReport(ScreeningCaseModel screeningCase) async {
    final pdfData = await generatePdfReport(screeningCase);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'EyeXpert_Report_${screeningCase.screeningId}.pdf',
    );
  }

  static Future<void> shareReport(ScreeningCaseModel screeningCase) async {
    final pdfData = await generatePdfReport(screeningCase);
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'EyeXpert_Report_${screeningCase.screeningId}.pdf',
    );
  }
}
