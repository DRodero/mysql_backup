# mysql_backup
Bash script to backup mysql databases and check it immediately.

Steps of the script :
 * Read all the schemas of the database
 * For each schema, make a dump.
 * Check if this dump ends with **Dump Completed**
 * If the dump is correct, the sql dump is compresed into a gz file.
 * If the dump is not correct, it sends an error email to the administrator.
 * At the end, it sends a summary email to the administrator.
