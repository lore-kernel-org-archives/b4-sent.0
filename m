From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 08:06:49 +0000
Subject: [PATCH v2] PM / devfreq: Do not change the frequency of a
 suspended device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-devfreq-suspend-sync-v2-1-10f0c3e14245@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32Py27DIBBFf8ViXSpeJuBV/6PKYsBDQlXbCdhWo
 8j/XrCrdtfdXGnmnLlPkjFFzKRrniThGnOcxhLES0P8FcYL0tiXTAQTmnMuaI9rSHineck3HHu
 aH6OnJw8m+Ja3LQNSTm8JQ/zase/nI+fFfaCfK+tno1CW4puPtT9dsR8y9iur5wPSfUYlENDpY
 ILpVl5hDjJSPw1DnLvGWWvBKxTKMGdPICXXrbKCO3AcjBcOpRPBkvrYNeZ5So+9fmHVP/5vunL
 KKQStNJMYlMS3ywDx87XYyXnbtm+YzRYhUQEAAA==
X-Change-ID: 20261112-devfreq-suspend-sync-7ca8fc51550a
To: MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Steven Price <steven.price@arm.com>, Liviu Dudau <liviu.dudau@arm.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794643608; l=11733;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=EI0y+BLKPjFBcDmDzlalQtLpyEYoapfaSTFvZTtOijc=;
 b=L9zhbsmchZoQhWkJundFa8kMK4Nzl3fxYpvXIh1errmPjcA2/itK/yJcSmIQfyz/T9Vva/5YH
 q7CFAmTs1Z9BC1dlpq1XzbsPZuNwGWONC7yhkIqMn2m3g4s7y/ggtXX
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Once a driver has called devfreq_suspend_device(), its device may be
clock gated or powered down, but devfreq can still call ->target() for
it: a PM QoS or sysfs min_freq/max_freq change, a devfreq cooling state
change, the userspace governor's set_freq, an OPP notifier or a change
of the passive governor's parent all end up in devfreq_update_target()
whatever the device state. DEVFREQ_GOV_SUSPEND only stops the load
monitoring of the governors that poll.

This is fatal where the clock is managed by firmware that has to access
the device's power domain to change the rate. On RK3588 with the GPU
core clock moved to SCMI_CLK_GPU (not in mainline yet), TF-A programs
the GPU GRF to set the rate, and with the GPU power domain off that
ends in an asynchronous SError.

Drivers cannot filter these calls reliably in ->target(): the suspend
count changes without devfreq->lock, and devfreq_suspend_device() and
devfreq_resume_device() only take the lock around the suspend and resume
frequency changes, so an update can run between a driver's check and its
clocks going off, or be overwritten by the resume frequency. Returning 0
from ->target() without changing the rate makes devfreq record a
frequency the device does not run at, and returning an error loses the
request.

Change the suspend count under devfreq->lock. While it is positive,
devfreq_update_target() neither evaluates the governor nor calls
->target(), it only records that an update was asked for.
devfreq_resume_device() restores the resume frequency, or the current one
if an update is pending, within the current limits, then runs that update,
so requests made while the device is suspended take effect on resume.
Polling governors are left to their next poll, as the driver has just
reset their load data.

The passive governor's parent updates are not deferred: exynos-bus
devices must follow their parent to its suspend frequency, also at
shutdown (exynos_bus_shutdown()).

If devfreq_suspend_device() fails, it resumes the device again, as some
callers abort their suspend without resuming, and a later
devfreq_resume_device() does nothing. A caller that ignores the error
and powers the device down anyway does so with devfreq resumed. If the
deferred update fails on resume, the error is logged and
DEVFREQ_GOV_RESUME is still sent.

Suggested-by: Boris Brezillon <boris.brezillon@collabora.com>
Link: https://lore.kernel.org/r/20261110140232.061d6844@fedora1.home
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
This comes from the review of a panthor patch [1] that kept devfreq from
changing the RK3588 GPU clock rate while the GPU is suspended by
filtering the calls in its ->target(). Boris Brezillon pointed out that
a driver cannot do that without races, and that the devfreq core should
not call ->target() between devfreq_suspend_device() and
devfreq_resume_device(). This patch does that in
devfreq_update_target(), which every governor and every core path (PM
QoS, sysfs, OPP notifier) goes through, so no governor needs a change.

It applies on top of "PM / devfreq: Resume at the frequency from before
suspend" [2], which changes the same lines of devfreq_suspend_device().
The panthor side, "drm/panthor: Suspend devfreq until the GPU is first
resumed" [3], suspends devfreq from probe until the GPU is first
resumed; without it updates are not deferred during that time.

ufshcd already skips rate changes in its ->target() while its clock
scaling is suspended; with this patch devfreq stops calling it in that
state. No other driver was tested.

Tested on an Orange Pi 5 (RK3588S) running a v7.3-based kernel with [2]
and the panthor patch, GPU core clock on the firmware-managed
SCMI_CLK_GPU with a 200 MHz opp-suspend (the configuration of Jonas
Karlman's RFC, not in mainline): min_freq, max_freq, the userspace
governor's set_freq and the cooling state written while the GPU was
runtime suspended no longer end in an SError and take effect when it
resumes; the userspace governor without a set_freq resumes within the
new limits. After each of two s2idle cycles the GPU was still suspended
at 200 MHz; a trace after the first showed no devfreq polling. A
minimum frequency removed while suspended (a pending update) is left to
simple_ondemand after resume: the first ten samples were all above
1 GHz under load. 200 GPU jobs ran with no warnings.
Not tested: the resume of a passive governor device (the board has
none) and a suspend frequency that cannot be set.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

[1] https://lore.kernel.org/r/20261110-panthor-suspend-clk-v1-1-53457050e51e@gmail.com
[2] https://lore.kernel.org/r/20261110-devfreq-resume-freq-v1-1-90de450ccbd0@gmail.com
[3] https://lore.kernel.org/r/20261112-panthor-suspend-clk-v2-1-62e1b168052d@gmail.com
---
Changes in v2:
- Keep only the suspend count, now a plain int changed under
  devfreq->lock, instead of a separate suspended flag that could
  disagree with it when suspend and resume race (Sashiko)
- Resume at the resume frequency clamped to the current limits, then
  run the deferred update: the userspace governor without set_freq
  stayed at the suspend frequency (Sashiko)
- Don't defer the passive governor's parent updates: exynos-bus
  children must follow their parent to its suspend frequency, also at
  shutdown (Sashiko)
- Drop pending_freq: the deferred update runs like any update_devfreq()
  call. If it fails, resume logs the error and still sends
  DEVFREQ_GOV_RESUME (Sashiko)
- Undo a failed devfreq_suspend_device(), as rk3399_dmc and lima abort
  without resuming; an unbalanced devfreq_resume_device() is a no-op
  (Sashiko)
- Leave polling governors to their next poll after resume; the driver
  has just reset their load data (Sashiko)
- Link to v1: https://patch.msgid.link/20261112-devfreq-suspend-sync-v1-1-af64603ef43e@gmail.com
---
 drivers/devfreq/devfreq.c | 74 ++++++++++++++++++++++++++++++++++++-----------
 include/linux/devfreq.h   |  8 +++--
 2 files changed, 63 insertions(+), 19 deletions(-)

diff --git a/drivers/devfreq/devfreq.c b/drivers/devfreq/devfreq.c
index 2cc4492f53c8..64fc88cdf6a2 100644
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
@@ -1145,19 +1155,22 @@ EXPORT_SYMBOL(devm_devfreq_remove_device);
 int devfreq_suspend_device(struct devfreq *devfreq)
 {
 	unsigned long resume_freq;
-	int ret;
+	int ret, count;
 
 	if (!devfreq)
 		return -EINVAL;
 
-	if (atomic_inc_return(&devfreq->suspend_count) > 1)
+	mutex_lock(&devfreq->lock);
+	count = ++devfreq->suspend_count;
+	mutex_unlock(&devfreq->lock);
+	if (count > 1)
 		return 0;
 
 	if (devfreq->governor) {
 		ret = devfreq->governor->event_handler(devfreq,
 					DEVFREQ_GOV_SUSPEND, NULL);
 		if (ret)
-			return ret;
+			goto err;
 	}
 
 	if (devfreq->suspend_freq) {
@@ -1173,10 +1186,15 @@ int devfreq_suspend_device(struct devfreq *devfreq)
 		devfreq->resume_freq = resume_freq;
 		mutex_unlock(&devfreq->lock);
 		if (ret)
-			return ret;
+			goto err;
 	}
 
 	return 0;
+
+err:
+	/* Callers may abort their suspend without resuming: undo it */
+	devfreq_resume_device(devfreq);
+	return ret;
 }
 EXPORT_SYMBOL(devfreq_suspend_device);
 
@@ -1190,30 +1208,52 @@ EXPORT_SYMBOL(devfreq_suspend_device);
  */
 int devfreq_resume_device(struct devfreq *devfreq)
 {
-	int ret;
+	unsigned long min_freq, max_freq, freq;
+	int ret = 0, err;
+	u32 flags;
 
 	if (!devfreq)
 		return -EINVAL;
 
-	if (atomic_dec_return(&devfreq->suspend_count) >= 1)
+	mutex_lock(&devfreq->lock);
+	/* Count 0: a failed devfreq_suspend_device() already resumed */
+	if (!devfreq->suspend_count || --devfreq->suspend_count > 0) {
+		mutex_unlock(&devfreq->lock);
 		return 0;
+	}
 
-	if (devfreq->resume_freq) {
-		mutex_lock(&devfreq->lock);
-		ret = devfreq_set_target(devfreq, devfreq->resume_freq, 0);
-		mutex_unlock(&devfreq->lock);
-		if (ret)
-			return ret;
+	freq = devfreq->resume_freq;
+	if (!freq && devfreq->update_pending)
+		freq = devfreq->previous_freq;
+	if (freq) {
+		/* Limits may have changed while suspended */
+		devfreq_get_freq_range(devfreq, &min_freq, &max_freq);
+		freq = clamp(freq, min_freq, max_freq);
+		flags = freq == max_freq ? DEVFREQ_FLAG_LEAST_UPPER_BOUND : 0;
+		ret = devfreq_set_target(devfreq, freq, flags);
+	}
+	/*
+	 * Run the update deferred while suspended. Polling governors
+	 * re-evaluate after DEVFREQ_GOV_RESUME, on fresh load data.
+	 */
+	if (!ret && devfreq->update_pending && devfreq->governor &&
+	    !IS_SUPPORTED_ATTR(devfreq->governor->attrs, POLLING_INTERVAL)) {
+		err = devfreq_update_target(devfreq, 0);
+		if (err)
+			dev_err(&devfreq->dev,
+				"failed to update frequency on resume (%d)\n", err);
 	}
+	devfreq->update_pending = false;
+	mutex_unlock(&devfreq->lock);
 
 	if (devfreq->governor) {
-		ret = devfreq->governor->event_handler(devfreq,
+		err = devfreq->governor->event_handler(devfreq,
 					DEVFREQ_GOV_RESUME, NULL);
-		if (ret)
-			return ret;
+		if (!ret)
+			ret = err;
 	}
 
-	return 0;
+	return ret;
 }
 EXPORT_SYMBOL(devfreq_resume_device);
 
diff --git a/include/linux/devfreq.h b/include/linux/devfreq.h
index dc1075dc3446..a1bd70449e1e 100644
--- a/include/linux/devfreq.h
+++ b/include/linux/devfreq.h
@@ -166,7 +166,10 @@ struct devfreq_stats {
  * @stop_polling:	 devfreq polling status of a device.
  * @suspend_freq:	 frequency of a device set during suspend phase.
  * @resume_freq:	 frequency of a device set in resume phase.
- * @suspend_count:	 suspend requests counter for a device.
+ * @suspend_count:	 suspend requests counter for a device, protected by
+ *		 @lock. While it is positive, frequency updates are deferred
+ *		 until resume, except the passive governor's parent updates.
+ * @update_pending:	 a frequency update was deferred while suspended.
  * @stats:	Statistics of devfreq device behavior
  * @transition_notifier_list: list head of DEVFREQ_TRANSITION_NOTIFIER notifier
  * @cdev:	Cooling device pointer if the devfreq has cooling property
@@ -209,7 +212,8 @@ struct devfreq {
 
 	unsigned long suspend_freq;
 	unsigned long resume_freq;
-	atomic_t suspend_count;
+	int suspend_count;
+	bool update_pending;
 
 	/* information for device frequency transitions */
 	struct devfreq_stats stats;

---
base-commit: b999ac4e2480b97a331654921bab1a8c2be3b2f9
change-id: 20261112-devfreq-suspend-sync-7ca8fc51550a
prerequisite-change-id: 20261110-devfreq-resume-freq-e42eaeb6f8f8:v1
prerequisite-patch-id: 36df3d7446ebdbd5093a58ba2aa8a83d2ecf9cf2

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

