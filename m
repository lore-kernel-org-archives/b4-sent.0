From: Nick Faro <yux50000@hotmail.com>
Date: Thu, 27 Aug 2026 19:44:15 +0200
Subject: [PATCH 5/6] media: cx231xx: always unregister nodes on USB
 disconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-cx231xx-disconnect-lifetime-v1-5-7bbf946bbd36@hotmail.com>
References: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
In-Reply-To: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nick Faro <yux50000@hotmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787852712; l=5250;
 i=yux50000@hotmail.com; s=20260827; h=from:subject:message-id;
 bh=lfYMdUVPkBvAiiFLQfWpvqyr8TfO0f8rtCgH5KZb5Kk=;
 b=QcsLRD7jwBhZLD3x9enMGFZKq90mt713EljTrvGk0P4MwqGVCBZViLyEhidR+GLnjZieYsSA0
 1WoRYO08rwyDwEOkDm+Nh7ZfKcXMcsMWehf4Rb9Hf1g/K7OpFaENMeE
X-Developer-Key: i=yux50000@hotmail.com; a=ed25519;
 pk=FMSCCFHmUW8ylFpPOeaegUBqrRhzdMS2snqX/kNbLtM=
X-Endpoint-Received: by B4 Relay for yux50000@hotmail.com/20260827 with auth_id=979
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The disconnect path skips cx231xx_release_resources() whenever an analog
video file is open. No close path performs the deferred teardown, so the
V4L2 nodes and I2C adapters remain registered and a later probe collides
with the stale instance. The users counter also does not cover MPEG, ALSA
or other framework references.

Always unregister every device node and subsystem during disconnect. Use
the VB2 unregister helper for queue-backed nodes so active streams are
stopped, and serialize disconnection against in-flight file operations.
The v4l2_device references now keep the backing memory alive until old
file handles close.

Fixes: e0d3bafd0258 ("V4L/DVB (10954): Add cx231xx USB driver")
Assisted-by: Codex:gpt-5.6-sol
Signed-off-by: Nick Faro <yux50000@hotmail.com>
---
 drivers/media/usb/cx231xx/cx231xx-417.c   |  2 +-
 drivers/media/usb/cx231xx/cx231xx-cards.c | 11 +++++------
 drivers/media/usb/cx231xx/cx231xx-video.c | 10 +++++-----
 drivers/media/usb/cx231xx/cx231xx.h       |  1 +
 4 files changed, 12 insertions(+), 12 deletions(-)

diff --git a/drivers/media/usb/cx231xx/cx231xx-417.c b/drivers/media/usb/cx231xx/cx231xx-417.c
index 3a509e55f61d..9bda68666b05 100644
--- a/drivers/media/usb/cx231xx/cx231xx-417.c
+++ b/drivers/media/usb/cx231xx/cx231xx-417.c
@@ -1672,7 +1672,7 @@ void cx231xx_417_unregister(struct cx231xx *dev)
 	dprintk(3, "%s()\n", __func__);
 
 	if (video_is_registered(&dev->v4l_device)) {
-		video_unregister_device(&dev->v4l_device);
+		vb2_video_unregister_device(&dev->v4l_device);
 	}
 }
 
diff --git a/drivers/media/usb/cx231xx/cx231xx-cards.c b/drivers/media/usb/cx231xx/cx231xx-cards.c
index 1b1e7bca4c6d..8e23de4cddf8 100644
--- a/drivers/media/usb/cx231xx/cx231xx-cards.c
+++ b/drivers/media/usb/cx231xx/cx231xx-cards.c
@@ -1946,7 +1946,6 @@ static int cx231xx_usb_probe(struct usb_interface *interface,
 	cx231xx_close_extension(dev);
 	cx231xx_ir_exit(dev);
 	cx231xx_release_analog_resources(dev);
-	cx231xx_417_unregister(dev);
 	cx231xx_remove_from_devlist(dev);
 	cx231xx_dev_uninit(dev);
 err_init:
@@ -1970,7 +1969,8 @@ static int cx231xx_usb_probe(struct usb_interface *interface,
 /*
  * cx231xx_usb_disconnect()
  * called when the device gets disconnected
- * video device will be unregistered on v4l2_close in case it is still open
+ * Device nodes are unregistered immediately. Their backing memory remains
+ * alive until the last open file descriptor is closed.
  */
 static void cx231xx_usb_disconnect(struct usb_interface *interface)
 {
@@ -1997,7 +1997,7 @@ static void cx231xx_usb_disconnect(struct usb_interface *interface)
 
 	if (dev->users) {
 		dev_warn(dev->dev,
-			 "device %s is open! Deregistration and memory deallocation are deferred on close.\n",
+			 "device %s is open; disconnecting it now\n",
 			 video_device_node_name(&dev->vdev));
 
 		/* Even having users, it is safe to remove the RC i2c driver */
@@ -2007,17 +2007,16 @@ static void cx231xx_usb_disconnect(struct usb_interface *interface)
 			cx231xx_uninit_isoc(dev);
 		else
 			cx231xx_uninit_bulk(dev);
+		cx231xx_uninit_vbi_isoc(dev);
 		wake_up_interruptible(&dev->wait_frame);
 		wake_up_interruptible(&dev->wait_stream);
-	} else {
 	}
 
 	cx231xx_close_extension(dev);
 
 	mutex_unlock(&dev->lock);
 
-	if (!dev->users)
-		cx231xx_release_resources(dev);
+	cx231xx_release_resources(dev);
 }
 
 static struct usb_driver cx231xx_usb_driver = {
diff --git a/drivers/media/usb/cx231xx/cx231xx-video.c b/drivers/media/usb/cx231xx/cx231xx-video.c
index 154bb4300392..c8c460da2b9a 100644
--- a/drivers/media/usb/cx231xx/cx231xx-video.c
+++ b/drivers/media/usb/cx231xx/cx231xx-video.c
@@ -1561,21 +1561,21 @@ void cx231xx_release_analog_resources(struct cx231xx *dev)
 
 	/*FIXME: I2C IR should be disconnected */
 
+	if (dev->board.has_417)
+		cx231xx_417_unregister(dev);
+
 	if (video_is_registered(&dev->radio_dev))
 		video_unregister_device(&dev->radio_dev);
 	if (video_is_registered(&dev->vbi_dev)) {
 		dev_info(dev->dev, "V4L2 device %s deregistered\n",
 			video_device_node_name(&dev->vbi_dev));
-		video_unregister_device(&dev->vbi_dev);
+		vb2_video_unregister_device(&dev->vbi_dev);
 	}
 	if (video_is_registered(&dev->vdev)) {
 		dev_info(dev->dev, "V4L2 device %s deregistered\n",
 			video_device_node_name(&dev->vdev));
 
-		if (dev->board.has_417)
-			cx231xx_417_unregister(dev);
-
-		video_unregister_device(&dev->vdev);
+		vb2_video_unregister_device(&dev->vdev);
 	}
 }
 
diff --git a/drivers/media/usb/cx231xx/cx231xx.h b/drivers/media/usb/cx231xx/cx231xx.h
index 19f5036a78d7..8fb1eb9d600e 100644
--- a/drivers/media/usb/cx231xx/cx231xx.h
+++ b/drivers/media/usb/cx231xx/cx231xx.h
@@ -873,6 +873,7 @@ void cx231xx_stop_TS1(struct cx231xx *dev);
 void cx231xx_start_TS1(struct cx231xx *dev);
 void cx231xx_uninit_isoc(struct cx231xx *dev);
 void cx231xx_uninit_bulk(struct cx231xx *dev);
+void cx231xx_uninit_vbi_isoc(struct cx231xx *dev);
 int cx231xx_set_mode(struct cx231xx *dev, enum cx231xx_mode set_mode);
 int cx231xx_unmute_audio(struct cx231xx *dev);
 int cx231xx_ep5_bulkout(struct cx231xx *dev, u8 *firmware, u16 size);

-- 
2.43.0

