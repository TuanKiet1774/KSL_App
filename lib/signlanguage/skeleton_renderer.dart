import 'package:image/image.dart' as img;
import 'dart:typed_data';

class HandLandmark {
  final double x; // Normalized [0, 1]
  final double y; // Normalized [0, 1]
  final double z; // Depth (không dùng cho 2D)

  const HandLandmark({required this.x, required this.y, this.z = 0.0});
}

class SkeletonRenderer {
  static const int canvasSize = 224;

  // MediaPipe HAND_CONNECTIONS — 21 landmarks, các cạnh kết nối
  static const List<List<int>> handConnections = [
    // Ngón cái (Thumb)
    [0, 1], [1, 2], [2, 3], [3, 4],
    // Ngón trỏ (Index)
    [0, 5], [5, 6], [6, 7], [7, 8],
    // Ngón giữa (Middle)
    [0, 9], [9, 10], [10, 11], [11, 12],
    // Ngón áp út (Ring)
    [0, 13], [13, 14], [14, 15], [15, 16],
    // Ngón út (Pinky)
    [0, 17], [17, 18], [18, 19], [19, 20],
    // Lòng bàn tay (Palm)
    [5, 9], [9, 13], [13, 17],
  ];

  /// Vẽ skeleton từ danh sách 21 landmarks
  ///
  /// [landmarks]: 21 HandLandmark, x/y normalized [0,1]
  /// [padding]: padding % để tránh landmark quá sát viền (default 0.05)
  ///
  /// Trả về img.Image 224×224 RGB (grayscale thực chất — R=G=B)
  static img.Image render(
      List<HandLandmark> landmarks, {
        double padding = 0.05,
      }) {
    // Tạo canvas đen 224×224
    final canvas = img.Image(width: canvasSize, height: canvasSize);
    img.fill(canvas, color: img.ColorRgb8(0, 0, 0));

    if (landmarks.length < 21) return canvas;

    // ── Normalize landmarks để bàn tay nằm vừa trong canvas ─────────────
    // Tính bounding box của landmarks
    double minX = landmarks.map((l) => l.x).reduce((a, b) => a < b ? a : b);
    double maxX = landmarks.map((l) => l.x).reduce((a, b) => a > b ? a : b);
    double minY = landmarks.map((l) => l.y).reduce((a, b) => a < b ? a : b);
    double maxY = landmarks.map((l) => l.y).reduce((a, b) => a > b ? a : b);

    final rangeX = (maxX - minX).clamp(0.001, double.infinity);
    final rangeY = (maxY - minY).clamp(0.001, double.infinity);
    final scale  = (1.0 - 2 * padding) / [rangeX, rangeY].reduce((a, b) => a > b ? a : b);

    // Convert về pixel coordinates với centering
    List<List<int>> points = landmarks.map((lm) {
      final nx = (lm.x - minX) * scale + padding + (1.0 - 2*padding - rangeX * scale) / 2;
      final ny = (lm.y - minY) * scale + padding + (1.0 - 2*padding - rangeY * scale) / 2;
      return [
        (nx * canvasSize).clamp(0, canvasSize - 1).toInt(),
        (ny * canvasSize).clamp(0, canvasSize - 1).toInt(),
      ];
    }).toList();

    // ── Vẽ connections (đường trắng) ────────────────────────────────────
    final lineColor = img.ColorRgb8(255, 255, 255);
    for (final conn in handConnections) {
      final p1 = points[conn[0]];
      final p2 = points[conn[1]];
      _drawLine(canvas, p1[0], p1[1], p2[0], p2[1], lineColor, thickness: 2);
    }

    // ── Vẽ landmark points (chấm tròn xám) ──────────────────────────────
    final dotColor = img.ColorRgb8(180, 180, 180);
    for (final p in points) {
      img.fillCircle(canvas,
        x: p[0], y: p[1], radius: 3,
        color: dotColor,
      );
    }

    return canvas;
  }

  /// Vẽ đường thẳng với độ dày tùy chỉnh (Bresenham + thickness)
  static void _drawLine(
      img.Image canvas,
      int x1, int y1, int x2, int y2,
      img.Color color, {
        int thickness = 2,
      }) {
    // Vẽ nhiều đường song song để tạo độ dày
    final half = thickness ~/ 2;
    for (int t = -half; t <= half; t++) {
      // Perpendicular offset
      final dx = (x2 - x1).abs();
      final dy = (y2 - y1).abs();
      if (dx >= dy) {
        // Horizontal dominant — offset theo Y
        img.drawLine(canvas,
          x1: x1, y1: (y1 + t).clamp(0, canvasSize - 1),
          x2: x2, y2: (y2 + t).clamp(0, canvasSize - 1),
          color: color,
        );
      } else {
        // Vertical dominant — offset theo X
        img.drawLine(canvas,
          x1: (x1 + t).clamp(0, canvasSize - 1), y1: y1,
          x2: (x2 + t).clamp(0, canvasSize - 1), y2: y2,
          color: color,
        );
      }
    }
  }

  /// Convert img.Image → Uint8List để hiển thị trong Flutter Image widget
  static Uint8List toBytes(img.Image image) {
    return Uint8List.fromList(img.encodePng(image));
  }
}
