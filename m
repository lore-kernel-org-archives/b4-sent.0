From: Joonho Lee <mynameisjune111@gmail.com>
Date: Fri, 13 Nov 2026 18:21:42 +0900
Subject: [PATCH v33 18/18] ALSA: virtio: settle PCM control state from late
 replies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-fix-virtio-snd-recovery-final-v33-18-13a934ad5ece@gmail.com>
References: <20261113-fix-virtio-snd-recovery-final-v33-0-13a934ad5ece@gmail.com>
In-Reply-To: <20261113-fix-virtio-snd-recovery-final-v33-0-13a934ad5ece@gmail.com>
To: linux-sound@vger.kernel.org, 
 Anton Yakovlev <anton.yakovlev@opensynergy.com>, 
 Matias Ezequiel Vara Larsen <mvaralar@redhat.com>
Cc: tiwai@suse.com, perex@perex.cz, mst@redhat.com, 
 virtualization@lists.linux.dev, linux-kernel@vger.kernel.org, 
 corbet@lwn.net, skhan@linuxfoundation.org, rdunlap@infradead.org, 
 linux-doc@vger.kernel.org, Takashi Iwai <tiwai@suse.de>, 
 Joonho Lee <mynameisjune111@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794561688; l=24244;
 i=mynameisjune111@gmail.com; s=default; h=from:subject:message-id;
 bh=wc8u23eSkMCDkXX4gxJLP5ms6FYX7RIBossnhoYJFak=;
 b=gVi7lS1+ugBBr0VVVDyU6aErdGE9X9BVKZ1ldMKE3zofQ1p/OXbKwmMC4Lgw2Esgx/a1kXz/O
 LeaV/QYgp1FB3+t4QmUxrpbCSjj+5HZKRFiVtZCgMioyHd0xqu/nDvi
X-Developer-Key: i=mynameisjune111@gmail.com; a=ed25519;
 pk=wqkZdvfcC8g8fDi6f0Y58LlaXIo+ubf6Y/9Lr9yhshc=
X-Endpoint-Received: by B4 Relay for mynameisjune111@gmail.com/default with auth_id=1508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A native PCM control request that times out remains owned by the device.
The driver therefore stops sending PCM control requests for the stream
until the device state is known. Only a device reset cleared that state,
and a reset happens only on remove or freeze. One reply arriving after
msg_timeout_ms left open, hw_params, prepare and trigger returning -EIO
until the driver was rebound or the guest resumed from suspend.

Keep the ordering guarantee, but let the reply resolve it. After a
synchronous wait times out, decide under the control queue lock whether
the reply has already completed. If not, mark the request late and count
it on the substream. When the device completes the request, apply its
result to the native device state and clear the unknown state once no
late request remains:

- PREPARE: success requires a later RELEASE
- START: success leaves the device running
- STOP: success stops the device
- RELEASE: success releases the stream
- an error reply leaves the state unchanged

Trigger still fails while the state is unknown, so it does not hold the
PCM stream lock any longer. The first uncertain request starts a shared
four-timeout wait window. hw_params, hw_free, prepare and open consume
the remaining time and continue from the reported state if a reply
arrives. When the window expires, the callback returns an error. A
later reply can still settle the state; if no reply ever arrives,
the driver must be rebound or the device reset. The opt-in
capture_pause_restart mode keeps its reset-required state.

Log when a reply is late, when it settles, and when it remains
outstanding after the wait.

Prepare and sync_stop close transfer admission and quiesce period work
before waiting. On failure they preserve stop_operating and leave the
stream closed. Prepare samples teardown state again after the late reply
settles. Failed native PAUSE rollback checks device_running under the
queue and stream locks before restoring capture_stopping and
capture_quiet_sequence.

Assisted-by: LLM
Signed-off-by: Joonho Lee <mynameisjune111@gmail.com>
---
 Documentation/sound/alsa-configuration.rst |  11 ++
 sound/virtio/virtio_card.c                 |   3 +
 sound/virtio/virtio_ctl_msg.c              |  87 +++++++---
 sound/virtio/virtio_ctl_msg.h              |   2 +
 sound/virtio/virtio_pcm.c                  |   1 +
 sound/virtio/virtio_pcm.h                  |  16 +-
 sound/virtio/virtio_pcm_ops.c              | 251 ++++++++++++++++++++++++++---
 7 files changed, 328 insertions(+), 43 deletions(-)

diff --git a/Documentation/sound/alsa-configuration.rst b/Documentation/sound/alsa-configuration.rst
index 0531a3e3129c..eeb92f059691 100644
--- a/Documentation/sound/alsa-configuration.rst
+++ b/Documentation/sound/alsa-configuration.rst
@@ -2562,6 +2562,17 @@ ALSA ring size, especially with small periods. The request buffers remain
 allocated from hw_params until hw_free.
 Captured audio is copied from each request buffer into the ALSA ring.
 
+A PCM control request that is not answered within ``msg_timeout_ms`` remains
+owned by the device. The driver sends no further PCM control request for that
+stream until the reply arrives. Trigger operations fail meanwhile. A timed-out
+request gets one additional wait window of four ``msg_timeout_ms`` intervals.
+The hw_params, hw_free and prepare callbacks share the remaining time in this
+window; repeated callbacks do not restart it. If the reply arrives, operations
+continue from the device state it reports.
+
+If the reply never arrives, the stream remains unavailable until the driver
+is rebound. The driver does not automatically reset the device.
+
 Module snd-virtuoso
 -------------------
 
diff --git a/sound/virtio/virtio_card.c b/sound/virtio/virtio_card.c
index 336da9a5b8fe..3f2242f27440 100644
--- a/sound/virtio/virtio_card.c
+++ b/sound/virtio/virtio_card.c
@@ -382,9 +382,12 @@ static void virtsnd_reset_vqs(struct virtio_snd *snd)
 		vss->device_running = false;
 		vss->release_required = false;
 		vss->control_uncertain = false;
+		vss->control_late = 0;
 		vss->capture_reset_observing = false;
 		vss->xfer_enabled = false;
 		vss->suspended = true;
+		/* Waiters observe resetting and return instead of timing out. */
+		wake_up_all(&vss->control_wait);
 	}
 	virtio_reset_device(vdev);
 
diff --git a/sound/virtio/virtio_ctl_msg.c b/sound/virtio/virtio_ctl_msg.c
index d7480253a5f5..97c5f27e5cbc 100644
--- a/sound/virtio/virtio_ctl_msg.c
+++ b/sound/virtio/virtio_ctl_msg.c
@@ -27,6 +27,8 @@
  * @pcm_epoch: Operation generation captured before request allocation.
  * @submitted: Request was handed to the device.
  * @cancelled: Request canceled during device teardown.
+ * @late: The sender stopped waiting while the device still owned the request;
+ *        completion settles the PCM state. Protected by the control queue lock.
  */
 struct virtio_snd_msg {
 	struct scatterlist sg_request;
@@ -41,6 +43,7 @@ struct virtio_snd_msg {
 	refcount_t ref_count;
 	bool cancelled;
 	bool submitted;
+	bool late;
 	struct virtio_pcm_substream *pcm;
 	u64 pcm_epoch;
 };
@@ -294,6 +297,32 @@ struct virtio_snd_msg *virtsnd_ctl_msg_alloc(size_t request_size,
 	return msg;
 }
 
+/**
+ * virtsnd_ctl_msg_status() - Convert a completed response to an errno value.
+ * @msg: Completed control message.
+ *
+ * Context: Any context.
+ * Return: 0 on success, -errno on failure.
+ */
+static int virtsnd_ctl_msg_status(struct virtio_snd_msg *msg)
+{
+	struct virtio_snd_hdr *response = virtsnd_ctl_msg_response(msg);
+
+	if (READ_ONCE(msg->cancelled))
+		return -ENODEV;
+
+	switch (le32_to_cpu(response->code)) {
+	case VIRTIO_SND_S_OK:
+		return 0;
+	case VIRTIO_SND_S_NOT_SUPP:
+		return -EOPNOTSUPP;
+	case VIRTIO_SND_S_IO_ERR:
+		return -EIO;
+	default:
+		return -EINVAL;
+	}
+}
+
 /**
  * virtsnd_ctl_msg_send() - Send a control message.
  * @snd: VirtIO sound device.
@@ -382,24 +411,7 @@ int virtsnd_ctl_msg_send(struct virtio_snd *snd, struct virtio_snd_msg *msg,
 				le32_to_cpu(request->code));
 			rc = -ETIMEDOUT;
 		} else if (rc > 0) {
-			if (READ_ONCE(msg->cancelled)) {
-				rc = -ENODEV;
-			} else {
-				switch (le32_to_cpu(response->code)) {
-				case VIRTIO_SND_S_OK:
-					rc = 0;
-					break;
-				case VIRTIO_SND_S_NOT_SUPP:
-					rc = -EOPNOTSUPP;
-					break;
-				case VIRTIO_SND_S_IO_ERR:
-					rc = -EIO;
-					break;
-				default:
-					rc = -EINVAL;
-					break;
-				}
-			}
+			rc = virtsnd_ctl_msg_status(msg);
 		}
 	}
 
@@ -419,11 +431,50 @@ int virtsnd_ctl_msg_send(struct virtio_snd *snd, struct virtio_snd_msg *msg,
 void virtsnd_ctl_msg_complete(struct virtio_snd_msg *msg)
 {
 	list_del(&msg->list);
+	if (msg->late) {
+		struct virtio_snd_hdr *request = virtsnd_ctl_msg_request(msg);
+
+		msg->late = false;
+		virtsnd_pcm_ctl_settle_locked(msg->pcm, msg->pcm_epoch,
+					      le32_to_cpu(request->code),
+					      virtsnd_ctl_msg_status(msg));
+	}
 	complete(&msg->notify);
 
 	virtsnd_ctl_msg_unref(msg);
 }
 
+/**
+ * virtsnd_ctl_msg_defer() - Hand a timed-out PCM request to its late reply.
+ * @snd: VirtIO sound device.
+ * @msg: PCM control message whose synchronous wait timed out.
+ *
+ * The device still owns a request after its sender times out. The control
+ * queue lock orders this decision against completion: either the reply has
+ * already arrived and its status is returned, or the eventual completion
+ * settles the PCM state. Until then, the substream does not send another
+ * PCM control request.
+ *
+ * Context: Any context. The caller holds a message reference.
+ * Return: The reply status if it already completed, -ENODEV if the request
+ *         was canceled, -ECANCELED if the PCM generation was reset, or
+ *         -ETIMEDOUT if the reply is still pending.
+ */
+int virtsnd_ctl_msg_defer(struct virtio_snd *snd, struct virtio_snd_msg *msg)
+{
+	struct virtio_snd_queue *queue = virtsnd_control_queue(snd);
+
+	guard(spinlock_irqsave)(&queue->lock);
+	if (completion_done(&msg->notify) || READ_ONCE(msg->cancelled))
+		return virtsnd_ctl_msg_status(msg);
+	if (!msg->pcm)
+		return -ETIMEDOUT;
+	if (!virtsnd_pcm_ctl_defer_locked(msg->pcm, msg->pcm_epoch))
+		return -ECANCELED;
+	msg->late = true;
+	return -ETIMEDOUT;
+}
+
 /**
  * virtsnd_ctl_msg_cancel_all() - Cancel all pending control messages.
  * @snd: VirtIO sound device.
diff --git a/sound/virtio/virtio_ctl_msg.h b/sound/virtio/virtio_ctl_msg.h
index b92c41c0c1a6..9cf8461736bb 100644
--- a/sound/virtio/virtio_ctl_msg.h
+++ b/sound/virtio/virtio_ctl_msg.h
@@ -84,6 +84,8 @@ static inline int virtsnd_ctl_msg_send_async(struct virtio_snd *snd,
 	return virtsnd_ctl_msg_send(snd, msg, true);
 }
 
+int virtsnd_ctl_msg_defer(struct virtio_snd *snd, struct virtio_snd_msg *msg);
+
 void virtsnd_ctl_msg_cancel_all(struct virtio_snd *snd);
 
 void virtsnd_ctl_msg_cleanup(struct virtio_snd *snd);
diff --git a/sound/virtio/virtio_pcm.c b/sound/virtio/virtio_pcm.c
index 38795c4acb01..8db0cdde3ca6 100644
--- a/sound/virtio/virtio_pcm.c
+++ b/sound/virtio/virtio_pcm.c
@@ -445,6 +445,7 @@ int virtsnd_pcm_parse_cfg(struct virtio_snd *snd)
 		INIT_WORK(&vss->elapsed_period, virtsnd_pcm_period_elapsed);
 		disable_work(&vss->elapsed_period);
 		init_waitqueue_head(&vss->msg_empty);
+		init_waitqueue_head(&vss->control_wait);
 		spin_lock_init(&vss->lock);
 		mutex_init(&vss->lifecycle_lock);
 	}
diff --git a/sound/virtio/virtio_pcm.h b/sound/virtio/virtio_pcm.h
index 0c625df1f4e4..2b231db23f0d 100644
--- a/sound/virtio/virtio_pcm.h
+++ b/sound/virtio/virtio_pcm.h
@@ -81,7 +81,12 @@ enum virtio_pcm_pause_restart_state {
  *             the PCM stream lock and @lock.
  * @device_running: Native START succeeded without a subsequent successful STOP.
  * @release_required: Successful PREPARE still needs a successful RELEASE.
- * @control_uncertain: Native control result requires device reset before reuse.
+ * @control_uncertain: A native control result is not yet known; no further
+ *                     PCM control request is sent until it is.
+ * @control_late: Timed-out native control requests still owned by the device.
+ *                Their replies settle the device state.
+ * @control_deadline: End of the shared late-reply wait window; protected by
+ *                    @lock.
  * @capture_reset_observing: Reclaim staged samples during RESET pointer capture.
  * @indirect_reset_observing: Suppress ordinary ACK refill during RESET pointer
  *                            capture; protected by the PCM stream lock.
@@ -98,6 +103,7 @@ enum virtio_pcm_pause_restart_state {
  * @owned_dma_area: Driver-owned PCM buffer backing asynchronous messages.
  * @owned_dma_bytes: Size of @owned_dma_area.
  * @msg_empty: Notify when msg_count is zero.
+ * @control_wait: Notify when native control state becomes known.
  */
 struct virtio_pcm_substream {
 	struct virtio_snd *snd;
@@ -142,6 +148,8 @@ struct virtio_pcm_substream {
 	bool device_running;
 	bool release_required;
 	bool control_uncertain;
+	unsigned int control_late;
+	unsigned long control_deadline;
 	bool capture_reset_observing;
 	bool indirect_reset_observing;
 	bool playback_pointer_active;
@@ -157,6 +165,7 @@ struct virtio_pcm_substream {
 	size_t owned_dma_bytes;
 #endif
 	wait_queue_head_t msg_empty;
+	wait_queue_head_t control_wait;
 };
 
 /* Caller holds the PCM stream lock and vss->lock. */
@@ -279,6 +288,11 @@ struct virtio_snd_msg *
 virtsnd_pcm_ctl_msg_alloc(struct virtio_pcm_substream *vss,
 			  unsigned int command, gfp_t gfp, u64 epoch);
 
+bool virtsnd_pcm_ctl_defer_locked(struct virtio_pcm_substream *vss, u64 epoch);
+
+void virtsnd_pcm_ctl_settle_locked(struct virtio_pcm_substream *vss, u64 epoch,
+				   u32 command, int status);
+
 int virtsnd_pcm_msg_alloc(struct virtio_pcm_substream *vss,
 			  unsigned int periods, unsigned int period_bytes);
 
diff --git a/sound/virtio/virtio_pcm_ops.c b/sound/virtio/virtio_pcm_ops.c
index 00ab4acfd813..30e4ccc1e8bc 100644
--- a/sound/virtio/virtio_pcm_ops.c
+++ b/sound/virtio/virtio_pcm_ops.c
@@ -3,6 +3,7 @@
  * virtio-snd: Virtio sound device
  * Copyright (C) 2021 OpenSynergy GmbH
  */
+#include <linux/jiffies.h>
 #include <linux/moduleparam.h>
 #include <linux/overflow.h>
 #include <linux/spinlock.h>
@@ -157,10 +158,92 @@ static bool virtsnd_pcm_pause_restart_transitioning(enum virtio_pcm_pause_restar
 	}
 }
 
+/* A late control reply gets one shared wait window across PCM callbacks. */
+#define VIRTSND_PCM_SETTLE_TIMEOUTS	4
+
+static unsigned long virtsnd_pcm_settle_jiffies(void)
+{
+	u64 ms = (u64)virtsnd_msg_timeout_ms * VIRTSND_PCM_SETTLE_TIMEOUTS;
+
+	return msecs_to_jiffies(min_t(u64, ms, UINT_MAX));
+}
+
+/**
+ * virtsnd_pcm_ctl_defer_locked() - Record a native control request whose
+ *                                  sender timed out.
+ * @vss: VirtIO PCM substream.
+ * @epoch: Generation of the request.
+ *
+ * Context: Control queue lock held with interrupts disabled.
+ * Return: false if the generation was reset, true otherwise.
+ */
+bool virtsnd_pcm_ctl_defer_locked(struct virtio_pcm_substream *vss, u64 epoch)
+{
+	guard(spinlock)(&vss->lock);
+	if (vss->resetting || vss->reset_epoch != epoch)
+		return false;
+	if (!vss->control_uncertain)
+		vss->control_deadline = jiffies + virtsnd_pcm_settle_jiffies();
+	vss->control_late++;
+	vss->control_uncertain = true;
+	return true;
+}
+
+/**
+ * virtsnd_pcm_ctl_settle_locked() - Apply a late native control reply.
+ * @vss: VirtIO PCM substream.
+ * @epoch: Generation of the request.
+ * @command: Control request code (VIRTIO_SND_R_PCM_XXX).
+ * @status: Reply status converted to an errno value.
+ *
+ * No other native control request is sent while one is outstanding, so the
+ * reply determines the device state. A failed request leaves it unchanged.
+ *
+ * Context: Control queue lock held with interrupts disabled.
+ */
+void virtsnd_pcm_ctl_settle_locked(struct virtio_pcm_substream *vss, u64 epoch,
+				   u32 command, int status)
+{
+	scoped_guard(spinlock, &vss->lock) {
+		if (vss->resetting || vss->reset_epoch != epoch ||
+		    !vss->control_late)
+			return;
+		if (!status) {
+			switch (command) {
+			case VIRTIO_SND_R_PCM_PREPARE:
+				vss->release_required = true;
+				break;
+			case VIRTIO_SND_R_PCM_START:
+				vss->device_running = true;
+				break;
+			case VIRTIO_SND_R_PCM_STOP:
+				vss->device_running = false;
+				break;
+			case VIRTIO_SND_R_PCM_RELEASE:
+				vss->release_required = false;
+				vss->device_running = false;
+				break;
+			}
+		}
+		if (--vss->control_late)
+			return;
+		vss->control_uncertain = false;
+		vss->control_deadline = 0;
+		wake_up_all(&vss->control_wait);
+	}
+
+	dev_info_ratelimited(&vss->snd->vdev->dev,
+			     "SID %u: late PCM control 0x%08x reply settled (%d)\n",
+			     vss->sid, command, status);
+}
+
 static int virtsnd_pcm_send_sync(struct virtio_pcm_substream *vss,
 				 struct virtio_snd_msg *msg)
 {
+	struct virtio_snd_hdr *request = virtsnd_ctl_msg_request(msg);
 	u64 epoch = virtsnd_ctl_msg_pcm_epoch(msg);
+	u32 command = le32_to_cpu(request->code);
+	bool deferred = false;
 	bool uncertain;
 	int rc;
 
@@ -174,17 +257,77 @@ static int virtsnd_pcm_send_sync(struct virtio_pcm_substream *vss,
 	}
 	virtsnd_ctl_msg_ref(msg);
 	rc = virtsnd_ctl_msg_send_sync(vss->snd, msg);
-	uncertain = virtsnd_ctl_msg_uncertain(msg, rc);
+	if (rc == -ETIMEDOUT) {
+		/* The device still owns the request; its reply settles the state. */
+		rc = virtsnd_ctl_msg_defer(vss->snd, msg);
+		deferred = rc == -ETIMEDOUT;
+	}
+	uncertain = !deferred && virtsnd_ctl_msg_uncertain(msg, rc);
 	virtsnd_ctl_msg_unref(msg);
 	scoped_guard(spinlock_irqsave, &vss->lock) {
 		if (epoch != vss->reset_epoch || vss->resetting)
 			return -ECANCELED;
-		if (rc && uncertain)
+		if (rc && uncertain && !vss->control_uncertain) {
+			vss->control_deadline =
+				jiffies + virtsnd_pcm_settle_jiffies();
 			vss->control_uncertain = true;
+		}
 	}
+	if (deferred)
+		dev_warn_ratelimited(&vss->snd->vdev->dev,
+				     "SID %u: PCM control 0x%08x reply is late; holding PCM commands\n",
+				     vss->sid, command);
 	return rc;
 }
 
+static bool virtsnd_pcm_control_settled(struct virtio_pcm_substream *vss)
+{
+	guard(spinlock_irqsave)(&vss->lock);
+	return vss->resetting || !vss->control_uncertain;
+}
+
+/**
+ * virtsnd_pcm_control_settle() - Wait for a late native control reply.
+ * @vss: VirtIO PCM substream.
+ *
+ * Trigger fails while a native control result is unknown. Sleepable
+ * operations wait a bounded time for the reply, then continue from the
+ * device state it reports.
+ *
+ * Context: Process context with @vss->lifecycle_lock held.
+ * Return: 0 if the state is known or a device reset is in progress, -EIO if
+ *         the reply is still outstanding, or -ERESTARTSYS if killed.
+ */
+static int virtsnd_pcm_control_settle(struct virtio_pcm_substream *vss)
+{
+	unsigned long now;
+	unsigned long timeout;
+	unsigned long deadline;
+	long rc;
+
+	lockdep_assert_held(&vss->lifecycle_lock);
+	scoped_guard(spinlock_irqsave, &vss->lock) {
+		if (vss->resetting || !vss->control_uncertain)
+			return 0;
+		deadline = vss->control_deadline;
+		now = jiffies;
+	}
+	timeout = time_before(now, deadline) ? deadline - now : 0;
+
+	rc = wait_event_killable_timeout(vss->control_wait,
+					 virtsnd_pcm_control_settled(vss),
+					 timeout);
+	if (rc < 0)
+		return rc;
+	if (virtsnd_pcm_control_settled(vss))
+		return 0;
+
+	dev_err_ratelimited(&vss->snd->vdev->dev,
+			    "SID %u: PCM control reply is still outstanding\n",
+			    vss->sid);
+	return -EIO;
+}
+
 static int
 virtsnd_pcm_pause_restart_send(struct virtio_pcm_substream *vss,
 			       struct virtio_snd_msg *msg,
@@ -272,6 +415,15 @@ virtsnd_pcm_pause_restart_fail(struct virtio_pcm_substream *vss,
 	vss->substream->runtime->stop_operating = true;
 }
 
+static void virtsnd_pcm_quiesce_period_work(struct virtio_pcm_substream *vss)
+{
+	lockdep_assert_held(&vss->lifecycle_lock);
+	if (vss->period_work_quiesced)
+		return;
+	disable_work_sync(&vss->elapsed_period);
+	vss->period_work_quiesced = true;
+}
+
 static int virtsnd_pcm_dev_prepare(struct virtio_pcm_substream *vss, u64 epoch)
 {
 	struct virtio_snd_msg *msg;
@@ -685,9 +837,21 @@ static int virtsnd_pcm_prepare_locked(struct snd_pcm_substream *substream)
 		if (vss->resetting)
 			return -ECANCELED;
 		epoch = vss->reset_epoch;
-		stopped = vss->stopped || vss->release_required || vss->msg_count;
 		vss->prepared = false;
 		vss->preparing = true;
+		vss->xfer_enabled = false;
+	}
+	virtsnd_pcm_quiesce_period_work(vss);
+	/* Teardown decisions below depend on the settled device state. */
+	rc = virtsnd_pcm_control_settle(vss);
+	if (rc) {
+		substream->runtime->stop_operating = true;
+		return rc;
+	}
+	scoped_guard(spinlock_irqsave, &vss->lock) {
+		if (vss->resetting || vss->reset_epoch != epoch)
+			return -ECANCELED;
+		stopped = vss->stopped || vss->release_required || vss->msg_count;
 	}
 	if (stopped) {
 		rc = virtsnd_pcm_sync_stop_locked(substream);
@@ -1127,13 +1291,10 @@ static int virtsnd_pcm_stop_device(struct virtio_pcm_substream *vss, u64 epoch)
 	return 0;
 }
 
-static int virtsnd_pcm_start_queue(struct virtio_pcm_substream *vss, u64 epoch)
+static int virtsnd_pcm_start_queue_check_locked(struct virtio_pcm_substream *vss,
+						u64 epoch)
 {
-	struct virtio_snd_queue *queue = virtsnd_pcm_queue(vss);
-	int rc = 0;
-
-	guard(spinlock_irqsave)(&queue->lock);
-	guard(spinlock)(&vss->lock);
+	lockdep_assert_held(&vss->lock);
 	if (vss->resetting || vss->reset_epoch != epoch)
 		return -ECANCELED;
 	if (vss->preparing)
@@ -1142,14 +1303,55 @@ static int virtsnd_pcm_start_queue(struct virtio_pcm_substream *vss, u64 epoch)
 		return vss->xfer_xrun ? -EPIPE : -EBADFD;
 	if (vss->control_uncertain)
 		return -EIO;
-	if (vss->direction == SNDRV_PCM_STREAM_CAPTURE) {
+	return 0;
+}
+
+static int virtsnd_pcm_start_queue_activate_locked(
+	struct virtio_pcm_substream *vss)
+{
+	int rc = 0;
+
+	lockdep_assert_held(&vss->lock);
+	if (vss->direction == SNDRV_PCM_STREAM_CAPTURE)
 		rc = vss->runtime_active ? virtsnd_pcm_capture_send(vss) : -EBADFD;
-	}
 	if (!rc)
 		vss->xfer_enabled = true;
 	return rc;
 }
 
+static int virtsnd_pcm_start_queue(struct virtio_pcm_substream *vss, u64 epoch)
+{
+	struct virtio_snd_queue *queue = virtsnd_pcm_queue(vss);
+	int rc;
+
+	guard(spinlock_irqsave)(&queue->lock);
+	guard(spinlock)(&vss->lock);
+	rc = virtsnd_pcm_start_queue_check_locked(vss, epoch);
+	return rc ? rc : virtsnd_pcm_start_queue_activate_locked(vss);
+}
+
+static int virtsnd_pcm_start_queue_rollback(struct virtio_pcm_substream *vss,
+					    u64 epoch,
+					    bool capture_stopping,
+					    u64 capture_quiet_sequence)
+{
+	struct virtio_snd_queue *queue = virtsnd_pcm_queue(vss);
+	int rc;
+
+	guard(spinlock_irqsave)(&queue->lock);
+	guard(spinlock)(&vss->lock);
+	if (!vss->device_running)
+		return -EIO;
+	rc = virtsnd_pcm_start_queue_check_locked(vss, epoch);
+	if (rc)
+		return rc;
+	if (vss->direction == SNDRV_PCM_STREAM_CAPTURE) {
+		vss->capture_stopping = capture_stopping;
+		vss->capture_quiet_sequence = capture_quiet_sequence;
+	}
+	return virtsnd_pcm_start_queue_activate_locked(vss);
+}
+
 /**
  * virtsnd_pcm_trigger_inner() - Process command for the PCM substream.
  * @substream: Kernel ALSA substream.
@@ -1269,17 +1471,12 @@ static int virtsnd_pcm_trigger_inner(struct snd_pcm_substream *substream,
 			}
 		}
 		if (rc && command == SNDRV_PCM_TRIGGER_PAUSE_PUSH) {
-			scoped_guard(spinlock_irqsave, &vss->lock) {
-				if (vss->reset_epoch == epoch && !vss->resetting &&
-				    vss->direction == SNDRV_PCM_STREAM_CAPTURE) {
-					vss->capture_stopping = capture_stopping;
-					vss->capture_quiet_sequence = capture_quiet_sequence;
-				}
-			}
 			if (substream->runtime->state != SNDRV_PCM_STATE_RUNNING) {
 				/* Failed resume rollback must leave a paused queue closed. */
 				virtsnd_pcm_trigger_failed(vss, epoch);
-			} else if (virtsnd_pcm_start_queue(vss, epoch)) {
+			} else if (virtsnd_pcm_start_queue_rollback(vss, epoch,
+									capture_stopping,
+									capture_quiet_sequence)) {
 				virtsnd_pcm_trigger_failed(vss, epoch);
 			} else if (vss->direction == SNDRV_PCM_STREAM_CAPTURE ||
 				   virtsnd_pcm_playback_progress_pending(vss)) {
@@ -1493,10 +1690,7 @@ static int virtsnd_pcm_release_locked(struct snd_pcm_substream *substream)
 
 	lockdep_assert_held(&vss->lifecycle_lock);
 	/* Keep late RX completions from requeuing work after cancellation. */
-	if (!vss->period_work_quiesced) {
-		disable_work_sync(&vss->elapsed_period);
-		vss->period_work_quiesced = true;
-	}
+	virtsnd_pcm_quiesce_period_work(vss);
 	if (virtsnd_pcm_pause_restart_enabled(vss))
 		return virtsnd_pcm_pause_restart_sync_stop(substream);
 
@@ -1581,12 +1775,21 @@ static int virtsnd_pcm_sync_stop_locked(struct snd_pcm_substream *substream)
 	lockdep_assert_held(&vss->lifecycle_lock);
 	scoped_guard(pcm_stream_lock_irqsave, substream) {
 		guard(spinlock_irqsave)(&vss->lock);
+		if (vss->resetting) {
+			substream->runtime->stop_operating = true;
+			return -ECANCELED;
+		}
 		preparing = vss->preparing;
 		vss->preparing = true;
 		vss->prepared = false;
 		vss->xfer_enabled = false;
 	}
-	rc = virtsnd_pcm_release_locked(substream);
+	virtsnd_pcm_quiesce_period_work(vss);
+	rc = virtsnd_pcm_control_settle(vss);
+	if (!rc)
+		rc = virtsnd_pcm_release_locked(substream);
+	if (rc)
+		substream->runtime->stop_operating = true;
 	scoped_guard(pcm_stream_lock_irqsave, substream) {
 		guard(spinlock_irqsave)(&vss->lock);
 		vss->preparing = preparing;

-- 
Git-157)

