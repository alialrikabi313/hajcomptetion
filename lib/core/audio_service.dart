import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'constants.dart';

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  bool _initialized = false;

  late final AudioPlayer _pCorrect;
  late final AudioPlayer _pWrong;
  late final AudioPlayer _pLevelUp;

  Future<void> init() async {
    if (_initialized) return;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.ambient, // لا يكسر صوت النظام
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: AndroidAudioUsage.game,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: false,
    ));

    _pCorrect = AudioPlayer();
    _pWrong = AudioPlayer();
    _pLevelUp = AudioPlayer();

    // تحميل الأصول مرة واحدة (Preload)
    await _pCorrect.setAsset(K.sfxCorrect);
    await _pWrong.setAsset(K.sfxWrong);
    await _pLevelUp.setAsset(K.sfxLevelUp);

    _pCorrect.setVolume(1.0);
    _pWrong.setVolume(1.0);
    _pLevelUp.setVolume(1.0);

    _initialized = true;
  }

  Future<void> play(String assetPath) async {
    await init();
    try {
      if (assetPath == K.sfxCorrect) {
        await _pCorrect.seek(Duration.zero);
        await _pCorrect.play();
      } else if (assetPath == K.sfxWrong) {
        await _pWrong.seek(Duration.zero);
        await _pWrong.play();
      } else if (assetPath == K.sfxLevelUp) {
        await _pLevelUp.seek(Duration.zero);
        await _pLevelUp.play();
      } else {
        // احتياط: تشغيل أي أصل آخر بلاير مؤقت
        final p = AudioPlayer();
        await p.setAsset(assetPath);
        await p.play();
        await p.dispose();
      }
    } catch (e) {
      // لا نقطع التجربة إن فشل الصوت
      // print('Audio error: $e');
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await _pCorrect.dispose();
    await _pWrong.dispose();
    await _pLevelUp.dispose();
    _initialized = false;
  }
}
