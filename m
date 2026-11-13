From: Joonho Lee <mynameisjune111@gmail.com>
Date: Fri, 13 Nov 2026 18:21:41 +0900
Subject: [PATCH v33 17/18] ALSA: virtio: preserve playback progress across
 pause and buffer access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-fix-virtio-snd-recovery-final-v33-17-13a934ad5ece@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794561688; l=14790;
 i=mynameisjune111@gmail.com; s=default; h=from:subject:message-id;
 bh=mlSoCi18UwM5YNTHt6PXxrV2d/Il0sarLRycL9AXGSQ=;
 b=Vg2VJG4uKKWM3hhVHnV+zOwsWDGBRf1txYR4Izq7XnZX8rtv/iJ31Y7LjulbxbnYAbVLZswko
 4/GEUJfzD57COavIven3r1ykwzeUbPqO2jFw6/0SIy8MtMjvcs2Wziz
X-Developer-Key: i=mynameisjune111@gmail.com; a=ed25519;
 pk=wqkZdvfcC8g8fDi6f0Y58LlaXIo+ubf6Y/9Lr9yhshc=
X-Endpoint-Received: by B4 Relay for mynameisjune111@gmail.com/default with auth_id=1508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TX completions can arrive after PAUSE closes transfer admission.
Preserve that progress and schedule catch-up when the stream resumes or
a rejected pause restores RUNNING. Cache device latency in stream-owned
state so a late completion does not need to dereference the ALSA
runtime. Clear both the cache and runtime delay on prepare and before
RESET observes the hardware pointer.

A playback pointer callback can also invoke ACK while the core has
closed buffer-access admission, after the pointer helper has already
accounted for completed hardware bytes. Track that callback context and
refill only previously committed data using pcm_indirect.appl_ptr. Keep
rejecting other ACKs while the gate is closed, and use the
snd_pcm_indirect_playback_transfer_appl_ptr() for the refill. If
runtime->control is absent, route the condition through the common
playback validator and XRUN error path rather than returning before
transfer failure handling.

Use the existing indirect hw_queue_size to keep outstanding TX below one
physical ring: buffer_bytes - period_bytes. Equal modulo cursors then
mean no unobserved completion, and a non-interrupt HWSYNC cannot consume
a hidden full-ring wrap before deferred period work. Continue using the
ordinary ALSA pointer update for silence, drain, stop-threshold and
wakeup policy.

Check for pending progress or a latched transfer error again in the
period worker under the PCM stream lock. A queued notification can
outlive a paused RESET or an earlier pointer observation. Calling the
period helper without new progress after resume can turn equal cursors
into a false wrap when the core has backdated its pointer timestamp.

This reduces queued buffering by one period. With two periods, only one
period can be queued.

The final candidate was tested on ARM64 QEMU with KASAN and lockdep.
RW/MMAP boundary pause, release, HWSYNC/poll, drop and reopen passed
with two- and eight-period rings. RW/MMAP also passed accepted RESET
from PREPARED followed by DRAIN and reopen, and accepted RESET while
RUNNING after the full 2,048-frame buffer became available.

A separate paired RW/MMAP gate fixture reproduced the baseline failure.
The generic ALSA indirect helper invokes ACK for each pointer callback
but masks its internal -EBADFD. Once hw_ptr == hw_io with no completion
outstanding, virtio period-work progress suppresses further callbacks,
so there is no ACK to retry the refill. Baseline stopped after 3,072
completed bytes with 1,024 bytes in sw_ready. The candidate drained
sw_ready and completed 4,096 bytes without any further client ACK. A
test-only hook changed appl_ptr to 2,560 while only 2,048 frames were
committed; the candidate refilled only committed data. The hostile
mutation used a test-only kernel hook because ARM64 control-page mmap is
unsupported. KASAN and lockdep reported no diagnostics.

Assisted-by: LLM
Signed-off-by: Joonho Lee <mynameisjune111@gmail.com>
---
 sound/virtio/virtio_pcm.c     |  3 ++
 sound/virtio/virtio_pcm.h     | 13 +++++++++
 sound/virtio/virtio_pcm_msg.c |  8 ++----
 sound/virtio/virtio_pcm_ops.c | 67 ++++++++++++++++++++++++++++++++-----------
 4 files changed, 69 insertions(+), 22 deletions(-)

diff --git a/sound/virtio/virtio_pcm.c b/sound/virtio/virtio_pcm.c
index 7b332c9476f1..38795c4acb01 100644
--- a/sound/virtio/virtio_pcm.c
+++ b/sound/virtio/virtio_pcm.c
@@ -338,6 +338,9 @@ static void virtsnd_pcm_period_elapsed(struct work_struct *work)
 	}
 
 	if (vss->direction != SNDRV_PCM_STREAM_CAPTURE) {
+		/* Ignore stale work after RESET rebases the playback cursors. */
+		if (!virtsnd_pcm_playback_progress_pending(vss))
+			return;
 		snd_pcm_period_elapsed_under_stream_lock(substream);
 		return;
 	}
diff --git a/sound/virtio/virtio_pcm.h b/sound/virtio/virtio_pcm.h
index 987105145205..0c625df1f4e4 100644
--- a/sound/virtio/virtio_pcm.h
+++ b/sound/virtio/virtio_pcm.h
@@ -53,6 +53,7 @@ enum virtio_pcm_pause_restart_state {
  *        substream operators, including @stopped.
  * @buffer_bytes: Current buffer size in bytes.
  * @hw_ptr: Substream hardware pointer value in bytes [0 ... buffer_bytes).
+ * @playback_latency_bytes: Device delay cached independently of the ALSA runtime.
  * @capture_ready: Managed-mode bytes copied but not yet acknowledged by ALSA;
  *                 always zero in free-running mode.
  * @capture_boundary: ALSA boundary captured for this prepared epoch.
@@ -84,6 +85,8 @@ enum virtio_pcm_pause_restart_state {
  * @capture_reset_observing: Reclaim staged samples during RESET pointer capture.
  * @indirect_reset_observing: Suppress ordinary ACK refill during RESET pointer
  *                            capture; protected by the PCM stream lock.
+ * @playback_pointer_active: Internal playback ACK context; protected by the
+ *                           PCM stream lock.
  * @suspended: True if the substream is suspended and must be reconfigured on
  *             the device side at resume.
  * @pause_restart_state: Device-side state for opt-in pause compatibility.
@@ -113,6 +116,7 @@ struct virtio_pcm_substream {
 	bool resetting;
 	size_t buffer_bytes;
 	size_t hw_ptr;
+	u32 playback_latency_bytes;
 	size_t capture_ready;
 	snd_pcm_uframes_t capture_boundary;
 	u64 capture_copied_total;
@@ -140,6 +144,7 @@ struct virtio_pcm_substream {
 	bool control_uncertain;
 	bool capture_reset_observing;
 	bool indirect_reset_observing;
+	bool playback_pointer_active;
 	bool suspended;
 	enum virtio_pcm_pause_restart_state pause_restart_state;
 	struct virtio_pcm_msg **msgs;
@@ -179,6 +184,14 @@ virtsnd_pcm_schedule_period_elapsed(struct virtio_pcm_substream *vss)
 	return schedule_work(&vss->elapsed_period);
 }
 
+/* Caller holds the PCM stream lock so RESET cannot rebase these cursors. */
+static inline bool
+virtsnd_pcm_playback_progress_pending(struct virtio_pcm_substream *vss)
+{
+	guard(spinlock_irqsave)(&vss->lock);
+	return vss->xfer_xrun || vss->hw_ptr != vss->pcm_indirect.hw_io;
+}
+
 /*
  * ALSA may observe a subperiod tail before its period callback. Keep actual
  * unread occupancy separate from pointer observations and notification state;
diff --git a/sound/virtio/virtio_pcm_msg.c b/sound/virtio/virtio_pcm_msg.c
index 9c67a8bf15f5..44761dff3e0d 100644
--- a/sound/virtio/virtio_pcm_msg.c
+++ b/sound/virtio/virtio_pcm_msg.c
@@ -1033,12 +1033,10 @@ static void virtsnd_pcm_msg_complete(struct virtio_pcm_msg *msg,
 	/* Keep latched errors until prepare establishes a fresh epoch. */
 	vss->msg_count--;
 
-	if (vss->xfer_enabled) {
-		struct snd_pcm_runtime *runtime = vss->substream->runtime;
-
-		runtime->delay = bytes_to_frames(runtime, latency_bytes);
+	/* A queued request can outlive the ALSA runtime after hw_free. */
+	vss->playback_latency_bytes = latency_bytes;
+	if (vss->prepared && !vss->preparing)
 		virtsnd_pcm_schedule_period_elapsed(vss);
-	}
 	if (!vss->msg_count)
 		wake_up_all(&vss->msg_empty);
 }
diff --git a/sound/virtio/virtio_pcm_ops.c b/sound/virtio/virtio_pcm_ops.c
index 4c9e1fa4ff92..00ab4acfd813 100644
--- a/sound/virtio/virtio_pcm_ops.c
+++ b/sound/virtio/virtio_pcm_ops.c
@@ -770,6 +770,13 @@ static int virtsnd_pcm_prepare_locked(struct snd_pcm_substream *substream)
 		memset(&vss->pcm_indirect, 0, sizeof(vss->pcm_indirect));
 		vss->pcm_indirect.sw_buffer_size = vss->buffer_bytes;
 		vss->pcm_indirect.hw_buffer_size = vss->buffer_bytes;
+		if (vss->direction == SNDRV_PCM_STREAM_PLAYBACK) {
+			/* Keep unobserved completions below one physical ring. */
+			vss->pcm_indirect.hw_queue_size = vss->buffer_bytes -
+				snd_pcm_lib_period_bytes(substream);
+			vss->playback_latency_bytes = 0;
+			substream->runtime->delay = 0;
+		}
 		if (vss->direction == SNDRV_PCM_STREAM_CAPTURE) {
 			vss->capture_boundary = substream->runtime->boundary;
 			rc = virtsnd_pcm_capture_refresh_mode_locked(vss,
@@ -1200,7 +1207,8 @@ static int virtsnd_pcm_trigger_inner(struct snd_pcm_substream *substream,
 		}
 
 		if (running) {
-			if (vss->direction == SNDRV_PCM_STREAM_CAPTURE)
+			if (vss->direction == SNDRV_PCM_STREAM_CAPTURE ||
+			    virtsnd_pcm_playback_progress_pending(vss))
 				virtsnd_pcm_schedule_period_elapsed(vss);
 			return 0;
 		}
@@ -1222,7 +1230,8 @@ static int virtsnd_pcm_trigger_inner(struct snd_pcm_substream *substream,
 				return -ECANCELED;
 			vss->device_running = true;
 		}
-		if (!rc && (vss->direction == SNDRV_PCM_STREAM_CAPTURE))
+		if (!rc && (vss->direction == SNDRV_PCM_STREAM_CAPTURE ||
+			    virtsnd_pcm_playback_progress_pending(vss)))
 			virtsnd_pcm_schedule_period_elapsed(vss);
 		return rc;
 	case SNDRV_PCM_TRIGGER_SUSPEND:
@@ -1272,7 +1281,8 @@ static int virtsnd_pcm_trigger_inner(struct snd_pcm_substream *substream,
 				virtsnd_pcm_trigger_failed(vss, epoch);
 			} else if (virtsnd_pcm_start_queue(vss, epoch)) {
 				virtsnd_pcm_trigger_failed(vss, epoch);
-			} else if (vss->direction == SNDRV_PCM_STREAM_CAPTURE) {
+			} else if (vss->direction == SNDRV_PCM_STREAM_CAPTURE ||
+				   virtsnd_pcm_playback_progress_pending(vss)) {
 				virtsnd_pcm_schedule_period_elapsed(vss);
 			}
 		}
@@ -1605,6 +1615,7 @@ virtsnd_pcm_pb_pointer(struct snd_pcm_substream *substream)
 {
 	struct virtio_pcm_substream *vss = snd_pcm_substream_chip(substream);
 	struct snd_pcm_runtime *runtime = substream->runtime;
+	snd_pcm_uframes_t position;
 	size_t hw_ptr;
 	bool paused_pointer = false;
 	bool defer_work = false;
@@ -1622,6 +1633,7 @@ virtsnd_pcm_pb_pointer(struct snd_pcm_substream *substream)
 		}
 		if (!paused_pointer)
 			hw_ptr = vss->hw_ptr;
+		runtime->delay = bytes_to_frames(runtime, vss->playback_latency_bytes);
 	}
 	if (paused_pointer) {
 		if (defer_work)
@@ -1629,8 +1641,11 @@ virtsnd_pcm_pb_pointer(struct snd_pcm_substream *substream)
 		return virtsnd_pcm_cached_pointer(runtime);
 	}
 
-	return snd_pcm_indirect_playback_pointer(substream,
-		&vss->pcm_indirect, hw_ptr);
+	vss->playback_pointer_active = true;
+	position = snd_pcm_indirect_playback_pointer(substream,
+						     &vss->pcm_indirect, hw_ptr);
+	vss->playback_pointer_active = false;
+	return position;
 }
 
 /* Caller holds vss->lock. */
@@ -1745,9 +1760,9 @@ struct virtsnd_pcm_transfer {
 /* Caller holds @vss->lock and the PCM stream lock. */
 static int virtsnd_pcm_playback_ack_validate(struct virtio_pcm_substream *vss,
 					     struct snd_pcm_runtime *runtime,
-					     const struct snd_pcm_indirect *rec)
+					     const struct snd_pcm_indirect *rec,
+					     snd_pcm_uframes_t appl_ptr)
 {
-	snd_pcm_uframes_t appl_ptr;
 	snd_pcm_uframes_t appl_diff;
 	snd_pcm_uframes_t signed_max;
 	snd_pcm_uframes_t back;
@@ -1761,7 +1776,7 @@ static int virtsnd_pcm_playback_ack_validate(struct virtio_pcm_substream *vss,
 	unsigned int hw_queue_size;
 
 	if (!runtime->control || !runtime->boundary ||
-	    runtime->control->appl_ptr >= runtime->boundary ||
+	    appl_ptr >= runtime->boundary ||
 	    rec->appl_ptr >= runtime->boundary)
 		return -EPIPE;
 
@@ -1776,7 +1791,6 @@ static int virtsnd_pcm_playback_ack_validate(struct virtio_pcm_substream *vss,
 		return -EPIPE;
 
 	/* Match the indirect helper's appl_ptr boundary-wrap calculation. */
-	appl_ptr = runtime->control->appl_ptr;
 	if (appl_ptr >= rec->appl_ptr) {
 		appl_diff = appl_ptr - rec->appl_ptr;
 	} else {
@@ -1868,7 +1882,8 @@ static int virtsnd_pcm_ack_xrun_locked(struct virtio_pcm_substream *vss,
 	return -EPIPE;
 }
 
-static int virtsnd_pcm_pb_ack_locked(struct snd_pcm_substream *substream)
+static int virtsnd_pcm_pb_ack_locked(struct snd_pcm_substream *substream,
+				     snd_pcm_uframes_t appl_ptr)
 {
 	struct virtio_pcm_substream *vss = snd_pcm_substream_chip(substream);
 	struct snd_pcm_runtime *runtime = substream->runtime;
@@ -1892,13 +1907,13 @@ static int virtsnd_pcm_pb_ack_locked(struct snd_pcm_substream *substream)
 				return -EBADFD;
 			transfer.indirect = vss->pcm_indirect;
 			rc = virtsnd_pcm_playback_ack_validate(vss, runtime,
-							       &transfer.indirect);
+							       &transfer.indirect, appl_ptr);
 			if (rc == -EBADFD)
 				return -EBADFD;
 			if (!rc)
-				rc = snd_pcm_indirect_playback_transfer(substream,
-									&transfer.indirect,
-									virtsnd_pcm_trans_copy);
+				rc = snd_pcm_indirect_playback_transfer_appl_ptr(
+					substream, &transfer.indirect,
+					virtsnd_pcm_trans_copy, appl_ptr);
 		}
 		if (!rc)
 			rc = transfer.error;
@@ -1937,8 +1952,6 @@ static int virtsnd_pcm_ack_state(struct snd_pcm_substream *substream)
 	case SNDRV_PCM_STATE_RUNNING:
 	case SNDRV_PCM_STATE_PAUSED:
 	case SNDRV_PCM_STATE_DRAINING:
-		if (atomic_read(&substream->runtime->buffer_accessing) < 0)
-			return -EBADFD;
 		return 0;
 	default:
 		return -EBADFD;
@@ -1949,6 +1962,8 @@ static int virtsnd_pcm_ack_state(struct snd_pcm_substream *substream)
 static int virtsnd_pcm_pb_ack(struct snd_pcm_substream *substream)
 {
 	struct virtio_pcm_substream *vss = snd_pcm_substream_chip(substream);
+	struct snd_pcm_runtime *runtime = substream->runtime;
+	snd_pcm_uframes_t appl_ptr;
 	int rc;
 
 	if (vss->indirect_reset_observing)
@@ -1956,7 +1971,21 @@ static int virtsnd_pcm_pb_ack(struct snd_pcm_substream *substream)
 	rc = virtsnd_pcm_ack_state(substream);
 	if (rc)
 		return rc;
-	return virtsnd_pcm_pb_ack_locked(substream);
+	if (atomic_read(&runtime->buffer_accessing) < 0) {
+		if (!vss->playback_pointer_active)
+			return -EBADFD;
+		/*
+		 * Pointer accounting already consumed completed hardware bytes.
+		 * Refill committed data without admitting a new application
+		 * pointer while a buffer operation has closed ACK admission.
+		 */
+		appl_ptr = vss->pcm_indirect.appl_ptr;
+	} else if (runtime->control) {
+		appl_ptr = READ_ONCE(runtime->control->appl_ptr);
+	} else {
+		appl_ptr = 0;
+	}
+	return virtsnd_pcm_pb_ack_locked(substream, appl_ptr);
 }
 
 static int virtsnd_pcm_capture_ack(struct virtio_pcm_substream *vss,
@@ -2087,6 +2116,8 @@ static int virtsnd_pcm_cp_ack(struct snd_pcm_substream *substream)
 	rc = virtsnd_pcm_ack_state(substream);
 	if (rc)
 		return rc;
+	if (atomic_read(&substream->runtime->buffer_accessing) < 0)
+		return -EBADFD;
 	return virtsnd_pcm_cp_ack_locked(substream);
 }
 
@@ -2228,6 +2259,8 @@ static int virtsnd_pcm_playback_reset(struct snd_pcm_substream *substream)
 		guard(spinlock)(&vss->lock);
 		if (vss->msg_count)
 			return -EBUSY;
+		vss->playback_latency_bytes = 0;
+		runtime->delay = 0;
 	}
 	vss->indirect_reset_observing = true;
 	rc = snd_pcm_lib_reset(substream);

-- 
Git-157)

