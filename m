From: Johannes Schrimpf <johannes.schrimpf@blueye.no>
Date: Thu, 22 Oct 2026 12:16:52 +0200
Subject: [PATCH v2] media: uvcvideo: Release streaming interfaces at
 disconnect, not last close
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-uvc-release-intfs-v2-1-901bc1c47cfb@blueye.no>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/32Nyw6CMBBFf4XM2hqKUtGV/2FY9DGVGlJMhzYSw
 r/b4t7M6uTee2YFwuCQ4FatEDA5cpPP0Bwq0IP0T2TOZIambgSv+ZnFpFnAESXlyM+WmLXXFk8
 XIRRvIe/eAa377M5H/2OK6oV6LqLSGBzNU1j2p4mX3j9/4ixfZwR2xkppursaIy549BP027Z9A
 XPd/+fEAAAA
X-Change-ID: 20261014-uvc-release-intfs-ff95e3766b15
To: laurent.pinchart@ideasonboard.com, hansg@kernel.org
Cc: ribalda@chromium.org, hverkuil@kernel.org, linux-kernel@vger.kernel.org, 
 mchehab@kernel.org, linux-media@vger.kernel.org, stable@vger.kernel.org, 
 Johannes Schrimpf <johannes.schrimpf@blueye.no>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792664229; l=7840;
 i=johannes.schrimpf@blueye.no; s=20261014; h=from:subject:message-id;
 bh=jITjUBkqSOrja9OK7j/wiP5VysOC8DbpzIk24IUo4ns=;
 b=PCRLhcqexTTYWT5A2+bjtxRNBlp44aWrcGYfceBjjiWYGAmJlROJ8vu54EeiA1t9sISWgXKH8
 khjZYShjQuUDa4Daum8GIFwL3duaVHmaLkve+IbVHmoTdqhAwatZbPI
X-Developer-Key: i=johannes.schrimpf@blueye.no; a=ed25519;
 pk=900KgDI7vLhnD9R982XOT47UCm3e4vWxQWBC4jDCUPo=
X-Endpoint-Received: by B4 Relay for johannes.schrimpf@blueye.no/20261014 with auth_id=1178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a UVC camera goes through a USB reset while an application holds it
open, the camera is unusable after the reset.

The old uvc_device releases its streaming interfaces only when its last
open file handle is closed, which unbinds them from the new uvc_device
that has claimed them in the meantime.

Release them on disconnect and on the probe error path instead, as the
last step of uvc_unregister_video(), which is renamed to
uvc_unregister_device().

This also ensures that usb_driver_release_interface() is only called
with the USB device lock held.

Fixes: c0efd232929c ("V4L/DVB (8145a): USB Video Class driver")
Cc: stable@vger.kernel.org # needs adjustments for <= 6.14: &uvc_driver.driver
Assisted-by: LLM
Reviewed-by: Ricardo Ribalda <ribalda@chromium.org>
Signed-off-by: Johannes Schrimpf <johannes.schrimpf@blueye.no>
---
Changes in v2:
- Shorten the commit message; the details are now below (Ricardo).
- Move the release into uvc_unregister_video() as its last step and
  rename that function to uvc_unregister_device() (Ricardo). The
  release still runs after the video nodes are unregistered and before
  kref_put(), in uvc_disconnect() and on the probe error path.
- Add Ricardo's Reviewed-by.
- Link to v1: https://patch.msgid.link/20261014-uvc-release-intfs-v1-1-18d6e8dfaad8@blueye.no
---
Details from the v1 commit message:

Mechanism: uvcvideo has no pre_reset() and post_reset() handlers, so
usb_reset_device() unbinds it and probes it again on the same struct
usb_interface objects. A file handle from before the reset keeps the
old uvc_device alive. usb_driver_release_interface() only checks that
the interface is bound to uvcvideo, not to which uvc_device, so the
old uvc_delete() unbinds the interfaces from the new device. The URBs
of a running stream then complete with -ESHUTDOWN,
uvc_video_complete() sets UVC_QUEUE_DISCONNECTED, and every following
VIDIOC_QBUF fails with -ENODEV. Nothing is logged, and the stream stays
dead until the next reset or replug.

Reproduction, with a Sonix camera (0c45:6366) on an i.MX6Q board,
Linux 6.18.24 (linux-fslc-imx):

  1. open() a video node of the camera and keep the file handle
  2. reset the camera with USBDEVFS_RESET
  3. stream from a video node of the re-probed device
  4. close() the file handle from step 1

The stream fails within a few milliseconds of the close() in 4 of 4
runs, with one KOBJ_UNBIND uevent per VideoStreaming interface; the
VideoControl interface stays bound. A handle on either streaming
interface has the same effect. Without step 1 the stream survives.

usb-serial splits it the same way: usb_serial_disconnect() releases the
sibling interface, and its kref release, destroy_serial(), releases
none. With no file handle open, uvc_disconnect() drops the last
reference itself, so on that path the interfaces are still released
from within uvc_disconnect(), as before.

Tested with v1 on the same board and kernel: the reproduction with the
handle on either streaming interface or closed before the stream
starts, a USB reset without a held handle, sysfs unbind/bind of the
VideoControl interface with and without a held handle, and a second
UVC camera (MJPEG and H.264 at 1080p). The stream survives all four
streaming runs, none of the five stale-handle closes unbinds an
interface, and the close() takes 0.13-0.23 ms instead of 38-42 ms.
USB-reset recovery and the second camera work, and sysfs unbind/bind
releases and reclaims the streaming interfaces.

Tested with v2 on the same board, built into the kernel image: the
reproduction with the handle on either streaming interface, closed
before the stream starts, and with no handle held. The stream survives
all four runs and no interface is unbound; in the two runs that close
the stale handle while streaming, 149 frames arrive in the 5 s after
the close.

Ricardo's "media: uvcvideo: Remove refcounted cleanup" (Nov 2024) would
have moved all device cleanup into uvc_disconnect(), and was NACKed
because it fixed no concrete bug. This patch keeps the refcounted
cleanup and moves only the release of the streaming interfaces.

Tool use: this was developed with an LLM coding assistant, Claude Code
running Claude Opus 5.5; v1 was also reviewed by GPT-6 Astra. Starting
from stream failures in our bench logs, the assistant traced the code
path, wrote the reproduction scripts, ran them and the tests above on
the device, surveyed the upstream history and other drivers, built and
checked the patch on media-committers next, and drafted the patch, the
changelog and these notes.

Test kernel: linux-fslc-imx 6.18.24 with three local uvcvideo patches
(keep MJPEG frames recovered by MJPEG_NO_EOF, nodrop=0 by default, and a
coherent_urbs parameter). None of them touches probe, uvc_disconnect(),
uvc_delete(), the interface claim/release or uvc_video_complete().

Not tested:
- an unmodified uvcvideo, or any kernel other than linux-fslc-imx
  6.18.24; on media-committers next, the patch is build-tested only
  (v1: gcc and clang, arm, arm64 and x86_64, W=1, sparse, smatch; v2:
  gcc, arm, W=1)
- a debug kernel: the test kernel is the board's production config
  (SMP, PREEMPT; no lockdep, DEBUG_ATOMIC_SLEEP, DEBUG_MUTEXES,
  SLUB_DEBUG, DEBUG_PAGEALLOC or KASAN)
- unplug and replug, sysfs unbind of a VideoStreaming interface, and
  the probe error path
- frame delivery after a sysfs rebind: the Sonix camera delivers no
  frames after any re-probe that does not follow a USB reset, with and
  without this patch, so those runs check only the binding; the
  second camera was not rebound
- v4l2-compliance
- any camera other than the two on this board
---
 drivers/media/usb/uvc/uvc_driver.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/drivers/media/usb/uvc/uvc_driver.c b/drivers/media/usb/uvc/uvc_driver.c
index cbc1456..bb8f0e3 100644
--- a/drivers/media/usb/uvc/uvc_driver.c
+++ b/drivers/media/usb/uvc/uvc_driver.c
@@ -1976,7 +1976,6 @@ static void uvc_delete(struct kref *kref)
 		struct uvc_streaming *streaming;
 
 		streaming = list_entry(p, struct uvc_streaming, list);
-		usb_driver_release_interface(&uvc_driver, streaming->intf);
 		uvc_stream_delete(streaming);
 	}
 
@@ -1992,9 +1991,9 @@ static void uvc_release(struct video_device *vdev)
 }
 
 /*
- * Unregister the video devices.
+ * Unregister the device and release the streaming interfaces.
  */
-static void uvc_unregister_video(struct uvc_device *dev)
+static void uvc_unregister_device(struct uvc_device *dev)
 {
 	struct uvc_streaming *stream;
 
@@ -2024,6 +2023,14 @@ static void uvc_unregister_video(struct uvc_device *dev)
 	if (media_devnode_is_registered(dev->mdev.devnode))
 		media_device_unregister(&dev->mdev);
 #endif
+
+	/*
+	 * Release the streaming interfaces here, not in uvc_delete(): after a
+	 * USB reset, a new uvc_device may already have claimed the same
+	 * interfaces.
+	 */
+	list_for_each_entry(stream, &dev->streams, list)
+		usb_driver_release_interface(&uvc_driver, stream->intf);
 }
 
 int uvc_register_video_device(struct uvc_device *dev,
@@ -2355,7 +2362,7 @@ static int uvc_probe(struct usb_interface *intf,
 	return 0;
 
 error:
-	uvc_unregister_video(dev);
+	uvc_unregister_device(dev);
 	kref_put(&dev->ref, uvc_delete);
 	return ret;
 }
@@ -2374,7 +2381,7 @@ static void uvc_disconnect(struct usb_interface *intf)
 	    UVC_SC_VIDEOSTREAMING)
 		return;
 
-	uvc_unregister_video(dev);
+	uvc_unregister_device(dev);
 	kref_put(&dev->ref, uvc_delete);
 }
 

---
base-commit: d7e7bca7169873b46e857c025c10f3336c1258d8
change-id: 20261014-uvc-release-intfs-ff95e3766b15

Best regards,
--  
Johannes Schrimpf <johannes.schrimpf@blueye.no>

