#!/bin/bash

# script voor het ophalen en doorsturen van SolarmanPV data naar Home assistant via MQTT
# script kan je draaien en meenemen in de cron schedule

# https://www.solarmanpv.com/portal/Terminal/TerminalMain.aspx?pid=XXXXX&key=XXXXXXX Url vervangen met url wanneer je handmatig inlogd op de omgeving
curl -c solarmanpv.cookie -s "https://www.solarmanpv.com/portal/Terminal/TerminalMain.aspx?pid=XXXXX&key=XXXXXXX" > /dev/null

# psid=XXXXX de XXXXX vervangen met zelfde 6 cijferige id als in de url hierboven hebt verkregen
curl -b solarmanpv.cookie -s "https://www.solarmanpv.com/portal/AjaxService.ashx?ac=upTerminalMain&psid=XXXXX" > solarman.json

POWER_NOW_UNIT=$(cat solarman.json | jq .[].nowpower | sed 's/[^a-zA-Z]*//g')
POWER_NOW=$(cat solarman.json | jq .[].nowpower | grep -o "[0-9.]\+")

if [ "$POWER_NOW_UNIT" = "kW" ]; then
  POWER_NOW_COR=${POWER_NOW}
else
  POWER_NOW_COR=$(echo "scale=2; $POWER_NOW / 1000" | bc -l | awk '{printf "%f", $0}' )
fi


POWER_DAY=$(cat solarman.json | jq .[].daypower | grep -o "[0-9.]\+")
POWER_MONTH=$(cat solarman.json | jq .[].monthpower | grep -o "[0-9.]\+")
POWER_YEAR=$(cat solarman.json | jq .[].yearpower | grep -o "[0-9.]\+")
POWER_ALL=$(cat solarman.json | jq .[].allpower | grep -o "[0-9.]\+")

ZON_DATA="[{\"nowpower\": ${POWER_NOW_COR}, \"daypower\": ${POWER_DAY}, \"monthpower\": ${POWER_MONTH}, \"yearpower\": ${POWER_YEAR}, \"allpower\": ${POWER_ALL} }]"

echo ${ZON_DATA} > solarman_processed.json 

ZON_DATA_PROCESSED=$(cat solarman_processed.json | jq -c .[])

# xxx.xxx.xxxx.xxx vervangen door je ip van je mqtt server
# zelfde geld voor user en pass
mosquitto_pub -h xxx.xxx.xxxx.xxx -p 1883 -u USER -P PASS -r -t "house/solar/back" -m "${ZON_DATA_PROCESSED}"
