#!/bin/bash
#########################################################
# quick Google PageSpeed Insights API tool
# & gtmetrix api tool
# written by George Liu (eva2000) https://centminmod.com
#
# https://developers.google.com/speed/docs/insights/v4/getting-started
# https://gtmetrix.com/api/
#########################################################
# variables
#############
VER='0.5'
DT=$(date +"%d%m%y-%H%M%S")


# GET API Key from https://console.developers.google.com/
# by enabling PageSpeed Insights API and creating the
# API key from Credentials page. If you don't want to set the
# GOOGLE_API_KEY variable within this script, you can set it in
# gitools.ini config file which resides in same directory as gitools.sh
GOOGLE_API_KEY=''

CMD_OUTPUT='y'
JSON_OUTPUT='y'
SNAPSHOTS='n'
SCREENSHOT='n'

# Gtmetrix API settings
GTMETRIX='n'
GTEMAIL=''
GTAPIKEY=''
GTBROWSER_WIDTH='1366'
GTBROWSER_HEIGHT='768'

# slack channel
SLACK='n'
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

slacksend() {
  dt=$DT
  # message="$dt: This is posted to #$channel and comes from a bot named $username."
  message="$1"
  curl -X POST --data-urlencode "payload={\"channel\": \"#$channel\", \"username\": \"$username\", \"text\": \"$message\", \"icon_emoji\": \":$icon:\"}" $webhook_url
}

gt_run() {
  fulldomain=$1
  prefix=$(echo $fulldomain | awk -F '://' '{print $1}')
  domain=$(echo $fulldomain | awk -F '://' '{print $2}')
  # browser = 3 chrome
  # location = 4 dallas
  curl -s --user $GTEMAIL:$GTAPIKEY --form url=${prefix}://${domain} --form x-metrix-adblock=0 --form x-metrix-video=1 --form browser=3 --form location=4 --form x-metrix-browser-width=$GTBROWSER_WIDTH --form x-metrix-browser-height=$GTBROWSER_HEIGHT --form x-metrix-throttle='5000/1000/30' https://gtmetrix.com/api/0.1/test | tee /tmp/gtmetrix.log
  echo "waiting on results..."
  sleep 30s
  gtmetrix_result=$(cat /tmp/gtmetrix.log | jq '.poll_state_url' | sed -e 's|\"||g')
  {
  curl -s --user $GTEMAIL:$GTAPIKEY $gtmetrix_result | jq '.'
  } > /tmp/gtmetrix-summary.log
  # waterfall=$(curl -s --user $gtemail:$gtapikey ${gtmetrix_result}/har | jq)
  
  onload_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.onload_time')
  first_contentful_paint_time=$(cat /tmp/gtmetrix-summary.log | jq '.results.first_contentful_paint_time')
  page_elements=$(cat /tmp/gtmetrix-summary.log | jq '.results.page_elements')
  report_url=$(cat /tmp/gtmetrix-summary.log | jq '.results.report_url')
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
  echo "GTMetrix Test (Dallas Chrome Broadband 5Mbps): ${prefix}://${domain}"
  echo "Report: $report_url"
  echo "Fully Loaded Time: $fully_loaded_time ms Total Page Size: $page_bytes (bytes) Requests: $page_elements"
  echo "RUM Speed Index: $rum_speed_index"
  echo "Redirect: $redirect_duration ms Connect: $connect_duration ms Backend: $backend_duration ms"
  echo "TTFB: $html_load_time ms DOM-int: $dom_interactive_time ms First-paint: $first_paint_time ms"
  echo "Contentful-paint: $first_contentful_paint_time ms DOM-loaded: $dom_content_loaded_time ms Onload: $onload_time ms"

  rm -rf /tmp/gtmetrix.log
  rm -rf /tmp/gtmetrix-summary.log
}

gi_run() {
  strategy=$3
  fulldomain=$1
  origin_check=$2
  prefix=$(echo $fulldomain | awk -F '://' '{print $1}')
  domain=$(echo $fulldomain | awk -F '://' '{print $2}')
  if [[ "$origin_check" = 'origin' ]]; then
    origins='origin%3A'
  elif [[ "$origin_check" = 'site' ]]; then
    origins='site%3A'
  elif [[ "$origin_check" = 'default' ]]; then
    origins='default'
  else
    origins='default site%3A origin%3A'
  fi
  for o in $origins; do
    if [[ "$o" = 'default' ]]; then
      o=""
      metric_opt='&fields=formattedResults%2CloadingExperience(initial_url%2Cmetrics%2Coverall_category)%2CpageStats%2CruleGroups'
    elif [[ "$o" = 'site%3A' ]]; then
      metric_opt='&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)'
    elif [[ "$o" = 'origin%3A' ]]; then
      metric_opt='&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)'
    fi
    turl_echo="https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=${o}${prefix}%3A%2F%2F${domain}%2F&screenshot=${screenshot_state}&snapshots=${snapshots_state}&strategy=${strategy}${metric_opt}&key=YOUR_GOOGLE_API_KEY"
    turl="https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=${o}${prefix}%3A%2F%2F${domain}%2F&screenshot=${screenshot_state}&snapshots=${snapshots_state}&strategy=${strategy}${metric_opt}&key=${GOOGLE_API_KEY}"
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

    # echo
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
      echo "${prefix}://$domain FCP median: $fcp_median ($fcp_cat) ms DCL median: $dcl_median ms ($dcl_cat)" | tee /tmp/gitool-${strategy}-summary.log
      echo "Page Load Distributions" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "$fcl_distribution_proportiona_perc % loads for this page have a fast FCP (less than $fcl_distribution_min milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "$fcl_distribution_proportionb_perc % loads for this page have an average FCP (less than $fcl_distribution_max milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "$fcl_distribution_proportionc_perc % loads for this page have a slow FCP (over $fcl_distribution_max milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "$dcl_distribution_proportiona_perc % loads for this page have a fast DCL (less than $dcl_distribution_min milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "$dcl_distribution_proportionb_perc % loads for this page have an average DCL (less than $dcl_distribution_max milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
      echo "$dcl_distribution_proportionc_perc % loads for this page have a slow DCL (over $dcl_distribution_max milliseconds)" | tee -a /tmp/gitool-${strategy}-summary.log
    fi
    echo
    if [[ "$SLACK" = [yY] ]]; then
      if [[ "$fcp_median" != 'null' || "$dcl_median" != 'null' ]]; then
        send_message="$(cat /tmp/gitool-${strategy}-summary.log)"
        slacksend "${strategy}\n$send_message"
      fi
    fi
    rm -rf /tmp/gitool-${strategy}.log
    rm -rf /tmp/gitool-${strategy}-summary.log
  done
}

#########################################################
case $1 in
  desktop )
    gi_run $2 $3 desktop
    ;;
  mobile )
    gi_run $2 $3 mobile
    ;;
  all )
    gi_run $2 $3 desktop
    gi_run $2 $3 mobile
    ;;
  gtmetrix )
    if [[ "$GTMETRIX" = [yY] ]]; then
      gt_run $2 $3
    else
      echo "GTMETRIX='n' detected"
    fi
    ;;
  pattern )
    ;;
  * )
  echo
  echo "Usage:"
  echo
  echo "$0 desktop https://domain.com {default|origin|site}"
  echo "$0 mobile https://domain.com {default|origin|site}"
  echo "$0 all https://domain.com {default|origin|site}"
  echo
    ;;
esac
exit