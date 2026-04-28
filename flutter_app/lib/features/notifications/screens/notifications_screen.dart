import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Wire up NotificationsBloc
    final mockNotifications = [
      _MockNotif('New job near you 📍', 'House Cleaning — KES 2,500 in Kilimani', '2m ago', Icons.work_outline, KaziTheme.primary),
      _MockNotif('Application received', 'John M. applied for your Plumbing job', '15m ago', Icons.person_outline, KaziTheme.info),
      _MockNotif('Payment secured 🔒', 'KES 1,800 held in escrow for: Garden Work', '1h ago', Icons.lock_outline, KaziTheme.success),
      _MockNotif('New message', 'Grace K.: I can start at 8am tomorrow', '2h ago', Icons.chat_bubble_outline, KaziTheme.accent),
      _MockNotif('Payment sent 💸', 'KES 2,250 sent to your M-Pesa', '1d ago', Icons.payments_outlined, KaziTheme.success),
    ];

    return Scaffold(
      backgroundColor: KaziTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read', style: TextStyle(
              fontFamily: 'Sora', fontSize: 13, color: KaziTheme.primary,
            )),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(KaziSpacing.md),
        itemCount: mockNotifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: KaziSpacing.sm),
        itemBuilder: (context, i) {
          final n = mockNotifications[i];
          return Container(
            padding: const EdgeInsets.all(KaziSpacing.md),
            decoration: BoxDecoration(
              color: i < 2 ? n.color.withOpacity(0.04) : KaziTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: i < 2 ? n.color.withOpacity(0.2) : KaziTheme.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: n.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(n.icon, size: 20, color: n.color),
                ),
                const SizedBox(width: KaziSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(n.title, style: KaziText.bodyMedium)),
                          if (i < 2)
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: KaziTheme.primary, shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(n.body, style: KaziText.caption, maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(n.time, style: KaziText.caption.copyWith(color: KaziTheme.textHint)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MockNotif {
  final String title, body, time;
  final IconData icon;
  final Color color;
  _MockNotif(this.title, this.body, this.time, this.icon, this.color);
}
