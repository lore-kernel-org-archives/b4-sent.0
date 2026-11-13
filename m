From: Joonho Lee <mynameisjune111@gmail.com>
Date: Fri, 13 Nov 2026 15:42:03 +0900
Subject: [PATCH v32 19/20] ALSA: pcm: allow stream suspension without power
 management
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-fix-virtio-snd-recovery-final-v32-19-4e95979e312c@gmail.com>
References: <20261113-fix-virtio-snd-recovery-final-v32-0-4e95979e312c@gmail.com>
In-Reply-To: <20261113-fix-virtio-snd-recovery-final-v32-0-4e95979e312c@gmail.com>
To: linux-sound@vger.kernel.org
Cc: tiwai@suse.com, perex@perex.cz, mst@redhat.com, 
 virtualization@lists.linux.dev, linux-kernel@vger.kernel.org, 
 corbet@lwn.net, skhan@linuxfoundation.org, rdunlap@infradead.org, 
 linux-doc@vger.kernel.org, Joonho Lee <mynameisjune111@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794552109; l=2166;
 i=mynameisjune111@gmail.com; s=default; h=from:subject:message-id;
 bh=3exDiH1TdiDmPhJt/w3j/w6DMwZbWLwqVdLqWOiTBTU=;
 b=bfJByh7/8yxMt79AqWrFUhmZADY2F3J6v8pSvc/UXtlzHhtE0z0kJvBK0Y78zWsUs8qROpC6T
 DtNP3WzIx8yBfwg2HXmb104xQZOy/3WKpR/Urb/DCMKBTEhziCyY/wQ
X-Developer-Key: i=mynameisjune111@gmail.com; a=ed25519;
 pk=wqkZdvfcC8g8fDi6f0Y58LlaXIo+ubf6Y/9Lr9yhshc=
X-Endpoint-Received: by B4 Relay for mynameisjune111@gmail.com/default with auth_id=1508
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Device recovery needs to suspend PCM streams even when CONFIG_PM is disabled. The no-op snd_pcm_suspend_all() stub leaves active streams running while virtio-snd resets their queues, so an application sees an I/O failure instead of the suspended state needed for prepare and recovery.

Build the logical stream suspension operation independently of power management. Keep system resume support conditional on CONFIG_PM.

Assisted-by: LLM
Signed-off-by: Joonho Lee <mynameisjune111@gmail.com>
---
 include/sound/pcm.h     | 7 -------
 sound/core/pcm_native.c | 2 +-
 2 files changed, 1 insertion(+), 8 deletions(-)

diff --git a/include/sound/pcm.h b/include/sound/pcm.h
index 7150f8356dc8..cdbde0524dd4 100644
--- a/include/sound/pcm.h
+++ b/include/sound/pcm.h
@@ -628,14 +628,7 @@ int snd_pcm_start(struct snd_pcm_substream *substream);
 int snd_pcm_stop(struct snd_pcm_substream *substream, snd_pcm_state_t status);
 int snd_pcm_drain_done(struct snd_pcm_substream *substream);
 int snd_pcm_stop_xrun(struct snd_pcm_substream *substream);
-#ifdef CONFIG_PM
 int snd_pcm_suspend_all(struct snd_pcm *pcm);
-#else
-static inline int snd_pcm_suspend_all(struct snd_pcm *pcm)
-{
-	return 0;
-}
-#endif
 int snd_pcm_kernel_ioctl(struct snd_pcm_substream *substream, unsigned int cmd, void *arg);
 int snd_pcm_open_substream(struct snd_pcm *pcm, int stream, struct file *file,
 			   struct snd_pcm_substream **rsubstream);
diff --git a/sound/core/pcm_native.c b/sound/core/pcm_native.c
index 8131a7be5dfd..a1c13647a14c 100644
--- a/sound/core/pcm_native.c
+++ b/sound/core/pcm_native.c
@@ -1828,7 +1828,6 @@ static int snd_pcm_pause_lock_irq(struct snd_pcm_substream *substream,
 				       (snd_pcm_state_t)push);
 }
 
-#ifdef CONFIG_PM
 /* suspend callback: state argument ignored */
 
 static int snd_pcm_pre_suspend(struct snd_pcm_substream *substream,
@@ -1939,6 +1938,7 @@ int snd_pcm_suspend_all(struct snd_pcm *pcm)
 }
 EXPORT_SYMBOL(snd_pcm_suspend_all);
 
+#ifdef CONFIG_PM
 /* resume callbacks: state argument ignored */
 
 static int snd_pcm_pre_resume(struct snd_pcm_substream *substream,

-- 
Git-157)

