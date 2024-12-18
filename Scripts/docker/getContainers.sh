#!/bin/bash

mapfile -t compose < <(docker inspect $(docker ps | cut -d' ' -f1 | tail -n +2) | jq -r '.[].Config.Labels["com.docker.compose.project.config_files"]' | sort -u)
for compose_files in ${compose[@]}; do
        if [ $(echo $compose_files | cut -d '/' -f 4) != "plex" ]; then
                if [ $(echo $compose_files | cut -d '/' -f 4) != "transmission" ]; then
                        echo $compose_files;
                fi
        fi
done
