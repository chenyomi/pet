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

  static const Map<String, List<String>> _bodies = {
    'egg': [
      '................',
      '......xxxx......',
      '....xxxxxxxx....',
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
      '....xxxxxxxx....',
      '......xxxx......',
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
  };

  static const Map<String, List<Offset>> _traits = {
    'cheek': [Offset(3, 8), Offset(12, 8)],
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
        if (bodyRows[y][x] != 'x') continue;
        final rect = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        final color = y < 5
            ? Color.lerp(primary, Colors.white, 0.18)!
            : y > 10
                ? secondary
                : primary;
        canvas.drawRect(rect, Paint()..color = color);
      }
    }

    for (final trait in species.traits) {
      final points = PixelPet._traits[trait] ?? const <Offset>[];
      final traitColor = trait == 'cheek' ? cheek : secondary;
      for (final point in points) {
        _drawCell(canvas, point.dx.toInt(), point.dy.toInt(), cell, traitColor);
      }
    }

    for (final point in _facePoints(species.face, mood)) {
      _drawCell(canvas, point.dx.toInt(), point.dy.toInt(), cell, ink);
    }
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
