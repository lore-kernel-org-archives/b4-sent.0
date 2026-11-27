From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 08:38:41 +0200
Subject: [PATCH RFC 04/10] coresight: cpu-debug: Bound the power up retries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-4-69d3ad1e0fc8@iav.lv>
References: <20261127-b4-coresight-cpu-debug-lockup-v1-0-69d3ad1e0fc8@iav.lv>
In-Reply-To: <20261127-b4-coresight-cpu-debug-lockup-v1-0-69d3ad1e0fc8@iav.lv>
To: Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Mike Leach <mike.leach@arm.com>, James Clark <james.clark@linaro.org>, 
 Leo Yan <leo.yan@arm.com>, Andrew Morton <akpm@linux-foundation.org>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>
Cc: coresight@lists.linaro.org, linux-arm-kernel@lists.infradead.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Douglas Anderson <dianders@chromium.org>, Petr Mladek <pmladek@suse.com>, 
 Feng Tang <feng.tang@linux.alibaba.com>, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1720; i=iav@iav.lv;
 h=from:subject:message-id; bh=OKoXj3xk8yJN6a1FsEpY+jvEvBIQaBsnTrhXnixY+6k=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNmcqoUHlzLNaDeaHN8Y25xg5q3QzJX17se2/tWX5r2dJ
 XFaRmtvRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZjIh3yG/4WmBxnvb+LcsUfz
 5OSKAxEVMn/kdr14dmhepnPjPZH9qUYM/wPnHf+1ULe+frm62Xlf9tCPs1uPP0qTWvNt3ukVIu3
 /1TgA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

debug_force_cpu_powered_up() starts over whenever the core is found
powered down again right after CORENPDRQ is set, with no limit. Where
the power controller does not hold the core up, the caller never
returns.

Give up after three tries. EDPRSR then shows the core powered down and
debug_access_permitted() keeps the caller away from its registers.

Fixes: 2227b7c74634 ("coresight: add support for CPU debug module")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/hwtracing/coresight/coresight-cpu-debug.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/hwtracing/coresight/coresight-cpu-debug.c b/drivers/hwtracing/coresight/coresight-cpu-debug.c
index c55de98100a3..9a8ce85fc468 100644
--- a/drivers/hwtracing/coresight/coresight-cpu-debug.c
+++ b/drivers/hwtracing/coresight/coresight-cpu-debug.c
@@ -84,6 +84,7 @@
 
 #define DEBUG_WAIT_SLEEP		1000
 #define DEBUG_WAIT_TIMEOUT		32000
+#define DEBUG_POWER_UP_TRIES		3
 
 struct debug_drvdata {
 	struct clk	*pclk;
@@ -147,6 +148,7 @@ static bool debug_access_permitted(struct debug_drvdata *drvdata)
 
 static void debug_force_cpu_powered_up(struct debug_drvdata *drvdata)
 {
+	int tries = DEBUG_POWER_UP_TRIES;
 	u32 edprcr;
 
 try_again:
@@ -186,8 +188,8 @@ static void debug_force_cpu_powered_up(struct debug_drvdata *drvdata)
 
 	drvdata->edprsr = readl_relaxed(drvdata->base + EDPRSR);
 
-	/* The core power domain got switched off on use, try again */
-	if (unlikely(!(drvdata->edprsr & EDPRSR_PU)))
+	/* The core power domain got switched off on use, try again if allowed */
+	if (unlikely(!(drvdata->edprsr & EDPRSR_PU)) && --tries)
 		goto try_again;
 }
 

-- 
2.43.0

