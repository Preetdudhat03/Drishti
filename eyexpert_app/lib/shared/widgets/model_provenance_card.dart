import 'package:flutter/material.dart';
import '../../data/models/dr_prediction_model.dart';
import '../../core/theme/app_colors.dart';

class ModelProvenanceCard extends StatelessWidget {
  final ModelProvenanceModel provenance;

  const ModelProvenanceCard({super.key, required this.provenance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory_rounded, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              const Text(
                'AI Model Provenance & Architecture',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  provenance.modelVersion,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _provenanceRow('Architecture', provenance.architecture),
          _provenanceRow('Training Dataset', provenance.trainingDataset),
          _provenanceRow('Target Layer (XAI)', 'layer4[1].conv2 (ResNet-18)'),
          _provenanceRow('Validation Benchmark', 'Held-out Stratified Test Set (QWK: 0.870, AUC: 0.980)'),
        ],
      ),
    );
  }

  Widget _provenanceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
