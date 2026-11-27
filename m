From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 08:38:43 +0200
Subject: [PATCH RFC 06/10] coresight: cpu-debug: Factor out
 debug_read_pcsr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-6-69d3ad1e0fc8@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2394; i=iav@iav.lv;
 h=from:subject:message-id; bh=B/rYUrk8vm3PL2FWwqb3V6PtGtt/Zu19DxNEfiWFah8=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNmcqkVrJ4Ycf5Oj86ShcQ3bDYO+bw8ecWvqC7JMu/Xd9
 OZPgXOVHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiHusYGea66U0yWqCyNXdN
 6365Z4ZXDsYzsSxQMWIQn/JscefjBfaMDAcu+x+P3q8keN+NgY3/9SFj6bU72Od5+M39ImFruNK
 /jB0A
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the reads of EDPCSR and of the registers it latches out of
debug_read_regs(), so that they can be reused without the EDPRCR power
request.

No functional change.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/hwtracing/coresight/coresight-cpu-debug.c | 46 ++++++++++++-----------
 1 file changed, 24 insertions(+), 22 deletions(-)

diff --git a/drivers/hwtracing/coresight/coresight-cpu-debug.c b/drivers/hwtracing/coresight/coresight-cpu-debug.c
index 64b5abe33aa8..63bc4cb8df52 100644
--- a/drivers/hwtracing/coresight/coresight-cpu-debug.c
+++ b/drivers/hwtracing/coresight/coresight-cpu-debug.c
@@ -199,27 +199,8 @@ static void debug_force_cpu_powered_up(struct debug_drvdata *drvdata)
 		goto try_again;
 }
 
-static void debug_read_regs(struct debug_drvdata *drvdata)
+static void debug_read_pcsr(struct debug_drvdata *drvdata)
 {
-	u32 save_edprcr;
-
-	CS_UNLOCK(drvdata->base);
-
-	/* Unlock os lock */
-	debug_os_unlock(drvdata);
-
-	/* Save EDPRCR register */
-	save_edprcr = readl_relaxed(drvdata->base + EDPRCR);
-
-	/*
-	 * Ensure CPU power domain is enabled to let registers
-	 * are accessiable.
-	 */
-	debug_force_cpu_powered_up(drvdata);
-
-	if (!debug_access_permitted(drvdata))
-		goto out;
-
 	drvdata->edpcsr = readl_relaxed(drvdata->base + EDPCSR);
 
 	/*
@@ -230,7 +211,7 @@ static void debug_read_regs(struct debug_drvdata *drvdata)
 	 * UNKNOWN state. So directly bail out for this case.
 	 */
 	if (drvdata->edpcsr == EDPCSR_PROHIBITED)
-		goto out;
+		return;
 
 	/*
 	 * A read of the EDPCSR normally has the side-effect of
@@ -245,8 +226,29 @@ static void debug_read_regs(struct debug_drvdata *drvdata)
 
 	if (drvdata->edvidsr_present)
 		drvdata->edvidsr = readl_relaxed(drvdata->base + EDVIDSR);
+}
+
+static void debug_read_regs(struct debug_drvdata *drvdata)
+{
+	u32 save_edprcr;
+
+	CS_UNLOCK(drvdata->base);
+
+	/* Unlock os lock */
+	debug_os_unlock(drvdata);
+
+	/* Save EDPRCR register */
+	save_edprcr = readl_relaxed(drvdata->base + EDPRCR);
+
+	/*
+	 * Ensure CPU power domain is enabled to let registers
+	 * are accessiable.
+	 */
+	debug_force_cpu_powered_up(drvdata);
+
+	if (debug_access_permitted(drvdata))
+		debug_read_pcsr(drvdata);
 
-out:
 	/* Restore EDPRCR register */
 	writel_relaxed(save_edprcr, drvdata->base + EDPRCR);
 

-- 
2.43.0

