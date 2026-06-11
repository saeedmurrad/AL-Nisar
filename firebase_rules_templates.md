## Firestore rules (role-based, public reads)

Role is stored in `users/{uid}.role` as one of: `user`, `admin`, `super_admin`.
Set a user as **Super Admin** by manually updating their `role` field in Firestore.

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function userDoc() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid));
    }

    function role() {
      return userDoc().data.role;
    }

    function isAdmin() {
      return signedIn() && (role() == 'admin' || role() == 'super_admin');
    }

    function isSuperAdmin() {
      return signedIn() && role() == 'super_admin';
    }

    // Public read, admin write
    match /books/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Irshadat (split by language)
    match /irshadat_en/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /irshadat_ur/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // News articles
    match /news/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Event announcements
    match /events/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Sabaq (general) lessons
    match /sabaq/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Sabaq PDFs (separate from books)
    match /sabaq_pdfs/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Super Admin in-app notifications (e.g. new Sabaq access requests)
    match /admin_notifications/{id} {
      allow read, update: if isSuperAdmin();
      allow create: if signedIn();
      allow delete: if false;
    }

    // Member requests for Sabaq access
    match /sabaq_access_requests/{id} {
      allow create: if signedIn()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.status == 'pending';

      // Users can read their own requests; admins can read all.
      allow read: if signedIn()
        && (
          resource.data.userId == request.auth.uid
          || isAdmin()
        );

      // Only admins can update request status / decisions.
      allow update: if isAdmin();
      allow delete: if false;
    }

    // Asbaq-e-Tareeqat lessons
    match /asbaq/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Asbaq-e-Tareeqat PDFs (separate from books)
    match /asbaq_pdfs/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Urdu Shajra details (number -> storagePath)
    match /shajra_urdu_details/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Gallery images metadata
    match /gallery_images/{id} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Users collection:
    // - users can create/read/update own profile
    // - super admin can list/update users (for promoting to admin)
    match /users/{uid} {
      allow create: if signedIn() && request.auth.uid == uid;
      allow read: if signedIn() && (request.auth.uid == uid || isSuperAdmin());
      // Users can update their own profile, but cannot change role.
      allow update: if signedIn()
        && (
          (request.auth.uid == uid
            && !( 'role' in request.resource.data
                  && request.resource.data.role != resource.data.role
                )
          )
          || isSuperAdmin()
        );
      allow delete: if false;

      // Per-user bookmarks/activity
      match /bookmarks/{bookmarkId} {
        allow read, write: if signedIn() && request.auth.uid == uid;
      }

      // Per-user Irshadat bookmarks
      match /irshadat_bookmarks/{bookmarkId} {
        allow read, write: if signedIn() && request.auth.uid == uid;
      }

      // Per-user Sabaq access grants (written by admins on approval)
      match /sabaq_access/{sabaqId} {
        allow read: if signedIn() && request.auth.uid == uid;
        allow write: if isAdmin();
      }

      // Per-user in-app notifications (written by admins on Sabaq decisions)
      match /notifications/{notificationId} {
        allow read, update: if signedIn() && request.auth.uid == uid;
        allow create: if isAdmin();
        allow delete: if false;
      }
    }
  }
}
```

## Storage rules (public reads for content, admin-only writes)

```js
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function signedIn() {
      return request.auth != null;
    }

    function role() {
      return firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role;
    }

    function isAdmin() {
      return signedIn() && (role() == 'admin' || role() == 'super_admin');
    }

    // Books PDFs + optional covers
    match /books/{allPaths=**} {
      allow read: if true;    // get + list
      allow write: if isAdmin();
    }

    match /book_covers/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Asbaq PDFs + thumbnails
    match /asbaq_pdfs/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /asbaq_thumbs/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Sabaq PDFs + thumbnails (separate folders from Asbaq)
    match /sabaq_pdfs/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /sabaq_thumbs/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Optional images for Irshadat cards
    match /irshadat_images/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // News & events images
    match /news_images/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    match /event_images/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Urdu Shajra PDFs (by number): shajra_urdu/<number>.pdf
    match /shajra_urdu/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Gallery images (high-quality originals)
    match /gallery_images/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // If you later upload PDFs/images for lessons, add folders here too.
  }
}

```

