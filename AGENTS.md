# IRMS Repository

Monorepo with two independently runnable projects: **backend** (Node.js/Fastify) and **mobile** (Flutter).

---

## Backend (`backend/`)

### Run Commands
- `npm run dev` — Start dev server with hot reload (`tsx watch src/app.ts`)
- `npm start` — Start production server
- `npm run migrate` — Run SQL migrations from `migrations/*.sql`
- `npm run typecheck` — TypeScript type check (`tsc --noEmit`)

### Architecture
- **Entry:** `src/app.ts` — Fastify 5.x app, registers routes, Redis, Socket.io, auto-escalation
- **Modules:** `src/modules/{auth,incidents,media,notifications,admin,contacts,realtime}/`
- **DB:** PostgreSQL via `pg`, migrations in `migrations/*.sql`
- **Cache/Session:** Redis via `ioredis`
- **Auth:** JWT (access + refresh tokens)
- **Media:** S3-compatible (local/Minio in dev, real S3 in prod), controlled by `MEDIA_BACKEND=local` env
- **Realtime:** Socket.io on the same port as the HTTP server

### Environment
- Config via `backend/.env` — copy and adjust for local dev
- Key vars: `PG_HOST`, `PG_PORT`, `REDIS_HOST`, `REDIS_PORT`, `JWT_SECRET`, `PORT`, `CORS_ORIGIN`, `S3_*`, `MEDIA_BACKEND`
- Docker services: `docker-compose.yml` provides PostgreSQL (port 5433) and Redis (port 6379)

### Database
- Run migrations before first start: `npm run migrate`
- Migration files are numbered (`001_init.sql` → `006_user_id_format.sql`) and run in order

---

## Mobile (`mobile/`)

### Run Commands
- `flutter run` — Run on connected device/emulator
- `flutter analyze` — Static analysis (flutter_lints)
- `flutter gen-l10n` — Generate localization from `lib/l10n/*.arb`

### Architecture
- **Entry:** `lib/main.dart` — Initializes storage, network discovery, Dio client, Socket client, BLoC providers
- **State:** BLoC pattern (`flutter_bloc`)
- **Routing:** `go_router` (declarative, configured in `lib/app/router.dart`)
- **Network:** `dio` for REST, `socket_io_client` for realtime
- **Storage:** `flutter_secure_storage` for tokens
- **Localization:** ARB files in `lib/l10n/`, generated via `l10n.yaml` config (`flutter: generate: true`)
- **JSON:** Uses `json_serializable` + `build_runner` — run `dart run build_runner build` after modifying models

### Features
- `features/{auth,incidents,dispatcher,admin,contacts,map}/` — Feature-based structure
- Each feature has `repo/`, `cubit/`, `model/` subdirectories

### Key Packages
- Maps: `flutter_map` + `latlong2` (OpenStreetMap-based, no API key required)
- Auth: `local_auth` for biometrics
- Location: `geolocator`
- Speech: `speech_to_text`

---

## Agent Skills

Repo-local skills are in `.agents/skills/` (22 skills focused on Flutter/Dart development).
These are referenced by `skills-lock.json` and provide specialized guidance for:
- Dart testing, mocking, static analysis
- Flutter widget/integration tests, responsive layouts, JSON serialization
- Build/run commands for Dart CLI apps

---

## General Notes

- **No CI/CD** workflows found in `.github/workflows/`
- **No root-level task runner** — each project is run independently
- Mobile uses `NetworkDiscovery` to auto-detect backend URL at startup (for connecting to local dev backend on same network)
- Backend CORS defaults to `*` in dev; mobile runs on whatever port Flutter assigns (auto-selected)