import 'package:flutter/material.dart';

class AutoSureLogo extends StatefulWidget {
  final double size;
  final bool animated;
  
  const AutoSureLogo({
    super.key,
    this.size = 120.0,
    this.animated = true,
  });

  @override
  State<AutoSureLogo> createState() => _AutoSureLogoState();
}

class _AutoSureLogoState extends State<AutoSureLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.animated 
        ? AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(_scaleAnimation.value)
                  ..rotateZ(_rotationAnimation.value),
                child: child,
              );
            },
            child: _buildLogo(),
          )
        : _buildLogo();
  }

  Widget _buildLogo() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.3),
            Colors.transparent,
          ],
          stops: const [0.1, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _AutoSureLogoPainter(glowIntensity: widget.animated ? _glowAnimation.value : 1.0),
        size: Size(widget.size, widget.size),
      ),
    );
  }
}

class _AutoSureLogoPainter extends CustomPainter {
  final double glowIntensity;

  _AutoSureLogoPainter({this.glowIntensity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    
    // Main shield background with gradient
    final shieldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blueAccent.withOpacity(0.9),
          Colors.lightBlue.withOpacity(0.7),
          Colors.blue.shade800.withOpacity(0.9),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    
    // Shield glow effect
    final glowPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.3 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
      ..style = PaintingStyle.fill;
    
    // Draw shield glow
    canvas.drawCircle(center, radius * 1.1, glowPaint);
    
    // Draw main shield
    _drawShield(canvas, center, radius, shieldPaint);
    
    // Draw car inside shield
    final carPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final carPath = Path();
    const carScale = 0.5; // Adjust size relative to shield
    final carCenter = Offset(center.dx, center.dy + radius * 0.1); // Slightly lower for balance
    final carWidth = radius * carScale * 0.8;
    final carHeight = radius * carScale * 0.4;
    
    // Car body (rectangle)
    carPath.moveTo(carCenter.dx - carWidth / 2, carCenter.dy);
    carPath.lineTo(carCenter.dx + carWidth / 2, carCenter.dy);
    carPath.lineTo(carCenter.dx + carWidth / 2, carCenter.dy - carHeight);
    carPath.lineTo(carCenter.dx - carWidth / 2, carCenter.dy - carHeight);
    carPath.close();
    
    // Front triangle (car front)
    carPath.moveTo(carCenter.dx + carWidth / 2, carCenter.dy - carHeight);
    carPath.lineTo(carCenter.dx + carWidth / 2 + carWidth * 0.3, carCenter.dy - carHeight * 0.5);
    carPath.lineTo(carCenter.dx + carWidth / 2, carCenter.dy - carHeight * 0.8);
    carPath.close();
    
    // Wheels (simple circles)
    final wheelRadius = carHeight * 0.2;
    canvas.drawCircle(Offset(carCenter.dx - carWidth * 0.3, carCenter.dy - carHeight * 0.1), wheelRadius, carPaint);
    canvas.drawCircle(Offset(carCenter.dx + carWidth * 0.3, carCenter.dy - carHeight * 0.1), wheelRadius, carPaint);
    
    canvas.drawPath(carPath, carPaint);
    
    // Draw outer ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = radius * 0.03
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius * 0.9, ringPaint);
    canvas.drawCircle(center, radius * 0.7, ringPaint);
  }
  
  void _drawShield(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    
    // Shield shape points
    final top = Offset(center.dx, center.dy - radius * 0.8);
    final leftTop = Offset(center.dx - radius * 0.6, center.dy - radius * 0.4);
    final rightTop = Offset(center.dx + radius * 0.6, center.dy - radius * 0.4);
    final leftBottom = Offset(center.dx - radius * 0.7, center.dy + radius * 0.6);
    final rightBottom = Offset(center.dx + radius * 0.7, center.dy + radius * 0.6);
    
    path.moveTo(top.dx, top.dy);
    path.quadraticBezierTo(
      leftTop.dx, leftTop.dy,
      leftBottom.dx, leftBottom.dy,
    );
    path.quadraticBezierTo(
      center.dx, center.dy + radius * 0.8,
      rightBottom.dx, rightBottom.dy,
    );
    path.quadraticBezierTo(
      rightTop.dx, rightTop.dy,
      top.dx, top.dy,
    );
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AutoSureLogoPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity;
  }
}

// Alternative minimalist version for smaller sizes
class AutoSureTextLogo extends StatelessWidget {
  final double size;
  final Color color;
  
  const AutoSureTextLogo({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AutoSureTextLogoPainter(color: color),
      size: Size(size * 3, size),
    );
  }
}

class _AutoSureTextLogoPainter extends CustomPainter {
  final Color color;

  const _AutoSureTextLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: color,
      fontSize: size.height * 0.8,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.5,
    );
    
    final textSpan = TextSpan(text: 'AS', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    
    textPainter.paint(canvas, Offset.zero);
    
    // Add a small shield icon next to text
    final shieldPaint = Paint()
      ..color = color
      ..strokeWidth = size.height * 0.08
      ..style = PaintingStyle.stroke;
    
    final shieldCenter = Offset(size.width - size.height * 0.4, size.height * 0.4);
    final shieldRadius = size.height * 0.3;
    
    canvas.drawCircle(shieldCenter, shieldRadius, shieldPaint);
  }

  @override
  bool shouldRepaint(covariant _AutoSureTextLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}