From: Joonho Lee <mynameisjune111@gmail.com>
Date: Fri, 13 Nov 2026 15:42:04 +0900
Subject: [PATCH v32 20/20] ALSA: virtio: reset the device when PCM state
 stays unknown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-fix-virtio-snd-recovery-final-v32-20-4e95979e312c@gmail.com>
References: <20261113-fix-virtio-snd-recovery-final-v32-0-4e95979e312c@gmail.com>
In-Reply-To: <20261113-fix-virtio-snd-recovery-final-v32-0-4e95979e312c@gmail.com>
To: linux-sound@vger.kernel.org
Cc: tiwai@suse.com, perex@perex.cz, mst@redhat.com, 
 virtualization@lists.linux.dev, linux-kernel@vger.kernel.org, 
 corbet@lwn.net, skhan@linuxfoundation.org, rdunlap@infradead.org, 
 linux-doc@vger.kernel.org, Joonho Lee <mynameisjune111@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794552109; l=23724;
 i=mynameisjune111@gmail.com; s=default; h=from:subject:message-id;
 bh=P5cgF87TpSuKPf0f42/FN5Ir74YlM+SPZ8Nr6QS1Nec=;
 b=BnS/7ugKj1BHYcmA9p5QL2xE3EMxQiv8ujz05LW/FxtCAbRZlpEIvqJy2uY9wxi2Stf1L2/vp
 f3b7NWbnO01C8mIKoY9P2KE5Mv1AM26qemPicS4l3Vs5RdgBYav0j6P
X-Developer-Key: i=mynameisjune111@gmail.com; a=ed25519;
 pk=wqkZdvfcC8g8fDi6f0Y58LlaXIo+ubf6Y/9Lr9yhshc=
X-Endpoint-Received: by B4 Relay for mynameisjune111@gmail.com/default with auth_id=1508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some failures leave the driver unable to learn or reclaim a stream's
device state:

- a native control reply still missing after the settle wait
- an uncertain control result in the opt-in capture_pause_restart mode,
  which marks its stream reset-required
- released I/O requests that the device does not return

The stream then fails until the guest suspends and resumes or the driver
is rebound.

Recover with a device reset. A delayed work item checks whether any
stream is still in such a state. If one is, it moves the open streams to
SUSPENDED with snd_pcm_suspend_all(), so applications see -ESTRPIPE and
prepare again, then runs virtio_device_reset_prepare() and
virtio_device_reset_done(). The driver implements reset_prepare and
reset_done with its freeze and restore sequences, which also serves
transport-initiated resets.

A late control reply or an unreturned I/O flush schedules the check five
message timeouts later, one beyond the wait in sleepable operations. A
failed settle wait or an uncertain pause-restart result requests it
immediately. Sleepable operations stop waiting for late replies while
recovery suspends the streams. Applications prepare again as soon as
their stream is suspended, so hw_params and prepare wait until the reset
has finished instead of failing with -ECANCELED. open and hw_free do not
wait: they run under the PCM open mutex, which recovery takes to suspend
the streams. Resets of one device are at least 30 seconds apart. Remove
and freeze disable the work before tearing the device down.

If the transport reset fails, disconnect the ALSA card rather than leave
streams permanently resetting. Configuration waiters receive -ENODEV.
Publish that result and wake waiters before disconnecting, since ALSA
disconnect waits for their power references. Rebinding the driver is
required after this terminal failure.

With CONFIG_PM disabled, the common PCM suspend operation still changes
active streams to SUSPENDED before their queues are reset.

Assisted-by: LLM
Signed-off-by: Joonho Lee <mynameisjune111@gmail.com>
---
 Documentation/sound/alsa-configuration.rst |  12 ++
 sound/virtio/virtio_card.c                 | 222 ++++++++++++++++++++++++++---
 sound/virtio/virtio_card.h                 |  16 +++
 sound/virtio/virtio_pcm.h                  |   2 +
 sound/virtio/virtio_pcm_ops.c              | 113 +++++++++++----
 5 files changed, 320 insertions(+), 45 deletions(-)

diff --git a/Documentation/sound/alsa-configuration.rst b/Documentation/sound/alsa-configuration.rst
index df9c048fcb9b..8c765bb0e7e5 100644
--- a/Documentation/sound/alsa-configuration.rst
+++ b/Documentation/sound/alsa-configuration.rst
@@ -2568,6 +2568,18 @@ stream until the reply arrives. Trigger operations fail meanwhile; hw_params,
 hw_free and prepare wait up to four timeouts for the reply and continue from
 the device state it reports.
 
+If that reply has not arrived after five timeouts, or released I/O requests
+are not returned, the driver suspends the open streams and resets the device.
+Applications observe ``-ESTRPIPE`` and prepare their streams again; hw_params
+and prepare wait until the reset has finished. The driver resets a device at
+most once every 30 seconds.
+
+Stream suspension for recovery is available even without power-management
+support. If the reset fails, the ALSA card is disconnected. Existing PCM
+handles report ``-ENODEV`` and the sound devices are removed. Rebinding the
+driver is required to use the device again; the driver does not repeatedly
+reset a failed device.
+
 Module snd-virtuoso
 -------------------
 
diff --git a/sound/virtio/virtio_card.c b/sound/virtio/virtio_card.c
index 3f2242f27440..dd110fd7ad16 100644
--- a/sound/virtio/virtio_card.c
+++ b/sound/virtio/virtio_card.c
@@ -16,6 +16,7 @@ module_param_named(msg_timeout_ms, virtsnd_msg_timeout_ms, uint, 0644);
 MODULE_PARM_DESC(msg_timeout_ms, "Message completion timeout in milliseconds");
 
 static void virtsnd_remove(struct virtio_device *vdev);
+static void virtsnd_recover_work(struct work_struct *work);
 
 /**
  * virtsnd_event_send() - Add an event to the event queue.
@@ -333,6 +334,11 @@ static int virtsnd_probe(struct virtio_device *vdev)
 	snd->vdev = vdev;
 	INIT_LIST_HEAD(&snd->ctl_msgs);
 	INIT_LIST_HEAD(&snd->pcm_list);
+	INIT_DELAYED_WORK(&snd->recover_work, virtsnd_recover_work);
+	init_waitqueue_head(&snd->recover_wait);
+	/* Recovery needs the complete device; probe enables it last. */
+	disable_delayed_work(&snd->recover_work);
+	snd->recover_next = jiffies;
 
 	vdev->priv = snd;
 
@@ -350,6 +356,7 @@ static int virtsnd_probe(struct virtio_device *vdev)
 		goto on_exit;
 
 	virtsnd_enable_event_vq(snd);
+	enable_delayed_work(&snd->recover_work);
 
 on_exit:
 	if (rc)
@@ -383,6 +390,7 @@ static void virtsnd_reset_vqs(struct virtio_snd *snd)
 		vss->release_required = false;
 		vss->control_uncertain = false;
 		vss->control_late = 0;
+		vss->io_flush_failed = false;
 		vss->capture_reset_observing = false;
 		vss->xfer_enabled = false;
 		vss->suspended = true;
@@ -449,6 +457,7 @@ static void virtsnd_remove(struct virtio_device *vdev)
 	struct virtio_snd *snd = vdev->priv;
 	unsigned int i;
 
+	disable_delayed_work_sync(&snd->recover_work);
 	virtsnd_disable_event_vq(snd);
 
 	if (snd->card)
@@ -470,18 +479,14 @@ static void virtsnd_remove(struct virtio_device *vdev)
 	kfree(snd->event_msgs);
 }
 
-#ifdef CONFIG_PM_SLEEP
 /**
- * virtsnd_freeze() - Suspend device.
- * @vdev: VirtIO parent device.
+ * virtsnd_quiesce() - Stop device access and retire outstanding requests.
+ * @snd: VirtIO sound device.
  *
- * Context: Any context.
- * Return: 0 on success, -errno on failure.
+ * Context: Any context that permits to sleep.
  */
-static int virtsnd_freeze(struct virtio_device *vdev)
+static void virtsnd_quiesce(struct virtio_snd *snd)
 {
-	struct virtio_snd *snd = vdev->priv;
-
 	virtsnd_disable_event_vq(snd);
 	virtsnd_ctl_msg_cancel_all(snd);
 
@@ -492,22 +497,19 @@ static int virtsnd_freeze(struct virtio_device *vdev)
 
 	kfree(snd->event_msgs);
 	snd->event_msgs = NULL;
-
-	return 0;
 }
 
 /**
- * virtsnd_restore() - Resume device.
- * @vdev: VirtIO parent device.
+ * virtsnd_restart() - Reinitialize virtqueues after a device reset.
+ * @snd: VirtIO sound device.
  *
- * Context: Any context.
+ * Context: Any context that permits to sleep.
  * Return: 0 on success, -errno on failure.
  */
-static int virtsnd_restore(struct virtio_device *vdev)
+static int virtsnd_restart(struct virtio_snd *snd)
 {
-	struct virtio_snd *snd = vdev->priv;
-	int rc;
 	unsigned int i;
+	int rc;
 
 	rc = virtsnd_find_vqs(snd);
 	if (rc) {
@@ -515,7 +517,7 @@ static int virtsnd_restore(struct virtio_device *vdev)
 		return rc;
 	}
 
-	virtio_device_ready(vdev);
+	virtio_device_ready(snd->vdev);
 	virtsnd_ctl_msg_enable(snd);
 
 	for (i = 0; i < snd->nsubstreams; ++i) {
@@ -528,6 +530,190 @@ static int virtsnd_restore(struct virtio_device *vdev)
 
 	return 0;
 }
+
+/* Minimum time between recovery resets of one device. */
+#define VIRTSND_RECOVER_INTERVAL_MS	30000
+
+static bool virtsnd_recover_needed(struct virtio_snd *snd)
+{
+	unsigned int i;
+
+	for (i = 0; snd->substreams && i < snd->nsubstreams; ++i) {
+		struct virtio_pcm_substream *vss = &snd->substreams[i];
+
+		guard(spinlock_irqsave)(&vss->lock);
+		if (vss->resetting)
+			continue;
+		if (vss->control_uncertain ||
+		    vss->pause_restart_state ==
+		    VIRTSND_PCM_PAUSE_RESTART_RESET_REQUIRED ||
+		    (vss->io_flush_failed && vss->msg_count))
+			return true;
+	}
+
+	return false;
+}
+
+/**
+ * virtsnd_recover_work() - Reset the device when a PCM state stays unknown.
+ * @work: Recovery work of the sound device.
+ *
+ * A control reply or released I/O request that never returns leaves its PCM
+ * stream unusable. Suspend the open streams so applications prepare them
+ * again, then reset the device with the transport reset sequence.
+ *
+ * Context: Process context.
+ */
+static void virtsnd_recover_work(struct work_struct *work)
+{
+	struct virtio_snd *snd = container_of(to_delayed_work(work),
+					      struct virtio_snd, recover_work);
+	struct virtio_device *vdev = snd->vdev;
+	struct virtio_pcm *vpcm;
+	unsigned int i;
+	int rc;
+
+	if (!virtsnd_recover_needed(snd))
+		return;
+
+	if (time_before(jiffies, snd->recover_next)) {
+		queue_delayed_work(system_dfl_wq, &snd->recover_work,
+				   snd->recover_next - jiffies);
+		return;
+	}
+	snd->recover_next = jiffies +
+			    msecs_to_jiffies(VIRTSND_RECOVER_INTERVAL_MS);
+
+	dev_warn(&vdev->dev, "PCM device state is unknown; resetting device\n");
+
+	WRITE_ONCE(snd->recovering, true);
+	for (i = 0; i < snd->nsubstreams; ++i)
+		wake_up_all(&snd->substreams[i].control_wait);
+
+	/* Applications observe -ESTRPIPE and prepare their streams again. */
+	list_for_each_entry(vpcm, &snd->pcm_list, list)
+		snd_pcm_suspend_all(vpcm->pcm);
+
+	rc = virtio_device_reset_prepare(vdev);
+	if (!rc)
+		rc = virtio_device_reset_done(vdev);
+	WRITE_ONCE(snd->recover_failed, !!rc);
+	/* Publish the result before releasing configuration waiters. */
+	smp_store_release(&snd->recovering, false);
+	wake_up_all(&snd->recover_wait);
+
+	if (rc) {
+		/*
+		 * Wake configuration waiters before disconnect, which waits for
+		 * their ALSA power references to be released.
+		 */
+		dev_err(&vdev->dev, "device recovery reset failed: %d; disconnecting\n",
+			rc);
+		snd_card_disconnect(snd->card);
+	}
+}
+
+/**
+ * virtsnd_recover_wait() - Wait until a recovery reset has finished.
+ * @snd: VirtIO sound device.
+ *
+ * Applications prepare their streams again as soon as recovery suspends
+ * them. Configuring a stream must wait until the reset has completed.
+ *
+ * Context: Process context. The caller must not hold the PCM open mutex or
+ *          a substream lifecycle lock, which recovery takes.
+ * Return: 0, -ENODEV if recovery failed, or -ERESTARTSYS if killed.
+ */
+int virtsnd_recover_wait(struct virtio_snd *snd)
+{
+	int rc;
+
+	rc = wait_event_killable(snd->recover_wait,
+				 /* Pair with recovery's result publication. */
+				 !smp_load_acquire(&snd->recovering));
+	if (rc)
+		return rc;
+	return READ_ONCE(snd->recover_failed) ? -ENODEV : 0;
+}
+
+/**
+ * virtsnd_recover_schedule() - Request a recovery check.
+ * @snd: VirtIO sound device.
+ * @delay: Time before the check, in jiffies. Zero brings a pending check
+ *         forward.
+ *
+ * Context: Any context.
+ */
+void virtsnd_recover_schedule(struct virtio_snd *snd, unsigned long delay)
+{
+	if (delay)
+		queue_delayed_work(system_dfl_wq, &snd->recover_work, delay);
+	else
+		mod_delayed_work(system_dfl_wq, &snd->recover_work, 0);
+}
+
+/*
+ * Transport resets and driver recovery use the freeze and restore sequence.
+ * Recovery calls these callbacks from its own work item.
+ */
+static int virtsnd_reset_prepare(struct virtio_device *vdev)
+{
+	struct virtio_snd *snd = vdev->priv;
+
+	if (current_work() != &snd->recover_work.work)
+		disable_delayed_work_sync(&snd->recover_work);
+	virtsnd_quiesce(snd);
+
+	return 0;
+}
+
+static int virtsnd_reset_done(struct virtio_device *vdev)
+{
+	struct virtio_snd *snd = vdev->priv;
+	int rc;
+
+	rc = virtsnd_restart(snd);
+	if (current_work() != &snd->recover_work.work)
+		enable_delayed_work(&snd->recover_work);
+
+	return rc;
+}
+
+#ifdef CONFIG_PM_SLEEP
+/**
+ * virtsnd_freeze() - Suspend device.
+ * @vdev: VirtIO parent device.
+ *
+ * Context: Any context.
+ * Return: 0 on success, -errno on failure.
+ */
+static int virtsnd_freeze(struct virtio_device *vdev)
+{
+	struct virtio_snd *snd = vdev->priv;
+
+	disable_delayed_work_sync(&snd->recover_work);
+	virtsnd_quiesce(snd);
+
+	return 0;
+}
+
+/**
+ * virtsnd_restore() - Resume device.
+ * @vdev: VirtIO parent device.
+ *
+ * Context: Any context.
+ * Return: 0 on success, -errno on failure.
+ */
+static int virtsnd_restore(struct virtio_device *vdev)
+{
+	struct virtio_snd *snd = vdev->priv;
+	int rc;
+
+	rc = virtsnd_restart(snd);
+	enable_delayed_work(&snd->recover_work);
+
+	return rc;
+}
 #endif /* CONFIG_PM_SLEEP */
 
 static const struct virtio_device_id id_table[] = {
@@ -547,6 +733,8 @@ static struct virtio_driver virtsnd_driver = {
 	.validate = virtsnd_validate,
 	.probe = virtsnd_probe,
 	.remove = virtsnd_remove,
+	.reset_prepare = virtsnd_reset_prepare,
+	.reset_done = virtsnd_reset_done,
 #ifdef CONFIG_PM_SLEEP
 	.freeze = virtsnd_freeze,
 	.restore = virtsnd_restore,
diff --git a/sound/virtio/virtio_card.h b/sound/virtio/virtio_card.h
index a733fa684c86..7b17e6c8a594 100644
--- a/sound/virtio/virtio_card.h
+++ b/sound/virtio/virtio_card.h
@@ -8,6 +8,7 @@
 
 #include <linux/slab.h>
 #include <linux/virtio.h>
+#include <linux/workqueue.h>
 #include <sound/core.h>
 #include <uapi/linux/virtio_snd.h>
 
@@ -61,6 +62,12 @@ struct virtio_kctl {
  * @kctl_infos: VirtIO control element information.
  * @kctls: VirtIO control elements.
  * @nkctls: Number of control elements.
+ * @recover_work: Resets the device when a PCM stream state stays unknown.
+ * @recover_next: Earliest time of the next recovery reset, in jiffies.
+ * @recovering: Recovery is suspending streams; sleepable PCM operations do
+ *              not wait for late control replies meanwhile.
+ * @recover_wait: Notify when recovery finishes.
+ * @recover_failed: Recovery failed; PCM configuration must return -ENODEV.
  */
 struct virtio_snd {
 	struct virtio_device *vdev;
@@ -81,11 +88,20 @@ struct virtio_snd {
 	struct virtio_snd_ctl_info *kctl_infos;
 	struct virtio_kctl *kctls;
 	u32 nkctls;
+	struct delayed_work recover_work;
+	unsigned long recover_next;
+	bool recovering;
+	bool recover_failed;
+	wait_queue_head_t recover_wait;
 };
 
 /* Message completion timeout in milliseconds (module parameter). */
 extern u32 virtsnd_msg_timeout_ms;
 
+void virtsnd_recover_schedule(struct virtio_snd *snd, unsigned long delay);
+
+int virtsnd_recover_wait(struct virtio_snd *snd);
+
 static inline struct virtio_snd_queue *
 virtsnd_control_queue(struct virtio_snd *snd)
 {
diff --git a/sound/virtio/virtio_pcm.h b/sound/virtio/virtio_pcm.h
index 4ead0d94af63..33d44fab08fa 100644
--- a/sound/virtio/virtio_pcm.h
+++ b/sound/virtio/virtio_pcm.h
@@ -85,6 +85,7 @@ enum virtio_pcm_pause_restart_state {
  *                     PCM control request is sent until it is.
  * @control_late: Timed-out native control requests still owned by the device.
  *                Their replies settle the device state.
+ * @io_flush_failed: Released I/O requests were not returned in time.
  * @capture_reset_observing: Reclaim staged samples during RESET pointer capture.
  * @indirect_reset_observing: Suppress ordinary ACK refill during RESET pointer
  *                            capture; protected by the PCM stream lock.
@@ -147,6 +148,7 @@ struct virtio_pcm_substream {
 	bool release_required;
 	bool control_uncertain;
 	unsigned int control_late;
+	bool io_flush_failed;
 	bool capture_reset_observing;
 	bool indirect_reset_observing;
 	bool playback_pointer_active;
diff --git a/sound/virtio/virtio_pcm_ops.c b/sound/virtio/virtio_pcm_ops.c
index 15d4473f4c0a..dcce428d704c 100644
--- a/sound/virtio/virtio_pcm_ops.c
+++ b/sound/virtio/virtio_pcm_ops.c
@@ -157,6 +157,35 @@ static bool virtsnd_pcm_pause_restart_transitioning(enum virtio_pcm_pause_restar
 	}
 }
 
+/* Sleepable operations wait this many message timeouts for a late reply. */
+#define VIRTSND_PCM_SETTLE_TIMEOUTS	4
+
+static unsigned long virtsnd_pcm_timeouts_jiffies(unsigned int count)
+{
+	u64 ms = (u64)virtsnd_msg_timeout_ms * count;
+
+	return msecs_to_jiffies(min_t(u64, ms, UINT_MAX));
+}
+
+static unsigned long virtsnd_pcm_settle_jiffies(void)
+{
+	return virtsnd_pcm_timeouts_jiffies(VIRTSND_PCM_SETTLE_TIMEOUTS);
+}
+
+/* Recovery starts after a waiting operation would have given up. */
+static unsigned long virtsnd_pcm_recover_jiffies(void)
+{
+	return virtsnd_pcm_timeouts_jiffies(VIRTSND_PCM_SETTLE_TIMEOUTS + 1);
+}
+
+/* A released I/O request that is not returned keeps its DMA buffer busy. */
+static void virtsnd_pcm_flush_failed(struct virtio_pcm_substream *vss)
+{
+	scoped_guard(spinlock_irqsave, &vss->lock)
+		vss->io_flush_failed = true;
+	virtsnd_recover_schedule(vss->snd, virtsnd_pcm_recover_jiffies());
+}
+
 /**
  * virtsnd_pcm_ctl_defer_locked() - Record a native control request whose
  *                                  sender timed out.
@@ -256,36 +285,37 @@ static int virtsnd_pcm_send_sync(struct virtio_pcm_substream *vss,
 		if (rc && uncertain)
 			vss->control_uncertain = true;
 	}
-	if (deferred)
+	if (deferred) {
 		dev_warn_ratelimited(&vss->snd->vdev->dev,
 				     "SID %u: PCM control 0x%08x reply is late; holding PCM commands\n",
 				     vss->sid, command);
+		/* Reset the device if the reply has not arrived by then. */
+		virtsnd_recover_schedule(vss->snd, virtsnd_pcm_recover_jiffies());
+	}
 	return rc;
 }
 
-/* Sleepable operations wait this many message timeouts for a late reply. */
-#define VIRTSND_PCM_SETTLE_TIMEOUTS	4
-
-static unsigned long virtsnd_pcm_settle_jiffies(void)
-{
-	u64 ms = (u64)virtsnd_msg_timeout_ms * VIRTSND_PCM_SETTLE_TIMEOUTS;
-
-	return msecs_to_jiffies(min_t(u64, ms, UINT_MAX));
-}
-
 static bool virtsnd_pcm_control_settled(struct virtio_pcm_substream *vss)
 {
 	guard(spinlock_irqsave)(&vss->lock);
 	return vss->resetting || !vss->control_uncertain;
 }
 
+static bool virtsnd_pcm_control_wait_done(struct virtio_pcm_substream *vss)
+{
+	return READ_ONCE(vss->snd->recovering) ||
+	       virtsnd_pcm_control_settled(vss);
+}
+
 /**
  * virtsnd_pcm_control_settle() - Wait for a late native control reply.
  * @vss: VirtIO PCM substream.
  *
  * Trigger fails while a native control result is unknown. Sleepable
  * operations wait a bounded time for the reply, then continue from the
- * device state it reports.
+ * device state it reports. If the reply does not arrive, device recovery
+ * resets the stream state. Recovery itself suspends the streams, so these
+ * operations do not wait while it runs.
  *
  * Context: Process context with @vss->lifecycle_lock held.
  * Return: 0 if the state is known or a device reset is in progress, -EIO if
@@ -298,18 +328,23 @@ static int virtsnd_pcm_control_settle(struct virtio_pcm_substream *vss)
 	lockdep_assert_held(&vss->lifecycle_lock);
 	if (virtsnd_pcm_control_settled(vss))
 		return 0;
+	if (READ_ONCE(vss->snd->recovering))
+		return -EIO;
 
 	rc = wait_event_killable_timeout(vss->control_wait,
-					 virtsnd_pcm_control_settled(vss),
+					 virtsnd_pcm_control_wait_done(vss),
 					 virtsnd_pcm_settle_jiffies());
 	if (rc < 0)
 		return rc;
 	if (virtsnd_pcm_control_settled(vss))
 		return 0;
+	if (READ_ONCE(vss->snd->recovering))
+		return -EIO;
 
 	dev_err_ratelimited(&vss->snd->vdev->dev,
-			    "SID %u: PCM control reply is still outstanding\n",
+			    "SID %u: PCM control reply is still outstanding; resetting device\n",
 			    vss->sid);
+	virtsnd_recover_schedule(vss->snd, 0);
 	return -EIO;
 }
 
@@ -370,10 +405,12 @@ virtsnd_pcm_pause_restart_send(struct virtio_pcm_substream *vss,
 		}
 	}
 
-	if (rc && uncertain)
+	if (rc && uncertain) {
 		dev_err(&vss->snd->vdev->dev,
-			"SID %u: PCM control state is unknown; device reprobe required\n",
+			"SID %u: PCM control state is unknown; resetting device\n",
 			vss->sid);
+		virtsnd_recover_schedule(vss->snd, 0);
+	}
 
 	return rc;
 }
@@ -395,6 +432,8 @@ virtsnd_pcm_pause_restart_fail(struct virtio_pcm_substream *vss,
 			vss->pause_restart_state =
 				VIRTSND_PCM_PAUSE_RESTART_RESET_REQUIRED;
 	}
+	if (reset_required)
+		virtsnd_recover_schedule(vss->snd, 0);
 	if (notify_xrun)
 		virtsnd_pcm_schedule_period_elapsed(vss);
 	vss->substream->runtime->stop_operating = true;
@@ -440,16 +479,22 @@ static int virtsnd_pcm_release_wait(struct virtio_pcm_substream *vss, u64 epoch)
 
 	waited = wait_event_timeout(vss->msg_empty,
 				   !virtsnd_pcm_msg_pending_num(vss), js);
-	guard(spinlock_irqsave)(&vss->lock);
-	if (vss->resetting || vss->reset_epoch != epoch)
-		return -ECANCELED;
-	if (!waited || vss->msg_count ||
-	    vss->pause_restart_state != VIRTSND_PCM_PAUSE_RESTART_RELEASE_SENT)
-		return -ETIMEDOUT;
-	vss->prepared = false;
-	vss->release_required = false;
-	vss->pause_restart_state = VIRTSND_PCM_PAUSE_RESTART_RELEASED;
-	return 0;
+	scoped_guard(spinlock_irqsave, &vss->lock) {
+		if (vss->resetting || vss->reset_epoch != epoch)
+			return -ECANCELED;
+		if (vss->pause_restart_state !=
+		    VIRTSND_PCM_PAUSE_RESTART_RELEASE_SENT)
+			return -ETIMEDOUT;
+		if (waited && !vss->msg_count) {
+			vss->prepared = false;
+			vss->release_required = false;
+			vss->pause_restart_state =
+				VIRTSND_PCM_PAUSE_RESTART_RELEASED;
+			return 0;
+		}
+	}
+	virtsnd_pcm_flush_failed(vss);
+	return -ETIMEDOUT;
 }
 
 static int
@@ -661,6 +706,9 @@ static int virtsnd_pcm_hw_params(struct snd_pcm_substream *substream,
 	u64 epoch;
 	int rc;
 
+	rc = virtsnd_recover_wait(vss->snd);
+	if (rc)
+		return rc;
 	guard(mutex)(&vss->lifecycle_lock);
 	/* Fixed descriptors require whole-byte periods covering the buffer. */
 	if (check_mul_overflow((size_t)params_periods(hw_params),
@@ -922,6 +970,7 @@ static int virtsnd_pcm_prepare_locked(struct snd_pcm_substream *substream)
 		vss->prepared = true;
 		vss->stopped = false;
 		vss->xfer_xrun = false;
+		vss->io_flush_failed = false;
 	}
 
 	return rc;
@@ -933,6 +982,10 @@ static int virtsnd_pcm_prepare(struct snd_pcm_substream *substream)
 
 	int rc;
 
+	/* Applications prepare again as soon as recovery suspends the stream. */
+	rc = virtsnd_recover_wait(vss->snd);
+	if (rc)
+		return rc;
 	guard(mutex)(&vss->lifecycle_lock);
 	rc = virtsnd_pcm_prepare_locked(substream);
 	if (!rc && vss->period_work_quiesced) {
@@ -1508,7 +1561,7 @@ virtsnd_pcm_pause_restart_sync_stop(struct snd_pcm_substream *substream)
 	    virtsnd_pcm_pause_restart_transitioning(state)) {
 		virtsnd_pcm_pause_restart_fail(vss, true, epoch);
 		dev_err(&vss->snd->vdev->dev,
-			"SID %u: PCM state is unknown; device reprobe required\n",
+			"SID %u: PCM state is unknown; resetting device\n",
 			vss->sid);
 		return -EIO;
 	}
@@ -1554,6 +1607,7 @@ virtsnd_pcm_pause_restart_sync_stop(struct snd_pcm_substream *substream)
 					    !virtsnd_pcm_msg_pending_num(vss), js);
 		if (waited <= 0) {
 			rc = waited ? (int)waited : -ETIMEDOUT;
+			virtsnd_pcm_flush_failed(vss);
 			virtsnd_pcm_pause_restart_fail(vss, false, epoch);
 			return rc;
 		}
@@ -1571,8 +1625,10 @@ virtsnd_pcm_pause_restart_sync_stop(struct snd_pcm_substream *substream)
 				rc = 0;
 			}
 		}
-		if (rc)
+		if (rc) {
+			virtsnd_pcm_flush_failed(vss);
 			virtsnd_pcm_pause_restart_fail(vss, false, epoch);
+		}
 		return rc;
 	}
 
@@ -1689,6 +1745,7 @@ static int virtsnd_pcm_release_locked(struct snd_pcm_substream *substream)
 		dev_warn(&snd->vdev->dev, "SID %u: failed to flush I/O queue\n",
 			 vss->sid);
 		substream->runtime->stop_operating = true;
+		virtsnd_pcm_flush_failed(vss);
 
 		return waited ? (int)waited : -ETIMEDOUT;
 	}

-- 
Git-157)

