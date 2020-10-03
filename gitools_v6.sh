#!/bin/bash
#########################################################
# quick Google PageSpeed Insights API tool v4 & v5 & v6
# & gtmetrix api tool & webpagetest.org api usage
# written by George Liu (eva2000) https://centminmod.com
#
# https://developers.google.com/speed/docs/insights/v4/getting-started
# https://developers.google.com/speed/docs/insights/v5/reference/pagespeedapi/runpagespeed
# https://gtmetrix.com/api/
# https://sites.google.com/a/webpagetest.org/docs/advanced-features/webpagetest-restful-apis
#
# WPT API locations & testers
# https://www.webpagetest.org/getLocations.php?k=A&f=html
# https://www.webpagetest.org/getTesters.php?k=A&f=html
#########################################################
# variables
#############
VER='3.1'
DT=$(date +"%d%m%y-%H%M%S")
TIMESTAMP=$(date +"%s")


# GET API Key from https://console.developers.google.com/
# by enabling PageSpeed Insights API and creating the
# API key from Credentials page. If you don't want to set the
# GOOGLE_API_KEY variable within this script, you can set it in
# gitools.ini config file which resides in same directory as gitools.sh
GOOGLE_API_KEY=''
# Insight API v4 or v5 
# note v6 uses v5 api endpoint
PAGESPEED_INSIGHTAPIVER='5'
PAGESPEED_COMPACT='y'
# work in progress not ready
PAGESPEED_SUGGESTION='n'
CMD_OUTPUT='y'
JSON_OUTPUT='y'
SNAPSHOTS='n'
SCREENSHOT='n'
PSI_FOUR_URL='https://www.googleapis.com/pagespeedonline/v4/runPagespeed'
PSI_SIX_URL='https://www.googleapis.com/pagespeedonline/v5/runPagespeed'

# Gtmetrix API settings
GTMETRIX='n'
GTEMAIL=''
GTAPIKEY=''
GTBROWSER_WIDTH='1366'
GTBROWSER_HEIGHT='768'
GTVIDEO='n'
# 1 = Vancouver, CA
# 2 = London, UK
# 3 = Sydney, Australia
# 4 = Dallas, USA
# 5 = Mumbai, India
# 6 = Sao Paulo, Brazil
# 7 = Hong Kong, China
GTLOCATION='4'
# Browsers
# 1 = Firefox
# 3 = Chrome
GTBROWSER='3'

# Webpagetest.org API Tests
WPT_LABEL=$(date +"%d%m%y-%H%M%S")
# json or xml
WPT_FORMAT='json'
WPT_DIR='/home/wptresults'
WPT_RESULT_TESTSTATUS_LOG='/tmp/wpt-teststatus-check.log'
# WPT_MODE median or average results
WPT_MODE='median'
WPT_KEEPUA='y'
WPT_IGNORESSL='n'
WPT_SHOW_HISTORY='y'
WPT_IGNORE_SSL='y'
WPT_RUNS='1'
WPT_LIGHTHOUSE='y'
WPT_APIURL='https://www.webpagetest.org/runtest.php'
WPT_APIKEY='YOUR_API_KEY'
WPT_LOCATION='Dulles:Chrome.Cable'
WPT_DULLES='y'
WPT_DULLES_THINKPAD='n'
WPT_DULLES_3G='n'
WPT_DULLES_3G_IPHONEEIGHT='n'
WPT_DULLES_3G_S7='n'
WPT_CALIFORNIA='n'
WPT_FRANKFURT='n'
WPT_SINGAPORE='n'
WPT_SYDNEY='n'
WPT_DALLAS='n'
WPT_LONDON='n'
WPT_TOKYO='n'
WPT_HONGKONG='n'
WPT_MUMBIA='n'
WPT_BRAZIL='n'
WPT_MELBOURNE='n'
WPT_BANGKOK='n'
WPT_JAKARTA='n'
WPT_TAIWAN='n'
WPT_CAPETOWN='n'

# wait time between API run and parsing
# result log
WPT_SLEEPTIME='15'

# slack channel
SLACK='n'
SLACK_LINKBUTTONS_WPT='n'
webhook_url=""       # Incoming Webhooks integration URL
channel="general"    # Default channel to post messages. '#' is prepended
username="psi-bot"   # Default username to post messages.
icon="ghost"         # Default emoji to post messages. Don't wrap it with ':'. See http://www.emoji-cheat-sheet.com; can be a url too.
#########################################################
# functions
#############
if [ -f gitools.ini ]; then
  . gitools.ini
fi

if [ ! -d "$WPT_DIR" ]; then
  mkdir -p "$WPT_DIR"
fi

if [ ! -f /usr/bin/jq ]; then
  if [ -d /etc/yum.repos.d ]; then
    yum -q -y install jq
  fi
  if [ -f /usr/bin/apt ]; then
    apt-get -y -q install jq
  fi
fi

if [[ "$SNAPSHOTS" = [Yy] ]]; then
  snapshots_state='true'
else
  snapshots_state='false'
fi

if [[ "$SCREENSHOT" = [Yy] ]]; then
  screenshot_state='true'
else
  screenshot_state='false'
fi

if [[ "$GTVIDEO" = [Yy] ]]; then
  gtvideo_state='1'
else
  gtvideo_state='0'
fi

if [[ "$WPT_IGNORE_SSL" = [yY] ]]; then
  ignore_ssl='&ignoreSSL=1'
else
  ignore_ssl=""
fi

if [[ "$WPT_SHOW_HISTORY" = [yY] ]]; then
  wpt_show_history='0'
else
  wpt_show_history='1'
fi

slacksend() {
  dt=$DT
  # message="$dt: This is posted to #$channel and comes from a bot named $username."
  message="$1"
  message_size=$(echo $message | wc -c)
  slack_fallback="$2"
  slack_test="$3"
  if [[ "SLACK_LINKBUTTONS_WPT" = [yY] ]]; then
    slack_button_msg="$4"
  else
    message_color="$4"
  fi
  slack_title="$slack_fallback"
  slack_message_title="$slack_title"
  slack_footer=$(basename "$0")
  # curl -X POST --data-urlencode "payload={\"channel\": \"#$channel\", \"username\": \"$username\", \"text\": \"$message\", \"icon_emoji\": \":$icon:\"}" $webhook_url
  
  if [[ "$slack_test" = 'wpt' && "SLACK_LINKBUTTONS_WPT" = [yY] ]]; then
    curl -X POST --data-urlencode "payload={\"channel\": \"#$channel\", \"username\": \"$username\", \"icon_emoji\": \":$icon:\", \"attachments\": [ { \"fallback\": \"${slack_fallback}\", $slack_button_msg \"color\": \"good\", \"ts\": \"$TIMESTAMP\", \"footer\": \"$slack_footer\", \"fields\": [{ \"title\": \"$slack_message_title\", \"value\": \"${message}\", \"short\": false }] } ]}" $webhook_url
  elif [[ "$slack_test" = 'psi' ]]; then
    curl -X POST --data-urlencode "payload={\"channel\": \"#$channel\", \"username\": \"$username\", \"icon_emoji\": \":$icon:\", \"attachments\": [ { \"fallback\": \"${slack_fallback}\", \"color\": \"$message_color\", \"ts\": \"$TIMESTAMP\", \"footer\": \"$slack_footer\", \"fields\": [{ \"title\": \"$slack_message_title\", \"value\": \"${message}\", \"short\": false }] } ]}" $webhook_url
  elif [[ "$slack_test" = 'psi-md' ]]; then
    curl -X POST --data-urlencode "payload={\"channel\": \"#$channel\", \"username\": \"$username\", \"icon_emoji\": \":$icon:\", \"attachments\": [ { \"fallback\": \"${slack_fallback}\", \"color\": \"$message_color\", \"ts\": \"$TIMESTAMP\", \"footer\": \"$slack_footer\", \"text\": \"${message}\", \"mrkdwn_in\": [\"text\", \"pretext\"] }] }" $webhook_url
  elif [[ "$slack_test" = 'gt' ]]; then
    curl -X POST --data-urlencode "payload={\"channel\": \"#$channel\", \"username\": \"$username\", \"icon_emoji\": \":$icon:\", \"attachments\": [ { \"fallback\": \"${slack_fallback}\", \"color\": \"$message_color\", \"ts\": \"$TIMESTAMP\", \"footer\": \"$slack_footer\", \"fields\": [{ \"title\": \"$slack_message_title\", \"value\": \"${message}\", \"short\": false }] } ]}" $webhook_url
  elif [[ "$slack_test" = 'wpt' && "SLACK_LINKBUTTONS_WPT" != [yY] ]]; then
    curl -X POST --data-urlencode "payload={\"channel\": \"#$channel\", \"username\": \"$username\", \"icon_emoji\": \":$icon:\", \"attachments\": [ { \"fallback\": \"${slack_fallback}\", \"color\": \"$message_color\", \"ts\": \"$TIMESTAMP\", \"footer\": \"$slack_footer\", \"fields\": [{ \"title\": \"$slack_message_title\", \"value\": \"${message}\", \"short\": false }] } ]}" $webhook_url
  else
    curl -X POST --data-urlencode "payload={\"channel\": \"#$channel\", \"username\": \"$username\", \"icon_emoji\": \":$icon:\", \"attachments\": [ { \"fallback\": \"${slack_fallback}\", \"color\": \"good\", \"ts\": \"$TIMESTAMP\", \"footer\": \"$slack_footer\", \"fields\": [{ \"title\": \"$slack_message_title\", \"value\": \"${message}\", \"short\": false }] } ]}" $webhook_url
  fi
}

wpt_run() {
  WPT_URL=$1
  WPT_REGION=${2}
  WPT_SPEED=${3:-Cable}
  WPT_SPEED=$(echo $WPT_SPEED | awk '{print tolower($0)}')
  WPT_RESOLUTION_WIDTH=${4:-1920}
  WPT_RESOLUTION_HEIGHT=${5:-1200}
  prefix=$(echo $WPT_URL | awk -F '://' '{print $1}')
  domain=$(echo $WPT_URL | awk -F '://' '{print $2}')
  if [[ "$WPT_SPEED" = 'cable' ]]; then
    WPT_SPEED='Cable'
    WPT_SPEED_TXT='cable'
  elif [[ "$WPT_SPEED" = '3g' ]]; then
    WPT_SPEED='3G'
    WPT_SPEED_TXT='3g'
  elif [[ "$WPT_SPEED" = '3g-fast' || "$WPT_SPEED" = '3gfast' ]]; then
    WPT_SPEED='3GFast'
    WPT_SPEED_TXT='3gfast'
  elif [[ "$WPT_SPEED" = '4g' ]]; then
    WPT_SPEED='4G'
    WPT_SPEED_TXT='4g'
  elif [[ "$WPT_SPEED" = 'lte' ]]; then
    WPT_SPEED='LTE'
    WPT_SPEED_TXT='lte'
  elif [[ "$WPT_SPEED" = 'fios' ]]; then
    WPT_SPEED='FIOS'
    WPT_SPEED_TXT='fios'
  else
    WPT_SPEED='Cable'
    WPT_SPEED_TXT='cable'
  fi
  if [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'dulles-3g' )" = 'dulles-3g' ]]; then
    WPT_REGION_CMD='dulles-3g'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'dulles-iphone8-3g' )" = 'dulles-iphone8-3g' ]]; then
    WPT_REGION_CMD='dulles-iphone8-3g'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'dulles-s7-3g' )" = 'dulles-s7-3g' ]]; then
    WPT_REGION_CMD='dulles-s7-3g'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'dulles-thinkpad' )" = 'dulles-thinkpad' ]]; then
    WPT_REGION_CMD='dulles-thinkpad'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'dulles' )" = 'dulles' ]]; then
    WPT_REGION_CMD='dulles'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'california' )" = 'california' ]]; then
    WPT_REGION_CMD='california'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'frankfurt' )" = 'frankfurt' ]]; then
    WPT_REGION_CMD='frankfurt'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'singapore' )" = 'singapore' ]]; then
    WPT_REGION_CMD='singapore'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'sydney' )" = 'sydney' ]]; then
    WPT_REGION_CMD='sydney'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'dallas' )" = 'dallas' ]]; then
    WPT_REGION_CMD='dallas'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'london' )" = 'london' ]]; then
    WPT_REGION_CMD='london'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'tokyo' )" = 'tokyo' ]]; then
    WPT_REGION_CMD='tokyo'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'hongkong' )" = 'hongkong' ]]; then
    WPT_REGION_CMD='hongkong'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'mumbia' )" = 'mumbia' ]]; then
    WPT_REGION_CMD='mumbia'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'brazil' )" = 'brazil' ]]; then
    WPT_REGION_CMD='brazil'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'melbourne' )" = 'melbourne' ]]; then
    WPT_REGION_CMD='melbourne'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'bangkok' )" = 'bangkok' ]]; then
    WPT_REGION_CMD='bangkok'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'jakarta' )" = 'jakarta' ]]; then
    WPT_REGION_CMD='jakarta'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'taiwan' )" = 'taiwan' ]]; then
    WPT_REGION_CMD='taiwan'
  elif [[ "$(echo $WPT_REGION | awk '{print tolower($0)}' | grep -o 'capetown' )" = 'capetown' ]]; then
    WPT_REGION_CMD='capetown'
  else
    WPT_REGION_CMD="none"
  fi
  if [[ "$WPT_DULLES_3G" = [yY] ]]; then
    WPT_SLEEPTIME='30'
    WPT_PROCEED='y'
    WPT_LOCATION='Dulles:MotoG4:3g'
    WPT_LOCATION_TXT='dulles-motog4-mobile.chrome.3g'
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='MotoG4_22'
  elif [[ "$WPT_DULLES_3G_IPHONEEIGHT" = [yY] ]]; then
    WPT_SLEEPTIME='30'
    WPT_PROCEED='y'
    WPT_LOCATION='Dulles_iPhone8:iPhone 8 iOS 12:3g'
    WPT_LOCATION_TXT='dulles-iphone8-mobile.iOS12.3g'
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='iPhone8_1'
  elif [[ "$WPT_DULLES_3G_S7" = [yY] ]]; then
    WPT_SLEEPTIME='30'
    WPT_PROCEED='y'
    WPT_LOCATION='Dulles:GalaxyS7:3g'
    WPT_LOCATION_TXT='dulles-galaxys7-mobile.chrome.3g'
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='Galaxy_S7_1'
  elif [[ "$WPT_DULLES" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="Dulles:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="dulles.chrome.${WPT_SPEED_TXT}"
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='VM04-07'
  elif [[ "$WPT_DULLES_THINKPAD" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="Dulles_Thinkpad:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="dulles-thinkpad.chrome.${WPT_SPEED_TXT}"
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='Thinkpad-7'
  elif [[ "$WPT_CALIFORNIA" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-us-west-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="california.ec2-us-west-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-203'
  elif [[ "$WPT_FRANKFURT" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-eu-central-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="frankfurt.ec2-eu-central-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-203'
  elif [[ "$WPT_SINGAPORE" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-ap-southeast-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="singapore.ec2-ap-southeast-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-202'
  elif [[ "$WPT_SYDNEY" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-ap-southeast-2:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="sydney.ec2-ap-southeast-2.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-201'
  elif [[ "$WPT_DALLAS" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="Texas2:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="dallas.Texas2.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='Dallas'
  elif [[ "$WPT_LONDON" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="London_EC2:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="london.London_EC2.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-203'
  elif [[ "$WPT_TOKYO" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-ap-northeast-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="tokyo.ec2-ap-northeast-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-203'
  elif [[ "$WPT_HONGKONG" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-ap-east-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="hongkong.ec2-ap-east-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-202'
  elif [[ "$WPT_MUMBIA" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ap-south-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="mumbia.ap-south-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-202'
  elif [[ "$WPT_BRAZIL" = [yY] ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-sa-east-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="brazil.ec2-sa-east-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-172-30-1-203'
  elif [[ "$WPT_MELBOURNE" = 'melbourne' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="azure-australia-southeast:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="melbourne.azure-australia-southeast.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='au-mel-az-x01'
  elif [[ "$WPT_BANGKOK" = 'bangkok' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="tencent-bangkok:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="bangkok.tencent-bangkok.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='VM-0-5-ubuntu'
  elif [[ "$WPT_JAKARTA" = 'jakarta' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="gce-asia-southeast2:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="jakarta.gce-asia-southeast2.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='id-cgk-gcp-x02'
  elif [[ "$WPT_TAIWAN" = 'taiwan' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="gce-asia-east1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="taiwan.gce-asia-east1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='tw-tpe-gcp-x02'
  elif [[ "$WPT_CAPETOWN" = 'capetown' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-af-south-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="capetown.ec2-af-south-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-202'
  fi
  ########################################################################
  # override options on command line
  if [[ "$WPT_REGION_CMD" = 'dulles-3g' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION='Dulles:MotoG4:3g'
    WPT_LOCATION_TXT='dulles-motog4-mobile.chrome.3g'
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='MotoG4_22'
  elif [[ "$WPT_REGION_CMD" = 'dulles-iphone8-3g' ]]; then
    WPT_SLEEPTIME='30'
    WPT_PROCEED='y'
    WPT_LOCATION='Dulles_iPhone8:iPhone 8 iOS 12:3g'
    WPT_LOCATION_TXT='dulles-iphone8-mobile.iOS12.3g'
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='iPhone8_1'
  elif [[ "$WPT_REGION_CMD" = 'dulles-s7-3g' ]]; then
    WPT_SLEEPTIME='30'
    WPT_PROCEED='y'
    WPT_LOCATION='Dulles:GalaxyS7:3g'
    WPT_LOCATION_TXT='dulles-galaxys7-mobile.chrome.3g'
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='Galaxy_S7_1'
  elif [[ "$WPT_REGION_CMD" = 'dulles' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="Dulles:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="dulles.chrome.${WPT_SPEED_TXT}"
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='VM04-07'
  elif [[ "$WPT_REGION_CMD" = 'dulles-thinkpad' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="Dulles_Thinkpad:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="dulles-thinkpad.chrome.${WPT_SPEED_TXT}"
    # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='Thinkpad-7'
  elif [[ "$WPT_REGION_CMD" = 'california' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-us-west-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="california.ec2-us-west-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-203'
  elif [[ "$WPT_REGION_CMD" = 'frankfurt' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-eu-central-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="frankfurt.ec2-eu-central-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-203'
  elif [[ "$WPT_REGION_CMD" = 'singapore' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-ap-southeast-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="singapore.ec2-ap-southeast-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-202'
  elif [[ "$WPT_REGION_CMD" = 'sydney' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-ap-southeast-2:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="sydney.ec2-ap-southeast-2.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-201'
  elif [[ "$WPT_REGION_CMD" = 'dallas' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="Texas2:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="dallas.Texas2.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='Dallas'
  elif [[ "$WPT_REGION_CMD" = 'london' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="London_EC2:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="london.London_EC2.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-203'
  elif [[ "$WPT_REGION_CMD" = 'tokyo' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-ap-northeast-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="tokyo.ec2-ap-northeast-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-203'
  elif [[ "$WPT_REGION_CMD" = 'hongkong' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-ap-east-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="hongkong.ec2-ap-east-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-202'
  elif [[ "$WPT_REGION_CMD" = 'mumbia' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ap-south-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="mumbia.ap-south-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-202'
  elif [[ "$WPT_REGION_CMD" = 'brazil' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-sa-east-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="brazil.ec2-sa-east-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-172-30-1-203'
  elif [[ "$WPT_REGION_CMD" = 'melbourne' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="azure-australia-southeast:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="melbourne.azure-australia-southeast.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='au-mel-az-x01'
  elif [[ "$WPT_REGION_CMD" = 'bangkok' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="tencent-bangkok:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="bangkok.tencent-bangkok.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='VM-0-5-ubuntu'
  elif [[ "$WPT_REGION_CMD" = 'jakarta' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="gce-asia-southeast2:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="jakarta.gce-asia-southeast2.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='id-cgk-gcp-x02'
  elif [[ "$WPT_REGION_CMD" = 'taiwan' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="gce-asia-east1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="taiwan.gce-asia-east1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='tw-tpe-gcp-x02'
  elif [[ "$WPT_REGION_CMD" = 'capetown' ]]; then
    WPT_PROCEED='y'
    WPT_LOCATION="ec2-af-south-1:Chrome.${WPT_SPEED}"
    WPT_LOCATION_TXT="capetown.ec2-af-south-1.chrome.${WPT_SPEED_TXT}"
   # define specific testers for specific locales
    # for more consistent repeated testing runs
    # https://www.webpagetest.org/getTesters.php
    TESTER_CABLE='ip-10-0-1-202'
  fi
  if [[ "$WPT_LIGHTHOUSE" = [yY] ]]; then
    wpt_lighthouse_opt='&lighthouse=1'
  else
    wpt_lighthouse_opt=""
  fi
  if [[ "$WPT_KEEPUA" = [yY] ]]; then
    wpt_keepua_opt='&keepua=1'
  else
    wpt_keepua_opt=""
  fi
  if [[ "$WPT_IGNORESSL" = [yY] ]]; then
    wpt_ignoressl_opt='&ignoreSSL=1'
  else
    wpt_ignoressl_opt=""
  fi
  if [[ "$WPT_PROCEED" = [yY] ]]; then
    WPT_LABEL="$WPT_LOCATION_TXT.$(date +"%d%m%y-%H%M%S")"
    WPT_RESULT_LOG="${WPT_DIR}/wpt-${WPT_LABEL}.log"
    WPT_SUMMARYRESULT_LOG="${WPT_DIR}/wpt-${WPT_LABEL}-summary.log"
    # WPT_TESTURL=$(echo "${WPT_APIURL}?k=$WPT_APIKEY&url=$WPT_URL&label=$WPT_LABEL&location=$WPT_LOCATION&runs=${WPT_RUNS}&fvonly=1&video=1&private=${wpt_show_history}&medianMetric=loadTime${wpt_lighthouse_opt}${wpt_keepua_opt}${wpt_ignoressl_opt}&width=${WPT_RESOLUTION_WIDTH}&height=${WPT_RESOLUTION_HEIGHT}${ignore_ssl}&f=xml&tester=${TESTER_CABLE}")
    WPT_TESTURL=$(echo "${WPT_APIURL}?k=$WPT_APIKEY&url=$WPT_URL&label=$WPT_LABEL&location=$WPT_LOCATION&runs=${WPT_RUNS}&fvonly=1&video=1&private=${wpt_show_history}&medianMetric=loadTime${wpt_lighthouse_opt}${wpt_keepua_opt}${wpt_ignoressl_opt}${ignore_ssl}&f=xml&tester=${TESTER_CABLE}")
    echo "curl -4s \"$WPT_TESTURL\"" > "$WPT_RESULT_LOG"
    curl -4s "$WPT_TESTURL" >> "$WPT_RESULT_LOG"
    WPT_USER_RESULTURL=$(grep -oP '(?<=<userUrl>).*(?=</userUrl>)' "$WPT_RESULT_LOG")
    WPT_USER_RESULTXMLURL=$(grep -oP '(?<=<xmlUrl>).*(?=</xmlUrl>)' "$WPT_RESULT_LOG")
    WPT_TESTIDA=$(grep -oP '(?<=<testId>).*(?=</testId>)' "$WPT_RESULT_LOG")
    WPT_USER_RESULTJSONURL="https://www.webpagetest.org/jsonResult.php?test=${WPT_TESTIDA}&pretty=1"
    echo
    echo "--------------------------------------------------------------------------------"
    echo "$WPT_LOCATION WPT Results"
    echo "--------------------------------------------------------------------------------"
    echo "Test ID: $WPT_TESTIDA"
    if [[ "$WPT_TESTIDA" ]]; then
      sleep "$WPT_SLEEPTIME"
      echo "$WPT_USER_RESULTURL"
    fi
    if [[ "$WPT_LIGHTHOUSE" = [yY] ]]; then
      WPT_LIGHTHOUSE_URL="https://www.webpagetest.org/lighthouse.php?test=$WPT_TESTIDA"
      echo "$WPT_LIGHTHOUSE_URL"
    fi
    if [[ "$WPT_SHOW_HISTORY" = [yY] ]]; then
      WPT_HISTORY_URL="https://www.webpagetest.org/testlog.php?days=1&filter=${domain}&all=on&video=on"
      echo "$WPT_HISTORY_URL"
    fi
    echo "$WPT_RESULT_LOG"
    WPT_RESULT_STATUSCODE=$(grep -oP '(?<=<statusCode>).*(?=</statusCode>)' "$WPT_RESULT_LOG")
    WPT_RESULT_STATUS=$(grep -oP '(?<=<statusText>).*(?=</statusText>)' "$WPT_RESULT_LOG")
    if [[ "$WPT_RESULT_STATUSCODE" -eq '100' || "$WPT_RESULT_STATUSCODE" -eq '101' || "$WPT_RESULT_STATUSCODE" -eq '200' ]]; then
      curl -4s "https://www.webpagetest.org/testStatus.php?f=xml&test=$WPT_TESTIDA" > "$WPT_RESULT_TESTSTATUS_LOG"
      WPT_RESULT_STATUSCODE=$(grep -oP '(?<=<statusCode>).*(?=</statusCode>)' "$WPT_RESULT_TESTSTATUS_LOG")
      WPT_RESULT_STATUS=$(grep -oP '(?<=<statusText>).*(?=</statusText>)' "$WPT_RESULT_TESTSTATUS_LOG")
      # check test result xml result status if Ok 200, proceed otherwise if 
      # Test Started 100 status or Waiting behind another test 101 status is found,
      # wait WPT_SLEEPTIME more to proceed
      while [[ "$WPT_RESULT_STATUSCODE" -eq '100' || "$WPT_RESULT_STATUSCODE" -eq '101' ]]; do
        sleep "$WPT_SLEEPTIME"
        if [[ "$WPT_RESULT_STATUSCODE" -eq '101' ]]; then
          sleep "$WPT_SLEEPTIME"
        fi
        curl -4s "https://www.webpagetest.org/testStatus.php?f=xml&test=$WPT_TESTIDA" > "$WPT_RESULT_TESTSTATUS_LOG"
        WPT_RESULT_STATUSCODE=$(grep -oP '(?<=<statusCode>).*(?=</statusCode>)' "$WPT_RESULT_TESTSTATUS_LOG")
        WPT_RESULT_STATUS=$(grep -oP '(?<=<statusText>).*(?=</statusText>)' "$WPT_RESULT_TESTSTATUS_LOG")
        echo "$WPT_RESULT_STATUS ($WPT_RESULT_STATUSCODE)"
        echo "waiting on results..."
      done
      if [[ "$WPT_RESULT_STATUSCODE" -eq '200' ]]; then
        WPT_USER_RESULTXMLURL=$(grep -oP '(?<=<xmlUrl>).*(?=</xmlUrl>)' "$WPT_RESULT_LOG")
        echo "$WPT_RESULT_STATUS ($WPT_RESULT_STATUSCODE)"
        echo "----"
        if [[ "$WPT_LIGHTHOUSE" = [yY] ]]; then
          # additional lighthouse metrics to parse
          wpt_ttfb=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<TTFB>).*(?=</TTFB>)' | tail -1)
          wpt_firstpaint=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<firstPaint>).*(?=</firstPaint>)' | tail -1)
          wpt_firstcontentfulpaint=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<firstContentfulPaint>).*(?=</firstContentfulPaint>)' | tail -1)
          wpt_fullyloaded=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<fullyLoaded>).*(?=</fullyLoaded>)' | tail -1)
          wpt_speedindex=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<SpeedIndex>).*(?=</SpeedIndex>)' | tail -1)
          wpt_domi=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<domInteractive>).*(?=</domInteractive>)' | tail -1)
          wpt_visualcomplete=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<visualComplete>).*(?=</visualComplete>)' | tail -1)
          wpt_chrome_lcp=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<chromeUserTiming.LargestContentfulPaint>).*(?=</chromeUserTiming.LargestContentfulPaint>)' | tail -1)
          wpt_chrome_cls=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<chromeUserTiming.CumulativeLayoutShift>).*(?=</chromeUserTiming.CumulativeLayoutShift>)' | tail -1)
          wpt_lighth_lcp=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<lighthouse.Performance.largest-contentful-paint>).*(?=</lighthouse.Performance.largest-contentful-paint>)' | tail -1)
          wpt_lighth_cls=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<lighthouse.Performance.cumulative-layout-shift>).*(?=</lighthouse.Performance.cumulative-layout-shift>)' | tail -1)
          wpt_lighth_fcp=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<lighthouse.Performance.first-contentful-paint>).*(?=</lighthouse.Performance.first-contentful-paint>)' | tail -1)
          wpt_lighth_fmp=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<lighthouse.Performance.first-meaningful-paint>).*(?=</lighthouse.Performance.first-meaningful-paint>)' | tail -1)
          wpt_lighth_speedindex=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<lighthouse.Performance.speed-index>).*(?=</lighthouse.Performance.speed-index>)' | tail -1)
          wpt_lighth_cpuidle=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<lighthouse.Performance.first-cpu-idle>).*(?=</lighthouse.Performance.first-cpu-idle>)' | tail -1)
          wpt_lighth_inputlatency=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<lighthouse.Performance.estimated-input-latency>).*(?=</lighthouse.Performance.estimated-input-latency>)' | tail -1)
          waterfall_url=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<waterfall>).*(?=</waterfall>)' | grep -v thumb)
          echo "curl -4s "$WPT_USER_RESULTXMLURL" | sed -n \"/<$WPT_MODE>/,/<\/$WPT_MODE>/p\" | egrep -m1 -m2 -m3 -m4 -m5 -m6 -m7 -m8 -m9 -m10 -m11 -m12 -m13 -m14 -m15 -m16 -m17 -m18 -m19 -m20 -m21 -m22 -m23 -m24 -m25 -m26 -m27 -m28 -m29 -m30 -m31 -m32 -m33 -m34 -m35 -m36 -m37 -m38 -m39 -m40 -m41 'loadTime|TTFB|render|<fullyLoaded>|<domElements>|<firstPaint>|<domInteractive>|<domContentLoadedEventStart>|<domContentLoadedEventEnd>|<SpeedIndex>|<visualComplete>|<requestsFull>|<requestsDoc>|<domComplete>|<fullyLoaded>|<bytesInDoc>|<bytesIn>|<score_cdn>|<score_gzip>|<score_compress>|<score_keep-alive>|<score_cache>|<lighthouse.Performance.first|<lighthouse.Performance.estimated|<lighthouse.Performance.speed|<lighthouse.BestPractices>|<lighthouse.Accessibility>|<lighthouse.ProgressiveWebApp>|<lighthouse.SEO>|<lighthouse.Performance>|chromeUserTiming.firstContentfulPaint|chromeUserTiming.firstMeaningfulPaint|chromeUserTiming.domComplete|firstContentfulPaint|chromeUserTiming.LargestContentfulPaint|chromeUserTiming.CumulativeLayoutShift|lighthouse.Performance.largest-contentful-paint|lighthouse.Performance.cumulative-layout-shift|lighthouse.Performance.total-blocking-time' | sed -e 's|<||' -e 's|>| |g' -e 's|<\/.*| |' | sort" >> "$WPT_RESULT_LOG"
          curl -4s "$WPT_USER_RESULTXMLURL" | sed -n "/<$WPT_MODE>/,/<\/$WPT_MODE>/p" | egrep -m1 -m2 -m3 -m4 -m5 -m6 -m7 -m8 -m9 -m10 -m11 -m12 -m13 -m14 -m15 -m16 -m17 -m18 -m19 -m20 -m21 -m22 -m23 -m24 -m25 -m26 -m27 -m28 -m29 -m30 -m31 -m32 -m33 -m34 -m35 -m36 -m37 -m38 -m39 -m40 -m41 'loadTime|TTFB|render|<fullyLoaded>|<domElements>|<firstPaint>|<domInteractive>|<domContentLoadedEventStart>|<domContentLoadedEventEnd>|<SpeedIndex>|<visualComplete>|<requestsFull>|<requestsDoc>|<domComplete>|<fullyLoaded>|<bytesInDoc>|<bytesIn>|<score_cdn>|<score_gzip>|<score_compress>|<score_keep-alive>|<score_cache>|<lighthouse.Performance.first|<lighthouse.Performance.estimated|<lighthouse.Performance.speed|<lighthouse.BestPractices>|<lighthouse.Accessibility>|<lighthouse.ProgressiveWebApp>|<lighthouse.SEO>|<lighthouse.Performance>|chromeUserTiming.firstContentfulPaint|chromeUserTiming.firstMeaningfulPaint|chromeUserTiming.domComplete|firstContentfulPaint|chromeUserTiming.LargestContentfulPaint|chromeUserTiming.CumulativeLayoutShift|lighthouse.Performance.largest-contentful-paint|lighthouse.Performance.cumulative-layout-shift|lighthouse.Performance.total-blocking-time' | sed -e 's|<||' -e 's|>| |g' -e 's|<\/.*| |' | sort | sed -e "s|bytesIn |bytesIn-fully-loaded |" -e "s|bytesInDoc |bytesInDoc-document-complete |" -e 's|render|start-render|' -e 's|domComplete|domComplete-time|' -e 's|fullyLoaded|fullyLoaded-time|' > "$WPT_SUMMARYRESULT_LOG"
          echo "$waterfall_url" >> "$WPT_SUMMARYRESULT_LOG"
          # exclude from slack filtered message
          sed -i 's|chromeUserTiming.firstContentfulPaint|chrome.firstContentfulPaint|g' "$WPT_SUMMARYRESULT_LOG"
          sed -i 's|chromeUserTiming.LargestContentfulPaint|chrome.LargestContentfulPaint|g' "$WPT_SUMMARYRESULT_LOG"
          sed -i 's|chromeUserTiming.CumulativeLayoutShift|chrome.CumulativeLayoutShift|g' "$WPT_SUMMARYRESULT_LOG"
        else
          wpt_ttfb=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<TTFB>).*(?=</TTFB>)' | tail -1)
          wpt_firstpaint=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<firstPaint>).*(?=</firstPaint>)' | tail -1)
          wpt_firstcontentfulpaint=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<firstContentfulPaint>).*(?=</firstContentfulPaint>)' | tail -1)
          wpt_fullyloaded=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<fullyLoaded>).*(?=</fullyLoaded>)' | tail -1)
          wpt_speedindex=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<SpeedIndex>).*(?=</SpeedIndex>)' | tail -1)
          wpt_domi=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<domInteractive>).*(?=</domInteractive>)' | tail -1)
          wpt_visualcomplete=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<visualComplete>).*(?=</visualComplete>)' | tail -1)
          wpt_chrome_lcp=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<chromeUserTiming.LargestContentfulPaint>).*(?=</chromeUserTiming.LargestContentfulPaint>)' | tail -1)
          wpt_chrome_cls=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<chromeUserTiming.CumulativeLayoutShift>).*(?=</chromeUserTiming.CumulativeLayoutShift>)' | tail -1)
          waterfall_url=$(curl -4s "$WPT_USER_RESULTXMLURL" | grep -oP '(?<=<waterfall>).*(?=</waterfall>)' | grep -v thumb)
          echo "curl -4s "$WPT_USER_RESULTXMLURL" | sed -n \"/<$WPT_MODE>/,/<\/$WPT_MODE>/p\" | egrep -m1 -m2 -m3 -m4 -m5 -m6 -m7 -m8 -m9 -m10 -m11 -m12 -m13 -m14 -m15 -m16 -m17 -m18 -m19 -m20 -m21 -m22 -m23 -m24 -m25 -m26 -m27 -m28 -m29 -m30 -m31 -m32 -m33 'loadTime|TTFB|render|<fullyLoaded>|<domElements>|<firstPaint>|firstMeaningfulPaint>|firstContentfulPaint>|<domInteractive>|<domContentLoadedEventStart>|<domContentLoadedEventEnd>|<SpeedIndex>|<visualComplete>|<requestsFull>|<requestsDoc>|<domComplete>|<fullyLoaded>|<bytesInDoc>|<bytesIn>|<score_cdn>|<score_gzip>|<score_compress>|<score_keep-alive>|<score_cache>|chromeUserTiming.firstContentfulPaint|chromeUserTiming.firstMeaningfulPaint|chromeUserTiming.domComplete|firstContentfulPaint|chromeUserTiming.LargestContentfulPaint|chromeUserTiming.CumulativeLayoutShift' | sed -e 's|<||' -e 's|>| |g' -e 's|<\/.*| |' | sort" >> "$WPT_RESULT_LOG"
          curl -4s "$WPT_USER_RESULTXMLURL" | sed -n "/<$WPT_MODE>/,/<\/$WPT_MODE>/p" | egrep -m1 -m2 -m3 -m4 -m5 -m6 -m7 -m8 -m9 -m10 -m11 -m12 -m13 -m14 -m15 -m16 -m17 -m18 -m19 -m20 -m21 -m22 -m23 -m24 -m25 -m26 -m27 -m28 -m29 -m30 -m31 -m32 -m33 'loadTime|TTFB|render|<fullyLoaded>|<domElements>|<firstPaint>|firstMeaningfulPaint>|firstContentfulPaint>|<domInteractive>|<domContentLoadedEventStart>|<domContentLoadedEventEnd>|<SpeedIndex>|<visualComplete>|<requestsFull>|<requestsDoc>|<domComplete>|<fullyLoaded>|<bytesInDoc>|<bytesIn>|<score_cdn>|<score_gzip>|<score_compress>|<score_keep-alive>|<score_cache>|chromeUserTiming.firstContentfulPaint|chromeUserTiming.firstMeaningfulPaint|chromeUserTiming.domComplete|firstContentfulPaint|chromeUserTiming.LargestContentfulPaint|chromeUserTiming.CumulativeLayoutShift' | sed -e 's|<||' -e 's|>| |g' -e 's|<\/.*| |' | sort > "$WPT_SUMMARYRESULT_LOG"
          echo "$waterfall_url" >> "$WPT_SUMMARYRESULT_LOG"
          # exclude from slack filtered message
          sed -i 's|chromeUserTiming.firstContentfulPaint|chrome.firstContentfulPaint|g' "$WPT_SUMMARYRESULT_LOG"
          sed -i 's|chromeUserTiming.LargestContentfulPaint|chrome.LargestContentfulPaint|g' "$WPT_SUMMARYRESULT_LOG"
          sed -i 's|chromeUserTiming.CumulativeLayoutShift|chrome.CumulativeLayoutShift|g' "$WPT_SUMMARYRESULT_LOG"
        fi

        cat "$WPT_SUMMARYRESULT_LOG" | tee -a "$WPT_RESULT_LOG"
        if [[ "$SLACK" = [yY] ]]; then
          send_message="$(cat $WPT_SUMMARYRESULT_LOG | grep -v 'chromeUserTiming')"
          if [[ "$SLACK_LINKBUTTONS_WPT" = [yY] ]]; then
            # slack_button_message="\"actions\": [ { \"type\": \"button\", \"name\": \"wpt-result-page\", \"text\": \"WPT Results\", \"url\": \"$WPT_USER_RESULTURL\", \"style\": \"primary\" }, { \"type\": \"button\", \"name\": \"wpt-xml-results-page\", \"text\": \"WPT XML Results\", \"url\": \"WPT_USER_RESULTXMLURL\", \"style\": \"primary\" }, { \"type\": \"button\", \"name\": \"lighthourse-results\", \"text\": \"Lighthouse Results\", \"url\": \"$WPT_LIGHTHOUSE_URL\", \"style\": \"primary\" }, { \"type\": \"button\", \"name\": \"wpt-history-log\", \"text\": \"WPT History Log\", \"url\": \"$WPT_HISTORY_URL\", \"style\": \"primary\" } ],"
            slack_button_message="\\\"actions\\\": [ { \\\"type\\\": \\\"button\\\", \\\"name\\\": \\\"wpt-result-page\\\", \\\"text\\\": \\\"WPT Results\\\", \\\"url\\\": \\\"$WPT_USER_RESULTURL\\\", \\\"style\\\": \\\"primary\\\" }, { \\\"type\\\": \\\"button\\\", \\\"name\\\": \\\"wpt-xml-results-page\\\", \\\"text\\\": \\\"WPT XML Results\\\", \\\"url\\\": \\\"WPT_USER_RESULTXMLURL\\\", \\\"style\\\": \\\"primary\\\" }, { \\\"type\\\": \\\"button\\\", \\\"name\\\": \\\"lighthourse-results\\\", \\\"text\\\": \\\"Lighthouse Results\\\", \\\"url\\\": \\\"$WPT_LIGHTHOUSE_URL\\\", \\\"style\\\": \\\"primary\\\" }, { \\\"type\\\": \\\"button\\\", \\\"name\\\": \\\"wpt-history-log\\\", \\\"text\\\": \\\"WPT History Log\\\", \\\"url\\\": \\\"$WPT_HISTORY_URL\\\", \\\"style\\\": \\\"primary\\\" } ],"
            slacksend "Webpagetest.org Test: $WPT_LOCATION\n$WPT_URL\n$send_message" "$DT - $WPT_LOCATION $WPT_SPEED" wpt "$slack_button_message"
          else
            if [[ "$WPT_SPEED" = 'Cable' ]]; then
              if [[ "$wpt_ttfb" -le '500' ]]; then
                message_color='#23ab11'
              elif [[ "$wpt_ttfb" -ge '501' && "$wpt_ttfb" -le '600' ]]; then
                message_color='#71bb30'
              elif [[ "$wpt_ttfb" -ge '601' && "$wpt_ttfb" -le '700' ]]; then
                message_color='#cbb708'
              elif [[ "$wpt_ttfb" -ge '701' && "$wpt_ttfb" -le '800' ]]; then
                message_color='#e29b20'
              elif [[ "$wpt_ttfb" -ge '801' ]]; then
                message_color='#bb4a12'
              fi
            fi
            if [[ "$WPT_SPEED" = '3G' ]]; then
              if [[ "$wpt_ttfb" -le '1324' ]]; then
                message_color='#23ab11'
              elif [[ "$wpt_ttfb" -ge '1325' && "$wpt_ttfb" -le '1424' ]]; then
                message_color='#71bb30'
              elif [[ "$wpt_ttfb" -ge '1425' && "$wpt_ttfb" -le '1524' ]]; then
                message_color='#cbb708'
              elif [[ "$wpt_ttfb" -ge '1525' && "$wpt_ttfb" -le '1624' ]]; then
                message_color='#e29b20'
              elif [[ "$wpt_ttfb" -ge '1625' ]]; then
                message_color='#bb4a12'
              fi
            fi
            if [[ "$WPT_SPEED" = '3GFast' ]]; then
              if [[ "$wpt_ttfb" -le '704' ]]; then
                message_color='#23ab11'
              elif [[ "$wpt_ttfb" -ge '705' && "$wpt_ttfb" -le '804' ]]; then
                message_color='#71bb30'
              elif [[ "$wpt_ttfb" -ge '805' && "$wpt_ttfb" -le '904' ]]; then
                message_color='#cbb708'
              elif [[ "$wpt_ttfb" -ge '905' && "$wpt_ttfb" -le '1004' ]]; then
                message_color='#e29b20'
              elif [[ "$wpt_ttfb" -ge '1005' ]]; then
                message_color='#bb4a12'
              fi
            fi
            if [[ "$WPT_SPEED" = '4G' ]]; then
              if [[ "$wpt_ttfb" -le '804' ]]; then
                message_color='#23ab11'
              elif [[ "$wpt_ttfb" -ge '805' && "$wpt_ttfb" -le '904' ]]; then
                message_color='#71bb30'
              elif [[ "$wpt_ttfb" -ge '905' && "$wpt_ttfb" -le '1004' ]]; then
                message_color='#cbb708'
              elif [[ "$wpt_ttfb" -ge '1005' && "$wpt_ttfb" -le '1104' ]]; then
                message_color='#e29b20'
              elif [[ "$wpt_ttfb" -ge '1105' ]]; then
                message_color='#bb4a12'
              fi
            fi
            if [[ "$WPT_SPEED" = 'LTE' ]]; then
              if [[ "$wpt_ttfb" -le '500' ]]; then
                message_color='#23ab11'
              elif [[ "$wpt_ttfb" -ge '501' && "$wpt_ttfb" -le '600' ]]; then
                message_color='#71bb30'
              elif [[ "$wpt_ttfb" -ge '601' && "$wpt_ttfb" -le '700' ]]; then
                message_color='#cbb708'
              elif [[ "$wpt_ttfb" -ge '701' && "$wpt_ttfb" -le '800' ]]; then
                message_color='#e29b20'
              elif [[ "$wpt_ttfb" -ge '801' ]]; then
                message_color='#bb4a12'
              fi
            fi
            if [[ "$WPT_SPEED" = 'FIOS' ]]; then
              if [[ "$wpt_ttfb" -le '500' ]]; then
                message_color='#23ab11'
              elif [[ "$wpt_ttfb" -ge '501' && "$wpt_ttfb" -le '600' ]]; then
                message_color='#71bb30'
              elif [[ "$wpt_ttfb" -ge '601' && "$wpt_ttfb" -le '700' ]]; then
                message_color='#cbb708'
              elif [[ "$wpt_ttfb" -ge '701' && "$wpt_ttfb" -le '800' ]]; then
                message_color='#e29b20'
              elif [[ "$wpt_ttfb" -ge '801' ]]; then
                message_color='#bb4a12'
              fi
            fi
            # slacksend "Webpagetest.org Test: $WPT_LOCATION\n$WPT_URL\n<$WPT_USER_RESULTURL|WPT Result Page>\n<$WPT_USER_RESULTXMLURL|WPT XML Result>\n<$WPT_LIGHTHOUSE_URL|Lighthouse Result Page>\n<$WPT_HISTORY_URL|WPT History Log>\n$send_message" "$DT - $WPT_LOCATION $WPT_SPEED" wpt $message_color
            slacksend "Webpagetest: $WPT_LOCATION_TXT\n$WPT_URL\n<$WPT_USER_RESULTURL|WPT Result Page>\t<$WPT_USER_RESULTXMLURL|WPT XML Result>\n<$WPT_HISTORY_URL|WPT History Log>\t<$WPT_LIGHTHOUSE_URL|Lighthouse Result Page>\n$send_message" "$DT - $WPT_LOCATION $WPT_SPEED" wpt $message_color
          fi
        fi
        echo "----"
      else
        echo "$WPT_RESULT_STATUS ($WPT_RESULT_STATUSCODE)"
      fi
    else
      echo "Webpagetest failed..."
    fi
    echo "--------------------------------------------------------------------------------"
    echo
  fi
}

gt_run() {
  fulldomain=$1
  prefix=$(echo $fulldomain | awk -F '://' '{print $1}')
  domain=$(echo $fulldomain | awk -F '://' '{print $2}')
  # browser = 3 chrome
  # location = 4 dallas
  curl -4s --user $GTEMAIL:$GTAPIKEY --form url=${prefix}://${domain} --form x-metrix-adblock=0 --form x-metrix-video=$gtvideo_state --form browser=$GTBROWSER --form location=$GTLOCATION --form x-metrix-browser-width=$GTBROWSER_WIDTH --form x-metrix-browser-height=$GTBROWSER_HEIGHT --form x-metrix-throttle='5000/1000/30' https://gtmetrix.com/api/0.1/test | tee /tmp/gtmetrix.log
  echo "waiting on results..."
  sleep 30s
  gtmetrix_result=$(cat /tmp/gtmetrix.log | jq '.poll_state_url' | sed -e 's|\"||g')
  if [[ "$JSON_OUTPUT" = [yY] ]]; then
    {
    result_state=$(curl -4s --user $GTEMAIL:$GTAPIKEY $gtmetrix_result | jq '.state'| sed -e 's|\"||g')
    if [[ "$result_state" = 'completed' ]]; then
      curl -4s --user $GTEMAIL:$GTAPIKEY $gtmetrix_result | jq '.'
    else
      sleep 15s
      curl -4s --user $GTEMAIL:$GTAPIKEY $gtmetrix_result | jq '.'
    fi
    } | tee /tmp/gtmetrix-summary.log
  else
    {
    result_state=$(curl -4s --user $GTEMAIL:$GTAPIKEY $gtmetrix_result | jq '.state'| sed -e 's|\"||g')
    if [[ "$result_state" = 'completed' ]]; then
      curl -4s --user $GTEMAIL:$GTAPIKEY $gtmetrix_result | jq '.'
    else
      sleep 15s
      curl -4s --user $GTEMAIL:$GTAPIKEY $gtmetrix_result | jq '.'
    fi
    } > /tmp/gtmetrix-summary.log
  fi
  # waterfall=$(curl -4s --user $gtemail:$gtapikey ${gtmetrix_result}/har | jq)
  
  onload_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.onload_time')
  first_contentful_paint_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.first_contentful_paint_time')
  page_elements=$(cat /tmp/gtmetrix-summary.log | jq '.results.page_elements')
  report_url=$(cat /tmp/gtmetrix-summary.log | jq '.results.report_url'| sed -e 's|\"||g')
  redirect_duration=$(cat /tmp/gtmetrix-summary.log | jq '.results.redirect_duration')
  first_paint_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.first_paint_time')
  dom_content_loaded_duration=$(cat /tmp/gtmetrix-summary.log | jq '.results.dom_content_loaded_duration')
  dom_content_loaded_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.dom_content_loaded_time')
  dom_interactive_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.dom_interactive_time')
  page_bytes=$(cat /tmp/gtmetrix-summary.log | jq '.results.page_bytes')
  page_load_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.page_load_time')
  html_bytes=$(cat /tmp/gtmetrix-summary.log | jq '.results.html_bytes')
  fully_loaded_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.fully_loaded_time')
  html_load_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.html_load_time')
  rum_speed_index=$(cat /tmp/gtmetrix-summary.log | jq '.results.rum_speed_index')
  yslow_score=$(cat /tmp/gtmetrix-summary.log | jq '.results.yslow_score')
  pagespeed_score=$(cat /tmp/gtmetrix-summary.log | jq '.results.pagespeed_score')
  backend_duration=$(cat /tmp/gtmetrix-summary.log | jq '.results.backend_duration')
  onload_duration=$(cat /tmp/gtmetrix-summary.log | jq '.results.onload_duration')
  connect_duration=$(cat /tmp/gtmetrix-summary.log | jq '.results.connect_duration')

  echo
  echo "--------------------------------------------------------------------------------"
  echo "Dallas Chrome Broadband 5Mbps: ${prefix}://${domain}" | tee /tmp/gitool-gtmetrix-slack-summary.log
  echo "PageSpeed Score: $pagespeed_score YSlow Score: $yslow_score" | tee -a /tmp/gitool-gtmetrix-slack-summary.log
  echo "Report: $report_url" | tee -a /tmp/gitool-gtmetrix-slack-summary.log
  echo "Fully Loaded Time: $fully_loaded_time ms Total Page Size: $page_bytes (bytes) Requests: $page_elements" | tee -a /tmp/gitool-gtmetrix-slack-summary.log
  echo "RUM Speed Index: $rum_speed_index" | tee -a /tmp/gitool-gtmetrix-slack-summary.log
  echo "Redirect: $redirect_duration ms Connect: $connect_duration ms Backend: $backend_duration ms" | tee -a /tmp/gitool-gtmetrix-slack-summary.log
  echo "TTFB: $html_load_time ms DOM-int: $dom_interactive_time ms First-paint: $first_paint_time ms" | tee -a /tmp/gitool-gtmetrix-slack-summary.log
  echo "Contentful-paint: $first_contentful_paint_time ms DOM-loaded: $dom_content_loaded_time ms Onload: $onload_time ms" | tee -a /tmp/gitool-gtmetrix-slack-summary.log

  if [[ "$SLACK" = [yY] ]]; then
    if [[ "$pagespeed_score" ]]; then
      send_message="$(cat /tmp/gitool-gtmetrix-slack-summary.log)"
      if [[ "$pagespeed_score" -ge '90' ]]; then
        message_color='#23ab11'
      elif [[ "$pagespeed_score" -ge '80' && "$pagespeed_score" -le '89' ]]; then
        message_color='#71bb30'
      elif [[ "$pagespeed_score" -ge '70' && "$pagespeed_score" -le '79' ]]; then
        message_color='#cbb708'
      elif [[ "$pagespeed_score" -ge '60' && "$pagespeed_score" -le '69' ]]; then
        message_color='#e29b20'
      elif [[ "$pagespeed_score" -le '59' ]]; then
        message_color='#bb4a12'
      fi
      slacksend "$send_message" "$DT - GTMetrix" gt $message_color
    fi
  fi

  rm -rf /tmp/gtmetrix.log
  rm -rf /tmp/gtmetrix-summary.log
  rm -rf /tmp/gitool-gtmetrix-slack-summary.log
}

####################
gi_run_six() {
  strategy=$2
  fulldomain=$1
  prefix=$(echo $fulldomain | awk -F '://' '{print $1}')
  domain=$(echo $fulldomain | awk -F '://' '{print $2}')
  turl_echo="${PSI_SIX_URL}?url=${prefix}%3A%2F%2F${domain}&strategy=${strategy}&key=YOUR_GOOGLE_API_KEY"
  turl="${PSI_SIX_URL}?url=${prefix}%3A%2F%2F${domain}&strategy=${strategy}&key=${GOOGLE_API_KEY}"
  echo
  echo "--------------------------------------------------------------------------------"
  if [[ "$CMD_OUTPUT" = [yY] ]]; then
    echo "curl -4s $turl_echo"
  fi
  if [[ "$JSON_OUTPUT" = [yY] ]]; then
    curl -4s $turl | tee /tmp/gitool-${strategy}.log
  else
    curl -4s $turl > /tmp/gitool-${strategy}.log
  fi
  err=$?
  # check for Internal 500 Errors
  BACKEND_ERRORCODE=$(cat /tmp/gitool-${strategy}.log | jq '.error.code')
  if [[ "$BACKEND_ERRORCODE" != 'null' ]]; then
    err=1   
  fi
  if [[ "$err" -ne '0' || "$(wc -l < /tmp/gitool-${strategy}.log)" -lt '2' ]]; then
    echo
    echo "$BACKEND_ERRORCODE error: aborting..."
    exit
  fi
  overall_cat=$(cat /tmp/gitool-${strategy}.log | jq -r ".loadingExperience.overall_category")
  fcp_median=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.percentile")
  fcp_cat=$(cat /tmp/gitool-${strategy}.log | jq -r ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.category")
  fcl_distribution_min=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[1] | .min')
  fcl_distribution_max=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[1] | .max')
  fcl_distribution_proportiona=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[0] | .proportion')
  fcl_distribution_proportionb=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[1] | .proportion')
  fcl_distribution_proportionc=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[2] | .proportion')
  fidelay_median=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_INPUT_DELAY_MS.percentile")
  fidelay_cat=$(cat /tmp/gitool-${strategy}.log | jq -r ".loadingExperience.metrics.FIRST_INPUT_DELAY_MS.category")
  fidelay_distribution_min=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_INPUT_DELAY_MS.distributions" | jq '.[1] | .min')
  fidelay_distribution_max=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_INPUT_DELAY_MS.distributions" | jq '.[1] | .max')
  fidelay_distribution_proportiona=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_INPUT_DELAY_MS.distributions" | jq '.[0] | .proportion')
  fidelay_distribution_proportionb=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_INPUT_DELAY_MS.distributions" | jq '.[1] | .proportion')
  fidelay_distribution_proportionc=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_INPUT_DELAY_MS.distributions" | jq '.[2] | .proportion')

  # cls
  cls_median=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.percentile")
  cls_cat=$(cat /tmp/gitool-${strategy}.log | jq -r ".loadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.category")
  cls_distribution_min=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.distributions" | jq '.[1] | .min')
  cls_distribution_min=$(echo $(printf "%.2f\n" $(echo "scale=2; $cls_distribution_min/100" | bc)))
  cls_distribution_max=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.distributions" | jq '.[1] | .max')
  cls_distribution_max=$(echo $(printf "%.2f\n" $(echo "scale=2; $cls_distribution_max/100" | bc)))
  cls_distribution_proportiona=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.distributions" | jq '.[0] | .proportion')
  cls_distribution_proportionb=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.distributions" | jq '.[1] | .proportion')
  cls_distribution_proportionc=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.distributions" | jq '.[2] | .proportion')

  # lcp
  lcp_median=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.percentile")
  lcp_cat=$(cat /tmp/gitool-${strategy}.log | jq -r ".loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.category")
  lcp_distribution_min=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.distributions" | jq '.[1] | .min')
  lcp_distribution_max=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.distributions" | jq '.[1] | .max')
  lcp_distribution_proportiona=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.distributions" | jq '.[0] | .proportion')
  lcp_distribution_proportionb=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.distributions" | jq '.[1] | .proportion')
  lcp_distribution_proportionc=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.distributions" | jq '.[2] | .proportion')

  if [[ "$overall_cat" = 'null' ]]; then
    overall_cat=''
  fi
  if [[ "$fcp_cat" = 'null' ]]; then
    fcp_cat=''
  fi
  if [[ "$fidelay_cat" = 'null' ]]; then
    fidelay_cat=''
  fi
  if [[ "$cls_cat" = 'null' ]]; then
    cls_cat=''
  fi
  if [[ "$lcp_cat" = 'null' ]]; then
    lcp_cat=''
  fi
  if [[ "$fcl_distribution_min" = 'null' || "$fidelay_distribution_min" = 'null' ]]; then
    fcl_distribution_min=''
    fcl_distribution_max=''
    fidelay_distribution_min=''
    fidelay_distribution_max=''
  fi
  if [[ "$cls_distribution_min" = 'null' || "$lcp_distribution_min" = 'null' ]]; then
    cls_distribution_min=''
    cls_distribution_max=''
    lcp_distribution_min=''
    lcp_distribution_max=''
  fi
  if [[ "$fcp_median" != 'null' ]]; then
    fcl_distribution_proportiona_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $fcl_distribution_proportiona)*100" | bc))
    fcl_distribution_proportionb_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $fcl_distribution_proportionb)*100" | bc))
    fcl_distribution_proportionc_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $fcl_distribution_proportionc)*100" | bc))
  fi
  if [[ "$fidelay_median" != 'null' ]]; then
    fidelay_distribution_proportiona_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $fidelay_distribution_proportiona)*100" | bc))
    fidelay_distribution_proportionb_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $fidelay_distribution_proportionb)*100" | bc))
    fidelay_distribution_proportionc_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $fidelay_distribution_proportionc)*100" | bc))
  fi
  if [[ "$cls_median" != 'null' ]]; then
    cls_distribution_proportiona_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $cls_distribution_proportiona)*100" | bc))
    cls_distribution_proportionb_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $cls_distribution_proportionb)*100" | bc))
    cls_distribution_proportionc_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $cls_distribution_proportionc)*100" | bc))
  fi
  if [[ "$lcp_median" != 'null' ]]; then
    lcp_distribution_proportiona_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $lcp_distribution_proportiona)*100" | bc))
    lcp_distribution_proportionb_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $lcp_distribution_proportionb)*100" | bc))
    lcp_distribution_proportionc_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $lcp_distribution_proportionc)*100" | bc))
  fi
  # lighthouse metrics
  LH_VER=$(cat /tmp/gitool-${strategy}.log | jq -r '.lighthouseResult.lighthouseVersion')
  LH_AGENT=$(cat /tmp/gitool-${strategy}.log | jq -r '.lighthouseResult.userAgent')
  LH_AGENTNETWORK=$(cat /tmp/gitool-${strategy}.log | jq -r '.lighthouseResult.environment.networkUserAgent')
  LH_WEIGHTS=$(cat /tmp/gitool-${strategy}.log | jq -r '.lighthouseResult.categories.performance.auditRefs[] | "\(.id) \(.weight)"' | sort -rk2 | head -n5 | column -t)
  LH_SCORE=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.categories.performance.score')
  LH_SCOREPERC=$(printf "%.0f\n" $(echo "$(printf "%.3f\n" $LH_SCORE)*100" | bc))
  LH_JSBOOTUPTIME=$(cat /tmp/gitool-${strategy}.log  | jq -r '.lighthouseResult.audits | .["bootup-time"].displayValue')
  LH_JSBOOTUPURLS=$(cat /tmp/gitool-${strategy}.log  | jq -r '.lighthouseResult.audits | .["bootup-time"].details.items[] | "\(.url) \(.total) \(.scripting) \(.scriptParseCompile)"'| awk '{printf("%s %0.2f %0.2f %0.2f\n", $1,$2,$3,$4)}')

  ttfb_rootdoc=$(cat /tmp/gitool-${strategy}.log | jq -r '.lighthouseResult.audits| .["server-response-time"].displayValue'| sed -e 's|Root document took ||')
  tt_pageweight=$(cat /tmp/gitool-${strategy}.log | jq -r '.lighthouseResult.audits | .["total-byte-weight"].displayValue'| sed -e 's|Total size was ||')
  render_blocking_savings=$(cat /tmp/gitool-${strategy}.log | jq -r '.lighthouseResult.audits | .["render-blocking-resources"].details.overallSavingsMs' | sed -e 's|Potential savings of ||')
  render_blocking_urls=$(cat /tmp/gitool-${strategy}.log  | jq -r '.lighthouseResult.audits | .["render-blocking-resources"].details.items[] | "\(.url) \(.totalBytes) \(.wastedMs)"')

  # v6
  domsize=$(cat /tmp/gitool-${strategy}.log | jq -r '.lighthouseResult.audits| .["dom-size"].displayValue')
  lcp_element=$(cat /tmp/gitool-${strategy}.log | jq -r '.lighthouseResult.audits| .["largest-contentful-paint-element"].details.items[] | "\(.node.snippet)\n\(.node.selector)"')

  if [[ "$LH_SCOREPERC" -ge '90' ]]; then
    psi_speed_score='fast'
  elif [[ "$LH_SCOREPERC" -ge '50' && "$LH_SCOREPERC" -le '89' ]]; then
    psi_speed_score='average'
  elif [[ "$LH_SCOREPERC" -le '49' ]]; then
    psi_speed_score='slow'
  fi
  if [[ "$fcp_median" != 'null' || "$fidelay_median" != 'null' ]]; then
    if [[ "$PAGESPEED_COMPACT" = [yY] ]]; then
      echo "${strategy} CrUX Rating: ${overall_cat}" | tee /tmp/gitool-${strategy}-summary.log
      echo "Test url: ${prefix}://$domain" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "FCP: ${fcp_median}ms ($fcp_cat) LCP: ${lcp_median}ms ($lcp_cat) FID: ${fidelay_median}ms ($fidelay_cat)" | tee -a /tmp/gitool-${strategy}-summary.log
      # echo "Page Load Distributions" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fcl_distribution_proportiona_perc}% pages fast FCP (<${fcl_distribution_min}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fcl_distribution_proportionb_perc}% pages average FCP (<${fcl_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fcl_distribution_proportionc_perc}% pages slow FCP (>${fcl_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fidelay_distribution_proportiona_perc}% pages fast FID (<${fidelay_distribution_min}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fidelay_distribution_proportionb_perc}% pages average FID (<${fidelay_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fidelay_distribution_proportionc_perc}% pages slow FID (>${fidelay_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log

      echo "${cls_distribution_proportiona_perc}% pages fast CLS (<${cls_distribution_min})" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${cls_distribution_proportionb_perc}% pages average CLS (<${cls_distribution_max})" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${cls_distribution_proportionc_perc}% pages slow CLS (>${cls_distribution_max})" | tee -a /tmp/gitool-${strategy}-summary.log

      echo "${lcp_distribution_proportiona_perc}% pages fast LCP (<${lcp_distribution_min}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${lcp_distribution_proportionb_perc}% pages average LCP (<${lcp_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${lcp_distribution_proportionc_perc}% pages slow LCP (>${lcp_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
    else
      echo "Test url: ${prefix}://$domain" | tee /tmp/gitool-${strategy}-summary.log
      echo "FCP median: $fcp_median ms ($fcp_cat) LCP median: $lcp_median ms ($lcp_cat) FID median: $fidelay_median ms ($fidelay_cat)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "Page Load Distributions" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fcl_distribution_proportiona_perc}% of page loads have a fast FCP (less than ${fcl_distribution_min} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fcl_distribution_proportionb_perc}% of page loads have an average FCP (less than ${fcl_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fcl_distribution_proportionc_perc}% of page loads have a slow FCP (over ${fcl_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fidelay_distribution_proportiona_perc}% of page loads have a fast FID (less than ${fidelay_distribution_min} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fidelay_distribution_proportionb_perc}% of page loads have an average FID (less than ${fidelay_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${fidelay_distribution_proportionc_perc}% of page loads have a slow FID (over ${fidelay_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log

      echo "${cls_distribution_proportiona_perc}% of page loads have a fast CLS (less than ${cls_distribution_min})" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${cls_distribution_proportionb_perc}% of page loads have an average CLS (less than ${cls_distribution_max})" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${cls_distribution_proportionc_perc}% of page loads have a slow CLS (over ${cls_distribution_max})" | tee -a /tmp/gitool-${strategy}-summary.log

      echo "${lcp_distribution_proportiona_perc}% of page loads have a fast LCP (less than ${lcp_distribution_min} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${lcp_distribution_proportionb_perc}% of page loads have an average LCP (less than ${lcp_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "${lcp_distribution_proportionc_perc}% of page loads have a slow LCP (over ${lcp_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
    fi
  fi

  echo "" | tee -a /tmp/gitool-${strategy}-summary.log
  echo -e "PageSpeed Insights v6 Score (${strategy}): $LH_SCOREPERC ($psi_speed_score)\n${prefix}://$domain" | tee -a /tmp/gitool-${strategy}-summary.log
  if [[ "$PAGESPEED_COMPACT" != [yY] ]]; then
    echo "PageSpeed Insights v6 Score Weighting" | tee -a /tmp/gitool-${strategy}-summary.log
    echo "$LH_WEIGHTS" | tee -a /tmp/gitool-${strategy}-summary.log
  fi

  # LH_FCP
  LH_FCP=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.audits.metrics.details.items[] | .firstContentfulPaint'| grep -v null)
  # LH_FMP
  LH_FMP=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.audits.metrics.details.items[] | .firstMeaningfulPaint'| grep -v null)
  # LH_SI
  LH_SI=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.audits.metrics.details.items[] | .speedIndex'| grep -v null)
  # LH_FCI
  LH_FCI=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.audits.metrics.details.items[] | .firstCPUIdle'| grep -v null)
  # LH_TTI
  LH_TTI=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.audits.metrics.details.items[] | .interactive'| grep -v null)
  # LH_FID
  LH_FID=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.audits.metrics.details.items[] | .estimatedInputLatency'| grep -v null)
  # LH_CLS
  LH_CLS=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.audits.metrics.details.items[] | .cumulativeLayoutShift'| grep -v null)
  LH_CLS=$(echo $(printf "%.2f\n" $(echo "scale=2; $LH_CLS/100" | bc)))
  # LH_LCP
  LH_LCP=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.audits.metrics.details.items[] | .largestContentfulPaint'| grep -v null)
  # LH_TBT
  LH_TBT=$(cat /tmp/gitool-${strategy}.log  | jq '.lighthouseResult.audits.metrics.details.items[] | .totalBlockingTime'| grep -v null)

  echo "Lighthouse Version: $LH_VER" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "Cumulative-Layout-Shift: $LH_CLS" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "Time-to-Interactive: $LH_TTI" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "Speed-Index: $LH_SI" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "Largest-Contentful-Paint: $LH_LCP" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "Total-Blocking-Time: $LH_TBT" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "Total-Page-Size: $tt_pageweight" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "First-Contentful-Paint: $LH_FCP" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "First-Meaningful-Paint: $LH_FMP" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "First-CPU-Idle: $LH_FCI" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "Estimated-Input-Latency: $LH_FID" | tee -a /tmp/gitool-${strategy}-summary.log
  echo "Time-To-First-Byte: $ttfb_rootdoc" | tee -a /tmp/gitool-${strategy}-summary.log

  echo "" | tee -a /tmp/gitool-${strategy}-summary-js.log
  echo "JavaScript-execution-time: $LH_JSBOOTUPTIME" | tee -a /tmp/gitool-${strategy}-summary-js.log
  echo "URL  Total  Script-Evaluation  Script-Parse" | tee -a /tmp/gitool-${strategy}-summary-js.log
  echo "$LH_JSBOOTUPURLS" | column -t | tee -a /tmp/gitool-${strategy}-summary-js.log

  echo "" | tee -a /tmp/gitool-${strategy}-summary-renderblock.log
  echo "Eliminate Render Blocking Resource Potential Savings: $render_blocking_savings" | tee -a /tmp/gitool-${strategy}-summary-renderblock.log
  echo "URL  Size   Potential-Savings" | tee -a /tmp/gitool-${strategy}-summary-renderblock.log
  echo "$render_blocking_urls" | column -t | tee -a /tmp/gitool-${strategy}-summary-renderblock.log

  echo
  if [[ "$SLACK" = [yY] ]]; then
    if [[ "$fcp_median" != 'null' || "$fidelay_median" != 'null' || "$cls_median" != 'null' || "$lcp_median" != 'null' || "$LH_SCORE" != 'null' ]]; then
      send_message="$(cat /tmp/gitool-${strategy}-summary.log)"
      send_messagejs="$(cat /tmp/gitool-${strategy}-summary-js.log)"
      send_message_renderblock="$(cat /tmp/gitool-${strategy}-summary-renderblock.log)"
      # LH_SCOREPERC_EVAL=$(echo $LH_SCOREPERC | cut -d . -f1)
      if [[ "$LH_SCOREPERC" -ge '90' ]]; then
        message_color='good'
      elif [[ "$LH_SCOREPERC" -ge '50' && "$LH_SCOREPERC" -le '89' ]]; then
        message_color='warning'
      elif [[ "$LH_SCOREPERC" -le '49' ]]; then
        message_color='danger'
      fi
      slacksend "$send_message" "$DT - Google PageSpeed Insights v6" psi "$message_color"
      slacksend "$send_messagejs" "$DT - Google PageSpeed Insights v6" psi-md "$message_color"
      slacksend "$send_message_renderblock" "$DT - Google PageSpeed Insights v6" psi-md "$message_color"
    fi
  fi
  rm -rf /tmp/gitool-${strategy}.log
  rm -rf /tmp/gitool-${strategy}-summary.log
  rm -rf /tmp/gitool-${strategy}-summary-js.log
  rm -rf /tmp/gitool-${strategy}-summary-renderblock.log
}

####################
gi_run() {
  strategy=$3
  fulldomain=$1
  origin_check=$2
  prefix=$(echo $fulldomain | awk -F '://' '{print $1}')
  domain=$(echo $fulldomain | awk -F '://' '{print $2}')
  if [[ "$origin_check" = 'origin' || "$origin_check" = 'orgin' || "$origin_check" = 'orign' ]]; then
    origins='origin%3A'
    origin_label='origin:'
  elif [[ "$origin_check" = 'site' ]]; then
    origins='site%3A'
    origin_label='site:'
  elif [[ "$origin_check" = 'default' ]]; then
    origins='default'
    origin_label=''
  elif [[ "$origin_check" = 'mobile'  && -z "$strategy" ]] || [[ "$origin_check" = 'desktop' && -z "$strategy" ]]; then
    origins='origin%3A'
    origin_label='origin:'
    strategy="$origin_check"
  else
    origins='default site%3A origin%3A'
  fi
  for o in $origins; do
    if [[ "$o" = 'default' ]]; then
      o=""
      metric_opt='&fields=formattedResults%2CloadingExperience(initial_url%2Cmetrics%2Coverall_category)%2CpageStats%2CruleGroups'
    elif [[ "$o" = 'site%3A' ]]; then
      metric_opt='&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)%2CpageStats%2Cscreenshot%2Csnapshots'
    elif [[ "$o" = 'origin%3A' ]]; then
      metric_opt='&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)%2CpageStats%2Cscreenshot%2Csnapshots'
    fi
    turl_echo="${PSI_FOUR_URL}?url=${o}${prefix}%3A%2F%2F${domain}%2F&screenshot=${screenshot_state}&snapshots=${snapshots_state}&strategy=${strategy}${metric_opt}&key=YOUR_GOOGLE_API_KEY"
    turl="${PSI_FOUR_URL}?url=${o}${prefix}%3A%2F%2F${domain}%2F&screenshot=${screenshot_state}&snapshots=${snapshots_state}&strategy=${strategy}${metric_opt}&key=${GOOGLE_API_KEY}"
    echo
    echo "--------------------------------------------------------------------------------"
    if [[ "$CMD_OUTPUT" = [yY] ]]; then
      echo "curl -4s $turl_echo"
    fi
    if [[ "$JSON_OUTPUT" = [yY] ]]; then
      curl -4s $turl | tee /tmp/gitool-${strategy}.log
    else
      curl -4s $turl > /tmp/gitool-${strategy}.log
    fi
    err=$?
    if [[ "$err" -ne '0' || "$(wc -l < /tmp/gitool-${strategy}.log)" -lt '2' ]]; then
      echo
      echo "error: aborting..."
      exit
    fi

    if [[ "$PAGESPEED_SUGGESTION" = [yY] && "$origin_check" = 'default' ]]; then
      gpsi_speed_score=$(cat /tmp/gitool-${strategy}.log | jq '.ruleGroups.SPEED.score')
      gpsi_speed_score_label="Score: $gpsi_speed_score"
      gpsi_numberresources=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .numberResources')
      gpsi_numberhosts=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .numberHosts')
      gpsi_totalrequestbytes=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .totalRequestBytes')
      gpsi_numberstaticresources=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .numberStaticResources')
      gpsi_htmlresponsebytes=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .htmlResponseBytes')
      gpsi_overthewireresponsebytes=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .overTheWireResponseBytes')
      gpsi_cssresponsebytes=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .cssResponseBytes')
      gpsi_imageresponsebytes=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .imageResponseBytes')
      gpsi_javascriptresponsebytes=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .javascriptResponseBytes')
      gpsi_otherresponsebytes=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .otherResponseBytes')
      gpsi_numberjsresources=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .numberJsResources')
      gpsi_numbercssresources=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .numberCssResources')
      gpsi_numtotalroundtrips=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .numTotalRoundTrips')
      gpsi_numrenderblockingroundtrips=$(cat /tmp/gitool-${strategy}.log | jq '.pageStats | .numRenderBlockingRoundTrips')

      # filtered json arrays
      gpsi_results_formatted_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults')
      
      gpsi_avoidlandingpageredirects_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .AvoidLandingPageRedirects')
      gpsi_avoidlandingpageredirects_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .AvoidLandingPageRedirects.localizedRuleName' | sed -e 's|\"||g')
      gpsi_avoidlandingpageredirects_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .AvoidLandingPageRedirects.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .AvoidLandingPageRedirects.urlBlocks')" = 'null' ]]; then
        gpsi_avoidlandingpageredirects_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .AvoidLandingPageRedirects.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_avoidlandingpageredirects_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .AvoidLandingPageRedirects.summary.args | .[] .value' | sed -e 's|\"||g')
      fi
      
      gpsi_enablegzipcompression_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .EnableGzipCompression')
      gpsi_enablegzipcompression_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .EnableGzipCompression.localizedRuleName' | sed -e 's|\"||g')
      gpsi_enablegzipcompression_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .EnableGzipCompression.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .EnableGzipCompression.urlBlocks')" = 'null' ]]; then
        gpsi_enablegzipcompression_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .EnableGzipCompression.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_enablegzipcompression_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .EnableGzipCompression.summary.args | .[] .value' | sed -e 's|\"||g')
      fi
      
      gpsi_leveragebrowsercaching_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .LeverageBrowserCaching')
      gpsi_leveragebrowsercaching_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .LeverageBrowserCaching.localizedRuleName' | sed -e 's|\"||g')
      gpsi_leveragebrowsercaching_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .LeverageBrowserCaching.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .LeverageBrowserCaching.urlBlocks')" = 'null' ]]; then
        gpsi_leveragebrowsercaching_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .LeverageBrowserCaching.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_leveragebrowsercaching_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .LeverageBrowserCaching.summary.args | .[] .value' | sed -e 's|\"||g')
      else
        gpsi_leveragebrowsercaching=y
        gpsi_leveragebrowsercaching_urls=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .LeverageBrowserCaching.urlBlocks | .[] .urls' |  jq '.[] .result.args | .[0] | .value')
        gpsi_leveragebrowsercaching_urls=$(echo "$gpsi_leveragebrowsercaching_urls" | grep -v 'Cannot iterate over null')
        gpsi_leveragebrowsercaching_urls=$(echo "$gpsi_leveragebrowsercaching_urls" | sed -e 's|\"||g')
        gpsi_leveragebrowsercaching_summary="Leverage browser caching for following cacheable resources\n${gpsi_leveragebrowsercaching_urls}"
      fi

      gpsi_mainresourceserverresponsetime_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime')
      gpsi_mainresourceserverresponsetime_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime.localizedRuleName' | sed -e 's|\"||g')
      gpsi_mainresourceserverresponsetime_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime.urlBlocks')" = 'null' ]]; then
        gpsi_mainresourceserverresponsetime_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_mainresourceserverresponsetime_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime.summary.args | .[] .value' | sed -e 's|\"||g')
      else
        gpsi_mainresourceserverresponsetime=y
        gpsi_mainresourceserverresponsetime_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime.urlBlocks' | jq '.[] .header.args | .[0] .key' | sed -e 's|\"||g')
        gpsi_mainresourceserverresponsetime_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime.urlBlocks' | jq '.[] .header.args | .[0] .value' | sed -e 's|\"||g')
        gpsi_mainresourceserverresponsetime_keylink=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime.urlBlocks' | jq '.[] .header.args | .[1] .key' | sed -e 's|\"||g')
        gpsi_mainresourceserverresponsetime_valuelink=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MainResourceServerResponseTime.urlBlocks' | jq '.[] .header.args | .[1] .value' | sed -e 's|\"||g')
      fi

      gpsi_minifycss_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyCss')
      gpsi_minifycss_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyCss.localizedRuleName' | sed -e 's|\"||g')
      gpsi_minifycss_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyCss.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyCss.urlBlocks')" = 'null' ]]; then
        gpsi_minifycss_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyCss.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_minifycss_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyCss.summary.args | .[] .value' | sed -e 's|\"||g')
      fi

      gpsi_minifyhtml_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyHTML')
      gpsi_minifyhtml_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyHTML.localizedRuleName' | sed -e 's|\"||g')
      gpsi_minifyhtml_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyHTML.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyHTML.urlBlocks')" = 'null' ]]; then
        gpsi_minifyhtml_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyHTML.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_minifyhtml_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyHTML.summary.args | .[] .value' | sed -e 's|\"||g')
      fi

      gpsi_minifyjavascript_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyJavaScript')
      gpsi_minifyjavascript_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyJavaScript.localizedRuleName' | sed -e 's|\"||g')
      gpsi_minifyjavascript_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyJavaScript.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyJavaScript.urlBlocks')" = 'null' ]]; then
        gpsi_minifyjavascript_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyJavaScript.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_minifyjavascript_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinifyJavaScript.summary.args | .[] .value' | sed -e 's|\"||g')
      fi

      gpsi_minimizerenderblockingresources_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources')
      gpsi_minimizerenderblockingresources_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.localizedRuleName' | sed -e 's|\"||g')
      gpsi_minimizerenderblockingresources_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.urlBlocks')" = 'null' ]]; then
        gpsi_minimizerenderblockingresources_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_minimizerenderblockingresources_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.summary.args | .[] .value' | sed -e 's|\"||g')
      else
        gpsi_minimizerenderblockingresources=y
        gpsi_minimizerenderblockingresources_keyone=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.summary.args | .[0] .key' | sed -e 's|\"||g')
        gpsi_minimizerenderblockingresources_valueone=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.summary.args | .[0] .value' | sed -e 's|\"||g')
        gpsi_minimizerenderblockingresources_keytwo=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.summary.args | .[1] .key' | sed -e 's|\"||g')
        gpsi_minimizerenderblockingresources_valuetwo=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.summary.args | .[1] .value' | sed -e 's|\"||g')
        if [[ "$gpsi_minimizerenderblockingresources_keyone" = 'NUM_CSS' ]]; then
          # number of render blocking css files found
          gpsi_minimizerenderblockingresources_css="$gpsi_minimizerenderblockingresources_valueone"
          gpsi_minimizerenderblockingresources_css_urls=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .MinimizeRenderBlockingResources.urlBlocks | .[] .urls' |  jq '.[] .result.args' | jq  '.[] .value')
          gpsi_minimizerenderblockingresources_css_urls=$(echo "$gpsi_minimizerenderblockingresources_css_urls" | grep -v 'Cannot iterate over null')
          gpsi_minimizerenderblockingresources_css_urls=$(echo "$gpsi_minimizerenderblockingresources_css_urls" | sed -e 's|\"||g')
          gpsi_minimizerenderblockingresources_css_summary="page has $gpsi_minimizerenderblockingresources_css blocking CSS resources\n${gpsi_minimizerenderblockingresources_css_urls}"
        fi
      fi

      gpsi_optimizeimages_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .OptimizeImages')
      gpsi_optimizeimages_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .OptimizeImages.localizedRuleName' | sed -e 's|\"||g')
      gpsi_optimizeimages_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .OptimizeImages.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .OptimizeImages.urlBlocks')" = 'null' ]]; then
        gpsi_optimizeimages_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .OptimizeImages.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_optimizeimages_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .OptimizeImages.summary.args | .[] .value' | sed -e 's|\"||g')
      fi

      gpsi_prioritizevisiblecontent_json=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .PrioritizeVisibleContent')
      gpsi_prioritizevisiblecontent_localname=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .PrioritizeVisibleContent.localizedRuleName' | sed -e 's|\"||g')
      gpsi_prioritizevisiblecontent_ruleimpact=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .PrioritizeVisibleContent.ruleImpact' | sed -e 's|\"||g')
      if [[ "$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .PrioritizeVisibleContent.urlBlocks')" = 'null' ]]; then
        gpsi_prioritizevisiblecontent_key=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .PrioritizeVisibleContent.summary.args | .[] .key' | sed -e 's|\"||g')
        gpsi_prioritizevisiblecontent_value=$(cat /tmp/gitool-${strategy}.log | jq '.formattedResults.ruleResults | .PrioritizeVisibleContent.summary.args | .[] .value' | sed -e 's|\"||g')
      fi
    elif [[ "$PAGESPEED_SUGGESTION" != [yY] && "$origin_check" = 'default' ]]; then
      gpsi_speed_score=$(cat /tmp/gitool-${strategy}.log | jq '.ruleGroups.SPEED.score')
      gpsi_speed_score_label="Score: $gpsi_speed_score"      
    else
      gpsi_speed_score_label=""
    fi
    overall_cat=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.overall_category" | sed -e 's|\"||g')
    fcp_median=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.median")
    fcp_cat=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.category" | sed -e 's|\"||g')
    dcl_median=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.DOM_CONTENT_LOADED_EVENT_FIRED_MS.median")
    dcl_cat=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.DOM_CONTENT_LOADED_EVENT_FIRED_MS.category" | sed -e 's|\"||g')
    fcl_distribution_min=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[1] | .min')
    fcl_distribution_max=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[1] | .max')
    fcl_distribution_proportiona=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[0] | .proportion')
    fcl_distribution_proportionb=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[1] | .proportion')
    fcl_distribution_proportionc=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.FIRST_CONTENTFUL_PAINT_MS.distributions" | jq '.[2] | .proportion')
    if [[ "$fcp_median" != 'null' ]]; then
      fcl_distribution_proportiona_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $fcl_distribution_proportiona)*100" | bc))
      fcl_distribution_proportionb_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $fcl_distribution_proportionb)*100" | bc))
      fcl_distribution_proportionc_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $fcl_distribution_proportionc)*100" | bc))
    fi
    dcl_distribution_min=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.DOM_CONTENT_LOADED_EVENT_FIRED_MS.distributions" | jq '.[1] | .min')
    dcl_distribution_max=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.DOM_CONTENT_LOADED_EVENT_FIRED_MS.distributions" | jq '.[1] | .max')
    dcl_distribution_proportiona=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.DOM_CONTENT_LOADED_EVENT_FIRED_MS.distributions" | jq '.[0] | .proportion')
    dcl_distribution_proportionb=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.DOM_CONTENT_LOADED_EVENT_FIRED_MS.distributions" | jq '.[1] | .proportion')
    dcl_distribution_proportionc=$(cat /tmp/gitool-${strategy}.log | jq ".loadingExperience.metrics.DOM_CONTENT_LOADED_EVENT_FIRED_MS.distributions" | jq '.[2] | .proportion')
    if [[ "$dcl_median" != 'null' ]]; then
      dcl_distribution_proportiona_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $dcl_distribution_proportiona)*100" | bc))
      dcl_distribution_proportionb_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $dcl_distribution_proportionb)*100" | bc))
      dcl_distribution_proportionc_perc=$(printf "%.2f\n" $(echo "$(printf "%.3f\n" $dcl_distribution_proportionc)*100" | bc))
    fi
    if [[ "$fcp_median" != 'null' || "$dcl_median" != 'null' ]]; then
      if [[ "$PAGESPEED_COMPACT" = [yY] ]]; then
        echo "${strategy} ($overall_cat) $gpsi_speed_score_label" | tee /tmp/gitool-${strategy}-summary.log
        echo "Test url: ${origin_label}${prefix}://$domain" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "FCP: ${fcp_median}ms ($fcp_cat) DCL: ${dcl_median}ms ($dcl_cat)" | tee -a /tmp/gitool-${strategy}-summary.log
        # echo "Page Load Distributions" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${fcl_distribution_proportiona_perc}% pages fast FCP (<${fcl_distribution_min}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${fcl_distribution_proportionb_perc}% pages average FCP (<${fcl_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${fcl_distribution_proportionc_perc}% pages slow FCP (>${fcl_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${dcl_distribution_proportiona_perc}% pages fast DCL (<${dcl_distribution_min}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${dcl_distribution_proportionb_perc}% pages average DCL (<${dcl_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${dcl_distribution_proportionc_perc}% pages slow DCL (>${dcl_distribution_max}ms)" | tee -a /tmp/gitool-${strategy}-summary.log
        if [[ "$gpsi_minimizerenderblockingresources" = [yY] ]]; then
          echo -e "\n$gpsi_minimizerenderblockingresources_css_summary" | tee -a /tmp/gitool-${strategy}-summary.log
        fi
        if [[ "$gpsi_leveragebrowsercaching" = [yY] ]]; then
          echo -e "\n$gpsi_leveragebrowsercaching_summary" | tee -a /tmp/gitool-${strategy}-summary.log
        fi
      else
        echo "Test url: ${origin_label}${prefix}://$domain" | tee /tmp/gitool-${strategy}-summary.log
        echo "FCP median: $fcp_median ms ($fcp_cat) DCL median: $dcl_median ms ($dcl_cat)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "Page Load Distributions" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${fcl_distribution_proportiona_perc}% of page loads have a fast FCP (less than ${fcl_distribution_min} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${fcl_distribution_proportionb_perc}% of page loads have an average FCP (less than ${fcl_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${fcl_distribution_proportionc_perc}% of page loads have a slow FCP (over ${fcl_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${dcl_distribution_proportiona_perc}% of page loads have a fast DCL (less than ${dcl_distribution_min} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${dcl_distribution_proportionb_perc}% of page loads have an average DCL (less than ${dcl_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
        echo "${dcl_distribution_proportionc_perc}% of page loads have a slow DCL (over ${dcl_distribution_max} milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
        if [[ "$gpsi_minimizerenderblockingresources" = [yY] ]]; then
          echo -e "\n$gpsi_minimizerenderblockingresources_css_summary" | tee -a /tmp/gitool-${strategy}-summary.log
        fi
        if [[ "$gpsi_leveragebrowsercaching" = [yY] ]]; then
          echo -e "\n$gpsi_leveragebrowsercaching_summary" | tee -a /tmp/gitool-${strategy}-summary.log
        fi
      fi
    fi
    echo
    if [[ "$SLACK" = [yY] ]]; then
      if [[ "$fcp_median" != 'null' || "$dcl_median" != 'null' ]]; then
        send_message="$(cat /tmp/gitool-${strategy}-summary.log)"
        if [[ "$overall_cat" = 'FAST' ]]; then
          message_color='good'
        elif [[ "$overall_cat" = 'AVERAGE' ]]; then
          message_color='warning'
        elif [[ "$overall_cat" = 'SLOW' ]]; then
          message_color='danger'
        fi
        slacksend "$send_message" "$DT - Google PageSpeed Insights v4" psi "$message_color"
      fi
    fi
    rm -rf /tmp/gitool-${strategy}.log
    rm -rf /tmp/gitool-${strategy}-summary.log
  done
}

#########################################################
case $1 in
  desktop )
    if [[ "$PAGESPEED_INSIGHTAPIVER" -eq '4' ]]; then
      gi_run $2 $3 desktop
    elif [[ "$PAGESPEED_INSIGHTAPIVER" -eq '5' ]]; then
      gi_run_six $2 desktop
    fi
    ;;
  mobile )
    if [[ "$PAGESPEED_INSIGHTAPIVER" -eq '4' ]]; then
      gi_run $2 $3 mobile
    elif [[ "$PAGESPEED_INSIGHTAPIVER" -eq '5' ]]; then
      gi_run_six $2 mobile
    fi
    ;;
  all )
    if [[ "$PAGESPEED_INSIGHTAPIVER" -eq '4' ]]; then
      gi_run $2 $3 desktop
      gi_run $2 $3 mobile
    elif [[ "$PAGESPEED_INSIGHTAPIVER" -eq '5' ]]; then
      gi_run_six $2 desktop
      gi_run_six $2 mobile
    fi
    ;;
  gtmetrix )
    if [[ "$GTMETRIX" = [yY] ]]; then
      gt_run $2 $3
    else
      echo "GTMETRIX='n' detected"
    fi
    ;;
  wpt )
    if [[ "$WPT" = [yY] ]]; then
      wpt_run $2 $3 $4 $5 $6
    else
      echo "WPT='n' detected"
    fi
    ;;
  * )
  echo
  echo "Usage:"
  echo
  if [[ "$PAGESPEED_INSIGHTAPIVER" -eq '4' ]]; then
    echo "Google PageSpeed Insights v4"
    echo "$0 desktop https://domain.com {default|origin|site}"
    echo "$0 mobile https://domain.com {default|origin|site}"
    echo "$0 all https://domain.com {default|origin|site}"
  elif [[ "$PAGESPEED_INSIGHTAPIVER" -eq '5' ]]; then
    echo "Google PageSpeed Insights v6"
    echo "$0 desktop https://domain.com"
    echo "$0 mobile https://domain.com"
    echo "$0 all https://domain.com"
  fi
  echo
  echo "GTMetrix"
  echo "$0 gtmetrix https://domain.com"
  echo
  echo "WebpageTest"
  echo
  echo "supported region(s)"
  echo "dulles, california, frankfurt, singapore, sydney"
  echo "dallas, london, tokyo, hongkong, mumbia, brazil,"
  echo "melbourne, bangkok, jakarta, taiwan, capetown"
  echo
  echo "$0 wpt https://community.centminmod.com {region} cable"
  echo "$0 wpt https://community.centminmod.com {region} 3g"
  echo "$0 wpt https://community.centminmod.com {region} 3gfast"
  echo "$0 wpt https://community.centminmod.com {region} 4g"
  echo "$0 wpt https://community.centminmod.com {region} lte"
  echo "$0 wpt https://community.centminmod.com {region} fios"
  echo
    ;;
esac
exit