import 'package:flutter/material.dart';

class AppHeader extends StatefulWidget {
  final VoidCallback onLogoTap;
  final VoidCallback? onAITap;
  final bool isSubscribed;

  const AppHeader({
    required this.onLogoTap,
    this.onAITap,
    this.isSubscribed = false,
    super.key,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _aiController;
  late Animation<double> _logoScale;
  late Animation<double> _aiScale;

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _aiController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    
    _aiScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _aiController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _aiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedBuilder(
            animation: _logoScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _logoScale.value,
                child: GestureDetector(
                  onTapDown: (_) => _logoController.forward(),
                  onTapUp: (_) => _logoController.reverse(),
                  onTapCancel: () => _logoController.reverse(),
                  onTap: widget.onLogoTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[50],
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B73FF),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B73FF).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'TilimApp',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          if (widget.onAITap != null && widget.isSubscribed)
            AnimatedBuilder(
              animation: _aiScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _aiScale.value,
                  child: GestureDetector(
                    onTapDown: (_) => _aiController.forward(),
                    onTapUp: (_) => _aiController.reverse(),
                    onTapCancel: () => _aiController.reverse(),
                    onTap: widget.onAITap,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
} 