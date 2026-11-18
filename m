From: Suyuan Wang <shyckless@gmail.com>
Date: Wed, 18 Nov 2026 15:38:25 +0000
Subject: [PATCH] remoteproc: omap: Fix cleanup after timer start failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-omap-rproc-v1-1-c2824060fd10@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHDG/WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0ML3fzcxALdooKi/GTdJGNjQxNLcxMz40RzJaCGgqLUtMwKsGHRsRB
 +cWlSVmpyCcgEpdpaAJiaNWRuAAAA
X-Change-ID: 20261118-omap-rproc-b331497463a7
To: andersson@kernel.org, mathieu.poirier@linaro.org
Cc: linux-remoteproc@vger.kernel.org, linux-omap@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795016304; l=2382;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=5CaSvn4PiRTxlXy+sXlFYuB0nwYQd2B6binwsJAROTE=;
 b=FcG4ouxfwBkbl5ONLABK/xpQ+rRul8yhXniLdOWoNT8bFvI26PaqOSNpexnFmOP/rfMFO+J4b
 5Gf2XbdaEynCI8NGMVOIpSqhIRgMOtP1hPyuDi+YwMMuV4ViuefbaiX
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When omap_rproc_start_timer() fails in omap_rproc_enable_timers(), the
error handling has three problems.

First, the stop loop also stops the timer that failed to start:

	while (i >= 0) {
		omap_rproc_stop_timer(&timers[i]);
		i--;
	}

omap_dm_timer_start() drops its runtime PM reference when
pm_runtime_resume_and_get() fails, so stopping that timer calls
pm_runtime_put_sync() once more than it should.

Second, the loop leaves i at -1 and then jumps to put_node, which falls
through to free_timers:

	while (i--) {
		...
		omap_rproc_release_timer(&timers[i]);

With i == -1 the condition is true and the first iteration uses
timers[-2]. The loop then keeps going through negative indexes.

Third, when configure is true, put_node puts np again. The parse loop
already put every node it got, and np still points at the last one, so
that reference is dropped twice.

Only stop the timers that were started. On resume (configure == false)
return the error and keep the timers: they still belong to the driver
and are released later by omap_rproc_disable_timers(rproc, true). On the
first start (configure == true) release all the timers that were set up
and skip put_node, since no node reference is held at this point.

Found with a static analysis tool and checked by hand.

Fixes: e28edc571925 ("remoteproc/omap: Request a timer(s) for remoteproc usage")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on arm with clang (W=1, no new warnings). I don't have
the hardware, so the failure path hasn't been run.
---
 drivers/remoteproc/omap_remoteproc.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/drivers/remoteproc/omap_remoteproc.c b/drivers/remoteproc/omap_remoteproc.c
index f52a531877ae..d50f2e993c4e 100644
--- a/drivers/remoteproc/omap_remoteproc.c
+++ b/drivers/remoteproc/omap_remoteproc.c
@@ -418,11 +418,14 @@ static int omap_rproc_enable_timers(struct rproc *rproc, bool configure)
 		}
 	}
 	if (ret) {
-		while (i >= 0) {
+		while (i--)
 			omap_rproc_stop_timer(&timers[i]);
-			i--;
-		}
-		goto put_node;
+
+		if (!configure)
+			return ret;
+
+		i = num_timers;
+		goto free_timers;
 	}
 	return 0;
 



