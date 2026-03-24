import 'package:audioplayers/audioplayers.dart';

import 'note_library.dart';

class NotePlayer {
  NotePlayer() {
    _player.setPlayerMode(PlayerMode.lowLatency);
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> play(NotePitch note) async {
    await _player.stop();
    await _player.play(AssetSource(note.assetName));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
