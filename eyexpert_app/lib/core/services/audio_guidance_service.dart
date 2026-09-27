import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAudioPrefKey = 'drishti_audio_guidance_enabled';

class AudioGuidanceNotifier extends StateNotifier<bool> {
  AudioGuidanceNotifier() : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_kAudioPrefKey) ?? true;
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAudioPrefKey, state);
    } catch (_) {}
  }
}

final audioGuidanceEnabledProvider = StateNotifierProvider<AudioGuidanceNotifier, bool>((ref) {
  return AudioGuidanceNotifier();
});

class AudioCueState {
  final String text;
  final String? hindiText;
  final DateTime timestamp;

  const AudioCueState({
    required this.text,
    this.hindiText,
    required this.timestamp,
  });
}

class AudioCueNotifier extends StateNotifier<AudioCueState?> {
  AudioCueNotifier() : super(null);

  void announce({required String text, String? hindiText}) {
    state = AudioCueState(
      text: text,
      hindiText: hindiText,
      timestamp: DateTime.now(),
    );
  }

  void clear() {
    state = null;
  }
}

final activeAudioCueProvider = StateNotifierProvider<AudioCueNotifier, AudioCueState?>((ref) {
  return AudioCueNotifier();
});

class AudioGuidanceService {
  static void promptReticleFraming(WidgetRef ref, String lang) {
    final enabled = ref.read(audioGuidanceEnabledProvider);
    if (!enabled) return;

    if (lang == 'hi') {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'आंख को कैमरे के केंद्र में रखें और स्थिर रहें।',
        hindiText: 'Center the patient’s eye inside the reticle ring and hold steady.',
      );
    } else {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'Center the patient’s eye inside the reticle ring and hold steady.',
        hindiText: 'आंख को केंद्र में रखें और स्थिर रहें।',
      );
    }
  }

  static void promptQualityChecking(WidgetRef ref, String lang) {
    final enabled = ref.read(audioGuidanceEnabledProvider);
    if (!enabled) return;

    if (lang == 'hi') {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'फोटो की स्पष्टता और प्रकाश की जांच की जा रही है...',
        hindiText: 'Evaluating optical focus, illumination, and retinal coverage...',
      );
    } else {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'Evaluating optical focus, illumination, and retinal coverage...',
        hindiText: 'फोटो की स्पष्टता और प्रकाश की जांच की जा रही है...',
      );
    }
  }

  static void promptQualityPass(WidgetRef ref, String lang) {
    final enabled = ref.read(audioGuidanceEnabledProvider);
    if (!enabled) return;

    if (lang == 'hi') {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'चित्र गुणवत्ता स्वीकृत! अब एआई विश्लेषण के लिए तैयार है।',
        hindiText: 'Image quality check passed. Retinal FOV is clear for AI analysis.',
      );
    } else {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'Image quality check passed. Retinal FOV is clear for AI analysis.',
        hindiText: 'चित्र गुणवत्ता स्वीकृत! अब एआई विश्लेषण के लिए तैयार है।',
      );
    }
  }

  static void promptQualityFail(WidgetRef ref, String lang) {
    final enabled = ref.read(audioGuidanceEnabledProvider);
    if (!enabled) return;

    if (lang == 'hi') {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'चित्र धुंधला है या प्रकाश कम है। मरीज की सुरक्षा के लिए दोबारा फोटो लें।',
        hindiText: 'Image blur detected. Please steady the camera and recapture.',
      );
    } else {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'Image blur detected. Please steady the camera and recapture.',
        hindiText: 'चित्र धुंधला है। कृपया दोबारा स्पष्ट फोटो लें।',
      );
    }
  }

  static void promptAiResult(WidgetRef ref, int drLevel, bool isReferable, String lang) {
    final enabled = ref.read(audioGuidanceEnabledProvider);
    if (!enabled) return;

    if (isReferable) {
      if (lang == 'hi') {
        ref.read(activeAudioCueProvider.notifier).announce(
          text: 'चेतावनी: रेटिना में क्षति पाई गई है। नेत्र विशेषज्ञ से 15 दिनों में संपर्क करें।',
          hindiText: 'Referral Required: Sight-threatening lesions detected. Consult doctor.',
        );
      } else {
        ref.read(activeAudioCueProvider.notifier).announce(
          text: 'Referral Required: Sight-threatening lesions detected. Consult doctor.',
          hindiText: 'चेतावनी: रेटिना में क्षति पाई गई है। डॉक्टर से मिलें।',
        );
      }
    } else {
      if (lang == 'hi') {
        ref.read(activeAudioCueProvider.notifier).announce(
          text: 'जांच सामान्य है। दृष्टि सुरक्षित है। अगले वर्ष नियमित जांच कराएं।',
          hindiText: 'Screening normal. No sight-threatening retinopathy. Annual check recommended.',
        );
      } else {
        ref.read(activeAudioCueProvider.notifier).announce(
          text: 'Screening normal. No sight-threatening retinopathy. Annual check recommended.',
          hindiText: 'जांच सामान्य है। अगले वर्ष नियमित जांच कराएं।',
        );
      }
    }
  }
}
