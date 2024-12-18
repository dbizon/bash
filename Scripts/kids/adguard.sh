#!/bin/bash

curl -H "Authorization: Basic ${BASIC_AUTH}" -H "Content-Type: application/json" http://opnsense:8081/control/filtering/set_rules -d @${USER_DIR}/Scripts/kids/adguard.json
