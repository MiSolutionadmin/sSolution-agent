import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final Widget child;
  
  const SkeletonLoader({
    super.key,
    required this.child,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(8),
    );
  }
}

class StatisticsSkeleton extends StatelessWidget {
  const StatisticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSkeletonStatRow('총괄 횟수'),
          const SizedBox(height: 12),
          _buildSkeletonStatRow('총괄 비율'),
          const SizedBox(height: 12),
          _buildSkeletonStatRow('총괄 정확도'),
          const SizedBox(height: 12),
          _buildSkeletonStatRow('이벤트 포인트'),
        ],
      ),
    );
  }

  Widget _buildSkeletonStatRow(String label) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: SkeletonLoader(
              child: Text(
                '로딩중...',  // 더미 텍스트
                style: const TextStyle(fontSize: 14, color: Colors.transparent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EventTableSkeleton extends StatelessWidget {
  const EventTableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Center(child: Text('날짜', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Center(child: Text('결과', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Center(child: Text('판단', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Center(child: Text('포인트', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          // 스켈레톤 행들
          ...List.generate(5, (index) => _buildSkeletonEventRow()),
        ],
      ),
    );
  }

  Widget _buildSkeletonEventRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: SkeletonText(width: 60, height: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: SkeletonText(width: 30, height: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: SkeletonText(width: 40, height: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: SkeletonText(width: 50, height: 12),
            ),
          ),
        ],
      ),
    );
  }
}