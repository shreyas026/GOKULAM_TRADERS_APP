import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  final size = 1024;
  final image = img.Image(width: size, height: size);

  img.fill(image, color: img.ColorRgb8(0x1B, 0x5E, 0x20));

  _drawGear(image, size ~/ 2, size ~/ 2, 340, 280, 12, img.ColorRgb8(0x2E, 0x7D, 0x32));

  _fillCircle(image, size ~/ 2, size ~/ 2, 200, img.ColorRgb8(0x2E, 0x7D, 0x32));
  _fillCircle(image, size ~/ 2, size ~/ 2, 160, img.ColorRgb8(0x38, 0x8E, 0x3C));

  _drawText(image, 'GT', size ~/ 2, size ~/ 2 - 20, img.ColorRgb8(0xFF, 0xFF, 0xFF), 180, bold: true);

  _drawText(image, 'SMART HARDWARE', size ~/ 2, size ~/ 2 + 160, img.ColorRgb8(0xFF, 0xFF, 0xFF), 38);

  final dir = Directory('assets/images');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  File('assets/images/app_icon.png').writeAsBytesSync(img.encodePng(image));
  print('Icon saved to assets/images/app_icon.png (${File('assets/images/app_icon.png').lengthSync()} bytes)');
}

void _fillCircle(img.Image image, int cx, int cy, int radius, img.Color color) {
  for (int y = cy - radius; y <= cy + radius; y++) {
    for (int x = cx - radius; x <= cx + radius; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        final dx = x - cx;
        final dy = y - cy;
        if (dx * dx + dy * dy <= radius * radius) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}

void _drawGear(img.Image image, int cx, int cy, int outerRadius, int innerRadius, int teeth, img.Color color) {
  for (int angle = 0; angle < 360; angle++) {
    final toothAngle = (angle % (360 ~/ teeth)).toDouble();
    final toothWidth = 360.0 / teeth;
    final inTooth = toothAngle > toothWidth * 0.25 && toothAngle < toothWidth * 0.75;
    final r = inTooth ? outerRadius : innerRadius;
    final rad = angle * pi / 180;
    final x = cx + (r * cos(rad)).toInt();
    final y = cy + (r * sin(rad)).toInt();
    if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
      image.setPixel(x, y, color);
    }
    for (int rr = (inTooth ? innerRadius : innerRadius - 40); rr <= r; rr++) {
      final xx = cx + (rr * cos(rad)).toInt();
      final yy = cy + (rr * sin(rad)).toInt();
      if (xx >= 0 && xx < image.width && yy >= 0 && yy < image.height) {
        image.setPixel(xx, yy, color);
      }
    }
  }
}

void _drawText(img.Image image, String text, int cx, int cy, img.Color color, int fontSize, {bool bold = false}) {
  final int charWidth = (fontSize * 0.65).toInt();
  final int charHeight = (fontSize * 1.2).toInt();
  final totalWidth = text.length * charWidth;
  final startX = cx - totalWidth ~/ 2;
  final startY = cy - charHeight ~/ 2;

  for (int i = 0; i < text.length; i++) {
    final charX = startX + i * charWidth;
    _drawLetter(image, text[i], charX, startY, charWidth, charHeight, color);
  }
}

void _drawLetter(img.Image image, String letter, int x, int y, int w, int h, img.Color color) {
  final patterns = <String, List<String>>{
    'G': ['######', '##', '## ##', '## ##', '## ##', '##  ##', '######'],
    'T': ['######', '  ##  ', '  ##  ', '  ##  ', '  ##  ', '  ##  ', '  ##  '],
    'S': ['######', '##', '##', '######', '   ##', '   ##', '######'],
    'M': ['##  ##', '####', '####', '## ##', '## ##', '## ##', '## ##'],
    'H': ['## ##', '## ##', '## ##', '######', '## ##', '## ##', '## ##'],
    'A': ['  ##  ', ' ## ##', '##   ##', '#######', '##   ##', '##   ##', '##   ##'],
    'R': ['####', '## ##', '## ##', '####', '## ##', '## ##', '## ##'],
    'W': ['##   ##', '##   ##', '##   ##', '## # ##', '####', '####', '##   ##'],
    ' ': ['    ', '    ', '    ', '    ', '    ', '    ', '    '],
    'E': ['######', '##', '##', '####', '##', '##', '######'],
    'I': ['######', '  ##  ', '  ##  ', '  ##  ', '  ##  ', '  ##  ', '######'],
    'L': ['##', '##', '##', '##', '##', '##', '######'],
    'D': ['####', '## ##', '## ##', '## ##', '## ##', '## ##', '####'],
    'C': ['######', '##', '##', '##', '##', '##', '######'],
    'K': ['## ##', '## #', '## #', '###', '## #', '## #', '## ##'],
    'O': [' ####', '##  ##', '##  ##', '##  ##', '##  ##', '##  ##', ' ####'],
    'P': ['####', '## ##', '## ##', '####', '##', '##', '##'],
    'N': ['##  ##', '### ##', '####', '## ###', '##  ##', '##  ##', '##  ##'],
  };

  final pattern = patterns[letter.toUpperCase()] ?? patterns[' ']!;
  final dotW = w ~/ (pattern.isNotEmpty ? pattern[0].length : 6);
  final dotH = h ~/ (pattern.isNotEmpty ? pattern.length : 7);

  for (int row = 0; row < pattern.length; row++) {
    for (int col = 0; col < pattern[row].length; col++) {
      if (pattern[row][col] == '#') {
        for (int dy = 0; dy < dotH; dy++) {
          for (int dx = 0; dx < dotW; dx++) {
            final px = x + col * dotW + dx;
            final py = y + row * dotH + dy;
            if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
              image.setPixel(px, py, color);
            }
          }
        }
      }
    }
  }
}
