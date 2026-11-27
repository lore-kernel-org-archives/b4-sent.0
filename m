From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 08:38:40 +0200
Subject: [PATCH RFC 03/10] coresight: cpu-debug: Publish the per-CPU data
 under debug_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-3-69d3ad1e0fc8@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2858; i=iav@iav.lv;
 h=from:subject:message-id; bh=ng8YC8Y3Ljza6ut1ftgTmWxS1VWe0wO1eJKzTsPgIWo=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNmcqoUfV0//U6O2Knptqe6+aL2KyYbsR6PPbdj+qo+tT
 3aN341THaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiHp6MDEeb58n2rV1wt73t
 u77kJH+XxhmKdfPzJnp6sexPFd///CPDX/F7m8+smeohYak5STtOxVTeZP3j4KV7723o2Lqywml
 JOgsA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The probe stores the per-CPU pointer before it has read the device ID
registers, so a device that it goes on to reject is visible to the
panic notifier and to the debugfs knob in between. The knob walks the
pointers under debug_lock, but the probe and the remove path change
them outside it: a write to the knob between the store and the
pm_runtime_put() of the probe leaves the device with one runtime PM
reference too many.

Store the pointer once the device is known to be usable, and change it
only under debug_lock, which the knob holds while it takes or drops the
runtime PM references of the published devices.

Fixes: 2227b7c74634 ("coresight: add support for CPU debug module")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/hwtracing/coresight/coresight-cpu-debug.c | 22 ++++++++--------------
 1 file changed, 8 insertions(+), 14 deletions(-)

diff --git a/drivers/hwtracing/coresight/coresight-cpu-debug.c b/drivers/hwtracing/coresight/coresight-cpu-debug.c
index f9e6e344ed59..c55de98100a3 100644
--- a/drivers/hwtracing/coresight/coresight-cpu-debug.c
+++ b/drivers/hwtracing/coresight/coresight-cpu-debug.c
@@ -590,30 +590,31 @@ static int __debug_probe(struct device *dev, struct resource *res)
 	drvdata->base = base;
 
 	cpus_read_lock();
-	per_cpu(debug_drvdata, drvdata->cpu) = drvdata;
 	ret = smp_call_function_single(drvdata->cpu, debug_init_arch_data,
 				       drvdata, 1);
 	cpus_read_unlock();
 
 	if (ret) {
 		dev_err(dev, "CPU%d debug arch init failed\n", drvdata->cpu);
-		goto err;
+		return ret;
 	}
 
 	if (!drvdata->edpcsr_present) {
 		dev_err(dev, "CPU%d sample-based profiling isn't implemented\n",
 			drvdata->cpu);
-		ret = -ENXIO;
-		goto err;
+		return -ENXIO;
 	}
 
 	if (!debug_count++) {
 		ret = debug_func_init();
-		if (ret)
-			goto err_func_init;
+		if (ret) {
+			debug_count--;
+			return ret;
+		}
 	}
 
 	mutex_lock(&debug_lock);
+	per_cpu(debug_drvdata, drvdata->cpu) = drvdata;
 	/* Turn off debug power domain if debugging is disabled */
 	if (!debug_enable)
 		pm_runtime_put(dev);
@@ -621,12 +622,6 @@ static int __debug_probe(struct device *dev, struct resource *res)
 
 	dev_info(dev, "Coresight debug-CPU%d initialized\n", drvdata->cpu);
 	return 0;
-
-err_func_init:
-	debug_count--;
-err:
-	per_cpu(debug_drvdata, drvdata->cpu) = NULL;
-	return ret;
 }
 
 static int debug_probe(struct amba_device *adev, const struct amba_id *id)
@@ -638,9 +633,8 @@ static void __debug_remove(struct device *dev)
 {
 	struct debug_drvdata *drvdata = dev_get_drvdata(dev);
 
-	per_cpu(debug_drvdata, drvdata->cpu) = NULL;
-
 	mutex_lock(&debug_lock);
+	per_cpu(debug_drvdata, drvdata->cpu) = NULL;
 	/* Turn off debug power domain before rmmod the module */
 	if (debug_enable)
 		pm_runtime_put(dev);

-- 
2.43.0

