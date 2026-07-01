import 'package:flutter/material.dart';
import 'package:suraksha_women_safety_app/features/cybercrime/data/cyber_law_data.dart';
import 'package:suraksha_women_safety_app/localization/app_localizations.dart';

/// Completely redesigned Learn tab — Cyber Crime Law Library.
/// All content is embedded offline (no backend dependency).
class CyberLearningTab extends StatelessWidget {
  const CyberLearningTab({
    super.key,
    required this.service,
    required this.onApiError,
  });

  // kept for API compatibility with parent widget, not used
  final dynamic service;
  final dynamic onApiError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Header ──────────────────────────────────────
        SliverToBoxAdapter(
          child: _HubHeader(l10n: l10n, isDark: isDark),
        ),

        // ── Topic Grid ───────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _TopicCard(
                topic: kCyberLawTopics[index],
                langCode: langCode,
                isDark: isDark,
              ),
              childCount: kCyberLawTopics.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
          ),
        ),

        // ── Emergency Helpline Banner ──────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: _HelplineBanner(l10n: l10n, isDark: isDark),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hub Header
// ─────────────────────────────────────────────────────────────
class _HubHeader extends StatelessWidget {
  const _HubHeader({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('cyberLawHubTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.t('cyberLawHubSubtitle'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Topic Card (grid tile)
// ─────────────────────────────────────────────────────────────
class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.langCode,
    required this.isDark,
  });

  final CyberLawTopic topic;
  final String langCode;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final content = topic.contentFor(langCode);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CyberLawDetailPage(
            topic: topic,
            langCode: langCode,
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? const Color(0xFF1A2536) : Colors.white,
          border: Border.all(
            color: topic.color.withOpacity(0.22),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: topic.color.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon chip
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: topic.color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(topic.icon, color: topic.color, size: 24),
            ),
            const Spacer(),
            // title
            Text(
              content.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.3,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            // applicable acts badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: topic.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                content.short,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: topic.color,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpline Banner
// ─────────────────────────────────────────────────────────────
class _HelplineBanner extends StatelessWidget {
  const _HelplineBanner({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1A2536) : Colors.white,
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phone_in_talk_rounded,
              color: Color(0xFF3B82F6),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('cyberLawHelplineTitle'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.t('cyberLawHelplineDesc'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF516078),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Detail Page
// ─────────────────────────────────────────────────────────────
class CyberLawDetailPage extends StatelessWidget {
  const CyberLawDetailPage({
    super.key,
    required this.topic,
    required this.langCode,
  });

  final CyberLawTopic topic;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = topic.contentFor(langCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF0F4F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: topic.color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, right: 16, bottom: 14),
              title: Text(
                content.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [topic.color, topic.color.withOpacity(0.65)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      topic.icon,
                      size: 130,
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content sections ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Acts badge row
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Badge(
                      label: content.short,
                      color: topic.color,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Overview
                _SectionCard(
                  icon: Icons.info_outline_rounded,
                  color: topic.color,
                  title: l10n.t('cyberLawOverviewHeader'),
                  isDark: isDark,
                  child: Text(
                    content.overview,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Acts & Sections
                _SectionCard(
                  icon: Icons.gavel_rounded,
                  color: const Color(0xFF3B82F6),
                  title: l10n.t('cyberLawActsHeader'),
                  isDark: isDark,
                  child: _BulletList(
                    items: content.acts,
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Punishment
                _SectionCard(
                  icon: Icons.balance_rounded,
                  color: const Color(0xFFEF4444),
                  title: l10n.t('cyberLawPunishmentHeader'),
                  isDark: isDark,
                  child: _BulletList(
                    items: content.punishments,
                    color: const Color(0xFFEF4444),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 12),

                // What to do
                _SectionCard(
                  icon: Icons.shield_rounded,
                  color: const Color(0xFF059669),
                  title: l10n.t('cyberLawWhatToDoHeader'),
                  isDark: isDark,
                  child: _BulletList(
                    items: content.whatToDo,
                    color: const Color(0xFF059669),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Where to report
                _SectionCard(
                  icon: Icons.phone_in_talk_rounded,
                  color: const Color(0xFFF97316),
                  title: l10n.t('cyberLawReportHeader'),
                  isDark: isDark,
                  child: _BulletList(
                    items: content.whereToReport,
                    color: const Color(0xFFF97316),
                    isDark: isDark,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable UI sub-widgets
// ─────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.30), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.isDark,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1A2536) : Colors.white,
        border: Border.all(color: color.withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.items,
    required this.color,
    required this.isDark,
  });

  final List<String> items;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 10),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
