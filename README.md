# MyCareNK

A health service platform for Nong Khai province — free condom and lubricant requests, monthly quota tracking, and QR pickup confirmation.

## Projects

| Directory | Description | Stack |
|-----------|-------------|-------|
| `app/` | Mobile app for end users | Flutter (Dart) |
| `web/` | Staff portal for health workers | React + TypeScript + Vite |

## Setup

### App (Flutter)
```bash
cd app
cp .env.example .env   # fill in Supabase URL and anon key
flutter pub get
flutter run
```

### Web (React)
```bash
cd web
cp .env.example .env   # fill in Supabase URL and anon key
npm install
npm run dev
```

## Supabase

Both projects share the same Supabase backend (ap-southeast-1). Edge Functions are located in `web/supabase/functions/`.
