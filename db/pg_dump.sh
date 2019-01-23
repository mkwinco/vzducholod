pg_dump -U postgres -W  --create --no-owner --exclude-schema='u_*' --dbname=econmod_v03 | perl parse_db_objects.pl > pg_dump_core.sql
pg_dump -U postgres -W --schema-only --no-owner --schema='u_*' --dbname=econmod_v03 | perl parse_db_objects.pl > pg_dump_userspace.sql
