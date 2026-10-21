# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/core/env.ts
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Siteora proof of concept: address + proposed structure -> applicable Queensland siting rules."""
# import os
# import pathlib
#
# ENV_FILE = pathlib.Path(__file__).resolve().parent.parent / ".env"
# # .env may use PG_PASSWORD etc.; psql reads PGPASSWORD etc.
# _ALIASES = {"PG_PASSWORD": "PGPASSWORD", "PG_HOST": "PGHOST", "PG_PORT": "PGPORT",
#             "PG_DATABASE": "PGDATABASE", "PG_USER": "PGUSER"}
#
#
# def load_env(path=ENV_FILE):
#     """Load KEY = VALUE lines from poc/.env into os.environ. Variables already set in the
#     environment win, so the file is only a default. Stdlib only."""
#     if not path.exists():
#         return
#     for line in path.read_text(encoding="utf-8-sig").splitlines():
#         line = line.strip()
#         if not line or line.startswith("#") or "=" not in line:
#             continue
#         key, value = (s.strip() for s in line.split("=", 1))
#         value = value.strip("'\"")
#         for k in (key, _ALIASES.get(key)):
#             if k:
#                 os.environ.setdefault(k, value)
#
#
# load_env()
