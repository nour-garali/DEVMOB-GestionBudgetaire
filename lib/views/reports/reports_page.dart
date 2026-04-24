import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF1E1E1E);
  static const _grey = Color(0xFF9095A1);
  static const _greyBg = Color(0xFFF6F7F9);
  static const _blue = Color(0xFF1644FF);
  static const _blueLight = Color(0xFFE0E7FF);
  static const _softBlue = Color(0xFFF0F3FF);
  static const _incomeBlue = Color(0xFF2DD4BF); // Teal/Cyan blue for Income
  static const _expenseBlue = _blue; // Primary blue for Expenses

  static const _donutColors = [
    Color(0xFF1644FF),
    Color(0xFF2DD4BF),
    Color(0xFF60A5FA),
    Color(0xFF818CF8),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
  ];

  int _selectedMonth = DateTime.now().month;
  int _year = DateTime.now().year;

  String _fmt(double v) => NumberFormat.currency(symbol: '', decimalDigits: 0).format(v.abs());

  List<_MonthEntry> _monthlyData(TransactionProvider p) {
    return List.generate(12, (i) {
      final mt = p.transactions.where((t) => t.date.year == _year && t.date.month == i + 1);
      final inc = mt.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
      final exp = mt.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
      return _MonthEntry(DateTime(_year, i + 1), inc, exp, inc - exp);
    });
  }

  List<_CatEntry> _catData(TransactionProvider p, String type) {
    final txs = p.transactions.where((t) => t.type == type && t.date.year == _year && t.date.month == _selectedMonth);
    final Map<String, double> m = {};
    for (final t in txs) { m[t.categoryId] = (m[t.categoryId] ?? 0) + t.amount; }
    if (m.isEmpty) return [];
    final total = m.values.fold(0.0, (a, b) => a + b);
    final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return List.generate(sorted.length, (i) {
      final e = sorted[i];
      final cat = p.categories.where((c) => c.id == e.key);
      return _CatEntry(cat.isNotEmpty ? cat.first.name : p.getCategoryName(e.key), e.value, total > 0 ? e.value / total * 100 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);
    final sp = Provider.of<SettingsProvider>(context);
    final hide = sp.hideBalances;
    final monthly = _monthlyData(tp);
    
    final expenseCats = _catData(tp, 'expense');
    final incomeCats = _catData(tp, 'income');
    
    final currentMonthEntry = monthly[_selectedMonth - 1];
    final totalIncome = currentMonthEntry.income;
    final totalExpense = currentMonthEntry.expense;
    final balance = currentMonthEntry.balance;

    return Scaffold(
      backgroundColor: _greyBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(tp),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildMonthSelector(),
                    const SizedBox(height: 32),
                    _buildDualStatCards(totalIncome, totalExpense, hide),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Monthly Evolution'),
                    _buildSparklineCard(monthly, hide),
                    const SizedBox(height: 32),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildGlassDonutCard('Expenses', expenseCats, hide, _expenseBlue)),
                          if (incomeCats.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            Expanded(child: _buildGlassDonutCard('Income', incomeCats, hide, _incomeBlue)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Annual Summary'),
                    _buildSummaryTable(monthly, hide),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(child: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _black)), alignment: Alignment.centerLeft),
    );
  }

  Widget _buildHeader(TransactionProvider tp) {
    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
          Text('Reports & Analytics', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _black)),
          _iconBtn(Icons.calendar_month_rounded, () => _showYearPicker(tp)),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _greyBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 18, color: _black)));
  }

  Widget _buildMonthSelector() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final active = _selectedMonth == month;
          final name = DateFormat('MMMM', 'en').format(DateTime(_year, month));
          return GestureDetector(
            onTap: () => setState(() => _selectedMonth = month),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: active ? _blue : _white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: active ? _blue.withValues(alpha: 0.3) : _black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase() + name.substring(1),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? _white : _grey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDualStatCards(double income, double expense, bool hide) {
    return Row(
      children: [
        Expanded(child: _statCard('Income', income, _incomeBlue, Icons.arrow_downward_rounded, hide)),
        const SizedBox(width: 16),
        Expanded(child: _statCard('Expenses', expense, _expenseBlue, Icons.arrow_upward_rounded, hide)),
      ],
    );
  }

  Widget _statCard(String label, double val, Color color, IconData icon, bool hide) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _grey)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hide ? '•••• DT' : '${_fmt(val)} DT',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _black),
          ),
        ],
      ),
    );
  }

  Widget _buildSparklineCard(List<_MonthEntry> data, bool hide) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(color: _grey.withValues(alpha: 0.1), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (v, meta) {
                      if (v == meta.min || v == meta.max || v % ((meta.max - meta.min) / 3).roundToDouble() == 0) {
                         return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            v >= 1000 ? '${(v/1000).toStringAsFixed(1)}k' : v.toInt().toString(),
                            style: const TextStyle(color: _grey, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      const style = TextStyle(color: _grey, fontWeight: FontWeight.bold, fontSize: 11);
                      final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                      if (v.toInt() >= 0 && v.toInt() < 12) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 10,
                          child: Text(months[v.toInt()], style: style),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: _grey.withValues(alpha: 0.2), width: 1),
                  left: BorderSide(color: _grey.withValues(alpha: 0.2), width: 1),
                  right: const BorderSide(color: Colors.transparent),
                  top: const BorderSide(color: Colors.transparent),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => _black.withValues(alpha: 0.8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((s) {
                      return LineTooltipItem(
                        '${hide ? '•••' : _fmt(s.y)} DT',
                        GoogleFonts.inter(color: _white, fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(12, (i) => FlSpot(i.toDouble(), data[i].income)),
                  isCurved: true, color: _incomeBlue, barWidth: 3, dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [_incomeBlue.withValues(alpha: 0.1), _incomeBlue.withValues(alpha: 0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                ),
                LineChartBarData(
                  spots: List.generate(12, (i) => FlSpot(i.toDouble(), data[i].expense)),
                  isCurved: true, color: _expenseBlue, barWidth: 3, dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [_expenseBlue.withValues(alpha: 0.1), _expenseBlue.withValues(alpha: 0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                ),
              ],
            )),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem('Income', _incomeBlue),
              const SizedBox(width: 24),
              _legendItem('Expenses', _expenseBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _grey)),
      ],
    );
  }

  Widget _buildGlassDonutCard(String title, List<_CatEntry> cats, bool hide, Color activeColor) {
    final ratios = cats.map((c) => c.pct / 100).toList();
    final colors = List.generate(cats.length, (i) => _donutColors[i % _donutColors.length]);
    final totalAmount = cats.fold(0.0, (s, c) => s + c.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _black)),
            Icon(Icons.more_vert_rounded, size: 18, color: _grey.withValues(alpha: 0.5)),
          ],
        ),
        const SizedBox(height: 16),
        if (cats.isEmpty)
          SizedBox(height: 100, child: Center(child: Text('No data', style: GoogleFonts.inter(color: _grey, fontSize: 12))))
        else ...[
          // Multi-segment donut
          SizedBox(height: 110, child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(110, 110),
              painter: _GlassDonutPainter(ratios: ratios, colors: colors, trackColor: activeColor.withValues(alpha: 0.08)),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                hide ? '•••' : _fmt(totalAmount),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _black),
              ),
              Text('DT', style: GoogleFonts.inter(fontSize: 10, color: _grey, fontWeight: FontWeight.w600)),
            ]),
          ])),
          const SizedBox(height: 16),
          // Full legend — all categories
          ...List.generate(cats.length, (i) {
            final c = cats[i];
            final col = colors[i % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(c.name, style: GoogleFonts.inter(fontSize: 11, color: _grey, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(
                  '${c.pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: col),
                ),
              ]),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildSummaryTable(List<_MonthEntry> data, bool hide) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        _tableRow('Month', 'Income', 'Expenses', isHeader: true),
        const Divider(),
        ...List.generate(12, (i) {
          final isSelected = _selectedMonth == i + 1;
          if (data[i].income == 0 && data[i].expense == 0 && !isSelected) return const SizedBox();
          return Container(
            decoration: BoxDecoration(
              color: isSelected ? _blue.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _tableRow(DateFormat('MMM', 'en').format(data[i].month), hide ? '•••' : _fmt(data[i].income), hide ? '•••' : _fmt(data[i].expense)),
          );
        }),
      ]),
    );
  }

  Widget _tableRow(String c1, String c2, String c3, {bool isHeader = false}) {
    final style = GoogleFonts.inter(fontSize: 13, fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500, color: isHeader ? _black : _grey);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Expanded(flex: 2, child: Text(c1, style: style)),
      Expanded(child: Text(c2, style: style.copyWith(color: isHeader ? _black : _incomeBlue))),
      Expanded(child: Text(c3, style: style.copyWith(color: isHeader ? _black : _expenseBlue))),
    ]));
  }

  void _showYearPicker(TransactionProvider tp) {
    final yrs = tp.transactions.map((t) => t.date.year).toSet().toList();
    if (!yrs.contains(DateTime.now().year)) yrs.add(DateTime.now().year);
    yrs.sort();
    showModalBottomSheet(context: context, backgroundColor: _white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Pick a Year', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      ...yrs.reversed.map((y) => ListTile(title: Center(child: Text('$y', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: y == _year ? _blue : _black))), onTap: () { setState(() => _year = y); Navigator.pop(context); })),
    ])));
  }
}

class _GlassDonutPainter extends CustomPainter {
  final List<double> ratios;
  final List<Color> colors;
  final Color trackColor;

  _GlassDonutPainter({required this.ratios, required this.colors, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 18.0;
    const gapAngle = 0.04; // small gap between segments
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw track (background ring)
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Draw each segment
    double startAngle = -pi / 2;
    for (int i = 0; i < ratios.length; i++) {
      final ratio = ratios[i];
      if (ratio <= 0) continue;
      final sweepAngle = 2 * pi * ratio;
      if (sweepAngle <= gapAngle * 2) {
        startAngle += sweepAngle;
        continue;
      }
      final segmentPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = colors[i % colors.length];
      canvas.drawArc(rect, startAngle + gapAngle, sweepAngle - gapAngle * 2, false, segmentPaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _GlassDonutPainter oldDelegate) =>
      oldDelegate.ratios != ratios || oldDelegate.colors != colors;
}

class _CatEntry { final String name; final double amount; final double pct; _CatEntry(this.name, this.amount, this.pct); }
class _MonthEntry { final DateTime month; final double income, expense, balance; _MonthEntry(this.month, this.income, this.expense, this.balance); }