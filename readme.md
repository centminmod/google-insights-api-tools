# Google PageSpeed Insights API Tools

Google PageSpeed Insights can now report the aggregate pagespeed results from [Chrome User Experience Report](https://developers.google.com/web/tools/chrome-user-experience-report/) for your entire `origin` domain as seen [here](https://community.centminmod.com/threads/your-sites-google-pagespeed-insights-result.15070/) and [here](https://www.seroundtable.com/google-pagespeed-insights-aggregated-speed-data-origin-25935.html). To be able to use `gitools.sh` script, you first you need to have a Google account to get `GOOGLE_API_KEY` to be able to query the [Google PageSpeed Insights v4 API](https://developers.google.com/speed/docs/insights/v4/getting-started).

## Google PageSpeed Insights API Key

You can get API Key from https://console.developers.google.com/ by enabling PageSpeed Insights API and creating the  API key from Credentials page. If you don't want to set the `GOOGLE_API_KEY` variable within this script, you can set it in `gitools.ini` config file which resides in same directory as `gitools.sh`

```
GOOGLE_API_KEY='YOUR_GOOGLE_API_KEY'
```

### Steps to creating API Key Credentials

1. Create a Google Account if you don't have one https://accounts.google.com/SignUp
2. Login to Google API Console http://code.google.com/apis/console
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

### Slack Channel

You can send results to a Slack Channel via incoming webhooks by setting `SLACK='y'` and other listed variables in `gitools.ini` config file which resides in same directory as `gitools.sh`

```
SLACK='y'
webhook_url=""       # Incoming Webhooks integration URL
channel="general"    # Default channel to post messages. '#' is prepended
username="psi-bot"   # Default username to post messages.
icon="ghost"         # Default emoji to post messages. Don't wrap it with ':'. See http://www.emoji-cheat-sheet.com; can be a url too.
```

![](/images/google-pagespeed-insight-api-gitool-slack-01.png)


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
4.90 % loads for this page have an slow DCL (over 2787 milliseconds)


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
2.70 % loads for this page have an slow DCL (over 4226 milliseconds)
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
4.90 % loads for this page have an slow DCL (over 2787 milliseconds)
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
4.90 % loads for this page have an slow DCL (over 2787 milliseconds)
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
13.50 % loads for this page have an slow DCL (over 2787 milliseconds)
```