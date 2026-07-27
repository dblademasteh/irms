import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

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

          return isDesktop
              ? _buildDesktopLayout(theme, d)
              : _buildMobileLayout(theme, d);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DESKTOP LAYOUT
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(ThemeData theme, DashboardLoaded d) {
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () => context.read<DispatcherCubit>().loadDashboard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopGreeting(theme),
            const SizedBox(height: 24),
            _buildDesktopStatRow(theme, d, isDark, loc),
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _buildPipelineCard(theme, d, isDark, loc)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildCategoriesCard(theme, d, isDark)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDesktopCriticalSection(theme, d, isDark, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopGreeting(ThemeData theme) {
    final hour = DateTime.now().hour;
    final loc = AppLocalizations.of(context)!;
    final greeting = hour < 12
        ? loc.greetingMorning
        : hour < 17
            ? loc.greetingAfternoon
            : loc.greetingEvening;
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting${loc.greetingSuffix}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: IrmsColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: IrmsColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: IrmsColors.successDark, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text(
                'Live',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: IrmsColors.successDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatRow(ThemeData theme, DashboardLoaded d, bool isDark, AppLocalizations loc) {
    final stats = [
      _StatCardData(loc.statTotalIncidents, d.total.toString(),
          isDark ? IrmsColors.primaryDark : IrmsColors.primary, Icons.inbox_rounded,
          subtitle: 'All reports'),
      _StatCardData(loc.statPending, (d.submitted + d.underReview).toString(),
          isDark ? IrmsColors.warningDark : IrmsColors.warning, Icons.pending_actions_rounded,
          subtitle: '${d.submitted} submitted · ${d.underReview} in review'),
      _StatCardData(loc.statVerifiedToday, d.verified.toString(),
          isDark ? IrmsColors.successDark : IrmsColors.success, Icons.verified_user_rounded,
          subtitle: '${d.resolved} resolved'),
      _StatCardData(loc.statCritical, d.critical.toString(),
          isDark ? IrmsColors.errorDark : IrmsColors.error, Icons.circle_notifications_rounded,
          subtitle: 'Needs immediate action'),
    ];

    return Row(
      children: List.generate(stats.length, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i < stats.length - 1 ? 16 : 0),
          child: _buildDesktopStatCard(theme, stats[i], isDark),
        ),
      )),
    );
  }

  Widget _buildDesktopStatCard(ThemeData theme, _StatCardData s, bool isDark) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [s.color.withValues(alpha: isDark ? 0.22 : 0.14), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(s.icon, color: s.color, size: 20),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      s.value,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          s.label,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                if (s.subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    s.subtitle!,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineCard(ThemeData theme, DashboardLoaded d, bool isDark, AppLocalizations loc) {
    final total = d.total;
    final segments = _buildSegments(d, total, isDark, loc);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.1)),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.stacked_bar_chart_rounded, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Text(loc.labelStatusPipeline,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$total total',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (total == 0)
            Center(
              child: Text(
                loc.emptyNoIncidentsInQueue,
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: segments.map((s) => Expanded(
                  flex: _max(1, s.count),
                  child: Container(height: 14, color: s.color),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 12,
              children: segments.map((s) {
                final pct = s.total > 0 ? (s.count / s.total * 100).round() : 0;
                return Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.count} ($pct%)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.color),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesCard(ThemeData theme, DashboardLoaded d, bool isDark) {
    final categories = [
      _CategoryData('Fire', Icons.local_fire_department_rounded, Colors.deepOrange,
          d.incidents.where((i) => i['type'] == 'fire').length),
      _CategoryData('Accident', Icons.car_crash_rounded, Colors.teal,
          d.incidents.where((i) => i['type'] == 'accident').length),
      _CategoryData('Crime', Icons.security_rounded, Colors.purple,
          d.incidents.where((i) => i['type'] == 'crime').length),
      _CategoryData('Medical', Icons.medical_services_rounded, Colors.red,
          d.incidents.where((i) => i['type'] == 'medical').length),
      _CategoryData('Disaster', Icons.storm_rounded, Colors.indigo,
          d.incidents.where((i) => i['type'] == 'disaster').length),
      _CategoryData('Infra', Icons.construction_rounded, Colors.blueGrey,
          d.incidents.where((i) => i['type'] == 'infrastructure').length),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.1)),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_rounded, size: 18, color: Colors.amber),
              ),
              const SizedBox(width: 10),
              Text('Incident Categories',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: categories.map((cat) {
              final isEmpty = cat.count == 0;
              return GestureDetector(
                onTap: () => context.go('/queue'),
                child: Container(
                  decoration: BoxDecoration(
                    color: isEmpty
                        ? theme.colorScheme.outline.withValues(alpha: 0.05)
                        : cat.color.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isEmpty
                          ? theme.colorScheme.outline.withValues(alpha: 0.08)
                          : cat.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (!isEmpty)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              cat.count.toString(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: cat.color),
                            ),
                          ),
                        ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat.icon,
                              color: isEmpty
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                                  : cat.color,
                              size: 24,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isEmpty
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.25)
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCriticalSection(ThemeData theme, DashboardLoaded d, bool isDark, AppLocalizations loc) {
    final errorColor = isDark ? IrmsColors.errorDark : IrmsColors.error;
    final errorBg = isDark ? IrmsColors.errorBgDark : IrmsColors.errorBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: errorBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.warning_amber_rounded, size: 18, color: errorColor),
            ),
            const SizedBox(width: 10),
            Text(loc.labelCriticalIncidents,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: errorBg, borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${d.recentCritical.length} ${loc.labelUrgent}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: errorColor),
              ),
            ),
            const Spacer(),
            if (d.recentCritical.isNotEmpty)
              TextButton.icon(
                onPressed: () => context.go('/queue'),
                icon: Icon(Icons.arrow_forward_rounded, size: 14, color: theme.colorScheme.primary),
                label: Text(
                  'View all',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (d.recentCritical.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: isDark ? IrmsColors.successDark : IrmsColors.success, size: 24),
                const SizedBox(width: 12),
                Text(
                  loc.emptyAllClear,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          )
        else
          ...d.recentCritical.take(5).map((inc) {
            final mins = _minutesAgo(inc['created_at']);
            final timeColor = mins < 10
                ? errorColor
                : mins < 60
                    ? (isDark ? IrmsColors.warningDark : IrmsColors.warning)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(width: 4, color: errorColor),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            final id = inc['id']?.toString() ?? '';
                            if (id.isNotEmpty) context.push('/queue/$id');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: errorBg, borderRadius: BorderRadius.circular(10)),
                                  child: Icon(Icons.warning_amber_rounded, color: errorColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inc['title'] ?? 'Critical Incident',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (inc['description'] != null &&
                                          inc['description'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            inc['description'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                                          ),
                                        ),
                                      if (inc['address'] != null &&
                                          inc['address'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 12,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  inc['address'],
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: timeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: timeColor.withValues(alpha: 0.25)),
                                  ),
                                  child: Text(
                                    _timeAgo(inc['created_at']),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: timeColor),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.chevron_right_rounded, size: 18,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOBILE LAYOUT (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(ThemeData theme, DashboardLoaded d) {
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
      _StatCardData(loc.statTotalIncidents, d.total.toString(),
          isDark ? IrmsColors.primaryDark : IrmsColors.primary, Icons.inbox),
      _StatCardData(loc.statPending, (d.submitted + d.underReview).toString(),
          isDark ? IrmsColors.warningDark : IrmsColors.warning, Icons.pending_actions),
      _StatCardData(loc.statVerifiedToday, d.verified.toString(),
          isDark ? IrmsColors.successDark : IrmsColors.success, Icons.verified_user),
      _StatCardData(loc.statCritical, d.critical.toString(),
          isDark ? IrmsColors.errorDark : IrmsColors.error, Icons.circle_notifications_rounded),
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
                right: -24, bottom: -24,
                child: Container(
                  width: 100, height: 100,
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, color: s.color, size: 20),
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
    final loc = AppLocalizations.of(context)!;

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
              loc.emptyNoIncidentsInQueue,
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 15),
            ),
          ),
        ),
      );
    }

    final segments = _buildSegments(d, total, isDark, loc);

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
            Text(loc.labelStatusPipeline,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: segments.map((s) {
                  return Expanded(
                    flex: _max(1, s.count),
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
              children: segments.map((s) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${s.label} (${s.count})',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              )).toList(),
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
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: warningBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.warning_amber_rounded, size: 20, color: warningFg),
              ),
              const SizedBox(width: 10),
              Text(loc.labelCriticalIncidents,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: warningBg, borderRadius: BorderRadius.circular(20)),
                child: Text('${d.recentCritical.length} ${loc.labelUrgent}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: warningFg)),
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
                  Icon(Icons.check_circle_outline,
                      color: isDark ? IrmsColors.successDark : IrmsColors.success, size: 28),
                  const SizedBox(width: 12),
                  Text(loc.emptyAllClear,
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600)),
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
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: warningBg, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.warning_amber_rounded, color: warningFg, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inc['title'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (inc['description'] != null && inc['description'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(inc['description'],
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                ),
                              if (inc['address'] != null && inc['address'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 12,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(inc['address'],
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 11,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
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
                          child: Text(_timeAgo(inc['created_at']),
                              style: TextStyle(fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w700)),
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

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  List<_Seg> _buildSegments(DashboardLoaded d, int total, bool isDark, AppLocalizations loc) {
    return [
      _Seg(loc.pipelineSubmitted, d.submitted, total, IrmsStatusColors.resolve('submitted', isDark)),
      _Seg(loc.pipelineReview, d.underReview, total, IrmsStatusColors.resolve('under_review', isDark)),
      _Seg(loc.pipelineVerified, d.verified, total, IrmsStatusColors.resolve('verified', isDark)),
      _Seg(loc.pipelineRejected, d.rejected, total, IrmsStatusColors.resolve('rejected', isDark)),
      _Seg(loc.pipelineResolved, d.resolved, total, IrmsStatusColors.resolve('resolved', isDark)),
    ]..removeWhere((s) => s.count == 0);
  }

  int _max(int a, int b) => a > b ? a : b;

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

  int _minutesAgo(String? createdAt) {
    if (createdAt == null) return 9999;
    try {
      return DateTime.now().difference(DateTime.parse(createdAt)).inMinutes;
    } catch (_) {
      return 9999;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;
  const _StatCardData(this.label, this.value, this.color, this.icon, {this.subtitle});
}

class _Seg {
  final String label;
  final int count;
  final int total;
  final Color color;
  _Seg(this.label, this.count, this.total, this.color);
}

class _CategoryData {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  const _CategoryData(this.label, this.icon, this.color, this.count);
}