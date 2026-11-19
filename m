From: Yasunobu Sakashita <hi@yasunobu.dev>
Date: Thu, 19 Nov 2026 20:44:56 +0900
Subject: [PATCH] media: uvcvideo: Batch StreamCam unlinks on ASUS ASM2142
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-streamcam-batched-unlink-v1-1-076bc02866c1@yasunobu.dev>
X-B4-Tracking: v=1; b=H4sIADfh/moC/yWMQQrCMBBFr1Jm7YCJEqhXEReTdGqidpRMWgqld
 zfR5fv89zZQzokVLt0GmZek6S0VzKGDEEnujGmoDPZonTGmRy2ZaQo0oacSIg84yyvJE0d/Jse
 n3lnHUPVP5jGtv/T19med/YNDab328KSMPpOE2CbhtcC+fwGU/I6fkwAAAA==
X-Change-ID: 20261119-streamcam-batched-unlink-fb4a6e39626e
To: linux-media@vger.kernel.org
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans de Goede <hansg@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Mathias Nyman <mathias.nyman@intel.com>, linux-usb@vger.kernel.org, 
 Yasunobu Sakashita <hi@yasunobu.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795088699; l=3387;
 i=hi@yasunobu.dev; s=linux-kernel; h=from:subject:message-id;
 bh=SM/F5q1dd2vyprkfGis4uWr1Bm42nEAIAtBJ4e6DG4M=;
 b=I9BApyP7CrZMcyE67xRmVhF+o4Qfb7NeHa7K21IK2F7ww7GGWsFrDUNCjCZrDlQVuTj6I55uk
 JhUduYDGWayBlHnEU3m24BcDXHfiMspq6gZ7Z1swHNKtiW+VXJqEBFR
X-Developer-Key: i=hi@yasunobu.dev; a=ed25519;
 pk=QjththR6KbbJLxSuYvQ/eDo4hRrutwL7BdLamwrIW9c=
X-Endpoint-Received: by B4 Relay for hi@yasunobu.dev/linux-kernel with auth_id=1570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Stopping a SuperSpeed StreamCam can halt xHCI on the ASUS PRIME Z270-A.
The fifth Stop Endpoint command timed out after an invalid type 15 event.

For the affected StreamCam and ASM2142, block URB resubmission.
Queue all unlinks before waiting so xHCI can coalesce them.

The stock driver reproduced the halt on Ubuntu 6.8.0-149-generic.
Three FFmpeg 720p MJPEG and audio capture cycles passed with the patch.

I used Codex to help analyze traces and draft the patch and changelog.

Signed-off-by: Yasunobu Sakashita <hi@yasunobu.dev>
---
Built uvc_video.o on media-committers/next with and without CONFIG_PCI.
---
 drivers/media/usb/uvc/uvc_video.c | 43 ++++++++++++++++++++++++++++++++++-----
 1 file changed, 38 insertions(+), 5 deletions(-)

diff --git a/drivers/media/usb/uvc/uvc_video.c b/drivers/media/usb/uvc/uvc_video.c
index a92a986ab..0ee5a7d17 100644
--- a/drivers/media/usb/uvc/uvc_video.c
+++ b/drivers/media/usb/uvc/uvc_video.c
@@ -11,6 +11,7 @@
 #include <linux/kernel.h>
 #include <linux/list.h>
 #include <linux/module.h>
+#include <linux/pci.h>
 #include <linux/slab.h>
 #include <linux/usb.h>
 #include <linux/usb/hcd.h>
@@ -1885,6 +1886,26 @@ static int uvc_alloc_urb_buffers(struct uvc_streaming *stream,
 	return 0;
 }
 
+static bool uvc_streamcam_batch_unlink(const struct uvc_streaming *stream)
+{
+	const struct usb_device *udev = stream->dev->udev;
+	struct device *controller = udev->bus->controller;
+	const struct pci_dev *pdev;
+
+	if (stream->frozen || udev->state != USB_STATE_CONFIGURED ||
+	    udev->speed != USB_SPEED_SUPER ||
+	    le16_to_cpu(udev->descriptor.idVendor) != 0x046d ||
+	    le16_to_cpu(udev->descriptor.idProduct) != 0x0893 ||
+	    !controller || !dev_is_pci(controller))
+		return false;
+
+	pdev = to_pci_dev(controller);
+	return pdev->vendor == PCI_VENDOR_ID_ASMEDIA &&
+	       pdev->device == 0x2142 &&
+	       pdev->subsystem_vendor == PCI_VENDOR_ID_ASUSTEK &&
+	       pdev->subsystem_device == 0x8732 && pdev->revision == 0;
+}
+
 /*
  * Uninitialize isochronous/bulk URBs and free transfer buffers.
  */
@@ -1896,12 +1917,24 @@ static void uvc_video_stop_transfer(struct uvc_streaming *stream,
 	uvc_video_stats_stop(stream);
 
 	/*
-	 * We must poison the URBs rather than kill them to ensure that even
-	 * after the completion handler returns, any asynchronous workqueues
-	 * will be prevented from resubmitting the URBs.
+	 * URBs must stay blocked until the workqueue has been flushed.
+	 * A completion handler can leave work that tries to resubmit an URB.
 	 */
-	for_each_uvc_urb(uvc_urb, stream)
-		usb_poison_urb(uvc_urb->urb);
+	if (uvc_streamcam_batch_unlink(stream)) {
+		/*
+		 * usb_block_urb() keeps URBs blocked after usb_kill_urb().
+		 * Queue unlinks together so xHCI can coalesce them.
+		 */
+		for_each_uvc_urb(uvc_urb, stream)
+			usb_block_urb(uvc_urb->urb);
+		for_each_uvc_urb(uvc_urb, stream)
+			usb_unlink_urb(uvc_urb->urb);
+		for_each_uvc_urb(uvc_urb, stream)
+			usb_kill_urb(uvc_urb->urb);
+	} else {
+		for_each_uvc_urb(uvc_urb, stream)
+			usb_poison_urb(uvc_urb->urb);
+	}
 
 	flush_workqueue(stream->async_wq);
 

---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261119-streamcam-batched-unlink-fb4a6e39626e

Best regards,
--  
Yasunobu Sakashita <hi@yasunobu.dev>

