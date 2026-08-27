From: Nick Faro <yux50000@hotmail.com>
Date: Thu, 27 Aug 2026 19:44:11 +0200
Subject: [PATCH 1/6] media: cx231xx: keep device state alive until final
 release
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-cx231xx-disconnect-lifetime-v1-1-7bbf946bbd36@hotmail.com>
References: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
In-Reply-To: <20260827-cx231xx-disconnect-lifetime-v1-0-7bbf946bbd36@hotmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nick Faro <yux50000@hotmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787852712; l=11644;
 i=yux50000@hotmail.com; s=20260827; h=from:subject:message-id;
 bh=w/AU95ECXvWftgDX5vGZLoQEfG7TvUvxOkb4vN+mino=;
 b=LxP2ECMWcPxM9xHsb5HBa7xMvoBYffnmi5qI3ue14yE9sepN1BEGYfHzpeqe+2JqZmkxDubT1
 MLmoO9O6vquAwrd0S8XslokX6rjRWWY9tYHJ7exGULAk6JzBJI4p0j6
X-Developer-Key: i=yux50000@hotmail.com; a=ed25519;
 pk=FMSCCFHmUW8ylFpPOeaegUBqrRhzdMS2snqX/kNbLtM=
X-Endpoint-Received: by B4 Relay for yux50000@hotmail.com/20260827 with auth_id=979
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The USB interface can be unbound while userspace still has a V4L2 or
ALSA device node open. Since struct cx231xx embeds the video devices and
is referenced by ALSA callbacks, interface-managed allocations have a
shorter lifetime than their users.

Allocate the shared device state and endpoint arrays explicitly. Use the
v4l2_device release callback as the single point that unregisters the
V4L2 device and frees its backing storage. Registered video nodes keep
their normal V4L2 references, while the ALSA card takes an additional
reference and is registered only after its endpoint data is ready.

Disconnect public interfaces during teardown, but defer control-handler
and media-device cleanup until the final reference is dropped. Update
probe unwinding to free directly before V4L2 registration and otherwise
drop the initial V4L2 reference.

Fixes: 184a82784d50 ("[media] cx231xx: use devm_ functions to allocate memory")
Assisted-by: Codex:gpt-5.6-sol
Signed-off-by: Nick Faro <yux50000@hotmail.com>
---
 drivers/media/usb/cx231xx/cx231xx-417.c   |  1 -
 drivers/media/usb/cx231xx/cx231xx-audio.c | 32 +++++++----
 drivers/media/usb/cx231xx/cx231xx-cards.c | 88 +++++++++++++++++++++++--------
 drivers/media/usb/cx231xx/cx231xx-video.c |  2 -
 4 files changed, 88 insertions(+), 35 deletions(-)

diff --git a/drivers/media/usb/cx231xx/cx231xx-417.c b/drivers/media/usb/cx231xx/cx231xx-417.c
index c695a97e202b..2323584bf818 100644
--- a/drivers/media/usb/cx231xx/cx231xx-417.c
+++ b/drivers/media/usb/cx231xx/cx231xx-417.c
@@ -1650,7 +1650,6 @@ void cx231xx_417_unregister(struct cx231xx *dev)
 
 	if (video_is_registered(&dev->v4l_device)) {
 		video_unregister_device(&dev->v4l_device);
-		v4l2_ctrl_handler_free(&dev->mpeg_ctrl_handler.hdl);
 	}
 }
 
diff --git a/drivers/media/usb/cx231xx/cx231xx-audio.c b/drivers/media/usb/cx231xx/cx231xx-audio.c
index b24ceef497e4..dd819a546af9 100644
--- a/drivers/media/usb/cx231xx/cx231xx-audio.c
+++ b/drivers/media/usb/cx231xx/cx231xx-audio.c
@@ -561,6 +561,15 @@ static const struct snd_pcm_ops snd_cx231xx_pcm_capture = {
 	.pointer = snd_cx231xx_capture_pointer,
 };
 
+static void cx231xx_audio_card_free(struct snd_card *card)
+{
+	struct cx231xx *dev = card->private_data;
+
+	kfree(dev->adev.alt_max_pkt_size);
+	dev->adev.alt_max_pkt_size = NULL;
+	v4l2_device_put(&dev->v4l2_dev);
+}
+
 static int cx231xx_audio_init(struct cx231xx *dev)
 {
 	struct cx231xx_audio *adev = &dev->adev;
@@ -585,6 +594,9 @@ static int cx231xx_audio_init(struct cx231xx *dev)
 			   THIS_MODULE, 0, &card);
 	if (err < 0)
 		return err;
+	v4l2_device_get(&dev->v4l2_dev);
+	card->private_data = dev;
+	card->private_free = cx231xx_audio_card_free;
 
 	spin_lock_init(&adev->slock);
 	err = snd_pcm_new(card, "Cx231xx Audio", 0, 0, 1, &pcm);
@@ -603,11 +615,6 @@ static int cx231xx_audio_init(struct cx231xx *dev)
 
 	INIT_WORK(&dev->wq_trigger, audio_trigger);
 
-	err = snd_card_register(card);
-	if (err < 0)
-		goto err_free_card;
-
-	adev->sndcard = card;
 	adev->udev = dev->udev;
 
 	/* compute alternate max packet sizes for Audio */
@@ -640,7 +647,7 @@ static int cx231xx_audio_init(struct cx231xx *dev)
 
 		if (uif->altsetting[i].desc.bNumEndpoints < isoc_pipe + 1) {
 			err = -ENODEV;
-			goto err_free_pkt_size;
+			goto err_free_card;
 		}
 
 		tmp = le16_to_cpu(uif->altsetting[i].endpoint[isoc_pipe].desc.
@@ -652,10 +659,13 @@ static int cx231xx_audio_init(struct cx231xx *dev)
 			adev->alt_max_pkt_size[i]);
 	}
 
+	err = snd_card_register(card);
+	if (err < 0)
+		goto err_free_card;
+
+	adev->sndcard = card;
 	return 0;
 
-err_free_pkt_size:
-	kfree(adev->alt_max_pkt_size);
 err_free_card:
 	snd_card_free(card);
 
@@ -664,6 +674,8 @@ static int cx231xx_audio_init(struct cx231xx *dev)
 
 static int cx231xx_audio_fini(struct cx231xx *dev)
 {
+	struct snd_card *card;
+
 	if (dev == NULL)
 		return 0;
 
@@ -675,9 +687,9 @@ static int cx231xx_audio_fini(struct cx231xx *dev)
 	}
 
 	if (dev->adev.sndcard) {
-		snd_card_free_when_closed(dev->adev.sndcard);
-		kfree(dev->adev.alt_max_pkt_size);
+		card = dev->adev.sndcard;
 		dev->adev.sndcard = NULL;
+		snd_card_free_when_closed(card);
 	}
 
 	return 0;
diff --git a/drivers/media/usb/cx231xx/cx231xx-cards.c b/drivers/media/usb/cx231xx/cx231xx-cards.c
index 69b24205bc56..1b1e7bca4c6d 100644
--- a/drivers/media/usb/cx231xx/cx231xx-cards.c
+++ b/drivers/media/usb/cx231xx/cx231xx-cards.c
@@ -1339,8 +1339,15 @@ void cx231xx_config_i2c(struct cx231xx *dev)
 static void cx231xx_unregister_media_device(struct cx231xx *dev)
 {
 #ifdef CONFIG_MEDIA_CONTROLLER
-	if (dev->media_dev) {
+	if (dev->media_dev)
 		media_device_unregister(dev->media_dev);
+#endif
+}
+
+static void cx231xx_cleanup_media_device(struct cx231xx *dev)
+{
+#ifdef CONFIG_MEDIA_CONTROLLER
+	if (dev->media_dev) {
 		media_device_cleanup(dev->media_dev);
 		kfree(dev->media_dev);
 		dev->media_dev = NULL;
@@ -1348,6 +1355,27 @@ static void cx231xx_unregister_media_device(struct cx231xx *dev)
 #endif
 }
 
+static void cx231xx_free_device(struct cx231xx *dev)
+{
+	kfree(dev->video_mode.alt_max_pkt_size);
+	kfree(dev->vbi_mode.alt_max_pkt_size);
+	kfree(dev->sliced_cc_mode.alt_max_pkt_size);
+	kfree(dev->ts1_mode.alt_max_pkt_size);
+	kfree(dev);
+}
+
+static void cx231xx_v4l2_release(struct v4l2_device *v4l2_dev)
+{
+	struct cx231xx *dev = container_of(v4l2_dev, struct cx231xx, v4l2_dev);
+
+	v4l2_ctrl_handler_free(&dev->mpeg_ctrl_handler.hdl);
+	v4l2_ctrl_handler_free(&dev->radio_ctrl_handler);
+	v4l2_ctrl_handler_free(&dev->ctrl_handler);
+	v4l2_device_unregister(v4l2_dev);
+	cx231xx_cleanup_media_device(dev);
+	cx231xx_free_device(dev);
+}
+
 /*
  * cx231xx_realease_resources()
  * unregisters the v4l2,i2c and usb devices
@@ -1359,18 +1387,23 @@ void cx231xx_release_resources(struct cx231xx *dev)
 
 	cx231xx_release_analog_resources(dev);
 
+	/* Wait for file operations that started before node removal. */
+	mutex_lock(&dev->lock);
+	v4l2_device_disconnect(&dev->v4l2_dev);
+	mutex_unlock(&dev->lock);
+
 	cx231xx_remove_from_devlist(dev);
 
 	/* Release I2C buses */
 	cx231xx_dev_uninit(dev);
 
-	/* delete v4l2 device */
-	v4l2_device_unregister(&dev->v4l2_dev);
-
 	cx231xx_unregister_media_device(dev);
 
-	/* Mark device as unused */
+	/* Mark the board slot unused before the final put can free dev. */
 	clear_bit(dev->devno, &cx231xx_devused);
+
+	/* Drop the initial reference after all nodes are unregistered. */
+	v4l2_device_put(&dev->v4l2_dev);
 }
 
 static int cx231xx_media_device_init(struct cx231xx *dev,
@@ -1544,7 +1577,6 @@ static void flush_request_modules(struct cx231xx *dev)
 
 static int cx231xx_init_v4l2(struct cx231xx *dev,
 			     struct usb_device *udev,
-			     struct usb_interface *interface,
 			     int isoc_pipe)
 {
 	struct usb_interface *uif;
@@ -1573,8 +1605,8 @@ static int cx231xx_init_v4l2(struct cx231xx *dev,
 		 dev->video_mode.end_point_addr,
 		 dev->video_mode.num_alt);
 
-	dev->video_mode.alt_max_pkt_size = devm_kmalloc_array(&interface->dev, 32,
-							      dev->video_mode.num_alt, GFP_KERNEL);
+	dev->video_mode.alt_max_pkt_size =
+		kmalloc_array(32, dev->video_mode.num_alt, GFP_KERNEL);
 	if (dev->video_mode.alt_max_pkt_size == NULL)
 		return -ENOMEM;
 
@@ -1615,8 +1647,8 @@ static int cx231xx_init_v4l2(struct cx231xx *dev,
 		 dev->vbi_mode.num_alt);
 
 	/* compute alternate max packet sizes for vbi */
-	dev->vbi_mode.alt_max_pkt_size = devm_kmalloc_array(&interface->dev, 32,
-							    dev->vbi_mode.num_alt, GFP_KERNEL);
+	dev->vbi_mode.alt_max_pkt_size =
+		kmalloc_array(32, dev->vbi_mode.num_alt, GFP_KERNEL);
 	if (dev->vbi_mode.alt_max_pkt_size == NULL)
 		return -ENOMEM;
 
@@ -1658,9 +1690,8 @@ static int cx231xx_init_v4l2(struct cx231xx *dev,
 		 "sliced CC EndPoint Addr 0x%x, Alternate settings: %i\n",
 		 dev->sliced_cc_mode.end_point_addr,
 		 dev->sliced_cc_mode.num_alt);
-	dev->sliced_cc_mode.alt_max_pkt_size = devm_kmalloc_array(&interface->dev, 32,
-								  dev->sliced_cc_mode.num_alt,
-								  GFP_KERNEL);
+	dev->sliced_cc_mode.alt_max_pkt_size =
+		kmalloc_array(32, dev->sliced_cc_mode.num_alt, GFP_KERNEL);
 	if (dev->sliced_cc_mode.alt_max_pkt_size == NULL)
 		return -ENOMEM;
 
@@ -1724,7 +1755,7 @@ static int cx231xx_usb_probe(struct usb_interface *interface,
 	udev = interface_to_usbdev(interface);
 
 	/* allocate memory for our device state and initialize it */
-	dev = devm_kzalloc(&interface->dev, sizeof(*dev), GFP_KERNEL);
+	dev = kzalloc_obj(*dev);
 	if (dev == NULL) {
 		retval = -ENOMEM;
 		goto err_if;
@@ -1818,15 +1849,16 @@ static int cx231xx_usb_probe(struct usb_interface *interface,
 		dev_err(d, "v4l2_device_register failed\n");
 		goto err_v4l2;
 	}
+	dev->v4l2_dev.release = cx231xx_v4l2_release;
 
 	/* allocate device struct */
 	retval = cx231xx_init_dev(dev, udev, nr);
 	if (retval)
 		goto err_init;
 
-	retval = cx231xx_init_v4l2(dev, udev, interface, isoc_pipe);
+	retval = cx231xx_init_v4l2(dev, udev, isoc_pipe);
 	if (retval)
-		goto err_init;
+		goto err_video_alt;
 
 	if (dev->current_pcb_config.ts1_source != 0xff) {
 		/* compute alternate max packet sizes for TS1 */
@@ -1854,9 +1886,8 @@ static int cx231xx_usb_probe(struct usb_interface *interface,
 			 dev->ts1_mode.end_point_addr,
 			 dev->ts1_mode.num_alt);
 
-		dev->ts1_mode.alt_max_pkt_size = devm_kmalloc_array(&interface->dev, 32,
-								    dev->ts1_mode.num_alt,
-								    GFP_KERNEL);
+		dev->ts1_mode.alt_max_pkt_size =
+			kmalloc_array(32, dev->ts1_mode.num_alt, GFP_KERNEL);
 		if (dev->ts1_mode.alt_max_pkt_size == NULL) {
 			retval = -ENOMEM;
 			goto err_video_alt;
@@ -1900,12 +1931,18 @@ static int cx231xx_usb_probe(struct usb_interface *interface,
 	if (!retval)
 		retval = media_device_register(dev->media_dev);
 #endif
-	if (retval < 0)
+	if (retval < 0) {
+		dev->state |= DEV_DISCONNECTED;
+		flush_request_modules(dev);
+		cx231xx_close_extension(dev);
+		usb_set_intfdata(interface, NULL);
 		cx231xx_release_resources(dev);
+	}
 	return retval;
 
 err_video_alt:
 	/* cx231xx_uninit_dev: */
+	dev->state |= DEV_DISCONNECTED;
 	cx231xx_close_extension(dev);
 	cx231xx_ir_exit(dev);
 	cx231xx_release_analog_resources(dev);
@@ -1913,13 +1950,20 @@ static int cx231xx_usb_probe(struct usb_interface *interface,
 	cx231xx_remove_from_devlist(dev);
 	cx231xx_dev_uninit(dev);
 err_init:
-	v4l2_device_unregister(&dev->v4l2_dev);
+	dev->state |= DEV_DISCONNECTED;
+	usb_set_intfdata(interface, NULL);
+	clear_bit(nr, &cx231xx_devused);
+	v4l2_device_disconnect(&dev->v4l2_dev);
+	v4l2_device_put(&dev->v4l2_dev);
+	return retval;
 err_v4l2:
-	cx231xx_unregister_media_device(dev);
+	cx231xx_cleanup_media_device(dev);
 err_media_init:
 	usb_set_intfdata(interface, NULL);
 err_if:
 	clear_bit(nr, &cx231xx_devused);
+	if (dev)
+		cx231xx_free_device(dev);
 	return retval;
 }
 
diff --git a/drivers/media/usb/cx231xx/cx231xx-video.c b/drivers/media/usb/cx231xx/cx231xx-video.c
index 70aa99fead27..058e8eed2847 100644
--- a/drivers/media/usb/cx231xx/cx231xx-video.c
+++ b/drivers/media/usb/cx231xx/cx231xx-video.c
@@ -1567,8 +1567,6 @@ void cx231xx_release_analog_resources(struct cx231xx *dev)
 
 		video_unregister_device(&dev->vdev);
 	}
-	v4l2_ctrl_handler_free(&dev->ctrl_handler);
-	v4l2_ctrl_handler_free(&dev->radio_ctrl_handler);
 }
 
 /*

-- 
2.43.0

