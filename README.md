# Uliseren — Project meta-repo

Umbrella repo for the **Uliseren** household-expenses app. It bundles
onboarding scripts, shared docs and pointers to the two real codebases:

- **back/** — Django REST API ([Uliseren/back](https://github.com/Uliseren/back))
- **front/** — Next.js front-end ([Uliseren/front](https://github.com/Uliseren/front))

Both subdirectories are independent git repos and are gitignored here.

## Onboarding (new developer)

```bash
git clone <this-repo-url> uliseren-project
cd uliseren-project
./init.sh
```

`init.sh` clones `back/` and `front/`, runs `uv sync` + `migrate` on the
back, and `npm install` on the front. Re-running it is safe — it skips
repos that already exist.

### Requirements

- Python 3.13 + [`uv`](https://docs.astral.sh/uv/)
- Node.js >= 20 + `npm`
- `git`

### Running

```bash
# back
cd back && uv run python manage.py runserver

# front (in another terminal)
cd front && npm run dev
```

## Layout

```
uliseren-project/
├── README.md          # this file
├── CLAUDE.md          # entry point for Claude Code sessions
├── init.sh            # one-shot bootstrap script
├── docs/              # cross-repo documentation
└── (back/, front/)    # cloned by init.sh, gitignored
```

## Working with Claude Code

Open a Claude Code session at the root of `uliseren-project/`. The
`CLAUDE.md` here tells Claude how the two subrepos fit together and
points to the per-repo `CLAUDE.md` files for deeper context.
