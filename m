From: Johannes Schrimpf <johannes.schrimpf@blueye.no>
Date: Wed, 14 Oct 2026 17:28:24 +0200
Subject: [PATCH] media: uvcvideo: Release streaming interfaces at
 disconnect, not last close
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-uvc-release-intfs-v1-1-18d6e8dfaad8@blueye.no>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMUQqDMBCE4avIPjdgtEb0KsUHTSe6IqlkVQTx7
 qb6+DHMf5AgMITq5KCAjYV/PkK/ErJD63so/kZTlmZGp/qt1s2qgAmtxMkvTpRzVYG8NKbTBcX
 fHOB4v5uf5rGs3Qi7/EN0nheVwvsjdQAAAA==
X-Change-ID: 20261014-uvc-release-intfs-ff95e3766b15
To: laurent.pinchart@ideasonboard.com, hansg@kernel.org
Cc: linux-media@vger.kernel.org, hverkuil@kernel.org, mchehab@kernel.org, 
 ribalda@chromium.org, linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Johannes Schrimpf <johannes.schrimpf@blueye.no>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791991739; l=7663;
 i=johannes.schrimpf@blueye.no; s=20261014; h=from:subject:message-id;
 bh=vP7V2E0qAI4aNNnmf2u3d9XezDINZxpJYxAsVgid9s4=;
 b=dOkr7T7NsbBPHvdN0gPdn9whWbWpbp3z4PVEEOBydKxgmDhqBJBM59zTHH1QzN9laslaT4cyA
 +2isZG+nSQODmvWF6gijIYeK6wUtkHz9etQQqlb9yHHr2ehUY7TVWpq
X-Developer-Key: i=johannes.schrimpf@blueye.no; a=ed25519;
 pk=900KgDI7vLhnD9R982XOT47UCm3e4vWxQWBC4jDCUPo=
X-Endpoint-Received: by B4 Relay for johannes.schrimpf@blueye.no/20261014 with auth_id=1178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

uvc_probe() claims the VideoStreaming interfaces with
usb_driver_claim_interface(), but they are released by uvc_delete(),
the kref release of the uvc_device. uvc_delete() runs when the last
reference to the disconnected device is released, potentially on a
later file close, long after uvc_disconnect().

A USB reset turns this into a bug. uvcvideo has no pre_reset() and
post_reset() handlers, so usb_reset_device() unbinds it from all the
interfaces it is bound to and probes it again on the same struct
usb_interface objects. A process that holds a file handle from before
the reset keeps the old uvc_device alive. When it closes the handle,
the old uvc_delete() calls usb_driver_release_interface() on
interfaces that the new uvc_device has claimed meanwhile.
usb_driver_release_interface() only checks that the interface is bound
to the uvcvideo driver, not to which instance, so it unbinds them from
the new device. usb_unbind_interface() disables the endpoints, the
URBs of a running stream complete with -ESHUTDOWN, uvc_video_complete()
marks the queue as disconnected, and every following VIDIOC_QBUF fails
with -ENODEV. Nothing is logged, and the stream stays dead until the
device is reset or plugged in again. The release from uvc_delete() also
runs without the USB device lock that usb_driver_release_interface()
requires.

This was found with a Sonix camera (0c45:6366) on an i.MX6Q board,
where a camera-control process kept a file handle open across a USB
reset issued by the streaming process. The failure was traced and
reproduced with the help of an LLM coding assistant. Reproduced on
Linux 6.18.24 (linux-fslc-imx) as follows:

  1. open() a video node of the camera and keep the file handle
  2. reset the camera with USBDEVFS_RESET
  3. stream from a video node of the re-probed device
  4. close() the file handle from step 1

The stream fails within a few milliseconds of the close(), in 4 of 4
runs. The kernel emits one KOBJ_UNBIND uevent for each VideoStreaming
interface; the VideoControl interface stays bound. Holding a node of
the other streaming interface has the same effect. Without step 1 the
stream survives.

Release the streaming interfaces where the binding is still ours: in
uvc_disconnect() for the VideoControl interface, which runs with the
USB device lock held, and in the probe error path, in the same context
as the claims in uvc_parse_streaming(). uvc_delete() then no longer
releases any interface. This is the split usb-serial uses:
usb_serial_disconnect() releases the sibling interface, and the kref
release, destroy_serial(), releases no interface; it drops its
interface reference with usb_put_intf(). With no file handle open,
uvc_disconnect() already drops the last reference, and uvc_delete()
runs synchronously from it, so on that path the interfaces are still
released from within uvc_disconnect(), as before.

Tested with this patch on the same i.MX6Q and kernel: the reproduction
above with the file handle opened on either streaming interface or
closed before the stream starts, a USB reset without a held file
handle, sysfs unbind/bind of the VideoControl interface with and
without a held file handle, and a second UVC camera (MJPEG and H.264
at 1080p).

The running stream survives in all four streaming runs, and none of
the five stale-handle closes unbinds an interface; the close() takes
0.13-0.23 ms instead of 38-42 ms (86 ms when no stream was running).
USB-reset recovery and streaming from the second camera pass. Sysfs
unbind/bind correctly releases and reclaims the streaming interfaces.

Fixes: c0efd232929c ("V4L/DVB (8145a): USB Video Class driver")
Cc: stable@vger.kernel.org # needs adjustments for <= 6.14: &uvc_driver.driver
Assisted-by: LLM
Signed-off-by: Johannes Schrimpf <johannes.schrimpf@blueye.no>
---
Hi Laurent, Hans,

Ricardo's "media: uvcvideo: Remove refcounted cleanup" (Nov 2024) would
have moved all device cleanup, including this release, into
uvc_disconnect(), and was NACKed because it fixed no concrete bug. This
patch keeps the refcounted cleanup and moves only the release of the
streaming interfaces, to fix the failure described in the commit
message, which we hit repeatedly in integration testing.

Tool use: this was developed with an LLM coding assistant, Claude Code
running Claude Opus 5.5, as well as reviewed by GPT-6 Astra. Starting
from stream failures in our bench logs, the assistant traced the code
path, wrote the reproduction scripts, ran them and the tests above on
the device, surveyed the upstream history and other drivers, built and
checked the patch on media-committers next, and drafted the patch, the
changelog and these notes. I reviewed the analysis and the patch.

Test kernel: linux-fslc-imx 6.18.24 with three local uvcvideo patches
(keep MJPEG frames recovered by MJPEG_NO_EOF, nodrop=0 by default, and a
coherent_urbs parameter). None of them touches probe, uvc_disconnect(),
uvc_delete(), the interface claim/release or uvc_video_complete().

Not tested:
- an unmodified uvcvideo, or any kernel other than linux-fslc-imx
  6.18.24; on media-committers next this patch is build-tested only
  (gcc and clang, arm, arm64 and x86_64, W=1, sparse, smatch)
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
 drivers/media/usb/uvc/uvc_driver.c | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/drivers/media/usb/uvc/uvc_driver.c b/drivers/media/usb/uvc/uvc_driver.c
index cbc1456..f71dfce 100644
--- a/drivers/media/usb/uvc/uvc_driver.c
+++ b/drivers/media/usb/uvc/uvc_driver.c
@@ -1976,7 +1976,6 @@ static void uvc_delete(struct kref *kref)
 		struct uvc_streaming *streaming;
 
 		streaming = list_entry(p, struct uvc_streaming, list);
-		usb_driver_release_interface(&uvc_driver, streaming->intf);
 		uvc_stream_delete(streaming);
 	}
 
@@ -2026,6 +2025,18 @@ static void uvc_unregister_video(struct uvc_device *dev)
 #endif
 }
 
+/*
+ * Release the streaming interfaces here, not in uvc_delete(): after a USB
+ * reset, a new uvc_device may already have claimed the same interfaces.
+ */
+static void uvc_release_streaming_intfs(struct uvc_device *dev)
+{
+	struct uvc_streaming *stream;
+
+	list_for_each_entry(stream, &dev->streams, list)
+		usb_driver_release_interface(&uvc_driver, stream->intf);
+}
+
 int uvc_register_video_device(struct uvc_device *dev,
 			      struct uvc_streaming *stream,
 			      struct uvc_video_queue *queue,
@@ -2356,6 +2367,7 @@ static int uvc_probe(struct usb_interface *intf,
 
 error:
 	uvc_unregister_video(dev);
+	uvc_release_streaming_intfs(dev);
 	kref_put(&dev->ref, uvc_delete);
 	return ret;
 }
@@ -2375,6 +2387,7 @@ static void uvc_disconnect(struct usb_interface *intf)
 		return;
 
 	uvc_unregister_video(dev);
+	uvc_release_streaming_intfs(dev);
 	kref_put(&dev->ref, uvc_delete);
 }
 

---
base-commit: d7e7bca7169873b46e857c025c10f3336c1258d8
change-id: 20261014-uvc-release-intfs-ff95e3766b15

Best regards,
--  
Johannes Schrimpf <johannes.schrimpf@blueye.no>

