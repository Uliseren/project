# Uliseren — Project meta-repo

Umbrella for the Uliseren household-expenses app. Two real codebases are
cloned as siblings by `init.sh`:

- `back/` — Django 5 + DRF + SQLite. Source of truth: `back/CLAUDE.md`.
- `front/` — Next.js 15 + TS + Tailwind v4 + shadcn. Source of truth: `front/CLAUDE.md`.

Each is an independent git repo (gitignored here) and deploys autonomously
on push to `master`. Touch them with separate commits in their own repo.

## Where to read first

When starting any task, after reading this file:

1. If the task is back-end → `Read back/CLAUDE.md`.
2. If the task is front-end → `Read front/CLAUDE.md`.
3. If the task spans both (e.g. new endpoint + new UI), read both.

## Conventions

- English in code, docs, and commit messages.
- Commit style (both repos): short imperative past-tense, no attribution.
- This meta-repo holds only onboarding / shared docs. Code changes go in
  `back/` or `front/`, never here.

## Verification

Before committing, verify your change in the repo you touched. Deploys are
autonomous on push to `master` and there is **no test gate in CI**, so the
local check is the only safety net.

```bash
# back/
cd back && uv run ruff check . && uv run pytest

# front/
cd front && npx tsc --noEmit && npm run lint
```

Note: test coverage is sparse (`back/CLAUDE.md` → "Known pitfalls"; front has
no tests yet). A green run is necessary but not sufficient — sanity-check the
behaviour you changed.

## Bootstrap

`./init.sh` clones both repos and installs deps. Re-runnable.
