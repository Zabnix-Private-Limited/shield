import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/shield_role.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_page_frame.dart';
import '../../../../shared/widgets/app_responsive.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../demo_role_data.dart';

class RoleDemoShell extends StatefulWidget {
  final SHIELDRole role;
  final String? sectionKey;

  const RoleDemoShell({
    super.key,
    required this.role,
    required this.sectionKey,
  });

  @override
  State<RoleDemoShell> createState() => _RoleDemoShellState();
}

class _RoleDemoShellState extends State<RoleDemoShell> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final demo = demoDataForRole(widget.role);
    final section = demo.sectionFor(widget.sectionKey);

    if (_isLoading) {
      return AppPageSkeleton(showSidebar: AppResponsive.isDesktop(context));
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      drawer: _RoleDrawer(demo: demo, activeSectionKey: section.key),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;

            if (isWide) {
              return Row(
                children: [
                  _RoleSidebar(demo: demo, activeSectionKey: section.key),
                  Expanded(
                    child: _RoleContent(demo: demo, section: section),
                  ),
                ],
              );
            }

            return _RoleContent(demo: demo, section: section);
          },
        ),
      ),
    );
  }
}

class _RoleContent extends StatelessWidget {
  final DemoRoleData demo;
  final DemoSectionData section;

  const _RoleContent({required this.demo, required this.section});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: AppPageFrame(
            maxWidth: 1240,
            padding: EdgeInsets.fromLTRB(
              AppResponsive.horizontalPadding(context),
              20,
              AppResponsive.horizontalPadding(context),
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DemoHeader(demo: demo, section: section),
                const SizedBox(height: 20),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: demo.sections.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = demo.sections[index];
                      final isActive = item.key == section.key;

                      return ChoiceChip(
                        label: Text(item.title),
                        selected: isActive,
                        selectedColor: demo.accentColor.withValues(alpha: 0.14),
                        labelStyle: AppTypography.small.copyWith(
                          color: isActive
                              ? demo.accentColor
                              : AppColors.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => context.go(
                          '/demo/${demo.role.routeKey}/${item.key}',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _HeroPanel(demo: demo, section: section),
                const SizedBox(height: 20),
                _MetricGrid(
                  metrics: section.metrics,
                  accentColor: demo.accentColor,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stack = constraints.maxWidth < 900;
                    final priorityPanel = _ListPanel(
                      title: 'Priority Queue',
                      subtitle: 'What needs attention first in this role view.',
                      items: section.queueItems,
                      accentColor: demo.accentColor,
                    );
                    final recentPanel = _ListPanel(
                      title: 'Recent Activity',
                      subtitle:
                          'Latest actions and timeline events in the demo flow.',
                      items: section.recentItems,
                      accentColor: AppColors.shieldBlue,
                    );

                    if (stack) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          priorityPanel,
                          const SizedBox(height: 20),
                          recentPanel,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: priorityPanel),
                        const SizedBox(width: 20),
                        Expanded(child: recentPanel),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _ListPanel(
                  title: 'Operational Insights',
                  subtitle:
                      'Management-ready talking points and observations for this screen.',
                  items: section.insightItems,
                  accentColor: AppColors.shieldNavy,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleSidebar extends StatelessWidget {
  final DemoRoleData demo;
  final String activeSectionKey;

  const _RoleSidebar({required this.demo, required this.activeSectionKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHIELD',
                  style: AppTypography.h3.copyWith(color: demo.accentColor),
                ),
                const SizedBox(height: 6),
                Text(
                  demo.role.label,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  demo.regionLabel,
                  style: AppTypography.tiny.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: demo.sections.map((section) {
                final isActive = section.key == activeSectionKey;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go(
                      '/demo/${demo.role.routeKey}/${section.key}',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? demo.accentColor.withValues(alpha: 0.12)
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: AppTypography.body.copyWith(
                              color: isActive
                                  ? demo.accentColor
                                  : AppColors.darkGray,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            section.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.tiny.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              text: 'Back to Login',
              type: AppButtonType.outline,
              onPressed: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleDrawer extends StatelessWidget {
  final DemoRoleData demo;
  final String activeSectionKey;

  const _RoleDrawer({required this.demo, required this.activeSectionKey});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHIELD',
                    style: AppTypography.h3.copyWith(color: demo.accentColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    demo.role.label,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    demo.regionLabel,
                    style: AppTypography.tiny.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: demo.sections.map((section) {
                  final isActive = section.key == activeSectionKey;
                  return ListTile(
                    selected: isActive,
                    selectedTileColor: demo.accentColor.withValues(alpha: 0.12),
                    title: Text(section.title),
                    subtitle: Text(
                      section.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/demo/${demo.role.routeKey}/${section.key}');
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                text: 'Back to Login',
                type: AppButtonType.outline,
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoHeader extends StatelessWidget {
  final DemoRoleData demo;
  final DemoSectionData section;

  const _DemoHeader({required this.demo, required this.section});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (context) {
            final scaffold = Scaffold.maybeOf(context);
            final showMenu = scaffold?.hasDrawer ?? false;
            if (!showMenu) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
              ),
            );
          },
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                demo.role.label,
                style: AppTypography.tiny.copyWith(
                  color: demo.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(section.title, style: AppTypography.h2),
              const SizedBox(height: 4),
              Text(
                demo.headline,
                style: AppTypography.small.copyWith(color: AppColors.gray),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RoleSwitcher(demo: demo),
      ],
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  final DemoRoleData demo;

  const _RoleSwitcher({required this.demo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SHIELDRole>(
          value: demo.role,
          items: SHIELDRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.label, style: AppTypography.small),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              context.go('/demo/${value.routeKey}/dashboard');
            }
          },
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final DemoRoleData demo;
  final DemoSectionData section;

  const _HeroPanel({required this.demo, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            demo.accentColor.withValues(alpha: 0.95),
            AppColors.shieldNavy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(demo.icon, color: AppColors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          demo.operatorName,
                          style: AppTypography.body.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          demo.regionLabel,
                          style: AppTypography.tiny.copyWith(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  section.summary,
                  style: AppTypography.h4.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 320,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: section.actions.map((action) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    action,
                    style: AppTypography.small.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<DemoMetric> metrics;
  final Color accentColor;

  const _MetricGrid({required this.metrics, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;

        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: AppTypography.small.copyWith(color: AppColors.gray),
                  ),
                  const Spacer(),
                  Text(
                    metric.value,
                    style: AppTypography.h2.copyWith(color: accentColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    metric.note,
                    style: AppTypography.tiny.copyWith(
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ListPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<DemoListItem> items;
  final Color accentColor;

  const _ListPanel({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h4),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(color: AppColors.gray),
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle,
                            style: AppTypography.small.copyWith(
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _TagChip(label: item.meta, color: AppColors.gray),
                              _TagChip(label: item.status, color: accentColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.tiny.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
