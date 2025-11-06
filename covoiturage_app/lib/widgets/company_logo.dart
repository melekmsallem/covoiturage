import 'package:flutter/material.dart';

class CompanyLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final String? tagline;
  final bool lightVariant; // For light backgrounds (white text/colors)

  const CompanyLogo({
    Key? key,
    this.size = 200,
    this.showTagline = true,
    this.tagline,
    this.lightVariant = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleColor = lightVariant ? Colors.white : Colors.blueGrey[900]!;
    final accentTextColor = lightVariant ? Colors.blue[200]! : Colors.blueAccent;
    final secondaryTextColor =
        lightVariant ? Colors.white.withOpacity(0.78) : Colors.blueGrey[500]!;

    final badgeBaseColor = lightVariant ? Colors.blue[500]! : Colors.white;
    final badgeHighlightColor = lightVariant ? Colors.blue[300]! : Colors.blue[100]!;
    final routeColor = lightVariant ? Colors.white : Colors.blueGrey[900]!;
    final waypointColor = lightVariant ? Colors.amber[200]! : Colors.orangeAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(lightVariant ? 0.18 : 0.1),
                    blurRadius: size * 0.08,
                    offset: Offset(0, size * 0.04),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: RouteBadgePainter(
                  baseColor: badgeBaseColor,
                  highlightColor: badgeHighlightColor,
                  routeColor: routeColor,
                  waypointColor: waypointColor,
                ),
              ),
            ),
            SizedBox(width: size * 0.1),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Ride',
                      style: TextStyle(
                      fontSize: size * 0.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: size * 0.004,
                      color: titleColor,
                    ),
                    children: [
                      TextSpan(
                        text: 'Share',
                        style: TextStyle(color: accentTextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: size * 0.04),
                  height: size * 0.015,
                  width: size * 0.26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentTextColor,
                        accentTextColor.withOpacity(0.2),
                      ],
                      ),
                    borderRadius: BorderRadius.circular(size * 0.01),
                  ),
                ),
                if (showTagline)
                  Padding(
                    padding: EdgeInsets.only(top: size * 0.05),
                    child: Text(
                      tagline ?? 'SMART CARPOOLING NETWORK',
                      style: TextStyle(
                        fontSize: size * 0.05,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        ),
      ],
    );
  }
}

class RouteBadgePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;
  final Color routeColor;
  final Color waypointColor;

  RouteBadgePainter({
    required this.baseColor,
    required this.highlightColor,
    required this.routeColor,
    required this.waypointColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, size.height / 2);

    final badgeRect = Rect.fromCircle(center: center, radius: radius);
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlightColor, baseColor],
      ).createShader(badgeRect);

    canvas.drawCircle(center, radius, backgroundPaint);

    final haloPaint = Paint()
      ..color = routeColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08;
    canvas.drawCircle(center, radius * 0.78, haloPaint);

    final routePath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.22,
        size.width * 0.68,
        size.height * 0.5,
      );

    final routePaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, routePaint);

    for (final metric in routePath.computeMetrics()) {
      final length = metric.length;
      const segmentCount = 5;
      for (int i = 1; i < segmentCount; i++) {
        final tangent = metric.getTangentForOffset(length * (i / segmentCount));
        if (tangent != null) {
          canvas.drawCircle(tangent.position, size.width * 0.02,
              Paint()..color = highlightColor.withOpacity(0.6));
        }
      }
    }

    final startPoint = Offset(size.width * 0.24, size.height * 0.72);
    final startHaloPaint = Paint()
      ..color = highlightColor.withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPoint, size.width * 0.12, startHaloPaint);
    canvas.drawCircle(
      startPoint,
      size.width * 0.05,
      Paint()
        ..color = routeColor
        ..style = PaintingStyle.fill,
    );

    final pinCenter = Offset(size.width * 0.72, size.height * 0.38);
    final pinRadius = size.width * 0.15;

    final pinPaint = Paint()
      ..color = waypointColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinCenter, pinRadius, pinPaint);
    
    canvas.drawCircle(
      pinCenter,
      pinRadius * 0.45,
      Paint()
        ..color = baseColor.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );

    final pointerPath = Path()
      ..moveTo(pinCenter.dx, pinCenter.dy + pinRadius)
      ..quadraticBezierTo(
        pinCenter.dx + pinRadius * 0.55,
        pinCenter.dy + pinRadius * 1.15,
        pinCenter.dx,
        pinCenter.dy + pinRadius * 1.8,
      )
      ..quadraticBezierTo(
        pinCenter.dx - pinRadius * 0.55,
        pinCenter.dy + pinRadius * 1.15,
        pinCenter.dx,
        pinCenter.dy + pinRadius,
      )
      ..close();

    canvas.drawPath(pointerPath, pinPaint);

    canvas.drawCircle(
      pinCenter.translate(0, pinRadius * 1.45),
      size.width * 0.04,
      Paint()
        ..color = pinPaint.color.withOpacity(0.5)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant RouteBadgePainter oldDelegate) {
    return baseColor != oldDelegate.baseColor ||
        highlightColor != oldDelegate.highlightColor ||
        routeColor != oldDelegate.routeColor ||
        waypointColor != oldDelegate.waypointColor;
  }
}

