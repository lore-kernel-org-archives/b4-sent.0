From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 21:16:23 +0000
Subject: [PATCH v3 2/2] PM / devfreq: Do not change the frequency of a
 suspended device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-devfreq-suspend-sync-v3-2-ef19fbf94d83@gmail.com>
References: <20261119-devfreq-suspend-sync-v3-0-ef19fbf94d83@gmail.com>
In-Reply-To: <20261119-devfreq-suspend-sync-v3-0-ef19fbf94d83@gmail.com>
To: MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Steven Price <steven.price@arm.com>, Liviu Dudau <liviu.dudau@arm.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Dong Aisheng <aisheng.dong@nxp.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795122981; l=7885;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=WL/O7Bh0K+xryo8GDJrE73Hz4Oi1+D3tM/9x/xgwYKw=;
 b=6XRWKeP9LHuuCVP4VAzhRyyioZRu4B0Let8G2mnCkMBYaCCaF46kbcxi8Ayu2n77dY16hTt/7
 hK+e6ilKoEZDBu2QPLAOusWkcz7Fgc6or6acMCry/VyevpcWpsZbt1p
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Once a driver has called devfreq_suspend_device(), its device may be
powered down, but PM QoS and sysfs limits, cooling, the userspace
governor's set_freq, OPP notifiers and the passive governor still reach
->target() through devfreq_update_target(). On RK3588 with the GPU clock
on SCMI_CLK_GPU (not in mainline yet), TF-A then accesses the GPU GRF
with its power domain off, which ends in an SError.

Drivers cannot filter these calls in ->target() without races, as the
suspend count changes outside devfreq->lock.

Change the suspend count under devfreq->lock. While it is positive,
devfreq_update_target() only records that an update is pending, except
for passive updates from the parent, which exynos-bus needs at suspend
and shutdown. devfreq_resume_device() runs the pending update. Polling
governors, whose load data the driver has just reset, and the passive
governor instead resume at the previous frequency within the current
limits. The userspace governor without set_freq keeps the frequency from
before suspend.

On error, both functions leave devfreq suspended, as callers may power
the device down regardless. After a failed resume, the next
devfreq_suspend_device() and devfreq_resume_device() pair retries.

Suggested-by: Boris Brezillon <boris.brezillon@collabora.com>
Link: https://lore.kernel.org/r/20261110140232.061d6844@fedora1.home
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/devfreq/devfreq.c            | 82 ++++++++++++++++++++++++++++--------
 drivers/devfreq/governor_userspace.c |  3 +-
 include/linux/devfreq.h              | 10 ++++-
 3 files changed, 75 insertions(+), 20 deletions(-)

diff --git a/drivers/devfreq/devfreq.c b/drivers/devfreq/devfreq.c
index 795a01d012ec..7f1d5a7523a1 100644
--- a/drivers/devfreq/devfreq.c
+++ b/drivers/devfreq/devfreq.c
@@ -407,6 +407,16 @@ int devfreq_update_target(struct devfreq *devfreq, unsigned long freq)
 	if (!devfreq->governor)
 		return -EINVAL;
 
+	/*
+	 * The device may be powered down while it is suspended. Leave it
+	 * alone, devfreq_resume_device() does the update. A passive device
+	 * (freq set) still follows its parent, as exynos-bus needs.
+	 */
+	if (devfreq->suspend_count > 0 && !freq) {
+		devfreq->update_pending = true;
+		return 0;
+	}
+
 	/* Reevaluate the proper frequency */
 	err = devfreq->governor->get_target_freq(devfreq, &freq);
 	if (err)
@@ -871,7 +881,7 @@ struct devfreq *devfreq_add_device(struct device *dev,
 	if (IS_ERR(devfreq->opp_table))
 		devfreq->opp_table = NULL;
 
-	atomic_set(&devfreq->suspend_count, 0);
+	devfreq->suspend_count = 0;
 
 	dev_set_name(&devfreq->dev, "%s", dev_name(dev));
 	err = device_register(&devfreq->dev);
@@ -1140,17 +1150,26 @@ EXPORT_SYMBOL(devm_devfreq_remove_device);
  *
  * This function is intended to be called by the pm callbacks
  * (e.g., runtime_suspend, suspend) of the device driver that
- * holds the devfreq.
+ * holds the devfreq. On error, devfreq stays suspended.
  */
 int devfreq_suspend_device(struct devfreq *devfreq)
 {
 	unsigned long resume_freq;
-	int ret;
+	int ret, count;
 
 	if (!devfreq)
 		return -EINVAL;
 
-	if (atomic_inc_return(&devfreq->suspend_count) > 1)
+	mutex_lock(&devfreq->lock);
+	/* A failed resume left the count raised: this suspend takes it over */
+	if (devfreq->resume_failed) {
+		devfreq->resume_failed = false;
+		mutex_unlock(&devfreq->lock);
+		return 0;
+	}
+	count = ++devfreq->suspend_count;
+	mutex_unlock(&devfreq->lock);
+	if (count > 1)
 		return 0;
 
 	if (devfreq->governor) {
@@ -1181,34 +1200,63 @@ EXPORT_SYMBOL(devfreq_suspend_device);
  *
  * This function is intended to be called by the pm callbacks
  * (e.g., runtime_resume, resume) of the device driver that
- * holds the devfreq.
+ * holds the devfreq. If the frequency cannot be set, devfreq stays
+ * suspended.
  */
 int devfreq_resume_device(struct devfreq *devfreq)
 {
-	int ret;
+	unsigned long min_freq, max_freq, freq;
+	int ret = 0;
+	u32 flags;
 
 	if (!devfreq)
 		return -EINVAL;
 
-	if (atomic_dec_return(&devfreq->suspend_count) >= 1)
+	mutex_lock(&devfreq->lock);
+	/* Count 0: no suspend to resume from */
+	if (devfreq->suspend_count <= 0 || --devfreq->suspend_count > 0) {
+		mutex_unlock(&devfreq->lock);
 		return 0;
+	}
 
-	if (devfreq->resume_freq) {
-		mutex_lock(&devfreq->lock);
-		ret = devfreq_set_target(devfreq, devfreq->resume_freq, 0);
+	/*
+	 * Run the update deferred while suspended, except for polling
+	 * governors, which re-evaluate on fresh load data after
+	 * DEVFREQ_GOV_RESUME, and the passive governor, which follows its
+	 * parent. These resume within the current limits.
+	 */
+	if (devfreq->update_pending && devfreq->governor &&
+	    !IS_SUPPORTED_ATTR(devfreq->governor->attrs, POLLING_INTERVAL) &&
+	    strncmp(devfreq->governor->name, DEVFREQ_GOV_PASSIVE,
+		    DEVFREQ_NAME_LEN)) {
+		ret = devfreq_update_target(devfreq, 0);
+	} else {
+		freq = devfreq->resume_freq;
+		if (!freq && devfreq->update_pending)
+			freq = devfreq->previous_freq;
+		if (freq) {
+			devfreq_get_freq_range(devfreq, &min_freq, &max_freq);
+			freq = clamp(freq, min_freq, max_freq);
+			flags = freq == max_freq ? DEVFREQ_FLAG_LEAST_UPPER_BOUND : 0;
+			ret = devfreq_set_target(devfreq, freq, flags);
+		}
+	}
+	if (ret) {
+		/* The caller may keep the device powered down */
+		devfreq->suspend_count++;
+		devfreq->resume_failed = true;
 		mutex_unlock(&devfreq->lock);
-		if (ret)
-			return ret;
+		return ret;
 	}
+	devfreq->update_pending = false;
+	devfreq->resume_failed = false;
+	mutex_unlock(&devfreq->lock);
 
-	if (devfreq->governor) {
+	if (devfreq->governor)
 		ret = devfreq->governor->event_handler(devfreq,
 					DEVFREQ_GOV_RESUME, NULL);
-		if (ret)
-			return ret;
-	}
 
-	return 0;
+	return ret;
 }
 EXPORT_SYMBOL(devfreq_resume_device);
 
diff --git a/drivers/devfreq/governor_userspace.c b/drivers/devfreq/governor_userspace.c
index 8211aadb81f0..eb2b2c7af01f 100644
--- a/drivers/devfreq/governor_userspace.c
+++ b/drivers/devfreq/governor_userspace.c
@@ -27,7 +27,8 @@ static int devfreq_userspace_func(struct devfreq *df, unsigned long *freq)
 	if (data->valid)
 		*freq = data->user_frequency;
 	else
-		*freq = df->previous_freq; /* No user freq specified yet */
+		/* No user freq specified yet: keep the one from before suspend */
+		*freq = df->resume_freq ?: df->previous_freq;
 
 	return 0;
 }
diff --git a/include/linux/devfreq.h b/include/linux/devfreq.h
index dc1075dc3446..c53fdce5db14 100644
--- a/include/linux/devfreq.h
+++ b/include/linux/devfreq.h
@@ -166,7 +166,11 @@ struct devfreq_stats {
  * @stop_polling:	 devfreq polling status of a device.
  * @suspend_freq:	 frequency of a device set during suspend phase.
  * @resume_freq:	 frequency of a device set in resume phase.
- * @suspend_count:	 suspend requests counter for a device.
+ * @suspend_count:	 suspend requests counter for a device, protected by
+ *		 @lock. While it is positive, frequency updates are deferred
+ *		 until resume, except the passive governor's parent updates.
+ * @update_pending:	 a frequency update was deferred while suspended.
+ * @resume_failed:	 devfreq_resume_device() failed and left @suspend_count raised.
  * @stats:	Statistics of devfreq device behavior
  * @transition_notifier_list: list head of DEVFREQ_TRANSITION_NOTIFIER notifier
  * @cdev:	Cooling device pointer if the devfreq has cooling property
@@ -209,7 +213,9 @@ struct devfreq {
 
 	unsigned long suspend_freq;
 	unsigned long resume_freq;
-	atomic_t suspend_count;
+	int suspend_count;
+	bool update_pending;
+	bool resume_failed;
 
 	/* information for device frequency transitions */
 	struct devfreq_stats stats;

-- 
2.55.0

