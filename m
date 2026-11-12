From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:06:53 +0000
Subject: [PATCH] PM / devfreq: Do not change the frequency of a suspended
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-devfreq-suspend-sync-v1-1-af64603ef43e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/0WN2w6CMBBEf4X02SbbDW2BXzE89LLVmoDaAtEY/
 90CRt9mkplzXixTipRZV71YoiXmeB1LEYeKubMZT8SjL50hoBJCIPe0hER3nud8o9Hz/Bwd184
 0wUkhJRhWrrdEIT427LHfe57thdy0sr6LQpmLb9pnf11XfWXwk633gfiWqUYyZFVoQtMtYoVZk
 4m76zDEqatag4hKgm9JgwdALVBR7YO0AFZYaZVuTKtZ/35/AAf60MP/AAAA
X-Change-ID: 20261112-devfreq-suspend-sync-7ca8fc51550a
To: MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Steven Price <steven.price@arm.com>, Liviu Dudau <liviu.dudau@arm.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794470812; l=9265;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=sz4IHAsVIZYsbyOu7vGLOdfU1fixm3Q4YunFaWxkBUc=;
 b=dEIp4QPrEY6u/zn+ul1s1SnwIzq4SO8WsKH7FsNXztXT7CnHqu6Hu1NhNQudXDJ1tA49kbIHW
 wMCHAfImJNPA95df51Wft15W9Sa+fDTCrMZb6hKmmyFQnbFBoEnH/Jd
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Once a driver has called devfreq_suspend_device(), its device may be
clock gated or powered down, but devfreq can still call ->target() for
it: a PM QoS or sysfs min_freq/max_freq change, a devfreq cooling state
change, the userspace governor's set_freq, an OPP notifier or a change of
the passive governor's parent all end up in devfreq_update_target()
whatever the device state. DEVFREQ_GOV_SUSPEND only stops the load
monitoring of the governors that poll.

This is fatal where the clock is managed by firmware that has to access
the device's power domain to change the rate. On RK3588 with the GPU
core clock on SCMI_CLK_GPU, TF-A programs the GPU GRF to set the rate,
and with the GPU power domain off that ends in an asynchronous SError.

Drivers cannot filter these calls reliably in ->target(): the suspend
count changes without devfreq->lock, and devfreq_suspend_device() and
devfreq_resume_device() only take the lock around the suspend and resume
frequency changes, so an update can run between a driver's check and its
clocks going off, or be overwritten by the resume frequency. Returning 0
from ->target() without changing the rate makes devfreq record a
frequency the device does not run at, and returning an error loses the
request.

Track the suspended state under devfreq->lock. devfreq_suspend_device()
sets it in the critical section that applies the suspend frequency, and
devfreq_resume_device() clears it in the one that restores the resume
frequency. While it is set, devfreq_update_target() neither evaluates the
governor nor calls ->target(). It records that an update was asked for,
and devfreq_resume_device() runs that update instead of restoring the
resume frequency, which may lie outside limits set in the meantime. So
requests made while the device is suspended take effect on resume. If
the governor was removed in the meantime, it restores the resume
frequency as before.

Suggested-by: Boris Brezillon <boris.brezillon@collabora.com>
Link: https://lore.kernel.org/r/20261110140232.061d6844@fedora1.home
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
This comes from the review of a panthor patch [1] that kept devfreq from
changing the RK3588 GPU clock rate while the GPU is suspended by
filtering the calls in its ->target(). Boris Brezillon pointed out that a
driver cannot do that without races, and that the devfreq core should not
call ->target() between devfreq_suspend_device() and
devfreq_resume_device(). This patch does that in
devfreq_update_target(), which every governor and every core path (PM
QoS, sysfs, OPP notifier, passive parent) goes through, so no governor
needs a change.

It applies on top of "PM / devfreq: Resume at the frequency from before
suspend" [2], which changes the same lines of devfreq_suspend_device().
The panthor side, "drm/panthor: Suspend devfreq until the GPU is first
resumed" (dri-devel), pairs panthor's devfreq suspend and resume calls,
which this change relies on across a system suspend.

ufshcd already skips rate changes in its ->target() while its clock
scaling is suspended; with this patch devfreq stops calling it in that
state. No other driver was tested.

One change of behaviour to point out: a device on the passive governor no
longer follows its parent once it is suspended itself. devfreq_suspend()
walks the device list newest first, so it usually suspends a passive
device before its devfreq parent, and cpufreq_suspend() runs after
devfreq_suspend(). What the parent does after that, such as an
exynos-bus parent going to its suspend frequency, was followed by the
passive device so far and is now deferred until devfreq_resume(). I
have no such hardware to test on. If a passive device should keep
following its parent there, the passive governor's notifiers could be
exempted; please tell me if you want that.

Concurrent devfreq_suspend_device() and devfreq_resume_device() calls
for one device (a driver's runtime PM against devfreq_suspend() and
devfreq_resume()) are still only ordered by the atomic suspend count, as
before. This patch does not change that.

Tested on an Orange Pi 5 (RK3588S) running a v7.3-based kernel with
this patch, [2] and the panthor patch, with the GPU core clock on the
firmware-managed SCMI_CLK_GPU and a 200 MHz opp-suspend: min_freq,
max_freq, the userspace governor's set_freq and the devfreq cooling
state written while the GPU was runtime suspended, also right after a
suspend-to-idle cycle, no longer end in an SError and take effect on
the next GPU job; 200 runtime suspend/resume cycles with max_freq
toggling every ~35 ms and a 3 minute sustained load ran without an
SError or WARN.
The governor check in devfreq_resume_device() was added after these
runs; it only matters when the governor is removed while an update is
pending.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed it and tested
it as described above.

[1] https://lore.kernel.org/r/20261110-panthor-suspend-clk-v1-1-53457050e51e@gmail.com
[2] https://lore.kernel.org/r/20261110-devfreq-resume-freq-v1-1-90de450ccbd0@gmail.com
---
 drivers/devfreq/devfreq.c | 40 ++++++++++++++++++++++++++++++----------
 include/linux/devfreq.h   |  7 +++++++
 2 files changed, 37 insertions(+), 10 deletions(-)

diff --git a/drivers/devfreq/devfreq.c b/drivers/devfreq/devfreq.c
index 043cdc37bd0b..45588de327dd 100644
--- a/drivers/devfreq/devfreq.c
+++ b/drivers/devfreq/devfreq.c
@@ -408,6 +408,16 @@ int devfreq_update_target(struct devfreq *devfreq, unsigned long freq)
 	if (!devfreq->governor)
 		return -EINVAL;
 
+	/*
+	 * The device may be powered down while it is suspended. Leave it
+	 * alone, devfreq_resume_device() does the update.
+	 */
+	if (devfreq->suspended) {
+		devfreq->update_pending = true;
+		devfreq->pending_freq = freq;
+		return 0;
+	}
+
 	/* Reevaluate the proper frequency */
 	err = devfreq->governor->get_target_freq(devfreq, &freq);
 	if (err)
@@ -1162,8 +1172,11 @@ int devfreq_suspend_device(struct devfreq *devfreq)
 			return ret;
 	}
 
+	mutex_lock(&devfreq->lock);
+	devfreq->suspended = true;
+	devfreq->update_pending = false;
+	ret = 0;
 	if (devfreq->suspend_freq) {
-		mutex_lock(&devfreq->lock);
 		/*
 		 * devfreq_set_target() records the frequency it sets as the
 		 * one to resume at. Keep the frequency from before suspend
@@ -1173,12 +1186,10 @@ int devfreq_suspend_device(struct devfreq *devfreq)
 		resume_freq = devfreq->previous_freq;
 		ret = devfreq_set_target(devfreq, devfreq->suspend_freq, 0);
 		devfreq->resume_freq = resume_freq;
-		mutex_unlock(&devfreq->lock);
-		if (ret)
-			return ret;
 	}
+	mutex_unlock(&devfreq->lock);
 
-	return 0;
+	return ret;
 }
 EXPORT_SYMBOL(devfreq_suspend_device);
 
@@ -1200,13 +1211,22 @@ int devfreq_resume_device(struct devfreq *devfreq)
 	if (atomic_dec_return(&devfreq->suspend_count) >= 1)
 		return 0;
 
-	if (devfreq->resume_freq) {
-		mutex_lock(&devfreq->lock);
+	mutex_lock(&devfreq->lock);
+	devfreq->suspended = false;
+	ret = 0;
+	if (devfreq->update_pending && devfreq->governor) {
+		/*
+		 * Run the update deferred while suspended. It takes the
+		 * limits set meanwhile into account, unlike resume_freq.
+		 */
+		devfreq->update_pending = false;
+		ret = devfreq_update_target(devfreq, devfreq->pending_freq);
+	} else if (devfreq->resume_freq) {
 		ret = devfreq_set_target(devfreq, devfreq->resume_freq, 0);
-		mutex_unlock(&devfreq->lock);
-		if (ret)
-			return ret;
 	}
+	mutex_unlock(&devfreq->lock);
+	if (ret)
+		return ret;
 
 	if (devfreq->governor) {
 		ret = devfreq->governor->event_handler(devfreq,
diff --git a/include/linux/devfreq.h b/include/linux/devfreq.h
index dc1075dc3446..71b5193673f7 100644
--- a/include/linux/devfreq.h
+++ b/include/linux/devfreq.h
@@ -167,6 +167,10 @@ struct devfreq_stats {
  * @suspend_freq:	 frequency of a device set during suspend phase.
  * @resume_freq:	 frequency of a device set in resume phase.
  * @suspend_count:	 suspend requests counter for a device.
+ * @suspended:	 the device is suspended, frequency updates are deferred
+ *		 until it is resumed. Protected by @lock.
+ * @update_pending:	 a frequency update was deferred while suspended.
+ * @pending_freq:	 the frequency argument of the deferred update.
  * @stats:	Statistics of devfreq device behavior
  * @transition_notifier_list: list head of DEVFREQ_TRANSITION_NOTIFIER notifier
  * @cdev:	Cooling device pointer if the devfreq has cooling property
@@ -210,6 +214,9 @@ struct devfreq {
 	unsigned long suspend_freq;
 	unsigned long resume_freq;
 	atomic_t suspend_count;
+	bool suspended;
+	bool update_pending;
+	unsigned long pending_freq;
 
 	/* information for device frequency transitions */
 	struct devfreq_stats stats;

---
base-commit: 9a222650d9e70d0027126e4df5b00b1b5b678a97
change-id: 20261112-devfreq-suspend-sync-7ca8fc51550a
prerequisite-change-id: 20261110-devfreq-resume-freq-e42eaeb6f8f8:v1
prerequisite-patch-id: 36df3d7446ebdbd5093a58ba2aa8a83d2ecf9cf2

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

