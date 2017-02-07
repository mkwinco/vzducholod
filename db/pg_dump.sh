pg_dump -U postgres -W  --create --exclude-schema='u_*' --dbname=econmod_v03 > pg_dump_core.sql
pg_dump -U postgres -W --schema-only --schema='u_*' --dbname=econmod_v03 > pg_dump_userspace.sql
