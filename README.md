# . Files

> [!IMPORTANT]
> This is my .bashrc script for my users

[.bashrc Script](.bashrc)<br>
----------------------------------------------------------------------------
# Bash Scripts
> [!IMPORTANT]
> These are my main scripts I use throughout my environments. They are a work in progress and constantly evolving.

> This gets all docker-compose.yml files that are currently running on the system. I use it to create a text file and run this command:<br>
> Note: I also set up a cron job to get the running containers every night.<br>
`for i in $(cat TEXTFILE); do docker compose -f $i pull && docker compose -f $i up -d`<br>

[Get All Docker Compose file paths](/Scripts/docker/getContainers.sh)

> I created a script that curls the api for Adguard Home to update the custom filter rules I have set up for everyone in the home using the adguard.json file.<br>

[Adguard.sh](/Scripts/kids/adguard.sh)

> I had lost my MariaDB database for NPM, having only the ib_logfile0 and not the ib_logfile1. I tried many attempts to recover but given it was unrecoverable on the many attempts, I created this script to get all the NGINX files for the proxy hosts and insert it into a brand new database.<br>

[create_proxy_hosts.sh](/Scripts/reinstall/nginx/create_proxy_hosts.sh)

> I found a daily, weekly and monthly script online and changed a lot of the items to cater to what I was trying to do with my backup. II ran a cron job daily for it to decide whether to do a daily, weekly or monthly backup of the files I wanted to keep (mainly docker files). I had a filter file as well to filter out files I did not need.<br>

[backup.sh](/Scripts/rsync/backup.sh)

