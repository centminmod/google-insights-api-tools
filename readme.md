# Contents

* [Google PageSpeed Insights API Tools](#google-pagespeed-insights-api-tools)
* [Google PageSpeed Insights API Key](#google-pagespeed-insights-api-key)
  * [Steps to creating API Key Credentials](#steps-to-creating-api-key-credentials)
* [Notes](#notes)
* [Install](#install)
* [Usage](#usage)
  * [Both Desktop & Mobile Test origin](#both-desktop--mobile-test-origin)
  * [Desktop Test origin](#desktop-test-origin)
  * [Desktop Test site only](#desktop-test-site-only)
  * [Desktop Test default url only](#desktop-test-default-url-only)
* [Errors](#errors)
* [Configuration](#configuration)
  * [JSON Output](#json-output)
  * [Command Output](#command-output)
  * [Slack Channel](#slack-channel)
  * [Cronjob Scheduled Runs](#cronjob-scheduled-runs)
* [GTMetrix Report](#gtmetrix-report)
  * [GTMetrix Slack Channel](#gtmetrix-slack-channel)
* [WebpageTest.org API Tests](#webpagetestorg-api-tests)
  * [WebpageTest.org Slack Channel](#webpagetestorg-slack-channel)
  * [WebpageTest.org Google Lighthouse](#webpagetestorg-google-lighthouse)
  * [WebpageTest.org Command Line Options](#webpagetestorg-command-line-options)
  * [WebpageTest.org Waterfall](#webpagetestorg-waterfall)


## Google PageSpeed Insights API Tools

Google PageSpeed Insights can now report the aggregate pagespeed results from [Chrome User Experience Report](https://developers.google.com/web/tools/chrome-user-experience-report/) for your entire `origin` domain as seen [here](https://community.centminmod.com/threads/your-sites-google-pagespeed-insights-result.15070/) and [here](https://www.seroundtable.com/google-pagespeed-insights-aggregated-speed-data-origin-25935.html). To be able to use `gitools.sh` script, you first you need to have a Google account to get `GOOGLE_API_KEY` to be able to query the [Google PageSpeed Insights v4 API](https://developers.google.com/speed/docs/insights/v4/getting-started).

## Google PageSpeed Insights API Key

You can get API Key from https://console.developers.google.com/ by enabling PageSpeed Insights API and creating the  API key from Credentials page. If you don't want to set the `GOOGLE_API_KEY` variable within this script, you can set it in `gitools.ini` config file which resides in same directory as `gitools.sh`

```
GOOGLE_API_KEY='YOUR_GOOGLE_API_KEY'
```

### Steps to creating API Key Credentials

1. Create a Google Account if you don't have one https://accounts.google.com/SignUp
2. Login to Google API Console https://console.developers.google.com/
3. Create a new project
4. Enable the PageSpeed Insights API you can find it in API library
5. Create an API Key via Credentials Page

![](/images/google-console-api-02.png)

![](/images/google-console-api-06.png)

![](/images/google-console-api-09.png) ![](/images/google-console-api-10.png)


## Notes

Notes from [Chrome User Experience Report](https://developers.google.com/web/tools/chrome-user-experience-report/)

**Consider population differences across origins**

> The metrics provided by the Chrome User Experience Report are powered by real user measurement data. As a result, the data reflects how real users experienced the visited origin and, unlike synthetic or local testing where the test is performed under fixed and simulated conditions, captures the full range of external factors that shape and contribute to the final user experience.
> 
> For example, differences in population of users accessing a particular origin can contribute meaningful differences to the user experience. If the site is frequented by more visitors with more modern devices or via a faster network, the results may appear “fast” even if the site is not well optimized. Conversely, a well optimized site that attracts a wider population of users, or a population with larger fraction of users on slower devices or networks, may appear “slow”.
> 
> When performing head-to-head comparisons across origins, it is important to account and control for the population differences: segment by provided dimensions, such as device type and connection type, and consider external factors such as size of the population, countries from which the origin is accessed, and so on.

**Consider Chrome population differences**

> The Chrome User Experience report is powered by real user measurement aggregated from Chrome users who have opted-in to syncing their browsing history, have not set up a Sync passphrase, and have usage statistic reporting enabled. This population may not be representative of the broader user base for a particular origin and many origins may have population differences among each other. Further, this data does not account for users with different browsers and differences in browser adoption in different geographic regions.
> 
> As a result, be careful with the types of conclusions being drawn when looking at a cross-section of origins, and when comparing individual origins: avoid using absolute comparisons and consider other population factors outlined in the sections above.

Metrics from [Chrome User Experience Report](https://developers.google.com/web/tools/chrome-user-experience-report/)

**First Contentful Paint**

> “First Contentful Paint reports the time when the browser first rendered any text, image (including background images), non-white canvas or SVG. This includes text with pending webfonts. This is the first time users could start consuming page content.”

**DOMContentLoaded**

> “The DOMContentLoaded reports the time when the initial HTML document has been completely loaded and parsed, without waiting for stylesheets, images, and subframes to finish loading.” 

## Install

To install `gitools.sh` and create persistent config file `gitools.ini` within same directory.

```
mkdir -p /root/tools
cd /root/tools
git clone https://github.com/centminmod/google-insights-api-tools
cd google-insights-api-tools
touch gitools.ini
```

To set variables in `/root/tools/google-insights-api-tools/gitools.ini` that override `gitools.sh` default

```
GOOGLE_API_KEY='YOUR_GOOGLE_API_KEY'
CMD_OUTPUT='y'
JSON_OUTPUT='y'
SLACK='y'
webhook_url='YOUR_SLACK_WEBHOOK_URL'
channel='YOUR_SLACK_CHANNEL_NAME'
icon='ghost'
```

## Usage

There are several parameters to pass on command line, desktop/mobile/all determines which type of site you want to test and default/origin/site determines if you want to test the entire domain and all pages (origin) or just the url page itself (default) or just the pages on specific site (site). The site domain you pass must have either `http://` or `https://` prefix.

```
./gitools.sh 

Usage:

./gitools.sh desktop https://domain.com {default|origin|site}
./gitools.sh mobile https://domain.com {default|origin|site}
./gitools.sh all https://domain.com {default|origin|site}
```

## Errors

If site's traffic is too low and not added to Chrome User Experience Report, you will not be able to get an data, in which case you will see the following

```
./gitools.sh desktop https://domain.com site               

--------------------------------------------------------------------------------
curl -4s https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=site%3Ahttps%3A%2F%2Fdomain.com%2F&screenshot=false&snapshots=false&strategy=desktop&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)&key=YOUR_GOOGLE_API_KEY
{}

error: aborting...
```

## Configuration

### JSON Output

You can optionally turn off the JSON output and only display the summary results as well by setting `JSON_OUTPUT='n'` variable in `gitools.ini` config file which resides in same directory as `gitools.sh`

```
./gitools.sh mobile https://www.google.com origin

--------------------------------------------------------------------------------
curl -4s https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=origin%3Ahttps%3A%2F%2Fwww.google.com%2F&screenshot=false&snapshots=false&strategy=mobile&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)&key=YOUR_GOOGLE_API_KEY

https://www.google.com FCP median: 469 (FAST) ms DCL median: 883 ms (FAST)
Page Load Distributions
91.30 % loads for this page have a fast FCP (less than 1567 milliseconds)
5.30 % loads for this page have an average FCP (less than 2963 milliseconds)
3.30 % loads for this page have an slow FCP (over 2963 milliseconds)
91.50 % loads for this page have a fast DCL (less than 2120 milliseconds)
5.70 % loads for this page have an average DCL (less than 4226 milliseconds)
2.70 % loads for this page have a slow DCL (over 4226 milliseconds)
```

### Command Output

You can optionally turn off the displaying the curl command & JSON output and only display the summary results as well by setting `JSON_OUTPUT='n'` & `CMD_OUTPUT='n'` variable in `gitools.ini` config file which resides in same directory as `gitools.sh`

```
./gitools.sh mobile https://www.google.com origin

--------------------------------------------------------------------------------
https://www.google.com FCP median: 469 (FAST) ms DCL median: 883 ms (FAST)
Page Load Distributions
91.30 % loads for this page have a fast FCP (less than 1567 milliseconds)
5.30 % loads for this page have an average FCP (less than 2963 milliseconds)
3.30 % loads for this page have an slow FCP (over 2963 milliseconds)
91.50 % loads for this page have a fast DCL (less than 2120 milliseconds)
5.70 % loads for this page have an average DCL (less than 4226 milliseconds)
2.70 % loads for this page have a slow DCL (over 4226 milliseconds)
```

### Slack Channel

You can send results to a Slack Channel via incoming webhooks by setting `SLACK='y'` and other listed variables in `gitools.ini` config file which resides in same directory as `gitools.sh`

```
SLACK='y'
webhook_url=""       # Incoming Webhooks integration URL
channel="general"    # Default channel to post messages. '#' is prepended
username="psi-bot"   # Default username to post messages.
icon="ghost"         # Default emoji to post messages. Don't wrap it with ':'. See http://www.emoji-cheat-sheet.com; can be a url too.
```

![](/images/google-pagespeed-insight-api-gitool-slack-01b.png)

### Cronjob Scheduled Runs

You can create a cronjob script to schedule `gitools.sh` runs for mobile domain name origin checks. Useful, if you have enabled [Slack Channel](#slack-channel) integration so can monitor your Google PageSpeed Insight results over time.

i.e. create a file called `cron.sh` at `/root/tools/google-insights-api-tools/cron.sh` containing the following - replacing the domains with your domains you want to check. Add as many domains you want - one per new line. Also added [GTMetrix Report](#gtmetrix-report) & [WebpageTest.org API Tests](#webpagetestorg-api-tests).

```
#!/bin/bash
cd /root/tools/google-insights-api-tools
./gitools.sh all https://www.google.com origin
./gitools.sh all https://centminmod.com origin
./gitools.sh all https://community.centminmod.com origin

./gitools.sh gtmetrix https://centminmod.com
./gitools.sh gtmetrix https://community.centminmod.com

./gitools.sh wpt https://centminmod.com dulles cable
./gitools.sh wpt https://centminmod.com california cable
./gitools.sh wpt https://centminmod.com frankfurt cable
./gitools.sh wpt https://centminmod.com singapore cable
./gitools.sh wpt https://centminmod.com sydney cable
./gitools.sh wpt https://centminmod.com dallas cable
./gitools.sh wpt https://centminmod.com london cable
./gitools.sh wpt https://community.centminmod.com dulles cable
./gitools.sh wpt https://community.centminmod.com california cable
./gitools.sh wpt https://community.centminmod.com frankfurt cable
./gitools.sh wpt https://community.centminmod.com singapore cable
./gitools.sh wpt https://community.centminmod.com sydney cable
./gitools.sh wpt https://community.centminmod.com dallas cable
./gitools.sh wpt https://community.centminmod.com london cable

./gitools.sh wpt https://centminmod.com dulles 3g
./gitools.sh wpt https://centminmod.com california 3g
./gitools.sh wpt https://centminmod.com frankfurt 3g
./gitools.sh wpt https://centminmod.com singapore 3g
./gitools.sh wpt https://centminmod.com sydney 3g
./gitools.sh wpt https://centminmod.com dallas 3g
./gitools.sh wpt https://centminmod.com london 3g
./gitools.sh wpt https://community.centminmod.com dulles 3g
./gitools.sh wpt https://community.centminmod.com california 3g
./gitools.sh wpt https://community.centminmod.com frankfurt 3g
./gitools.sh wpt https://community.centminmod.com singapore 3g
./gitools.sh wpt https://community.centminmod.com sydney 3g
./gitools.sh wpt https://community.centminmod.com dallas 3g
./gitools.sh wpt https://community.centminmod.com london 3g
```

ensure permissions are executeable

```
chmod +x /root/tools/google-insights-api-tools/cron.sh
```

do manual script run to check that it's working

```
/root/tools/google-insights-api-tools/cron.sh
```

setup cronjob to run every Monday once a week at 5:19 AM

```
19 5 * * MON /root/tools/google-insights-api-tools/cron.sh >/dev/null 2>&1
```

### Both Desktop & Mobile Test origin

Both Desktop & Mobile test `origin:` of a domain - all pages scanned for the domain = [https://www.google.com](https://developers.google.com/speed/pagespeed/insights/?url=origin%3Ahttps%3A%2F%2Fwww.google.com%2F)

![](/images/google-pagespeed-insight-api-gitool-desktop-01b.png)

![](/images/google-pagespeed-insight-api-gitool-mobile-01b.png)

```
./gitools.sh all https://www.google.com origin

--------------------------------------------------------------------------------
curl -4s https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=origin%3Ahttps%3A%2F%2Fwww.google.com%2F&screenshot=false&snapshots=false&strategy=desktop&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)&key=YOUR_GOOGLE_API_KEY
{
 "loadingExperience": {
  "metrics": {
   "FIRST_CONTENTFUL_PAINT_MS": {
    "median": 409,
    "distributions": [
     {
      "min": 0,
      "max": 984,
      "proportion": 0.8454713690354932
     },
     {
      "min": 984,
      "max": 2073,
      "proportion": 0.10403871224107414
     },
     {
      "min": 2073,
      "proportion": 0.0504899187234326
     }
    ],
    "category": "FAST"
   },
   "DOM_CONTENT_LOADED_EVENT_FIRED_MS": {
    "median": 872,
    "distributions": [
     {
      "min": 0,
      "max": 1366,
      "proportion": 0.806970519946481
     },
     {
      "min": 1366,
      "max": 2787,
      "proportion": 0.1438260280157439
     },
     {
      "min": 2787,
      "proportion": 0.04920345203777508
     }
    ],
    "category": "FAST"
   }
  },
  "overall_category": "FAST",
  "initial_url": "https://www.google.com/"
 }
}

https://www.google.com FCP median: 409 (FAST) ms DCL median: 872 ms (FAST)
Page Load Distributions
84.50 % loads for this page have a fast FCP (less than 984 milliseconds)
10.40 % loads for this page have an average FCP (less than 2073 milliseconds)
5.00 % loads for this page have an slow FCP (over 2073 milliseconds)
80.70 % loads for this page have a fast DCL (less than 1366 milliseconds)
14.40 % loads for this page have an average DCL (less than 2787 milliseconds)
4.90 % loads for this page have a slow DCL (over 2787 milliseconds)


--------------------------------------------------------------------------------
curl -4s https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=origin%3Ahttps%3A%2F%2Fwww.google.com%2F&screenshot=false&snapshots=false&strategy=mobile&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)&key=YOUR_GOOGLE_API_KEY
{
 "loadingExperience": {
  "metrics": {
   "FIRST_CONTENTFUL_PAINT_MS": {
    "median": 469,
    "distributions": [
     {
      "min": 0,
      "max": 1567,
      "proportion": 0.9132962514832138
     },
     {
      "min": 1567,
      "max": 2963,
      "proportion": 0.05335475928893682
     },
     {
      "min": 2963,
      "proportion": 0.03334898922784932
     }
    ],
    "category": "FAST"
   },
   "DOM_CONTENT_LOADED_EVENT_FIRED_MS": {
    "median": 883,
    "distributions": [
     {
      "min": 0,
      "max": 2120,
      "proportion": 0.9154626026722679
     },
     {
      "min": 2120,
      "max": 4226,
      "proportion": 0.05745611798106648
     },
     {
      "min": 4226,
      "proportion": 0.027081279346665484
     }
    ],
    "category": "FAST"
   }
  },
  "overall_category": "FAST",
  "initial_url": "https://www.google.com/"
 }
}

https://www.google.com FCP median: 469 (FAST) ms DCL median: 883 ms (FAST)
Page Load Distributions
91.30 % loads for this page have a fast FCP (less than 1567 milliseconds)
5.30 % loads for this page have an average FCP (less than 2963 milliseconds)
3.30 % loads for this page have an slow FCP (over 2963 milliseconds)
91.50 % loads for this page have a fast DCL (less than 2120 milliseconds)
5.70 % loads for this page have an average DCL (less than 4226 milliseconds)
2.70 % loads for this page have a slow DCL (over 4226 milliseconds)
```

### Desktop Test origin

Desktop test `origin:` of a domain - all pages scanned for the domain = [https://www.google.com](https://developers.google.com/speed/pagespeed/insights/?url=origin%3Ahttps%3A%2F%2Fwww.google.com%2F)

```
./gitools.sh desktop https://www.google.com origin

--------------------------------------------------------------------------------
curl -4s https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=origin%3Ahttps%3A%2F%2Fwww.google.com%2F&screenshot=false&snapshots=false&strategy=desktop&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)&key=YOUR_GOOGLE_API_KEY
{
 "loadingExperience": {
  "metrics": {
   "FIRST_CONTENTFUL_PAINT_MS": {
    "median": 409,
    "distributions": [
     {
      "min": 0,
      "max": 984,
      "proportion": 0.8454713690354932
     },
     {
      "min": 984,
      "max": 2073,
      "proportion": 0.10403871224107414
     },
     {
      "min": 2073,
      "proportion": 0.0504899187234326
     }
    ],
    "category": "FAST"
   },
   "DOM_CONTENT_LOADED_EVENT_FIRED_MS": {
    "median": 872,
    "distributions": [
     {
      "min": 0,
      "max": 1366,
      "proportion": 0.806970519946481
     },
     {
      "min": 1366,
      "max": 2787,
      "proportion": 0.1438260280157439
     },
     {
      "min": 2787,
      "proportion": 0.04920345203777508
     }
    ],
    "category": "FAST"
   }
  },
  "overall_category": "FAST",
  "initial_url": "https://www.google.com/"
 }
}

https://www.google.com FCP median: 409 (FAST) ms DCL median: 872 ms (FAST)
Page Load Distributions
84.50 % loads for this page have a fast FCP (less than 984 milliseconds)
10.40 % loads for this page have an average FCP (less than 2073 milliseconds)
5.00 % loads for this page have an slow FCP (over 2073 milliseconds)
80.70 % loads for this page have a fast DCL (less than 1366 milliseconds)
14.40 % loads for this page have an average DCL (less than 2787 milliseconds)
4.90 % loads for this page have a slow DCL (over 2787 milliseconds)
```

### Desktop Test site only

Desktop Test `site` only = [https://www.google.com](https://developers.google.com/speed/pagespeed/insights/?url=site%3Ahttps%3A%2F%2Fwww.google.com)

```
./gitools.sh desktop https://www.google.com site

--------------------------------------------------------------------------------
curl -4s https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=site%3Ahttps%3A%2F%2Fwww.google.com%2F&screenshot=false&snapshots=false&strategy=desktop&fields=loadingExperience(initial_url%2Cmetrics%2Coverall_category)&key=YOUR_GOOGLE_API_KEY
{
 "loadingExperience": {
  "metrics": {
   "FIRST_CONTENTFUL_PAINT_MS": {
    "median": 409,
    "distributions": [
     {
      "min": 0,
      "max": 984,
      "proportion": 0.8454713690354932
     },
     {
      "min": 984,
      "max": 2073,
      "proportion": 0.10403871224107414
     },
     {
      "min": 2073,
      "proportion": 0.0504899187234326
     }
    ],
    "category": "FAST"
   },
   "DOM_CONTENT_LOADED_EVENT_FIRED_MS": {
    "median": 872,
    "distributions": [
     {
      "min": 0,
      "max": 1366,
      "proportion": 0.806970519946481
     },
     {
      "min": 1366,
      "max": 2787,
      "proportion": 0.1438260280157439
     },
     {
      "min": 2787,
      "proportion": 0.04920345203777508
     }
    ],
    "category": "FAST"
   }
  },
  "overall_category": "FAST",
  "initial_url": "https://www.google.com/"
 }
}

https://www.google.com FCP median: 409 (FAST) ms DCL median: 872 ms (FAST)
Page Load Distributions
84.50 % loads for this page have a fast FCP (less than 984 milliseconds)
10.40 % loads for this page have an average FCP (less than 2073 milliseconds)
5.00 % loads for this page have an slow FCP (over 2073 milliseconds)
80.70 % loads for this page have a fast DCL (less than 1366 milliseconds)
14.40 % loads for this page have an average DCL (less than 2787 milliseconds)
4.90 % loads for this page have a slow DCL (over 2787 milliseconds)
```

### Desktop Test default url only

Desktop Test `default` url only = [https://www.google.com](https://developers.google.com/speed/pagespeed/insights/?url=https%3A%2F%2Fwww.google.com)

```
./gitools.sh desktop https://www.google.com default

--------------------------------------------------------------------------------
curl -4s https://www.googleapis.com/pagespeedonline/v4/runPagespeed?url=https%3A%2F%2Fwww.google.com%2F&screenshot=false&snapshots=false&strategy=desktop&fields=formattedResults%2CloadingExperience(initial_url%2Cmetrics%2Coverall_category)%2CpageStats%2CruleGroups&key=YOUR_GOOGLE_API_KEY
{
 "ruleGroups": {
  "SPEED": {
   "score": 100
  }
 },
 "loadingExperience": {
  "metrics": {
   "FIRST_CONTENTFUL_PAINT_MS": {
    "median": 653,
    "distributions": [
     {
      "min": 0,
      "max": 984,
      "proportion": 0.665188778465699
     },
     {
      "min": 984,
      "max": 2073,
      "proportion": 0.17106665988487277
     },
     {
      "min": 2073,
      "proportion": 0.16374456164942816
     }
    ],
    "category": "FAST"
   },
   "DOM_CONTENT_LOADED_EVENT_FIRED_MS": {
    "median": 728,
    "distributions": [
     {
      "min": 0,
      "max": 1366,
      "proportion": 0.7305463486065137
     },
     {
      "min": 1366,
      "max": 2787,
      "proportion": 0.1349309122511865
     },
     {
      "min": 2787,
      "proportion": 0.13452273914229979
     }
    ],
    "category": "FAST"
   }
  },
  "overall_category": "FAST",
  "initial_url": "https://www.google.com/"
 },
 "pageStats": {
  "numberResources": 15,
  "numberHosts": 6,
  "totalRequestBytes": "2286",
  "numberStaticResources": 9,
  "htmlResponseBytes": "227045",
  "overTheWireResponseBytes": "434876",
  "imageResponseBytes": "37282",
  "javascriptResponseBytes": "825514",
  "otherResponseBytes": "41770",
  "numberJsResources": 4,
  "numTotalRoundTrips": 10,
  "numRenderBlockingRoundTrips": 0
 },
 "formattedResults": {
  "locale": "en_US",
  "ruleResults": {
   "AvoidLandingPageRedirects": {
    "localizedRuleName": "Avoid landing page redirects",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "Your page has no redirects. Learn more about {{BEGIN_LINK}}avoiding landing page redirects{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/AvoidRedirects"
      }
     ]
    }
   },
   "EnableGzipCompression": {
    "localizedRuleName": "Enable compression",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "You have compression enabled. Learn more about {{BEGIN_LINK}}enabling compression{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/EnableCompression"
      }
     ]
    }
   },
   "LeverageBrowserCaching": {
    "localizedRuleName": "Leverage browser caching",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "You have enabled browser caching. Learn more about {{BEGIN_LINK}}browser caching recommendations{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/LeverageBrowserCaching"
      }
     ]
    }
   },
   "MainResourceServerResponseTime": {
    "localizedRuleName": "Reduce server response time",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "Your server responded quickly. Learn more about {{BEGIN_LINK}}server response time optimization{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/Server"
      }
     ]
    }
   },
   "MinifyCss": {
    "localizedRuleName": "Minify CSS",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "Your CSS is minified. Learn more about {{BEGIN_LINK}}minifying CSS{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/MinifyResources"
      }
     ]
    }
   },
   "MinifyHTML": {
    "localizedRuleName": "Minify HTML",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "Your HTML is minified. Learn more about {{BEGIN_LINK}}minifying HTML{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/MinifyResources"
      }
     ]
    }
   },
   "MinifyJavaScript": {
    "localizedRuleName": "Minify JavaScript",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "Your JavaScript content is minified. Learn more about {{BEGIN_LINK}}minifying JavaScript{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/MinifyResources"
      }
     ]
    }
   },
   "MinimizeRenderBlockingResources": {
    "localizedRuleName": "Eliminate render-blocking JavaScript and CSS in above-the-fold content",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "You have no render-blocking resources. Learn more about {{BEGIN_LINK}}removing render-blocking resources{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/BlockingJS"
      }
     ]
    }
   },
   "OptimizeImages": {
    "localizedRuleName": "Optimize images",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "Your images are optimized. Learn more about {{BEGIN_LINK}}optimizing images{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/OptimizeImages"
      }
     ]
    }
   },
   "PrioritizeVisibleContent": {
    "localizedRuleName": "Prioritize visible content",
    "ruleImpact": 0.0,
    "groups": [
     "SPEED"
    ],
    "summary": {
     "format": "You have the above-the-fold content properly prioritized. Learn more about {{BEGIN_LINK}}prioritizing visible content{{END_LINK}}.",
     "args": [
      {
       "type": "HYPERLINK",
       "key": "LINK",
       "value": "https://developers.google.com/speed/docs/insights/PrioritizeVisibleContent"
      }
     ]
    }
   }
  }
 }
}

https://www.google.com FCP median: 653 (FAST) ms DCL median: 728 ms (FAST)
Page Load Distributions
66.50 % loads for this page have a fast FCP (less than 984 milliseconds)
17.10 % loads for this page have an average FCP (less than 2073 milliseconds)
16.40 % loads for this page have an slow FCP (over 2073 milliseconds)
73.10 % loads for this page have a fast DCL (less than 1366 milliseconds)
13.50 % loads for this page have an average DCL (less than 2787 milliseconds)
13.50 % loads for this page have a slow DCL (over 2787 milliseconds)
```

## GTMetrix Report

To run GTMetrix report, you need to have signed up for a GTMetrix account and  set variables in `/root/tools/google-insights-api-tools/gitools.ini` that override `gitools.sh` default and set your GTMetrix account email and API key from https://gtmetrix.com/api/

```
GTMETRIX='y'
GTEMAIL='YOUR_GTMETRIX_ACCOUNT_EMAIL'
GTAPIKEY='YOUR_GTMETRIX_API_KEY'
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
```

Run `gitools.sh` gtmetrix option passing site to test https://community.centminmod.com. The site domain you pass must have either `http://` or `https://` prefix.

```
cd /root/tools/google-insights-api-tools

./gitools.sh gtmetrix https://community.centminmod.com

{"credits_left":56,"test_id":"GBIHKb7W","poll_state_url":"https://gtmetrix.com/api/0.1/test/GBIHKb7W"}
waiting on results...
{
  "resources": {
    "report_pdf": "https://gtmetrix.com/api/0.1/test/GBIHKb7W/report-pdf",
    "pagespeed": "https://gtmetrix.com/api/0.1/test/GBIHKb7W/pagespeed",
    "har": "https://gtmetrix.com/api/0.1/test/GBIHKb7W/har",
    "pagespeed_files": "https://gtmetrix.com/api/0.1/test/GBIHKb7W/pagespeed-files",
    "report_pdf_full": "https://gtmetrix.com/api/0.1/test/GBIHKb7W/report-pdf?full=1",
    "yslow": "https://gtmetrix.com/api/0.1/test/GBIHKb7W/yslow",
    "screenshot": "https://gtmetrix.com/api/0.1/test/GBIHKb7W/screenshot"
  },
  "error": "",
  "results": {
    "onload_time": 916,
    "first_contentful_paint_time": 687,
    "page_elements": 28,
    "report_url": "https://gtmetrix.com/reports/community.centminmod.com/ArOUhu5I",
    "redirect_duration": 0,
    "first_paint_time": 687,
    "dom_content_loaded_duration": null,
    "dom_content_loaded_time": 911,
    "dom_interactive_time": 667,
    "page_bytes": 508764,
    "page_load_time": 916,
    "html_bytes": 16691,
    "fully_loaded_time": 1885,
    "html_load_time": 395,
    "rum_speed_index": 687,
    "yslow_score": 89,
    "pagespeed_score": 95,
    "backend_duration": 208,
    "onload_duration": 2,
    "connect_duration": 187
  },
  "state": "completed"
}

--------------------------------------------------------------------------------
GTMetrix Test (Dallas Chrome Broadband 5Mbps): https://community.centminmod.com
PageSpeed Score: 95 YSlow Score: 89
Report: https://gtmetrix.com/reports/community.centminmod.com/ArOUhu5I
Fully Loaded Time: 1885 ms Total Page Size: 508764 (bytes) Requests: 28
RUM Speed Index: 687
Redirect: 0 ms Connect: 187 ms Backend: 208 ms
TTFB: 395 ms DOM-int: 667 ms First-paint: 687 ms
Contentful-paint: 687 ms DOM-loaded: 911 ms Onload: 916 ms
```

### GTMetrix Slack Channel

![](/images/gtmetrix-api-slack-01.png)


## WebpageTest.org API Tests

To run WebpageTest.org report via the [API](https://sites.google.com/a/webpagetest.org/docs/advanced-features/webpagetest-restful-apis), you need to have signed up for a [WebPageTest.org account](https://www.webpagetest.org/forums/member.php?action=register) to get API Key and set variables in `/root/tools/google-insights-api-tools/gitools.ini` that override `gitools.sh` default and set your WebpageTest.org API key from http://www.webpagetest.org/getkey.php. This test routine's code was borrowed from another one of my custom scripts which queried the WebpageTest.org API. I will be slowly porting the code over to `gitools.sh`.

```
WPT='y'
WPT_APIKEY='YOUR_WPT_API_KEY'
```

* Currently, tests are done only from Dulles, Dulles Motorola G4 3G, Dulles Galaxy S7, California, Frankfurt, Singapore, Sydney, Dallas & London locations for Chrome Cable 5Mbps speed profile and will later be expanded to other profile/locations. Due to delays in processing results, there's a incremental 15 seconds delay until results are displayed. If results are still not available, another 15 second delay and recheck is triggered and so on until results are available.
* WPT tests are run from a specific tester id for the region listed at https://www.webpagetest.org/getTesters.php. So WPT tests are more comparable between test runs when using the same tester id as usually there are many testers within a specific region. 
* Currently, for Dulles tester id `TESTER_CABLE='VM3-06'` and for California tester id `TESTER_CABLE='ip-172-31-8-84'` and for Frankfurt tester id `TESTER_CABLE='ip-172-31-28-65'` and for Singapore tester id `TESTER_CABLE='ip-172-31-39-48'` and for Sydney tester id `TESTER_CABLE='ip-172-31-7-201'` and for Dulles Motorola G4 3G tester id `TESTER_CABLE='MotoG4_21'` are used. Dulles region is the main test location so has the most tester server ids (32) ranging from `VM1-01 to VM1-08`, `VM2-01 to VM2-08`, `VM3-01 to VM3-08` and `VM4-01 to VM4-08`.

Dulles test with variables set in `/root/tools/google-insights-api-tools/gitools.ini` to

```
WPT_DULLES='y'
WPT_DULLES_3G='n'
WPT_DULLES_3G_S7='n'
WPT_CALIFORNIA='n'
WPT_FRANKFURT='n'
WPT_SINGAPORE='n'
WPT_SYDNEY='n'
WPT_DALLAS='n'
WPT_LONDON='n'
```

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com             

--------------------------------------------------------------------------------
Dulles:Chrome.Cable WPT Results
--------------------------------------------------------------------------------
Test ID: 180704_H8_23eed1d3922c72ddac94702865d442fb
https://www.webpagetest.org/result/180704_H8_23eed1d3922c72ddac94702865d442fb/
/home/wptresults/wpt-dulles.chrome.cable.040718-074351.log
Ok
----
firstPaint 1065 
loadTime 1270 
domInteractive 1235 
fullyLoaded 2536 
requests 25 
TTFB 453 
domElements 1983 
visualComplete 1900 
render 1100 
SpeedIndex 1124 
visualComplete85 1100 
visualComplete90 1100 
visualComplete95 1300 
visualComplete99 1300 
chromeUserTiming.firstPaint 1064 
ok----
--------------------------------------------------------------------------------
```

California test with variable set in `/root/tools/google-insights-api-tools/gitools.ini` to

```
WPT_DULLES='n'
WPT_DULLES_3G='n'
WPT_DULLES_3G_S7='n'
WPT_CALIFORNIA='y'
WPT_FRANKFURT='n'
WPT_SINGAPORE='n'
WPT_SYDNEY='n'
WPT_DALLAS='n'
WPT_LONDON='n'
```

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com          

--------------------------------------------------------------------------------
ec2-us-west-1:Chrome.Cable WPT Results
--------------------------------------------------------------------------------
Test ID: 180704_DX_a6a1d27c616668ec6ae373c527e92168
https://www.webpagetest.org/result/180704_DX_a6a1d27c616668ec6ae373c527e92168/
/home/wptresults/wpt-california.ec2-us-west-1.chrome.cable.040718-195523.log
Ok (200)
----
firstPaint 603 
loadTime 621 
domInteractive 231 
fullyLoaded 1621 
requests 25 
TTFB 191 
domElements 2001 
visualComplete 1100 
render 600 
SpeedIndex 605 
visualComplete85 600 
visualComplete90 600 
visualComplete95 600 
visualComplete99 600 
chromeUserTiming.domInteractive 231 
ok----
--------------------------------------------------------------------------------
```

Frankfurt test with variable set in `/root/tools/google-insights-api-tools/gitools.ini` to

```
WPT_DULLES='n'
WPT_DULLES_3G='n'
WPT_DULLES_3G_S7='n'
WPT_CALIFORNIA='n'
WPT_FRANKFURT='y'
WPT_SINGAPORE='n'
WPT_SYDNEY='n'
WPT_DALLAS='n'
WPT_LONDON='n'
```

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com

--------------------------------------------------------------------------------
ec2-eu-central-1:Chrome.Cable WPT Results
--------------------------------------------------------------------------------
Test ID: 180704_F3_4a0be6f7e2c7ee3428da8fd714310cef
https://www.webpagetest.org/result/180704_F3_4a0be6f7e2c7ee3428da8fd714310cef/
/home/wptresults/wpt-frankfurt.ec2-eu-central-1.chrome.cable.040718-211129.log
Ok (200)
----
firstPaint 1212 
loadTime 1324 
domInteractive 1300 
fullyLoaded 3183 
requests 29 
TTFB 754 
domElements 1982 
visualComplete 2500 
render 1300 
SpeedIndex 1383 
visualComplete85 1300 
visualComplete90 1300 
visualComplete95 2400 
visualComplete99 2500 
chromeUserTiming.firstPaint 1211 
ok----
--------------------------------------------------------------------------------
```

Singapore test with variable set in `/root/tools/google-insights-api-tools/gitools.ini` to

```
WPT_DULLES='n'
WPT_DULLES_3G='n'
WPT_DULLES_3G_S7='n'
WPT_CALIFORNIA='n'
WPT_FRANKFURT='n'
WPT_SINGAPORE='y'
WPT_SYDNEY='n'
WPT_DALLAS='n'
WPT_LONDON='n'
```

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com

--------------------------------------------------------------------------------
ec2-ap-southeast-1:Chrome.Cable WPT Results
--------------------------------------------------------------------------------
Test ID: 180704_X4_3fb278c50ca48c6a253bb1b10fa0547d
https://www.webpagetest.org/result/180704_X4_3fb278c50ca48c6a253bb1b10fa0547d/
/home/wptresults/wpt-singapore.ec2-ap-southeast-1.chrome.cable.040718-220521.log
Ok (200)
----
firstPaint 2116 
loadTime 1978 
domInteractive 1335 
fullyLoaded 4060 
requests 27 
TTFB 970 
domElements 1973 
visualComplete 2400 
render 2100 
SpeedIndex 2103 
visualComplete85 2100 
visualComplete90 2100 
visualComplete95 2100 
visualComplete99 2100 
chromeUserTiming.domInteractive 1335 
ok----
--------------------------------------------------------------------------------
```

Sydney test with variable set in `/root/tools/google-insights-api-tools/gitools.ini` to

```
WPT_DULLES='n'
WPT_DULLES_3G='n'
WPT_DULLES_3G_S7='n'
WPT_CALIFORNIA='n'
WPT_FRANKFURT='n'
WPT_SINGAPORE='n'
WPT_SYDNEY='y'
WPT_DALLAS='n'
WPT_LONDON='n'
```

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com

--------------------------------------------------------------------------------
ec2-ap-southeast-2:Chrome.Cable WPT Results
--------------------------------------------------------------------------------
Test ID: 180704_RR_177c25aa214d6a05433e71d164426586
https://www.webpagetest.org/result/180704_RR_177c25aa214d6a05433e71d164426586/
/home/wptresults/wpt-sydney.ec2-ap-southeast-2.chrome.cable.040718-221502.log
Ok (200)
----
firstPaint 1260 
loadTime 1365 
domInteractive 1250 
fullyLoaded 3444 
requests 51 
TTFB 799 
domElements 1982 
visualComplete 2500 
render 1300 
SpeedIndex 1391 
visualComplete85 1300 
visualComplete90 1400 
visualComplete95 2400 
visualComplete99 2500 
chromeUserTiming.domInteractive 1249 
ok----
--------------------------------------------------------------------------------
```

Dulles Motorla G4 3G test with variable set in `/root/tools/google-insights-api-tools/gitools.ini` to

```
WPT_DULLES='n'
WPT_DULLES_3G='y'
WPT_DULLES_3G_S7='n'
WPT_CALIFORNIA='n'
WPT_FRANKFURT='n'
WPT_SINGAPORE='n'
WPT_SYDNEY='n'
WPT_DALLAS='n'
WPT_LONDON='n'
```

Very long backlog queue !

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com

--------------------------------------------------------------------------------
Dulles:MotoG4:3g WPT Results
--------------------------------------------------------------------------------
Test ID: 180705_MY_8MM
https://www.webpagetest.org/result/180705_MY_8MM/
https://www.webpagetest.org/lighthouse.php?test=180705_MY_8MM
/home/wptresults/wpt-dulles-motog4-mobile.chrome.3g.050718-034125.log
Waiting behind 5 other tests...
Waiting behind 5 other tests... (101)
waiting on results...
Waiting behind 5 other tests...
Waiting behind 5 other tests... (101)
waiting on results...
Waiting behind 5 other tests...
Waiting behind 5 other tests... (101)
waiting on results...
Waiting behind 5 other tests...
Waiting behind 5 other tests... (101)
waiting on results...
Waiting behind 5 other tests...
Waiting behind 5 other tests... (101)
waiting on results...
Waiting behind 7 other tests...
Waiting behind 7 other tests... (101)
waiting on results...
```

Dallas test with variable set in `/root/tools/google-insights-api-tools/gitools.ini` to

```
WPT_DULLES='n'
WPT_DULLES_3G='n'
WPT_DULLES_3G_S7='n'
WPT_CALIFORNIA='n'
WPT_FRANKFURT='n'
WPT_SINGAPORE='n'
WPT_SYDNEY='n'
WPT_DALLAS='y'
WPT_LONDON='n'
```

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com

--------------------------------------------------------------------------------
Texas2:Chrome.Cable WPT Results
--------------------------------------------------------------------------------
Test ID: 180705_HS_1N86
https://www.webpagetest.org/result/180705_HS_1N86/
https://www.webpagetest.org/lighthouse.php?test=180705_HS_1N86
/home/wptresults/wpt-dallas.Texas2.chrome.cable.050718-222621.log
Test Started 26 seconds ago
Test Started 26 seconds ago (100)
waiting on results...
Test Complete
Test Complete (200)
waiting on results...
Test Complete
Test Complete (200)
----
firstPaint 867 
loadTime 1041 
domInteractive 565 
fullyLoaded 2560 
requests 25 
TTFB 428 
domElements 1967 
visualComplete 1967 
render 900 
SpeedIndex 910 
visualComplete85 900 
visualComplete90 900 
visualComplete95 900 
visualComplete99 900 
chromeUserTiming.domInteractive 564 
chromeUserTiming.firstPaint 866 
chromeUserTiming.firstContentfulPaint 866 
chromeUserTiming.firstMeaningfulPaintCandidate 1011 
chromeUserTiming.firstMeaningfulPaint 1011 
chromeUserTiming.domComplete 1040 
lighthouse.Performance.first-contentful-paint 1489 
lighthouse.Performance.estimated-input-latency 50 
lighthouse.Performance.speed-index 1720 
lighthouse.Performance.first-meaningful-paint 2005 
lighthouse.Performance.first-cpu-idle 4316 
https://www.webpagetest.org/results/18/07/05/HS/1N86/1_waterfall.png
ok----
--------------------------------------------------------------------------------
```

London test with variable set in `/root/tools/google-insights-api-tools/gitools.ini` to

```
WPT_DULLES='n'
WPT_DULLES_3G='n'
WPT_DULLES_3G_S7='n'
WPT_CALIFORNIA='n'
WPT_FRANKFURT='n'
WPT_SINGAPORE='n'
WPT_SYDNEY='n'
WPT_DALLAS='n'
WPT_LONDON='y'
```

Experiencing a queue backlog but eventually completed

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com

--------------------------------------------------------------------------------
London_EC2:Chrome.Cable WPT Results
--------------------------------------------------------------------------------
Test ID: 180705_NX_1NC7
https://www.webpagetest.org/result/180705_NX_1NC7/
https://www.webpagetest.org/lighthouse.php?test=180705_NX_1NC7
/home/wptresults/wpt-london.London_EC2.chrome.cable.050718-223146.log
Waiting behind 5 other tests...
Waiting behind 5 other tests... (101)
waiting on results...
Waiting behind 3 other tests...
Waiting behind 3 other tests... (101)
waiting on results...
Waiting at the front of the queue...
Waiting at the front of the queue... (101)
waiting on results...
Test Started 21 seconds ago
Test Started 21 seconds ago (100)
waiting on results...
Test Complete
Test Complete (200)
waiting on results...
Test Complete
Test Complete (200)
----
firstPaint 1350 
loadTime 1375 
domInteractive 1089 
fullyLoaded 2768 
requests 28 
TTFB 812 
domElements 1978 
visualComplete 2500 
render 1300 
SpeedIndex 1374 
visualComplete85 1300 
visualComplete90 1300 
visualComplete95 2300 
visualComplete99 2500 
chromeUserTiming.domInteractive 1088 
chromeUserTiming.firstPaint 1350 
chromeUserTiming.firstContentfulPaint 1350 
chromeUserTiming.domComplete 1375 
chromeUserTiming.firstMeaningfulPaint 1449 
chromeUserTiming.firstMeaningfulPaintCandidate 1449 
lighthouse.Performance.first-contentful-paint 2296 
lighthouse.Performance.estimated-input-latency 20 
lighthouse.Performance.speed-index 2553 
lighthouse.Performance.first-meaningful-paint 2733 
lighthouse.Performance.first-cpu-idle 3669 
https://www.webpagetest.org/results/18/07/05/NX/1NC7/1_waterfall.png
ok----
--------------------------------------------------------------------------------
```

### WebpageTest.org Slack Channel

Dulles Motorla G4 3G test

![](/images/wpt-dulles-3g-slack-01.png)

Dulles test

![](/images/wpt-dulles-slack-01.png)

California test

![](/images/wpt-california-slack-01.png)

Frankfurt test

![](/images/wpt-frankfurt-slack-01.png)

Singapore test

![](/images/wpt-singapore-slack-01.png)

Sydney test

![](/images/wpt-sydney-slack-01.png)

### WebpageTest.org Google Lighthouse

As at July 5, 2018 Google Lighthouse reports are enabled by default via `WPT_LIGHTHOUSE='y` variable which you can disable by setting `WPT_LIGHTHOUSE='n` in `/root/tools/google-insights-api-tools/gitools.ini`

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com

--------------------------------------------------------------------------------
Dulles:Chrome.Cable WPT Results
--------------------------------------------------------------------------------
Test ID: 180704_M6_1dc3d8b3c9e13e620146cb06b2fe9124
https://www.webpagetest.org/result/180704_M6_1dc3d8b3c9e13e620146cb06b2fe9124/
https://www.webpagetest.org/lighthouse.php?test=180704_M6_1dc3d8b3c9e13e620146cb06b2fe9124
/home/wptresults/wpt-dulles.chrome.cable.040718-234013.log
Test Started 29 seconds ago
Test Started 29 seconds ago (100)
waiting on results...
Test Complete
Test Complete (200)
waiting on results...
Test Complete
Test Complete (200)
----
firstPaint 899 
loadTime 1115 
domInteractive 1094 
fullyLoaded 2504 
requests 25 
TTFB 402 
domElements 1979 
visualComplete 1900 
render 1000 
SpeedIndex 1023 
visualComplete85 1000 
visualComplete90 1000 
visualComplete95 1200 
visualComplete99 1200 
chromeUserTiming.firstPaint 899 
chromeUserTiming.firstContentfulPaint 899 
chromeUserTiming.firstMeaningfulPaintCandidate 1032 
chromeUserTiming.firstMeaningfulPaint 1032 
chromeUserTiming.domInteractive 1094 
chromeUserTiming.domComplete 1114 
lighthouse.Performance.first-contentful-paint 1840 
lighthouse.Performance.estimated-input-latency 41 
lighthouse.Performance.speed-index 2089 
lighthouse.Performance.first-meaningful-paint 2179 
lighthouse.Performance.first-cpu-idle 4157 
ok----
--------------------------------------------------------------------------------

```

Dulles test with Google Lighthouse report

![](/images/wpt-dulles-slack-lighthouse-01.png)

### WebpageTest.org Command Line Options

You can also pass the WebpageTets.org test region name on the command line for the following regions

Dulles Galaxy S7 3G test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com dulles-s7-3g
```

Dulles Motorola G4 3G test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com dulles-3g
```

Dulles test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com dulles
```

California test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com california
```

Frankfurt test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com frankfurt
```

Singapore test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com singapore
```

Sydney test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com sydney
```

Dallas test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com dallas
```

London test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com london
```

You can also pass the speed profile for your tests now - supported options are `cable`, `3g`, `4g`, `lte` and `fios` on the command line for the following regions

Dulles test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com dulles cable
./gitools.sh wpt https://community.centminmod.com dulles 3g
./gitools.sh wpt https://community.centminmod.com dulles 4g
./gitools.sh wpt https://community.centminmod.com dulles lte
./gitools.sh wpt https://community.centminmod.com dulles fios
```

California test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com california cable
./gitools.sh wpt https://community.centminmod.com california 3g
./gitools.sh wpt https://community.centminmod.com california 4g
./gitools.sh wpt https://community.centminmod.com california lte
./gitools.sh wpt https://community.centminmod.com california fios
```

Frankfurt test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com frankfurt cable
./gitools.sh wpt https://community.centminmod.com frankfurt 3g
./gitools.sh wpt https://community.centminmod.com frankfurt 4g
./gitools.sh wpt https://community.centminmod.com frankfurt lte
./gitools.sh wpt https://community.centminmod.com frankfurt fios
```

Singapore test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com singapore cable
./gitools.sh wpt https://community.centminmod.com singapore 3g
./gitools.sh wpt https://community.centminmod.com singapore 4g
./gitools.sh wpt https://community.centminmod.com singapore lte
./gitools.sh wpt https://community.centminmod.com singapore fios
```

Sydney test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com sydney cable
./gitools.sh wpt https://community.centminmod.com sydney 3g
./gitools.sh wpt https://community.centminmod.com sydney 4g
./gitools.sh wpt https://community.centminmod.com sydney lte
./gitools.sh wpt https://community.centminmod.com sydney fios
```

Dallas test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com dallas cable
./gitools.sh wpt https://community.centminmod.com dallas 3g
./gitools.sh wpt https://community.centminmod.com dallas 4g
./gitools.sh wpt https://community.centminmod.com dallas lte
./gitools.sh wpt https://community.centminmod.com dallas fios
```

London test

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com london cable
./gitools.sh wpt https://community.centminmod.com london 3g
./gitools.sh wpt https://community.centminmod.com london 4g
./gitools.sh wpt https://community.centminmod.com london lte
./gitools.sh wpt https://community.centminmod.com london fios
```

### WebpageTest.org Waterfall

Latest version now includes the waterfall screenshot image as well

```
cd /root/tools/google-insights-api-tools

./gitools.sh wpt https://community.centminmod.com dulles

--------------------------------------------------------------------------------
Dulles:Chrome.Cable WPT Results
--------------------------------------------------------------------------------
Test ID: 180705_SK_ARW
https://www.webpagetest.org/result/180705_SK_ARW/
https://www.webpagetest.org/lighthouse.php?test=180705_SK_ARW
/home/wptresults/wpt-dulles.chrome.cable.050718-044704.log
Test Started 27 seconds ago
Test Started 27 seconds ago (100)
waiting on results...
Test Complete
Test Complete (200)
waiting on results...
Test Complete
Test Complete (200)
----
firstPaint 1235 
loadTime 1511 
domInteractive 1459 
fullyLoaded 3112 
requests 25 
TTFB 496 
domElements 1979 
visualComplete 2300 
render 1300 
SpeedIndex 1326 
visualComplete85 1300 
visualComplete90 1300 
visualComplete95 1500 
visualComplete99 1500 
chromeUserTiming.firstPaint 1235 
chromeUserTiming.firstContentfulPaint 1235 
chromeUserTiming.domInteractive 1459 
chromeUserTiming.firstMeaningfulPaintCandidate 1479 
chromeUserTiming.firstMeaningfulPaint 1479 
chromeUserTiming.domComplete 1511 
lighthouse.Performance.first-contentful-paint 1814 
lighthouse.Performance.estimated-input-latency 38 
lighthouse.Performance.speed-index 2068 
lighthouse.Performance.first-meaningful-paint 2176 
lighthouse.Performance.first-cpu-idle 4164 
https://www.webpagetest.org/results/18/07/05/SK/ARW/1_waterfall.png
ok----
--------------------------------------------------------------------------------
```

![](/images/wpt-dulles-slack-waterfall-01.png)