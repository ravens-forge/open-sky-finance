import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/l10n.dart';
import '../core/widgets/not_found_gate.dart';
import '../core/widgets/not_found_page.dart';
import '../data/enums/category_kind.dart';
import '../data/enums/transaction_type.dart';
import '../data/providers.dart';
import '../features/assets_accounts/pages/assets_account_detail_page.dart';
import '../features/assets_accounts/pages/assets_account_editor_page.dart';
import '../features/assets_accounts/pages/assets_accounts_page.dart';
import '../features/categories/pages/categories_page.dart';
import '../features/categories/pages/category_editor_page.dart';
import '../features/categories/pages/category_group_editor_page.dart';
import '../features/onboarding/pages/onboarding_page.dart';
import '../features/onboarding/providers/onboarding_provider.dart';
import '../features/shell/models/main_page.dart';
import '../features/transactions/pages/transaction_editor_page.dart';
import '../features/transactions/pages/transactions_page.dart';
import '../features/shell/pages/main_shell.dart';
import '../features/shell/pages/stub_page.dart';
import 'routes.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final rootKey = GlobalKey<NavigatorState>();

  // Re-runs the redirect when the onboarding state loads or changes.
  final onboarding = ValueNotifier<bool?>(null);
  ref.listen(
    onboardingProvider,
    (_, next) => onboarding.value = next.value?.steps.isNotEmpty,
    fireImmediately: true,
  );

  void goHome(BuildContext context) => context.go(Routes.home);

  // Full-screen editor on the root navigator, above the shell.
  Page<void> editor(GoRouterState state, Widget child) =>
      MaterialPage(key: state.pageKey, fullscreenDialog: true, child: child);

  // The type a new transaction starts with (`/transactions/new?type=income`).
  TransactionType typeOf(GoRouterState state) =>
      TransactionType.values.firstWhere(
        (type) => type.name == state.uri.queryParameters['type'],
        orElse: () => TransactionType.expense,
      );

  // The type a new category or group is created with.
  CategoryKind kindOf(GoRouterState state) => CategoryKind.values.firstWhere(
    (kind) => kind.name == state.uri.queryParameters['kind'],
    orElse: () => CategoryKind.expense,
  );

  // Shows the not-found page when [find] resolves to null.
  Widget gate(
    BuildContext context,
    String id,
    Future<Object?> Function() find,
    Widget child,
  ) => NotFoundGate(
    key: ValueKey(id),
    find: find,
    onHome: () => goHome(context),
    child: child,
  );

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.home,
    refreshListenable: onboarding,
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      // The welcome step links to Backups (restore, Bluecoins import).
      final allowed = atOnboarding || state.uri.path == Routes.backups;
      return switch (onboarding.value) {
        true when !allowed => Routes.onboarding,
        false when atOnboarding => Routes.home,
        _ => null,
      };
    },
    errorBuilder: (context, state) =>
        NotFoundPage(onHome: () => goHome(context)),
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => shell,
        navigatorContainerBuilder: (context, shell, children) =>
            MainShell(navigationShell: shell, children: children),
        branches: [
          for (final page in MainPage.values)
            StatefulShellBranch(
              // Swiping shows the neighbour page before it is selected.
              preload: true,
              routes: [
                GoRoute(
                  path: page.path,
                  // ponytail: empty until each main page is built.
                  builder: (context, state) => switch (page) {
                    MainPage.transactions => const TransactionsPage(),
                    _ => const SizedBox.expand(),
                  },
                  routes: switch (page) {
                    MainPage.transactions => [
                      GoRoute(
                        path: 'new',
                        parentNavigatorKey: rootKey,
                        pageBuilder: (context, state) => editor(
                          state,
                          TransactionEditorPage(type: typeOf(state)),
                        ),
                      ),
                      GoRoute(
                        path: ':transactionId',
                        parentNavigatorKey: rootKey,
                        pageBuilder: (context, state) {
                          final id = state.pathParameters['transactionId']!;
                          return editor(
                            state,
                            gate(
                              context,
                              id,
                              () => ref
                                  .read(transactionsRepositoryProvider)
                                  .findById(id),
                              TransactionEditorPage(id: id),
                            ),
                          );
                        },
                      ),
                    ],
                    MainPage.reminders => [
                      GoRoute(
                        path: 'new',
                        parentNavigatorKey: rootKey,
                        pageBuilder: (context, state) => editor(
                          state,
                          StubPage(title: context.l10n.editorNewReminder),
                        ),
                      ),
                      // ponytail: no reminder lookup until the reminders
                      // repository exists; gate it like the others then.
                      GoRoute(
                        path: ':reminderId',
                        parentNavigatorKey: rootKey,
                        pageBuilder: (context, state) => editor(
                          state,
                          StubPage(title: context.l10n.editorEditReminder),
                        ),
                      ),
                    ],
                    _ => const [],
                  },
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: Routes.calendar,
        builder: (context, state) => StubPage(title: context.l10n.pageCalendar),
      ),
      GoRoute(
        path: Routes.assetsAccounts,
        builder: (context, state) => const AssetsAccountsPage(),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (context, state) =>
                editor(state, const AssetsAccountEditorPage()),
          ),
          GoRoute(
            path: ':assetsAccountId',
            builder: (context, state) {
              final id = state.pathParameters['assetsAccountId']!;
              return gate(
                context,
                id,
                () => ref.read(assetsAccountsRepositoryProvider).findById(id),
                AssetsAccountDetailPage(id: id),
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['assetsAccountId']!;
                  return editor(
                    state,
                    gate(
                      context,
                      id,
                      () => ref
                          .read(assetsAccountsRepositoryProvider)
                          .findById(id),
                      AssetsAccountEditorPage(id: id),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.categories,
        builder: (context, state) => const CategoriesPage(),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (context, state) => editor(
              state,
              CategoryEditorPage(
                kind: kindOf(state),
                groupId: state.uri.queryParameters['groupId'],
              ),
            ),
          ),
          GoRoute(
            path: 'groups/new',
            pageBuilder: (context, state) =>
                editor(state, CategoryGroupEditorPage(kind: kindOf(state))),
          ),
          GoRoute(
            path: 'groups/:groupId',
            pageBuilder: (context, state) {
              final id = state.pathParameters['groupId']!;
              return editor(
                state,
                gate(
                  context,
                  id,
                  () =>
                      ref.read(categoriesRepositoryProvider).findGroupById(id),
                  CategoryGroupEditorPage(id: id),
                ),
              );
            },
          ),
          GoRoute(
            path: ':categoryId',
            pageBuilder: (context, state) {
              final id = state.pathParameters['categoryId']!;
              return editor(
                state,
                gate(
                  context,
                  id,
                  () => ref.read(categoriesRepositoryProvider).findById(id),
                  CategoryEditorPage(id: id),
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.trash,
        builder: (context, state) => StubPage(title: context.l10n.pageTrash),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => StubPage(title: context.l10n.pageSettings),
        routes: [
          GoRoute(
            path: 'home-sections',
            builder: (context, state) =>
                StubPage(title: context.l10n.pageArrangeHome),
          ),
          GoRoute(
            path: 'backups',
            builder: (context, state) =>
                StubPage(title: context.l10n.pageBackups),
          ),
          GoRoute(
            path: 'report-bug',
            builder: (context, state) =>
                StubPage(title: context.l10n.actionReportBug),
          ),
        ],
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.erased,
        builder: (context, state) => StubPage(title: context.l10n.pageErased),
      ),
      GoRoute(
        path: Routes.support,
        builder: (context, state) => StubPage(title: context.l10n.pageSupport),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    onboarding.dispose();
  });
  return router;
}
