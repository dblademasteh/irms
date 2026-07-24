import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/dispatcher_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DispatcherCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: IrmsAppBar(
        title: AppLocalizations.of(context)!.dashboardAppBarTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DispatcherCubit>().loadDashboard(),
          ),
        ],
      ),
      body: BlocBuilder<DispatcherCubit, DispatcherState>(
        builder: (ctx, state) {
          if (state is DispatcherLoading && state is! DashboardLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DispatcherError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error.withValues(alpha: 0.7)),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.errorFailedToLoadDashboard,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.read<DispatcherCubit>().loadDashboard(),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.btnRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          final d = state is DashboardLoaded ? state : null;
          if (d == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => context.read<DispatcherCubit>().loadDashboard(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildGreeting(theme),
                const SizedBox(height: 20),
                _buildStatCards(theme, d),
                const SizedBox(height: 20),
                _buildStatusCard(theme, d),
                const SizedBox(height: 20),
                _buildCriticalSection(theme, d),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    final loc = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? loc.greetingMorning
        : hour < 17
            ? loc.greetingAfternoon
            : loc.greetingEvening;
    return Text(
      '$greeting${loc.greetingSuffix}',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStatCards(ThemeData theme, DashboardLoaded d) {
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final stats = [
      _StatCardData(loc.statTotalIncidents, d.total.toString(), isDark ? IrmsColors.primaryDark : IrmsColors.primary, Icons.inbox),
      _StatCardData(loc.statPending, (d.submitted + d.underReview).toString(), isDark ? IrmsColors.warningDark : IrmsColors.warning, Icons.pending_actions),
      _StatCardData(loc.statVerifiedToday, d.verified.toString(), isDark ? IrmsColors.successDark : IrmsColors.success, Icons.verified_user),
      _StatCardData(loc.statCritical, d.critical.toString(), isDark ? IrmsColors.errorDark : IrmsColors.error, Icons.circle_notifications_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: stats.length,
      itemBuilder: (ctx, i) {
        final s = stats[i];
        return Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: isDark ? 0.1 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                bottom: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [s.color.withValues(alpha: isDark ? 0.25 : 0.15), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s.icon, color: s.color, size: 20),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      s.value,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(ThemeData theme, DashboardLoaded d) {
    final total = d.total;
    final isDark = theme.brightness == Brightness.dark;

    if (total == 0) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.emptyNoIncidentsInQueue,
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 15),
            ),
          ),
        ),
      );
    }

    final segments = [
      _Seg(AppLocalizations.of(context)!.pipelineSubmitted, d.submitted, total, IrmsStatusColors.resolve('submitted', isDark)),
      _Seg(AppLocalizations.of(context)!.pipelineReview, d.underReview, total, IrmsStatusColors.resolve('under_review', isDark)),
      _Seg(AppLocalizations.of(context)!.pipelineVerified, d.verified, total, IrmsStatusColors.resolve('verified', isDark)),
      _Seg(AppLocalizations.of(context)!.pipelineRejected, d.rejected, total, IrmsStatusColors.resolve('rejected', isDark)),
      _Seg(AppLocalizations.of(context)!.pipelineResolved, d.resolved, total, IrmsStatusColors.resolve('resolved', isDark)),
    ]..removeWhere((s) => s.count == 0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.labelStatusPipeline,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: segments.map((s) {
                  return Expanded(
                    flex: max(1, s.count),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: s.color,
                        border: Border(
                          right: BorderSide(
                            color: theme.cardTheme.color ?? theme.colorScheme.surface,
                            width: s == segments.last ? 0 : 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: segments.map((s) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      '${s.label} (${s.count})',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalSection(ThemeData theme, DashboardLoaded d) {
    final isDark = theme.brightness == Brightness.dark;
    final warningBg = isDark ? IrmsColors.errorBgDark : IrmsColors.errorBg;
    final warningFg = isDark ? IrmsColors.errorDark : IrmsColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded, size: 20, color: warningFg),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.labelCriticalIncidents,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: warningBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${d.recentCritical.length} ${AppLocalizations.of(context)!.labelUrgent}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: warningFg,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (d.recentCritical.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: isDark ? IrmsColors.successDark : IrmsColors.success, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.emptyAllClear,
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: d.recentCritical.length,
            itemBuilder: (ctx, i) {
              final inc = d.recentCritical[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: warningBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.warning_amber_rounded, color: warningFg, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inc['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (inc['description'] != null && inc['description'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    inc['description'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                  ),
                                ),
                              if (inc['address'] != null && inc['address'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          inc['address'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _timeAgo(inc['created_at']),
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  int max(int a, int b) => a > b ? a : b;

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

class _StatCardData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCardData(this.label, this.value, this.color, this.icon);
}

class _Seg {
  final String label;
  final int count;
  final int total;
  final Color color;
  _Seg(this.label, this.count, this.total, this.color);
}