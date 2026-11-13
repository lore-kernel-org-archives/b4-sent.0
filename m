From: Joonho Lee <mynameisjune111@gmail.com>
Date: Fri, 13 Nov 2026 15:41:47 +0900
Subject: [PATCH v32 03/20] ALSA: pcm: add an optional reset operation under
 the stream lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-fix-virtio-snd-recovery-final-v32-3-4e95979e312c@gmail.com>
References: <20261113-fix-virtio-snd-recovery-final-v32-0-4e95979e312c@gmail.com>
In-Reply-To: <20261113-fix-virtio-snd-recovery-final-v32-0-4e95979e312c@gmail.com>
To: linux-sound@vger.kernel.org
Cc: tiwai@suse.com, perex@perex.cz, mst@redhat.com, 
 virtualization@lists.linux.dev, linux-kernel@vger.kernel.org, 
 corbet@lwn.net, skhan@linuxfoundation.org, rdunlap@infradead.org, 
 linux-doc@vger.kernel.org, Joonho Lee <mynameisjune111@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794552109; l=8454;
 i=mynameisjune111@gmail.com; s=default; h=from:subject:message-id;
 bh=efD3642upyG77bVZgndIqVLXrjo9sS8u1oil6oXMfIw=;
 b=YY4ASwKkHAbytvqFZFFqWxxPLlSs1QT89QTccj4fPNKh5HpVaVJ8fvhfhuhuBx2qs+dSWOAeu
 PJcEcoS7NdQC+e7coolx6WjD83gOGHBfE5NT/eqwVus/OrE7MaJdBTv
X-Developer-Key: i=mynameisjune111@gmail.com; a=ed25519;
 pk=wqkZdvfcC8g8fDi6f0Y58LlaXIo+ubf6Y/9Lr9yhshc=
X-Endpoint-Received: by B4 Relay for mynameisjune111@gmail.com/default with auth_id=1508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A driver may need to synchronize private capture accounting with the
common RESET pointer observation and the core's position rebase.

Add an optional reset operation called under the member's stream lock.
Expose snd_pcm_lib_reset() so the callback can retain common pointer and
time handling. On zero return the core completes that member's rebase
before unlocking it. Drivers without the callback retain the ioctl path.
The operation is also used after a successful prepare.

Zero permits the position rebase; it does not promise XRUN recovery. A
negative return skips the core rebase, so a callback returning an error
must leave coherent pointer state even after partial work.

Linked RESET and prepare stop at the first error without rollback.
Earlier callback members may already have completed. Legacy members keep
the existing post_action policy. Applications must recover the group
after partial failure before relying on shared positions.

This adds an internal kernel operation and no userspace ioctl or layout.
Out-of-tree modules using snd_pcm_ops need to be rebuilt.

Complete appl_ptr rebasing once in the callback path. A later linked
member can sleep in prepare while the earlier member accepts SYNC_PTR; a
subsequent unlocked post_prepare assignment would overwrite that
acknowledgment. Keep explicit RESET playback silence processing and
leave prepare-time filling to the normal START path, preserving samples
written and rewound after prepare.

Assisted-by: LLM
Signed-off-by: Joonho Lee <mynameisjune111@gmail.com>
---
 include/sound/pcm.h     | 21 +++++++++++++++++++++
 sound/core/pcm_lib.c    | 29 ++++++++++++++++++++++++-----
 sound/core/pcm_native.c | 45 ++++++++++++++++++++++++++++++++++++++++-----
 3 files changed, 85 insertions(+), 10 deletions(-)

diff --git a/include/sound/pcm.h b/include/sound/pcm.h
index 965be5603729..6c386d576841 100644
--- a/include/sound/pcm.h
+++ b/include/sound/pcm.h
@@ -77,6 +77,26 @@ struct snd_pcm_ops {
 			     unsigned long offset);
 	int (*mmap)(struct snd_pcm_substream *substream, struct vm_area_struct *vma);
 	int (*ack)(struct snd_pcm_substream *substream);
+	/*
+	 * Optional RESET operation, also used after a successful prepare.
+	 * Called with this substream's PCM lock held; atomic streams must not
+	 * sleep. Do not reacquire the PCM lock through snd_pcm_lib_ioctl().
+	 * snd_pcm_lib_reset() provides the common pointer update under this
+	 * lock. The core completes the position and appl_ptr rebase before
+	 * unlocking a successful member.
+	 *
+	 * Return zero to let the core complete the position rebase. As with
+	 * the legacy RESET ioctl, zero does not guarantee recovery from XRUN;
+	 * callers must still handle the stream state and subsequent I/O errors.
+	 * On a negative return the core does not finish the rebase, so the
+	 * callback must leave coherent pointer state even after partial work.
+	 *
+	 * Linked RESET/prepare
+	 * stops at the first error without rollback. Earlier callback members
+	 * retain their completed reset; legacy members retain the existing
+	 * post_action policy. An error does not guarantee unchanged state.
+	 */
+	int (*reset)(struct snd_pcm_substream *substream);
 };
 
 /*
@@ -1179,6 +1199,7 @@ static inline void snd_pcm_set_sync(struct snd_pcm_substream *substream)
 {
 	substream->runtime->std_sync_id = true;
 }
+int snd_pcm_lib_reset(struct snd_pcm_substream *substream);
 int snd_pcm_lib_ioctl(struct snd_pcm_substream *substream,
 		      unsigned int cmd, void *arg);                      
 void snd_pcm_period_elapsed_under_stream_lock(struct snd_pcm_substream *substream);
diff --git a/sound/core/pcm_lib.c b/sound/core/pcm_lib.c
index 4fb581b03480..c751f7dad1d3 100644
--- a/sound/core/pcm_lib.c
+++ b/sound/core/pcm_lib.c
@@ -1766,14 +1766,25 @@ int snd_pcm_hw_params_bits(const struct snd_pcm_hw_params *p)
 }
 EXPORT_SYMBOL(snd_pcm_hw_params_bits);
 
-static int snd_pcm_lib_ioctl_reset(struct snd_pcm_substream *substream,
-				   void *arg)
+/**
+ * snd_pcm_lib_reset - Reset the pointer while holding the PCM stream lock
+ * @substream: PCM substream
+ *
+ * Context: PCM stream lock held. The caller must not hold driver locks
+ * acquired by the pointer or XRUN callbacks.
+ *
+ * Update a running stream through the ordinary pointer path. Other states
+ * start at zero. Pointer errors keep the existing RESET return semantics;
+ * a zero return does not imply recovery from XRUN.
+ * This helper does not update appl_ptr or acquire the stream lock.
+ *
+ * Return: zero.
+ */
+int snd_pcm_lib_reset(struct snd_pcm_substream *substream)
 {
 	struct snd_pcm_runtime *runtime = substream->runtime;
 
-	guard(pcm_stream_lock_irqsave)(substream);
-	if (snd_pcm_running(substream) &&
-	    snd_pcm_update_hw_ptr(substream) >= 0)
+	if (snd_pcm_running(substream) && snd_pcm_update_hw_ptr(substream) >= 0)
 		runtime->status->hw_ptr %= runtime->buffer_size;
 	else {
 		runtime->status->hw_ptr = 0;
@@ -1781,6 +1792,14 @@ static int snd_pcm_lib_ioctl_reset(struct snd_pcm_substream *substream,
 	}
 	return 0;
 }
+EXPORT_SYMBOL(snd_pcm_lib_reset);
+
+static int snd_pcm_lib_ioctl_reset(struct snd_pcm_substream *substream,
+				   void *arg)
+{
+	guard(pcm_stream_lock_irqsave)(substream);
+	return snd_pcm_lib_reset(substream);
+}
 
 static int snd_pcm_lib_ioctl_channel_info(struct snd_pcm_substream *substream,
 					  void *arg)
diff --git a/sound/core/pcm_native.c b/sound/core/pcm_native.c
index a2ea44c3c1d2..a547ac720b51 100644
--- a/sound/core/pcm_native.c
+++ b/sound/core/pcm_native.c
@@ -1984,11 +1984,35 @@ static int snd_pcm_pre_reset(struct snd_pcm_substream *substream,
 	}
 }
 
-static int snd_pcm_do_reset(struct snd_pcm_substream *substream,
-			    snd_pcm_state_t state)
+static int snd_pcm_reset_substream(struct snd_pcm_substream *substream,
+				   bool for_prepare)
 {
 	struct snd_pcm_runtime *runtime = substream->runtime;
-	int err = snd_pcm_ops_ioctl(substream, SNDRV_PCM_IOCTL1_RESET, NULL);
+	int err;
+
+	if (substream->ops->reset) {
+		/*
+		 * Complete this member before releasing its PCM lock. A later
+		 * linked member may fail; RESET has no group rollback operation.
+		 */
+		guard(pcm_stream_lock_irq)(substream);
+
+		err = substream->ops->reset(substream);
+		if (err < 0)
+			return err;
+		runtime->hw_ptr_base = 0;
+		runtime->hw_ptr_interrupt = runtime->status->hw_ptr -
+			runtime->status->hw_ptr % runtime->period_size;
+		runtime->silence_start = runtime->status->hw_ptr;
+		runtime->silence_filled = 0;
+		runtime->control->appl_ptr = runtime->status->hw_ptr;
+		if (!for_prepare && substream->stream == SNDRV_PCM_STREAM_PLAYBACK &&
+		    runtime->silence_size > 0)
+			snd_pcm_playback_silence(substream, ULONG_MAX);
+		return 0;
+	}
+
+	err = snd_pcm_ops_ioctl(substream, SNDRV_PCM_IOCTL1_RESET, NULL);
 	if (err < 0)
 		return err;
 	guard(pcm_stream_lock_irq)(substream);
@@ -2000,10 +2024,19 @@ static int snd_pcm_do_reset(struct snd_pcm_substream *substream,
 	return 0;
 }
 
+static int snd_pcm_do_reset(struct snd_pcm_substream *substream,
+			    snd_pcm_state_t state)
+{
+	return snd_pcm_reset_substream(substream, false);
+}
+
 static void snd_pcm_post_reset(struct snd_pcm_substream *substream,
 			       snd_pcm_state_t state)
 {
 	struct snd_pcm_runtime *runtime = substream->runtime;
+
+	if (substream->ops->reset)
+		return;
 	guard(pcm_stream_lock_irq)(substream);
 	runtime->control->appl_ptr = runtime->status->hw_ptr;
 	if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK &&
@@ -2053,14 +2086,16 @@ static int snd_pcm_do_prepare(struct snd_pcm_substream *substream,
 	if (err < 0)
 		return err;
 	pcm_qos_req_update(substream, period_to_usecs(substream->runtime));
-	return snd_pcm_do_reset(substream, state);
+	return snd_pcm_reset_substream(substream, true);
 }
 
 static void snd_pcm_post_prepare(struct snd_pcm_substream *substream,
 				 snd_pcm_state_t state)
 {
 	struct snd_pcm_runtime *runtime = substream->runtime;
-	runtime->control->appl_ptr = runtime->status->hw_ptr;
+	/* The reset callback path already completed this rebase under the lock. */
+	if (!substream->ops->reset)
+		runtime->control->appl_ptr = runtime->status->hw_ptr;
 	snd_pcm_set_state(substream, SNDRV_PCM_STATE_PREPARED);
 }
 

-- 
Git-157)

