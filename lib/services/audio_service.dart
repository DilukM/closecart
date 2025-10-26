import 'package:audioplayers/audioplayers.dart';

/// Service for handling audio playback in the app
class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  /// Play the alarm sound
  static Future<void> playAlarm() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    }

    try {
      _isPlaying = true;
      final source = AssetSource('alarm.mp3');
      await _audioPlayer.play(source);

      // Automatically stop after 5 seconds to prevent continuous playback
      Future.delayed(const Duration(seconds: 5), () {
        if (_isPlaying) {
          _audioPlayer.stop();
          _isPlaying = false;
        }
      });
    } catch (e) {
      print('Error playing alarm sound: $e');
      _isPlaying = false;
    }
  }

  /// Stop the alarm sound
  static Future<void> stopAlarm() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      _isPlaying = false;
    }
  }

  /// Dispose the audio player (call this when the app is closing)
  static void dispose() {
    _audioPlayer.dispose();
    _isPlaying = false;
  }
}
