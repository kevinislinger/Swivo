# Swivo App – Developer Guide

## Overview
Swivo helps small groups quickly reach consensus by swiping through category-specific options (e.g., cuisines, movies). Users anonymously join a “swiping session,” like or dislike each option in Tinder-style fashion, and the first option liked by **N** participants ends the session as the match. Push notifications keep everyone in sync.

## Tech Stack
- **Frontend**: SwiftUI (iOS 17+)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)

---

## High-Level User Flow
1. Launch app → Landing Screen lists **Open Sessions**.
2. User may:
   a. **Start Session** → choose category, set _match quorum_ (N), receive invite code.
   b. **Join Session** → enter invite code.
   c. **Continue Session** → resume swiping on an open session.
3. Swipe Deck presents category options in random order.
4. When ≥ N users like the same option, **Match Found** → close session → push notification to all members.
5. Results appear in **Closed Sessions** list; creator may also manually close sessions.

---

## App Screens & States
### 1. Landing Screen
- List of **Open Sessions** (joined but unmatched)
- Pull-to-refresh (swipe down) or automatic refresh on view appear fetches latest session statuses; if any session status becomes `matched`, the app automatically navigates to the corresponding Results screen.
- Primary actions:
  - “Start Session”
  - “Join Session”
- Session cell shows: category icon, quorum _N_, participants joined / N, last updated time.

### 2. Start Session Flow
1. Select **Category** from predefined list.
2. Set **Match Quorum (N)** (2-5, default 2).
3. Session created in Supabase; user becomes _creator_.
4. Display **Invite Code & Share Sheet**.
5. Creator may immediately start swiping.

### 3. Join Session Flow
1. Input invite code.
2. Validate via Supabase RPC; fetch session meta & deck.
3. **Server-side guard**: reject join if `session_participants` count ≥ `sessions.quorum_n` (client shows “Session full” alert).
4. If session already matched/closed → show read-only result.
5. Else → enter Swipe Deck.

### 4. Swipe Deck Screen
- Full-screen card with option image & label.
- Gestures: swipe right (like), left (dislike).
- Progress indicator (cards remaining).
- Toolbar: leave session, session info.
- After a **like** is sent, the client calls `like_option(session_id, option_id)` (RPC) which returns `{ match_found: bool, matched_option_id? }`; if `match_found` == true navigate immediately to Results.
- If push notifications are disabled, this RPC-based response still guarantees instant result feedback to the liking user.
- Real-time outcome polling fallback: the deck view listens for a `match_found` flag returned from each like instead of relying on APNs.
- Real-time listener for **match events** → navigate to Results.

### 5. Results Screen
- Matched option image, label, list of agreeing users.
- “Start New Session” CTA.

### 6. Closed Sessions
- Historical list (matched or manually closed) sorted by date.
- Tapping shows Results screen.

### 7. Settings / Profile
- Anonymous device authentication (Supabase `auth.anonymous()`).
- User can set **Username** (defaults to `anon-<random>`).

---

## Matching Algorithm
```
if likes_for_option[user_id] == true for ≥ N distinct users:
    mark session.status = "matched"
    save matched_option_id
    notify participants
```
Implementation:
1. Each **like** inserts a row into `likes` (`session_id`, `option_id`, `user_id`). Dislikes are not stored.
2. A Postgres trigger counts distinct `user_id` per `option_id` within the session.
3. When count == N → update `sessions.status` to `matched`, store `matched_option_id`, and write `matched_at`.
4. Edge Function sends APNs to all `session_participants`.

---

## Data Model (Supabase)
| Table | Purpose |
|-------|---------|
| `users` | id (uuid), username, apns_token (nullable), created_at |
| `categories` | id, name |
| `sessions` | id, creator_id, category_id (fk), quorum_n, status (open/matched/closed), matched_option_id, invite_code, created_at |
| `session_participants` | session_id, user_id, joined_at (CHECK: participant_count(session_id) < quota at insert time) |
| `options` | id, category_id (fk), label, image_url |
| `session_options` | session_id, option_id, order_index |
| `likes` | id, session_id, option_id, user_id, created_at |

Indexes & RLS policies secure rows per `session_id` membership (also include a BEFORE INSERT trigger on `session_participants` that raises an exception when `SELECT COUNT(*) FROM session_participants WHERE session_id = NEW.session_id` >= `(SELECT quorum_n FROM sessions WHERE id = NEW.session_id)`).

---

## Notifications
- **Client registration**: On app launch or APNs token refresh, the iOS client calls `update_apns_token(token)` (Supabase RPC) to upsert the token into `users.apns_token` (or set to NULL when the user disables notifications).
- **Edge Function `notify_match()`** (triggered on `UPDATE sessions SET status='matched'`) queries `users.apns_token` for all participants, filters out NULLs, and sends APNs payloads to each token.
- Tokens flagged as invalid by APNs are set to NULL on the next failed send.

---

## Error & Edge-Case Handling
- If push notifications are disabled, match visibility still works:
  1. Immediate RPC response after a like.
  2. Periodic pull-to-refresh or on-launch fetch of open sessions.
- If a user finishes deck before match, they see a final screen where they can navigated back to the Landing Screen (Open Sessions list) where they can pull to refresh or will see the match on a future app launch.
- Creator may **Manually Close** session → status=`closed` (no match).
- Likes recorded idempotently; unique constraint (`session_id`,`option_id`,`user_id`) prevents duplicates.
- Network offline → local queue swipes, sync when online.

---

## Project Structure

```text
Swivo/
├── app/                                  # iOS client application
│   └── Swivo/                            # Xcode workspace
│       ├── Swivo/                        # SwiftUI app target & source files
│       │   ├── Assets.xcassets/          # App icons & colors
│       │   ├── ContentView.swift         # Root view (for previews)
│       │   ├── SwivoApp.swift            # @main entry point
│       │   ├── Features/                 # Feature-oriented SwiftUI modules
│       │   │   ├── Landing/              # Open / Closed sessions list
│       │   │   ├── StartSession/
│       │   │   ├── JoinSession/
│       │   │   ├── SwipeDeck/
│       │   │   ├── Results/
│       │   │   └── Settings/
│       │   ├── Models/                   # Shared Codable models & view models
│       │   ├── Networking/               # Supabase client & HTTP helpers
│       │   ├── Services/                 # Push notifications, persistence, analytics
│       │   ├── Extensions/               # Swift helpers & modifiers
│       │   └── Resources/                # Asset catalogs, localization files
│       ├── SwivoTests/                   # Unit tests
│       └── SwivoUITests/                 # UI tests (XCTest & XCTestPlan)
│
├── backend/                              # Supabase backend
│   └── supabase/
│       ├── migrations/                   # auto-generated DB migration scripts
│       ├── sql/                          # hand-written schema, views & triggers
│       ├── functions/                    # Edge Functions (TypeScript)
│       │   ├── like_option/
│       │   │   └── index.ts
│       │   ├── notify_match/
│       │   │   └── index.ts
│       │   └── update_apns_token/
│       │       └── index.ts
│       ├── seed/                         # Seed data (e.g., default categories)
│       └── README.md                     # Backend setup instructions
│
├── scripts/                              # Dev & CI helper scripts
│   ├── format.sh
│   ├── ci_build_ios.sh
│   └── deploy_supabase.sh
│
├── .github/                              # GitHub Actions workflows
│   └── workflows/
│       ├── ios-ci.yml                    # iOS CI pipeline (build & tests)
│       └── supabase-deploy.yml           # Supabase migration & function deploy
│
├── docs/                                 # Project documentation
│   └── CONTEXT.md                        # Developer guide (this file)
│
├── .gitignore                            # Git & Xcode derived data rules
│
├── .env                                  # Sample environment variables
│
└── README.md                             # Project overview & setup
```

