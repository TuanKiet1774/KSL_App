import 'package:flutter/material.dart';
import 'package:ksl/component/appColors.dart';
import 'package:ksl/controller/progressController.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../model/progress.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  ProgressModel? _progressData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await ProgressController.getUserProgress();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _progressData = result['data'];
        } else {
          _errorMessage = result['message'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Thống kê học tập',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: AppColors.primaryTeal,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          child: _buildContent(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryTeal, Color(0xFF2D6A65)],
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/thongke.png',
            height: 150,
            width: 150,
          ),
          const SizedBox(height: 20),
          const Text(
            'Hành trình học tập của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryTeal),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStatsGrid(),
          const SizedBox(height: 24),
          _buildAverageScoreCard(),
          const SizedBox(height: 24),
          _buildActivityChart(),
          const SizedBox(height: 24),
          _buildTopicProgressSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    final streak = _progressData?.stats.streakDays ?? 0;
    final totalWordsLearned = _progressData?.stats.totalWordsLearned ?? 0;
    final totalExp = _progressData?.stats.totalExp ?? 0;
    final totalLearningMinutes = _progressData?.stats.totalLearningMinutes ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _premiumStatCard(
                title: 'Chuỗi ngày',
                value: '$streak',
                unit: 'ngày',
                icon: Icons.local_fire_department_rounded,
                colors: [const Color(0xFFFF9D6C), const Color(0xFFBB4E75)],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _premiumStatCard(
                title: 'Từ đã học',
                value: '$totalWordsLearned',
                unit: 'từ',
                icon: Icons.menu_book_rounded,
                colors: [const Color(0xFF64E8DE), const Color(0xFF82BBFF)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _premiumStatCard(
                title: 'Tổng EXP',
                value: '$totalExp',
                unit: 'exp',
                icon: Icons.auto_awesome_rounded,
                colors: [const Color(0xFFFFC845), const Color(0xFFFF6B6B)],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _premiumStatCard(
                title: 'Thời gian học',
                value: totalLearningMinutes.toStringAsFixed(0),
                unit: 'phút',
                icon: Icons.timer_rounded,
                colors: [const Color(0xFF84FAB0), const Color(0xFF8FD3F4)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _premiumStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageScoreCard() {
    final double avgScore = _progressData?.averageTestScore ?? 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppColors.primaryTeal, size: 24),
              SizedBox(width: 12),
              Text(
                'Điểm kiểm tra trung bình',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: avgScore / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    avgScore >= 80 ? Colors.greenAccent.shade700 : 
                    avgScore >= 50 ? AppColors.accentOrange : Colors.redAccent
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    avgScore.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    'Trên 100',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final history = _progressData?.accessHistory ?? [];
    
    // Gom nhóm thời gian theo ngày
    Map<String, double> dailyStats = {};
    for (var item in history) {
      try {
        DateTime date = DateTime.parse(item.sessionStart);
        String formattedDate = DateFormat('dd/MM').format(date);
        double duration = item.duration.toDouble();
        dailyStats[formattedDate] = (dailyStats[formattedDate] ?? 0) + duration;
      } catch (_) {}
    }

    final sortedDates = dailyStats.keys.toList();
    // Lấy tối đa 7 ngày gần nhất
    final displayDates = sortedDates.length > 7 
        ? sortedDates.sublist(sortedDates.length - 7) 
        : sortedDates;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thời gian sử dụng gần đây',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayDates.isEmpty ? 'Chưa có dữ liệu hoạt động' : 'Thống kê tổng số giây học tập mỗi ngày',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          displayDates.isEmpty 
          ? _buildEmptyChartPlaceholder()
          : AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < displayDates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              displayDates[index],
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(displayDates.length, (index) {
                        final dateStr = displayDates[index];
                        final val = dailyStats[dateStr] ?? 0.0;
                        return FlSpot(index.toDouble(), val);
                      }),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryTeal, Color(0xFF64E8DE)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryTeal.withOpacity(0.2),
                          AppColors.primaryTeal.withOpacity(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryBlue,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '${barSpot.y.toInt()} giây',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartPlaceholder() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Center(
        child: Text(
          'Không có dữ liệu thời gian',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTopicProgressSection() {
    final topics = _progressData?.topicProgress ?? [];
    if (topics.isEmpty) return _buildEmptyTopicsPlaceholder();

    final double screenWidth = MediaQuery.of(context).size.width - 40;
    final double barWidth = 85.0;
    final double chartWidth = topics.length > 4 ? topics.length * barWidth : screenWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Tiến độ theo chủ đề',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 320,
          padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primaryBlue,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${topics[groupIndex].topicName}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toInt()}%',
                              style: const TextStyle(color: AppColors.accentOrange, fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < topics.length) {
                            String name = topics[index].topicName;
                            if (name.length > 12) name = '${name.substring(0, 10)}...';
                            return SideTitleWidget(
                              meta: meta,
                              space: 10,
                              child: Transform.rotate(
                                angle: -0.4,
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 70),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade50,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(topics.length, (index) {
                    final percent = topics[index].percentage;
                    final List<Color> availableColors = [
                      AppColors.primaryTeal,
                      const Color(0xFF5AD7F3),
                      const Color(0xFFFFA585),
                      const Color(0xFFFF7EB3),
                      const Color(0xFF70F570),
                      const Color(0xFF4FACFE),
                      const Color(0xFFF093FB),
                    ];
                    final color = availableColors[index % availableColors.length];

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: percent,
                          gradient: LinearGradient(
                            colors: [
                              color,
                              color.withOpacity(0.6),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: Colors.grey.shade50,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTopicsPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          'Chưa có tiến độ chủ đề',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
      ),
    );
  }
}


