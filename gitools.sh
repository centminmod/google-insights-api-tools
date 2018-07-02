#!/bin/bash
#########################################################
# quick Google PageSpeed Insights API tool
# written by George Liu (eva2000) https://centminmod.com
# https://developers.google.com/speed/docs/insights/v4/getting-started
#########################################################
# variables
#############
DT=$(date +"%d%m%y-%H%M%S")

# GET API Key from https://console.developers.google.com/
# by enabling PageSpeed Insights API and creating the
# API key from Credentials page. If you don't want to set the
# GOOGLE_API_KEY variable within this script, you can set it in
# gitools.ini config file which resides in same directory as gitools.sh
GOOGLE_API_KEY=''

SNAPSHOTS='n'
SCREENSHOT='n'
#########################################################
# functions
#############
if [ -f gitools.ini ]; then
  . gitools.ini
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

gi_desktop() {
  strategy=desktop
  fulldomain=$1
  origin_check=$2
  prefix=$(echo $fulldomain | awk -F '://' '{print $1}')
  domain=$(echo $fulldomain | awk -F '://' '{print $2}')
  if [[ "$origin_check" = 'origin' ]]; then
    origins='origin%3A'
  elif [[ "$origin_check" = 'site' ]]; then
    origins='default'
  else
    origins='default origin%3A'
  fi
  for o in $origins; do
    if [[ "$o" = 'default' ]]; then
      o=""
      metric_opt='&fields=formattedResults%2CloadingExperience(initial_url%2Cmetrics%2Coverall_category)%2CpageStats%2CruleGroups'
    elif [[ "$o" = 'origin%3A' ]]; then
      metric_opt='&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)'
    fi
    turl_echo="https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=${o}${prefix}%3A%2F%2F${domain}%2F&screenshot=${screenshot_state}&snapshots=${snapshots_state}&strategy=${strategy}${metric_opt}&key=YOUR_GOOGLE_API_KEY"
    turl="https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=${o}${prefix}%3A%2F%2F${domain}%2F&screenshot=${screenshot_state}&snapshots=${snapshots_state}&strategy=${strategy}${metric_opt}&key=${GOOGLE_API_KEY}"
    echo
    echo "--------------------------------------------------------------------------------"
    echo "curl -4s $turl_echo"
    curl -4s $turl
  done
}

gi_mobile() {
  strategy=mobile
  fulldomain=$1
  origin_check=$2
  prefix=$(echo $fulldomain | awk -F '://' '{print $1}')
  domain=$(echo $fulldomain | awk -F '://' '{print $2}')
  if [[ "$origin_check" = 'origin' ]]; then
    origins='origin%3A'
  elif [[ "$origin_check" = 'site' ]]; then
    origins='default'
  else
    origins='default origin%3A'
  fi
  for o in $origins; do
    if [[ "$o" = 'default' ]]; then
      o=""
      metric_opt='&fields=formattedResults%2CloadingExperience(initial_url%2Cmetrics%2Coverall_category)%2CpageStats%2CruleGroups'
    elif [[ "$o" = 'origin%3A' ]]; then
      metric_opt='&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)'
    fi
    turl_echo="https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=${o}${prefix}%3A%2F%2F${domain}%2F&screenshot=${screenshot_state}&snapshots=${snapshots_state}&strategy=${strategy}${metric_opt}&key=YOUR_GOOGLE_API_KEY"
    turl="https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=${o}${prefix}%3A%2F%2F${domain}%2F&screenshot=${screenshot_state}&snapshots=${snapshots_state}&strategy=${strategy}${metric_opt}&key=${GOOGLE_API_KEY}"
    echo
    echo "--------------------------------------------------------------------------------"
    echo "curl -4s $turl_echo"
    curl -4s $turl
  done
}

gi_both() {
  _fulldomain=$1
  _origin_check=$2
  gi_desktop $_fulldomain $_origin_check
  gi_mobile $_fulldomain $_origin_check
}
#########################################################
case $1 in
  desktop )
    gi_desktop $2 $3
    ;;
  mobile )
    gi_mobile $2 $3
    ;;
  all )
    gi_both $2 $3
    ;;
  pattern )
    ;;
  pattern )
    ;;
  * )
  echo
  echo "Usage:"
  echo
  echo "$0 desktop https://domain.com {origin|site}"
  echo "$0 mobile https://domain.com {origin|site}"
  echo "$0 all https://domain.com {origin|site}"
  echo
    ;;
esac
exit