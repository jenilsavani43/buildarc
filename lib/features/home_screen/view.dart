
import 'package:ardennes/libraries/account_context/bloc.dart';
import 'package:ardennes/libraries/account_context/state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bloc.dart';
import 'event.dart';
import 'recently_drawings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeScreenBloc(),
      child: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("here");
    final accountState = context.watch<AccountContextBloc>().state;

    // Dispatch event if the selected project is available
    if (accountState is AccountContextLoadedState &&
        accountState.selectedProject != null) {
      print("Ca;;");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<HomeScreenBloc>()
            .add(FetchHomeScreenContentEvent(accountState.selectedProject!));
      });
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Welcome, ${FirebaseAuth.instance.currentUser?.displayName ?? ""}",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          "Here's what's happening on your projects today.",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.sticky_note_2),
            title: const Text('Add Sheets'),
            onTap: () => context.go('/drawing-publish/file-upload'),
          ),
        ),
        const RecentlyViewedDrawings(),
      ],
    );
  }
}
