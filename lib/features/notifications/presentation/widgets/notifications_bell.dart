import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../cubit/notifications_cubit.dart';

/// Bell button that opens Notifications, with a badge counting the alerts
/// the user hasn't seen yet.
class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select(
      (NotificationsCubit cubit) => cubit.state.newCount,
    );

    return IconButton(
      // push, not go, so back returns to the dashboard.
      onPressed: () => context.push(RoutePaths.notifications),
      tooltip: count == 0 ? 'Notifications' : 'Notifications, $count new',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(count > 0 ? Icons.notifications : Icons.notifications_none),
      ),
    );
  }
}
