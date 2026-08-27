From: Nick Faro <yux50000@hotmail.com>
Date: Thu, 27 Aug 2026 19:44:12 +0200
Subject: [PATCH 2/6] media: cx231xx: stop resubmitting URBs after
 disconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-cx231xx-disconnect-lifetime-v1-2-7bbf946bbd36@hotmail.com>
References: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
In-Reply-To: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nick Faro <yux50000@hotmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787852712; l=3674;
 i=yux50000@hotmail.com; s=20260827; h=from:subject:message-id;
 bh=2Ru5eg+WVX8Q1bap6mSISOc5AFov0+AcLBFgPkvKzfA=;
 b=uu6yy4V69LYNf4+ZbRl3wBC//XBslOO0v/du/JGOAy8HALqEsTJGO2Fg4QKF1ZVzO+aiqLNE+
 oSPqDporgUAAWZnO3Z3HeLnwIPgeArPwbxZUSWxq227UO0nwfCA+UXc
X-Developer-Key: i=yux50000@hotmail.com; a=ed25519;
 pk=FMSCCFHmUW8ylFpPOeaegUBqrRhzdMS2snqX/kNbLtM=
X-Endpoint-Received: by B4 Relay for yux50000@hotmail.com/20260827 with auth_id=979
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

URB completion handlers normally resubmit transfers after processing. A
completion can race with disconnect after the device has been marked gone,
causing the transfer loop to continue while teardown kills and frees URBs.

Return from the video and VBI completion handlers once the device is
disconnected. Continue to kill and free existing transfers during teardown,
but skip endpoint resets and capture commands that require live hardware.

Fixes: e0d3bafd0258 ("V4L/DVB (10954): Add cx231xx USB driver")
Assisted-by: Codex:gpt-5.6-sol
Signed-off-by: Nick Faro <yux50000@hotmail.com>
---
 drivers/media/usb/cx231xx/cx231xx-core.c | 16 ++++++++++++++--
 drivers/media/usb/cx231xx/cx231xx-vbi.c  |  6 ++++++
 2 files changed, 20 insertions(+), 2 deletions(-)

diff --git a/drivers/media/usb/cx231xx/cx231xx-core.c b/drivers/media/usb/cx231xx/cx231xx-core.c
index d8312201694f..462eb4c7564e 100644
--- a/drivers/media/usb/cx231xx/cx231xx-core.c
+++ b/drivers/media/usb/cx231xx/cx231xx-core.c
@@ -785,6 +785,9 @@ static void cx231xx_isoc_irq_callback(struct urb *urb)
 	unsigned long flags;
 	int i;
 
+	if (dev->state & DEV_DISCONNECTED)
+		return;
+
 	switch (urb->status) {
 	case 0:		/* success */
 	case -ETIMEDOUT:	/* NAK */
@@ -830,6 +833,9 @@ static void cx231xx_bulk_irq_callback(struct urb *urb)
 	struct cx231xx *dev = container_of(vmode, struct cx231xx, video_mode);
 	unsigned long flags;
 
+	if (dev->state & DEV_DISCONNECTED)
+		return;
+
 	switch (urb->status) {
 	case 0:		/* success */
 	case -ETIMEDOUT:	/* NAK */
@@ -895,7 +901,7 @@ void cx231xx_uninit_isoc(struct cx231xx *dev)
 		dev->video_mode.isoc_ctl.transfer_buffer[i] = NULL;
 	}
 
-	if (broken_pipe) {
+	if (broken_pipe && !(dev->state & DEV_DISCONNECTED)) {
 		cx231xx_isocdbg("Reset endpoint to recover broken pipe.");
 		usb_reset_endpoint(dev->udev, dev->video_mode.end_point_addr);
 	}
@@ -908,6 +914,9 @@ void cx231xx_uninit_isoc(struct cx231xx *dev)
 	dev->video_mode.isoc_ctl.num_bufs = 0;
 	dma_q->p_left_data = NULL;
 
+	if (dev->state & DEV_DISCONNECTED)
+		return;
+
 	if (dev->mode_tv == 0)
 		cx231xx_capture_start(dev, 0, Raw_Video);
 	else
@@ -954,7 +963,7 @@ void cx231xx_uninit_bulk(struct cx231xx *dev)
 		dev->video_mode.bulk_ctl.transfer_buffer[i] = NULL;
 	}
 
-	if (broken_pipe) {
+	if (broken_pipe && !(dev->state & DEV_DISCONNECTED)) {
 		cx231xx_isocdbg("Reset endpoint to recover broken pipe.");
 		usb_reset_endpoint(dev->udev, dev->video_mode.end_point_addr);
 	}
@@ -967,6 +976,9 @@ void cx231xx_uninit_bulk(struct cx231xx *dev)
 	dev->video_mode.bulk_ctl.num_bufs = 0;
 	dma_q->p_left_data = NULL;
 
+	if (dev->state & DEV_DISCONNECTED)
+		return;
+
 	if (dev->mode_tv == 0)
 		cx231xx_capture_start(dev, 0, Raw_Video);
 	else
diff --git a/drivers/media/usb/cx231xx/cx231xx-vbi.c b/drivers/media/usb/cx231xx/cx231xx-vbi.c
index 338e10148465..b51955f1dd30 100644
--- a/drivers/media/usb/cx231xx/cx231xx-vbi.c
+++ b/drivers/media/usb/cx231xx/cx231xx-vbi.c
@@ -260,6 +260,9 @@ static void cx231xx_irq_vbi_callback(struct urb *urb)
 	struct cx231xx *dev = container_of(vmode, struct cx231xx, vbi_mode);
 	unsigned long flags;
 
+	if (dev->state & DEV_DISCONNECTED)
+		return;
+
 	switch (urb->status) {
 	case 0:		/* success */
 	case -ETIMEDOUT:	/* NAK */
@@ -328,6 +331,9 @@ void cx231xx_uninit_vbi_isoc(struct cx231xx *dev)
 	dev->vbi_mode.bulk_ctl.transfer_buffer = NULL;
 	dev->vbi_mode.bulk_ctl.num_bufs = 0;
 
+	if (dev->state & DEV_DISCONNECTED)
+		return;
+
 	cx231xx_capture_start(dev, 0, Vbi);
 }
 EXPORT_SYMBOL_GPL(cx231xx_uninit_vbi_isoc);

-- 
2.43.0

