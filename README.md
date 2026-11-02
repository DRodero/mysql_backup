# mysql_backup

> **This project is no longer maintained.** Its evolution is
> [plesk-s3-backup](https://github.com/DRodero/plesk-s3-backup): database
> and file backups of a Plesk server to S3, with automatic rotation of the
> copies, a single daily entry point and a systemd installer.
>
> *Este proyecto ya no se mantiene. Su evolución es
> [plesk-s3-backup](https://github.com/DRodero/plesk-s3-backup).*

Bash script to backup mysql databases and check it immediately.

Steps of the script :
 * Read all the schemas of the database
 * For each schema, make a dump.
 * Check if this dump ends with **Dump Completed**
 * If the dump is correct, the sql dump is compresed into a gz file.
 * If the dump is not correct, it sends an error email to the administrator.
 * At the end, it sends a summary email to the administrator.
