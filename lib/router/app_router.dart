import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/asbaq_screen.dart';
import '../models/book_model.dart';
import '../models/book_reader_args.dart';
import '../models/irshad_firestore_model.dart';
import '../models/event_firestore_model.dart';
import '../models/news_firestore_model.dart';
import '../auth/auth_provider.dart';
import '../screens/book_detail_screen.dart';
import '../screens/book_reader_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/books_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/home_screen.dart';
import '../screens/irshadat_screen.dart';
import '../screens/irshadat_bookmarks_screen.dart';
import '../screens/news_detail_screen.dart';
import '../screens/news_events_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sabaq_list_screen.dart';
import '../models/shajra_entry_model.dart';
import '../screens/shajra_detail_screen.dart';
import '../screens/shajra_pdf_screen.dart';
import '../screens/shajra_urdu_pdf_screen.dart';
import '../screens/shijra_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/add_data_screen.dart';
import '../screens/add_book_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/admin_upload_book_screen.dart';
import '../screens/admin_irshadat_screen.dart';
import '../screens/admin_news_events_screen.dart';
import '../screens/admin_shajra_urdu_details_screen.dart';
import '../screens/admin_upload_shajra_urdu_detail_screen.dart';
import '../screens/admin_upload_gallery_images_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/super_admin_panel_screen.dart';
import '../screens/super_admin_users_screen.dart';
import '../screens/admin_upload_asbaq_screen.dart';
import '../screens/admin_social_links_screen.dart';
import '../screens/admin_upload_sabaq_screen.dart';
import '../screens/admin_sabaq_requests_screen.dart';

GoRouter createAppRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      const authRoutes = {'/login', '/signup', '/forgot-password'};
      final onAuthRoute = authRoutes.contains(loc);
      final isAuthed = auth.isAuthenticated;

      if (!isAuthed) {
        return onAuthRoute ? null : '/login';
      }

      // If signed in, keep auth screens inaccessible.
      if (onAuthRoute) return '/home';

      // Add Data is admin-only.
      if (loc.startsWith('/profile/add-data') && !auth.isAdminOrHigher) {
        return '/home';
      }

      // Role-based guards for admin routes.
      if (loc.startsWith('/admin') && !auth.isAdminOrHigher) {
        return '/home';
      }
      if (loc.startsWith('/super-admin') && !auth.isSuperAdmin) {
        return '/home';
      }
      // Asbaq-e-Tareeqat: Admin / Super Admin only (same as home grid).
      if (loc == '/asbaq' || loc.startsWith('/asbaq/')) {
        if (!auth.isAdminOrHigher) return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/sabaq',
        builder: (context, state) => const SabaqListScreen(),
      ),
      GoRoute(
        path: '/irshadat',
        builder: (context, state) => const IrshadatScreen(),
      ),
      GoRoute(
        path: '/shijra',
        builder: (context, state) => const ShijraScreen(),
      ),
      GoRoute(
        path: '/shajra',
        builder: (context, state) => const ShijraScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! ShajraDetailRouteArgs) {
                return const _ShajraDetailMissing();
              }
              return ShajraDetailScreen(args: extra);
            },
          ),
          GoRoute(
            path: 'pdf',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! ShajraPdfRouteArgs) {
                return const _ShajraDetailMissing();
              }
              return ShajraPdfScreen(args: extra);
            },
          ),
          GoRoute(
            path: 'urdu-pdf',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! ShajraUrduPdfArgs) {
                return const _ShajraDetailMissing();
              }
              return ShajraUrduPdfScreen(args: extra);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: '/asbaq',
        builder: (context, state) => const AsbaqScreen(),
      ),
      GoRoute(
        path: '/books',
        builder: (context, state) => const BooksScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final book = state.extra as BookModel?;
              final id = state.uri.queryParameters['id'] ?? book?.id;
              return BookDetailScreen(
                initialBook: book,
                bookId: id,
              );
            },
          ),
          GoRoute(
            path: 'reader',
            builder: (context, state) {
              final args = state.extra as BookReaderArgs?;
              if (args == null) {
                return const _MissingBookPlaceholder();
              }
              return BookReaderScreen(args: args);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
        routes: [
          GoRoute(
            path: 'irshadat',
            builder: (context, state) => const IrshadatBookmarksScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/news-events',
        builder: (context, state) => const NewsEventsScreen(),
        routes: [
          GoRoute(
            path: 'news-detail',
            builder: (context, state) {
              final extra = state.extra;
              final id = extra is NewsFirestoreModel
                  ? extra.id
                  : (state.uri.queryParameters['id'] ?? 'n1');
              return NewsDetailScreen(
                newsId: id,
                initial: extra is NewsFirestoreModel ? extra : null,
              );
            },
          ),
          GoRoute(
            path: 'event-detail',
            builder: (context, state) {
              final extra = state.extra;
              final id = extra is EventFirestoreModel
                  ? extra.id
                  : (state.uri.queryParameters['id'] ?? 'e1');
              return EventDetailScreen(
                eventId: id,
                initial: extra is EventFirestoreModel ? extra : null,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/add-data',
        builder: (context, state) => const AddDataScreen(),
        routes: [
          GoRoute(
            path: 'books',
            builder: (context, state) => const AddBookScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/admin/add-data',
        builder: (context, state) => const AddDataScreen(),
        routes: [
          GoRoute(
            path: 'books',
            builder: (context, state) => const AdminUploadBookScreen(),
          ),
          GoRoute(
            path: 'shajra-urdu',
            builder: (context, state) => const AdminShajraUrduDetailsScreen(),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is! AdminShajraUrduUploadArgs) {
                    return const _ShajraDetailMissing();
                  }
                  return AdminUploadShajraUrduDetailScreen(args: extra);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'irshadat-english',
            builder: (context, state) => const AdminIrshadatScreen(
              initialLanguage: IrshadatLanguage.english,
            ),
          ),
          GoRoute(
            path: 'irshadat-urdu',
            builder: (context, state) => const AdminIrshadatScreen(
              initialLanguage: IrshadatLanguage.urdu,
            ),
          ),
          GoRoute(
            path: 'sabaq',
            builder: (context, state) => const AdminUploadSabaqScreen(),
          ),
          GoRoute(
            path: 'asbaq',
            builder: (context, state) => const AdminUploadAsbaqScreen(),
          ),
          GoRoute(
            path: 'news-events',
            builder: (context, state) => const AdminNewsEventsScreen(),
          ),
          GoRoute(
            path: 'gallery',
            builder: (context, state) => const AdminUploadGalleryImagesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/books',
        builder: (context, state) => const AdminUploadBookScreen(),
      ),
      GoRoute(
        path: '/admin/irshadat',
        builder: (context, state) => const AdminIrshadatScreen(),
      ),
      GoRoute(
        path: '/admin/sabaq',
        builder: (context, state) => const AdminUploadSabaqScreen(),
      ),
      GoRoute(
        path: '/admin/sabaq-requests',
        builder: (context, state) => const AdminSabaqRequestsScreen(),
      ),
      GoRoute(
        path: '/admin/social-links',
        builder: (context, state) => const AdminSocialLinksScreen(),
      ),
      GoRoute(
        path: '/admin/asbaq',
        builder: (context, state) => const AdminUploadAsbaqScreen(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminPanelScreen(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const SuperAdminUsersScreen(),
          ),
        ],
      ),
    ],
  );
}

class _ShajraDetailMissing extends StatelessWidget {
  const _ShajraDetailMissing();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Open a Shajra entry from the list to view details.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingBookPlaceholder extends StatelessWidget {
  const _MissingBookPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No book was provided for the reader.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

