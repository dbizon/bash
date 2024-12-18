#!/bin/bash

umask 022
which jq &>/dev/null || apt install jq -y >/dev/null
SCRIPTS_DIR=$(realpath $(dirname $0))
start_date="'$(date +'%F %T')'"
. "${SCRIPTS_DIR}/.secrets"
SQL_INSERT=( "USE \`$DATABASE_NAME\`;" )

function main(){
        clear -x #clear only screen, keeping scrollback
        sql_add_certificate
        sql_add_proxy_hosts
        #print out entire array at once
        printf "%s\n" "${SQL_INSERT[@]}"
        #send the payload to SQL
        }

        #GET SINGLE TABLE FROM FULL BACKUP - sed -ne '/CREATE TABLE.*`proxy_host`/,/^UNLOCK TABLES;/p' backup_sql.sql >| proxy_hosts_db_with_data.sql
function sql_add_certificate(){
        declare -i is_deleted=0
        declare -i sql_id=$(grep -m1 -e 'ssl_certificate' "${PROXY_HOST_DIR}/1.conf" | sed 's/\(.*\)\/.*/\1/' | cut -d'-' -f2)
        declare -i owner_user_id=1
        certificate_date_expiry="'$(date '+%F %T' -d "$(openssl x509 -enddate -noout -in ${CERTIFICATE_DIR}/npm-5/fullchain.pem | cut -d'=' -f2)")'"
        nice_name="'DOMAIN_NAME'"
        provider="'letsencrypt'"
        meta="'{
        \\\"letsencrypt_email\\\":\\\"${LETSENCRYPT_EMAIL}\\\",
        \\\"dns_challenge\\\":true,
        \\\"dns_provider\\\":\\\"${DNS_PROVIDER}\\\",
        \\\"dns_provider_credentials\\\":\\\"dns_cloudflare_email = ${DNS_EMAIL}\\\\r\\\\ndns_cloudflare_api_key = ${DNS_API_KEY}\\\",
        \\\"letsencrypt_agree\\\":true
        }'"
        sql_domain_names="'[\\\"CERT_DOMAIN_NAME1\\\",\\\"CERT_DOMAIN_NAME2\\\"]'"
        SQL_INSERT+=( "$(echo -En "INSERT INTO \`certificate\` VALUES ($sql_id,"$start_date","$start_date",$owner_user_id,$is_deleted,$provider,$nice_name,$sql_domain_names,$certificate_date_expiry,$(printf %s $meta)")")
        }

function sql_add_proxy_hosts(){
        # ($NEW_DB_ID_PROXY,$start_date,$start_date,1,0,$json_domain_name,$forward_host,$forward_port,0,$host_certificate,$ssl_forced,$caching_enabled,$block_exploits,'','{\"letsencrypt_agree\":false,\"dns_challenge\":false,\"nginx_online\":true,\"nginx_err\":null}',$allow_websocket_upgrade,$http2_enabled,$forward_scheme,$enabled,'[]',$hsts_enabled,$hsts_enabled);
        # DELETE FROM proxy_host WHERE `is_deleted` = 1;
        # DISABLED - INSERT INTO `proxy_host` VALUES(2,'2024-02-20 17:45:07','2024-02-20 20:21:14',1,0,'[\"valid.DOMAIN_NAME\"]','valid',8443,0,2,1,1,1,'','{\"letsencrypt_agree\":false,\"dns_challenge\":false,\"nginx_online\":true,\"nginx_err\":null}',1,1,'http',0,'[]',1,1);
        # ENABLED - INSERT INTO `proxy_host` VALUES (2,'2024-02-20 17:45:07','2024-02-20 17:45:09',1,0,'[\"valid.DOMAIN_NAME\"]','valid',8443,0,2,1,1,1,'','{\"letsencrypt_agree\":false,\"dns_challenge\":false,\"nginx_online\":true,\"nginx_err\":null}',1,1,'http',1,'[]',1,1);

                meta="'{\\\"letsencrypt_agree\\\":true,\\\"nginx_online\\\":true,\\\"nginx_err\\\":null}'"
                readarray -t -d $'\0' proxy_hosts < <(find $PROXY_HOST_DIR -maxdepth 1 -type f -name '*.conf' -print0)
                NEW_DB_ID_PROXY=1
                for proxy_host in "${proxy_hosts[@]}"; do
                        #[ -z $backup_dir ] && backup_dir="$(dirname $proxy_host)/backup"
                        #[ -d $backup_dir ] || mkdir -p $backup_dir
                        #[ -f "$backup_dir/$(basename $proxy_host)" ] || cp $proxy_host "$backup_dir/$(basename $proxy_host)"
                        #[ -f "${PROXY_HOST_DIR}/.dont_move" ] || mv $proxy_host "$(dirname $proxy_host)/$NEW_DB_ID_PROXY.conf"
                        [[ $(grep -Eq 'http2' $proxy_host) -eq 0 ]] && http2_enabled=1 || http2_enabled=0
                        [[ $(grep -Eq 'add_header Strict-Transport-Security $hsts_header always' $proxy_host) -eq 0 ]] && hsts_enabled=1 || hsts_enabled=0
                        [[ $(grep -Eq '^include conf.d/include/block-exploits.conf;' $proxy_host) -eq 0 ]] && block_exploits=1 || block_exploits=0
                        [[ $(grep -Eq '^include conf.d/include/assets.conf;' $proxy_host) -eq 0 ]] && caching_enabled=1 || caching_enabled=0
                        [[ $(grep -Eq '^include conf.d/include/force-ssl.conf;' $proxy_host) -eq 0 ]] && ssl_forced=1 || ssl_forced=0
                        [[ $(grep -Eq '^proxy_http_version 1.1;' $proxy_host) -eq 0 ]] && allow_websocket_upgrade=1 || allow_websocket_upgrade=0
                        declare -i host_certificate=$(grep -m1 -e 'ssl_certificate' $proxy_host | sed 's/\(.*\)\/.*/\1/' | cut -d'-' -f2)
                        DOMAIN_NAMES=$(egrep '^# [a-z]' $proxy_host | cut -d' ' -f 2)
                        forward_host="'$(egrep -m1 -e 'server.*"' $proxy_host | cut -d '"' -f2)'"
                        forward_port=$(egrep -m1 -e '.*port' $proxy_host | grep -Eo "[0-9]+")
                        forward_scheme="'$(egrep -m1 -E '.*forward_scheme' $proxy_host | grep -oE '[^ ]+$' | sed 's/;//g')'"
                        json_domain_name="'[\\\"$DOMAIN_NAMES\\\"]'"
                        enabled=1
                        echo "Backup Location: $(dirname $proxy_host)/backup"
                        echo "Filename: $proxy_host"
                        echo "Directory: $(dirname $proxy_host)"
                        echo "New File Name: $(dirname $proxy_host)/$NEW_DB_ID_PROXY.conf"
                        echo "DB_QUERY #:"$((NEW_DB_ID_PROXY++))
                        echo "--------------------------------------------------------------------------------"
                        SQL_INSERT+=( "$(echo -en "INSERT INTO \`proxy_host\` VALUES ($((NEW_DB_ID_PROXY++)),$start_date,$start_date,1,0,$json_domain_name,$forward_host,$forward_port,0,$host_certificate,$ssl_forced,$caching_enabled,$block_exploits,'',$meta,$allow_websocket_upgrade,$http2_enabled,$forward_scheme,$enabled,'[]',$hsts_enabled,$hsts_enabled);")")
                        echo "--------------------------------------------------------------------------------"
                done
                #echo "$NEW_DB_ID_PROXY - Auto_Increment number"
        touch "${PROXY_HOST_DIR}/.dont_move"
        SQL_INSERT+=( "$(echo -En "ALTER TABLE \`certificate\` AUTO_INCREMENT=$((++sql_id));")")
        SQL_INSERT+=( "$(echo -En "ALTER TABLE \`proxy_host\` AUTO_INCREMENT=$((++NEW_DB_ID_PROXY));")")
        #alter table to set auto-increment $NEW_DB_ID_PROXY
        }
#Old items below


function change_file_certs(){
        #Get all npm files to change names
        readarray -t files_to_change <<< "$(find /storage/containers/nginx/config/letsencrypt_data/ -name '*npm-5*' -exec echo {} \;)"
        echo "${files_to_change[@]}"
        echo "--------------------------------------------------------"
        readarray -t files_to_edit_with_new_changes< <(grep -Rlwe 'npm-5' "${NGINX_CONFIG_PATH}/")
        echo "${files_to_edit_with_new_changes[@]}"
        echo "--------------------------------------------------------"
        }
function determine_auth_renew(){
        expires=$(cat .auth_token | jq -r '.expires')
        [[ $(date --date='1 hour ago' +'%s') -ge $(date -d $expires +'%s') ]] && \
        get_auth_token || \
        AUTH_TOKEN_API=$(jq -r '.token' '.auth_token')
        }
function get_auth_token(){
                ENDPOINT="${PROXY_HOST_NAME}${TOKEN_API}"
                AUTH_BODY="identity=$USERNAME&secret=$PASSWORD"
                curl "${CURL_OPTS[@]/#/-H}" -d $AUTH_BODY "${ENDPOINT}" | jq '.' >| .auth_token
        }

main
: <<'sql_statement'
        USE \`nginx\`;
        BEGIN;
        LOCK TABLES \`certificate\` WRITE;
        ALTER TABLE \`certificate\` DISABLE KEYS;
                        #INSERTS
        ALTER TABLE \`certificate\` ENABLE KEYS;
        UNLOCK TABLES;
        END;
        BEGIN;
        LOCK TABLES \`proxy_host\` WRITE;
        ALTER TABLE \`proxy_host\` DISABLE KEYS;
                #INSERTS
        ALTER TABLE \`certificate\` ENABLE KEYS;
        UNLOCK TABLES;
        ALTER TABLE \`certificate\` AUTOINCREMENT=6;
        ALTER TABLE \`proxy_host\` AUTOINCREMENT=$NEW_DB_ID_PROXY;
        UNLOCK TABLES;
        FLUSH PRIVILEGES;
        SELECT * FROM \`certificate\`;"
        SELECT * FROM \`proxy_host\`;"

sql_statement
