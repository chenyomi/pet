import 'package:flutter/material.dart';

import '../models/pet_state.dart';

class PixelPet extends StatelessWidget {
  const PixelPet({
    super.key,
    required this.species,
    required this.mood,
    this.size = 240,
  });

  final PetSpecies species;
  final PetMood mood;
  final double size;

  static const Map<String, String> _pixellabSouthAssetBySpeciesId = {
    'egg': 'assets/pixellab/official_line/egg.png',
    'bubble': 'assets/pixellab/official_line/baby.png',
    'sunbit': 'assets/pixellab/official_line/rookie.png',
    'halo': 'assets/pixellab/official_line/ultimate.png',
  };

  static const Map<String, List<String>> _bodies = {
    'egg': [
      '................',
      '......iiii......',
      '....iibbbbii....',
      '...iibbbbbbii...',
      '..iibbbbbbbbii..',
      '..ixbbbbbbbbxi..',
      '.iixbbbbssbbxii.',
      '.iixbbssbbssxii.',
      '.iixbssbbbbsxii.',
      '.iixssbbbbssxii.',
      '..ixsbbbbbbsxi..',
      '...iixbbbbii....',
      '....iixxxii.....',
      '......iiii......',
      '................',
      '................',
    ],
    'blob': [
      '................',
      '.....xxxxxx.....',
      '...xxxxxxxxxx...',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxx..',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxx..',
      '...xxxxxxxxxx...',
      '....xx....xx....',
      '...xx......xx...',
      '................',
      '................',
    ],
    'cat': [
      '...xx......xx...',
      '..xxxx....xxxx..',
      '..xxxxxxxxxxxx..',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxx..',
      '...xxxxxxxxxx...',
      '...xxxxxxxxxx...',
      '....xx....xx....',
      '...xx......xx...',
      '..xx........xx..',
      '................',
      '................',
    ],
    'dragon': [
      '......xx........',
      '....xxxxxx......',
      '..xxxxxxxxxx....',
      '..xxxxxxxxxxxx..',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxxxx',
      '...xxxxxxxxxxxxx',
      '....xxxxxxxxxxx.',
      '....xxxxxxxxxx..',
      '...xx..xx..xx...',
      '..xx...xx...xx..',
      '................',
      '................',
    ],
    'seed': [
      '.......xx.......',
      '......xxxx......',
      '.....xxxxxx.....',
      '...xxxxxxxxxx...',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxx..',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxx..',
      '...xxxxxxxxxx...',
      '....xx....xx....',
      '...xx......xx...',
      '................',
      '................',
    ],
    'bird': [
      '.......xx.......',
      '.....xxxxxx.....',
      '...xxxxxxxxxx...',
      '..xxxxxxxxxxxx..',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxx..',
      '...xxxxxxxxxx...',
      '...xxxxxxxxxx...',
      '....xxxxxxxx....',
      '...xx..xx..xx...',
      '..xx...xx...xx..',
      '................',
      '................',
    ],
    'golem': [
      '...xx......xx...',
      '..xxxx....xxxx..',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxx..',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxx..',
      '..xxxx....xxxx..',
      '..xxxx....xxxx..',
      '..xx........xx..',
      '................',
      '................',
    ],
    'ghost': [
      '.....xxxxxx.....',
      '...xxxxxxxxxx...',
      '..xxxxxxxxxxxx..',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '.xxxxxxxxxxxxxx.',
      '..xxxxxxxxxxxx..',
      '..xxxxxxxxxxxx..',
      '...xxxxxxxxxx...',
      '...xxxxxxxxxx...',
      '..xx..xx..xx....',
      '.xx..xx..xx.....',
      '................',
      '................',
      '................',
    ],
    'flame_baby': [
      '......ss........',
      '.....sxxs.......',
      '....ixxxxi......',
      '...ixbbbbxi.....',
      '..iixbbbbxxii...',
      '..ixxbbbbxxxi...',
      '..ixxxxxssxxi...',
      '..ixxxxxxxxxi...',
      '...ixxxiixxxi...',
      '...ix......xi...',
      '..ii......ii....',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
    'flame_rookie': [
      '....sii..iis....',
      '...isxxiixxsi...',
      '..isxxxxxxxxsi..',
      '.isxxxxbbbxxxxsi',
      '.ixxxxxbbbxxxxi.',
      '.ixxxxxxxssxxxi.',
      '..ixxxxxxxxxxi..',
      '..ixxxxiixxxxi..',
      '..sxi......ixs..',
      '...ii......ii...',
      '...i........i...',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
    'flame_champion': [
      '..sii......iis..',
      '.isxxii..iixxsi.',
      'isxxxxxxxxxxxxsi',
      'ixxxxbbbbbbxxxxi',
      'ixxxxxbbbbxxxxxi',
      '.ixxxxssssssxxi.',
      '..ixxxxxxxxxxi..',
      '..sxxxiiiixxxs..',
      '.ssxi......ixss.',
      '.ii........ii...',
      '..i........i....',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
    'star_baby': [
      '......ss........',
      '.....sxxs.......',
      '....ixxxxi......',
      '...isxbbxsi.....',
      '...ixxbbbxxi....',
      '..isxxbbxxsi....',
      '..sxxxxxxxxs....',
      '...sxxiixxs.....',
      '....i......i....',
      '...ii......ii...',
      '................',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
    'star_rookie': [
      '....ss....ss....',
      '...isxi..ixsi...',
      '..isxxxiixxxsi..',
      '.isxxxxbbxxxxsi.',
      '.ixxxxxbbbxxxxi.',
      '..ixxxxbbbbxxi..',
      '..sxxxxxxxxxxs..',
      '...sxxxiixxxs...',
      '....ii....ii....',
      '...ii......ii...',
      '................',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
    'shade_baby': [
      '.......s........',
      '......isi.......',
      '....iixxxii.....',
      '...ixxxxxxxi....',
      '..ixxbbbbxxi....',
      '..ixxxxxxxxi....',
      '..ixxxxxxxxi....',
      '...ixxxxxxi.....',
      '...sxx..xxs.....',
      '..sxx....xxs....',
      '................',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
    'shade_rookie': [
      '.....s....s.....',
      '...isxi..ixsi...',
      '..isxxxxxxsi....',
      '..ixxbbbbxxi....',
      '.ixxxxxxxxxxxi..',
      '.ixxxxxxxxxxxi..',
      '..ixxx....xxxi..',
      '..sxxs....sxxs..',
      '.sxx........xxs.',
      '................',
      '................',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
    'shade_champion': [
      '...s........s...',
      '.isxi......ixsi.',
      'isxxxxi..ixxxxsi',
      '.ixxxxxxbbxxxxi.',
      '.ixxxxxxxxxxxxi.',
      '..ixxxxxxxxxxi..',
      '..sxxx....xxxs..',
      '.sxxs......sxxs.',
      'sxx..........xxs',
      '................',
      '................',
      '................',
      '................',
      '................',
      '................',
      '................',
    ],
  };

  static const Map<String, List<Offset>> _traits = {
    'cheek': [Offset(3, 8), Offset(12, 8)],
    'crack': [
      Offset(6, 3),
      Offset(7, 4),
      Offset(8, 5),
      Offset(9, 6),
      Offset(10, 7),
      Offset(9, 8),
    ],
    'horn': [Offset(4, 2), Offset(11, 2)],
    'wing': [
      Offset(1, 7),
      Offset(2, 7),
      Offset(13, 7),
      Offset(14, 7),
      Offset(1, 8),
      Offset(14, 8),
    ],
    'leaf': [Offset(7, 0), Offset(6, 1), Offset(7, 1), Offset(8, 1)],
    'tail': [Offset(12, 10), Offset(13, 10), Offset(14, 11)],
    'armor': [
      Offset(4, 4),
      Offset(5, 4),
      Offset(10, 4),
      Offset(11, 4),
      Offset(6, 11),
      Offset(9, 11),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final pixellabAsset = _pixellabSouthAssetBySpeciesId[species.id];
    if (pixellabAsset != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          pixellabAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelPetPainter(species: species, mood: mood),
      ),
    );
  }
}

class _PixelPetPainter extends CustomPainter {
  const _PixelPetPainter({
    required this.species,
    required this.mood,
  });

  final PetSpecies species;
  final PetMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    const columns = 16;
    const rows = 16;
    final cell = size.width / columns;
    final bodyRows = PixelPet._bodies[species.body]!;

    final primary = Color(species.primary);
    final secondary = Color(species.secondary);
    const ink = Color(0xFF20363A);
    final cheek = const Color(0xFFFF9CB8).withValues(alpha: 0.75);

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final symbol = bodyRows[y][x];
        if (symbol == '.') continue;
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        final color = _colorForSymbol(
          symbol,
          x,
          y,
          bodyRows,
          primary,
          secondary,
          ink,
        );
        canvas.drawRect(rect, Paint()..color = color);
      }
    }

    for (final trait in species.traits) {
      final points = PixelPet._traits[trait] ?? const <Offset>[];
      final traitColor = switch (trait) {
        'cheek' => cheek,
        'crack' => secondary,
        _ => secondary,
      };
      for (final point in points) {
        _drawCell(canvas, point.dx.toInt(), point.dy.toInt(), cell, traitColor);
      }
    }

    for (final point in _facePoints(species.face, mood)) {
      _drawCell(canvas, point.dx.toInt(), point.dy.toInt(), cell, ink);
    }
  }

  Color _colorForSymbol(
    String symbol,
    int x,
    int y,
    List<String> rows,
    Color primary,
    Color secondary,
    Color ink,
  ) {
    final isSolid = symbol != '.';
    final outlined = isSolid && _isOutlineCell(rows, x, y);
    if (outlined) return ink;

    return switch (symbol) {
      'x' => y < 5
          ? Color.lerp(primary, Colors.white, 0.18)!
          : y > 10
              ? secondary
              : _isBellyZone(x, y)
                  ? Color.lerp(primary, Colors.white, 0.52)!
                  : primary,
      's' => secondary,
      'b' => Color.lerp(primary, Colors.white, 0.72)!,
      'i' => ink,
      _ => primary,
    };
  }

  bool _isBellyZone(int x, int y) {
    return x >= 5 && x <= 10 && y >= 6 && y <= 10;
  }

  bool _isOutlineCell(List<String> rows, int x, int y) {
    bool solidAt(int px, int py) {
      if (py < 0 || py >= rows.length) return false;
      if (px < 0 || px >= rows[py].length) return false;
      return rows[py][px] != '.';
    }

    // 4-neighbor contour gives a clean pixel outline for legacy bodies.
    return !solidAt(x - 1, y) || !solidAt(x + 1, y) || !solidAt(x, y - 1) || !solidAt(x, y + 1);
  }

  List<Offset> _facePoints(String face, PetMood mood) {
    switch (mood) {
      case PetMood.sleepy:
        return const [
          Offset(4, 6),
          Offset(5, 6),
          Offset(10, 6),
          Offset(11, 6),
          Offset(6, 9),
          Offset(7, 9),
          Offset(8, 9),
          Offset(9, 9),
        ];
      case PetMood.battle:
        return const [
          Offset(4, 5),
          Offset(5, 6),
          Offset(10, 6),
          Offset(11, 5),
          Offset(6, 9),
          Offset(7, 9),
          Offset(8, 9),
          Offset(9, 9),
          Offset(7, 10),
          Offset(8, 10),
        ];
      case PetMood.sick:
      case PetMood.sad:
        return const [
          Offset(5, 6),
          Offset(10, 6),
          Offset(6, 9),
          Offset(7, 9),
          Offset(8, 9),
          Offset(9, 9),
        ];
      case PetMood.happy:
        return const [
          Offset(4, 6),
          Offset(5, 7),
          Offset(10, 7),
          Offset(11, 6),
          Offset(6, 9),
          Offset(7, 10),
          Offset(8, 10),
          Offset(9, 9),
        ];
      case PetMood.idle:
        break;
    }

    switch (face) {
      case 'wide':
        return const [
          Offset(4, 6),
          Offset(5, 6),
          Offset(10, 6),
          Offset(11, 6),
          Offset(6, 9),
          Offset(7, 10),
          Offset(8, 10),
          Offset(9, 9),
        ];
      case 'joy':
        return const [
          Offset(4, 6),
          Offset(5, 7),
          Offset(10, 7),
          Offset(11, 6),
          Offset(6, 9),
          Offset(7, 10),
          Offset(8, 10),
          Offset(9, 9),
        ];
      case 'angry':
        return const [
          Offset(4, 5),
          Offset(5, 6),
          Offset(10, 6),
          Offset(11, 5),
          Offset(6, 9),
          Offset(7, 9),
          Offset(8, 9),
          Offset(9, 9),
          Offset(7, 10),
          Offset(8, 10),
        ];
      case 'flat':
        return const [
          Offset(5, 6),
          Offset(10, 6),
          Offset(6, 9),
          Offset(7, 9),
          Offset(8, 9),
          Offset(9, 9),
        ];
      case 'smile':
        return const [
          Offset(5, 6),
          Offset(10, 6),
          Offset(6, 9),
          Offset(7, 10),
          Offset(8, 10),
          Offset(9, 9),
        ];
      default:
        return const [
          Offset(5, 6),
          Offset(10, 6),
          Offset(6, 9),
          Offset(7, 9),
          Offset(8, 9),
          Offset(9, 9),
        ];
    }
  }

  void _drawCell(Canvas canvas, int x, int y, double cell, Color color) {
    canvas.drawRect(
      Rect.fromLTWH(x * cell, y * cell, cell, cell),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelPetPainter oldDelegate) {
    return oldDelegate.species != species || oldDelegate.mood != mood;
  }
}
