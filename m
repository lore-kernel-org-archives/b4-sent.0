From: Nick Faro <yux50000@hotmail.com>
Date: Thu, 27 Aug 2026 19:44:14 +0200
Subject: [PATCH 4/6] media: cx231xx: make ALSA teardown disconnect-safe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-cx231xx-disconnect-lifetime-v1-4-7bbf946bbd36@hotmail.com>
References: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
In-Reply-To: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nick Faro <yux50000@hotmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787852712; l=3100;
 i=yux50000@hotmail.com; s=20260827; h=from:subject:message-id;
 bh=2wJ7fv8GuAFzsZR7lLL6TpM9/IcmchnjsNHHBj9K50o=;
 b=oo4zrYhdeUJ7VUQxDmUUJjozwjG0+7VrfPlglj1FLeSZ/YhyF2DETdgIdlDDkLPqSXnuIgfF4
 RM8jj4GPt70BaO3VclaTVIhz5wz7NUMc/QwXlHFOZwvbcGZZDMOzGAd
X-Developer-Key: i=yux50000@hotmail.com; a=ed25519;
 pk=FMSCCFHmUW8ylFpPOeaegUBqrRhzdMS2snqX/kNbLtM=
X-Endpoint-Received: by B4 Relay for yux50000@hotmail.com/20260827 with auth_id=979
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ALSA card and an open PCM file can outlive the USB interface. Work
items, PCM callbacks and close currently remain able to touch the hardware
after disconnect, and card teardown does not actively disconnect userspace.

Disconnect the ALSA card and stop its stream and transfers. Cancel its
trigger work before deferring the final card release. Make late PCM
callbacks report the disconnected state and let close release software
state without issuing hardware commands.

Fixes: e0d3bafd0258 ("V4L/DVB (10954): Add cx231xx USB driver")
Assisted-by: Codex:gpt-5.6-sol
Signed-off-by: Nick Faro <yux50000@hotmail.com>
---
 drivers/media/usb/cx231xx/cx231xx-audio.c | 31 +++++++++++++++++++++++++++++--
 1 file changed, 29 insertions(+), 2 deletions(-)

diff --git a/drivers/media/usb/cx231xx/cx231xx-audio.c b/drivers/media/usb/cx231xx/cx231xx-audio.c
index dd819a546af9..a10b887edf51 100644
--- a/drivers/media/usb/cx231xx/cx231xx-audio.c
+++ b/drivers/media/usb/cx231xx/cx231xx-audio.c
@@ -448,10 +448,17 @@ static int snd_cx231xx_pcm_close(struct snd_pcm_substream *substream)
 		return -ENODEV;
 	}
 
-	dev_dbg(dev->dev, "closing device\n");
-
 	/* inform hardware to stop streaming */
 	mutex_lock(&dev->lock);
+	dev->adev.capture_pcm_substream = NULL;
+	if (dev->state & DEV_DISCONNECTED) {
+		dev->adev.users--;
+		mutex_unlock(&dev->lock);
+		cancel_work_sync(&dev->wq_trigger);
+		return 0;
+	}
+
+	dev_dbg(dev->dev, "closing device\n");
 	ret = cx231xx_capture_start(dev, 0, Audio);
 
 	/* set alternate setting for audio interface */
@@ -485,6 +492,9 @@ static int snd_cx231xx_prepare(struct snd_pcm_substream *substream)
 {
 	struct cx231xx *dev = snd_pcm_substream_chip(substream);
 
+	if (dev->state & DEV_DISCONNECTED)
+		return -ENODEV;
+
 	dev->adev.hwptr_done_capture = 0;
 	dev->adev.capture_transfer_done = 0;
 
@@ -495,6 +505,14 @@ static void audio_trigger(struct work_struct *work)
 {
 	struct cx231xx *dev = container_of(work, struct cx231xx, wq_trigger);
 
+	if (dev->state & DEV_DISCONNECTED) {
+		if (dev->USE_ISO)
+			cx231xx_isoc_audio_deinit(dev);
+		else
+			cx231xx_bulk_audio_deinit(dev);
+		return;
+	}
+
 	if (atomic_read(&dev->stream_started)) {
 		dev_dbg(dev->dev, "starting capture");
 		if (is_fw_load(dev) == 0)
@@ -545,6 +563,8 @@ static snd_pcm_uframes_t snd_cx231xx_capture_pointer(struct snd_pcm_substream
 	snd_pcm_uframes_t hwptr_done;
 
 	dev = snd_pcm_substream_chip(substream);
+	if (dev->state & DEV_DISCONNECTED)
+		return SNDRV_PCM_POS_XRUN;
 
 	spin_lock_irqsave(&dev->adev.slock, flags);
 	hwptr_done = dev->adev.hwptr_done_capture;
@@ -689,6 +709,13 @@ static int cx231xx_audio_fini(struct cx231xx *dev)
 	if (dev->adev.sndcard) {
 		card = dev->adev.sndcard;
 		dev->adev.sndcard = NULL;
+		snd_card_disconnect(card);
+		atomic_set(&dev->stream_started, 0);
+		cancel_work_sync(&dev->wq_trigger);
+		if (dev->USE_ISO)
+			cx231xx_isoc_audio_deinit(dev);
+		else
+			cx231xx_bulk_audio_deinit(dev);
 		snd_card_free_when_closed(card);
 	}
 

-- 
2.43.0

