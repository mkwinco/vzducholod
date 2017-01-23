pg_dump -U postgres -W  --create --schema=general --schema=rules econmod_v03 > pg_dump_core.sql
pg_dump -U postgres -W --schema-only --create  --exclude-schema=general --exclude-schema=rules econmod_v03 > pg_dump_userspace.sql
