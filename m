From: Davide Vitturini <mdvitturini@gmail.com>
Date: Fri, 13 Nov 2026 16:37:33 +0100
Subject: [PATCH] media: staging: ipu7: isys: close the firmware stream when
 enabling the source fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-ipu7-isys-close-on-enable-failure-v1-1-3473e098115b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3NQQrCMBBG4auUWTvQRIzWq0gXMf1jB0JSMrRUS
 u9ucPlt3jtIUQVKz+6gik1USm4wl47C7PMHLFMz2d46Y8yVZVnvLPpVDqkouGRG9u8Ejl7SWsF
 uCo/b4AYbg6XWWSqi7P/HazzPHxzY5tpzAAAA
X-Change-ID: 20261113-ipu7-isys-close-on-enable-failure-6dc859692fc2
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Bingbu Cao <bingbu.cao@intel.com>, linux-media@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Davide Vitturini <mdvitturini@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794584253; l=3670;
 i=mdvitturini@gmail.com; s=20261113; h=from:subject:message-id;
 bh=7DM20gbywDQPpG7hvrpaxI9Untar2fwINYVnL+pTASQ=;
 b=VKTVo4DwVQ0O1UizNU9kjONMX6xMH8fLXv9Mrq1uBBdWzccM2fcNnM9aayAoDnRouxlybBsNt
 4qOp0KGm3jGCleg8pTcAiBELvADcIZCceL9oj2i4FbV7/EZAo2jbnL8
X-Developer-Key: i=mdvitturini@gmail.com; a=ed25519;
 pk=qHGCynxkIIOSj9Y1SqEb12yeOmEFSgLKtIUxOhZ2o2U=
X-Endpoint-Received: by B4 Relay for mdvitturini@gmail.com/20261113 with auth_id=1511
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ipu7_isys_video_set_streaming() opens and starts the firmware stream
(start_stream_firmware(), which increments isys->stream_opened) before
enabling the source subdevice. If v4l2_subdev_enable_streams() then
fails, the error path only flushes the stream with
stop_streaming_firmware(): the firmware stream is never closed and
stream_opened is never decremented.

Since isys_suspend() refuses to suspend while stream_opened is non-zero,
a single failed stream start (e.g. a sensor that does not answer on I2C
right after power-up) blocks system suspend with -EBUSY until the next
reboot, even though no stream is open any more:

  intel_ipu7_isys.isys intel_ipu7.isys.40: enable streams Intel IPU7 CSI2 2 failed with -121
  ...
  intel_ipu7_isys.isys intel_ipu7.isys.40: PM: failed to suspend: error -16

Close the firmware stream in the error path too, mirroring the stream-off
path (stop, disable source, close).

Observed on a Lenovo ThinkPad X1 Carbon Gen 14 (Panther Lake, IPU7.5) with
the ST VD55G1 IR sensor: after five failed stream starts suspend was refused
until reboot; with this patch applied suspend/resume works.

The leak was found, and this fix written, with the help of an AI coding
assistant (Claude Code, model Claude Opus 5.5) while debugging the failed
suspend on this laptop. I reviewed the change and tested it on the
hardware above.

Fixes: a516d36bdc3d ("media: staging/ipu7: add IPU7 input system device driver")
Cc: stable@vger.kernel.org
Signed-off-by: Davide Vitturini <mdvitturini@gmail.com>
---
How this was tested (Lenovo ThinkPad X1 Carbon Gen 14, Ubuntu 26.04,
kernel 7.0.0-43 with the staging ipu7 ISYS rebuilt with this patch):
- Reproducer: a test-only module parameter in the out-of-tree vd55g1
  driver makes the sensor's enable_streams() return -EIO, which drives
  ipu7_isys_video_set_streaming() into the error path:
    vd55g1 i2c-TBE20A1:00: test_fail_streams: failing this stream start
    intel_ipu7_isys.isys intel_ipu7.isys.40: enable streams Intel IPU7 CSI2 2 failed with -5
    intel_ipu7_isys.isys intel_ipu7.isys.40: stream stop time out
    intel_ipu7_isys.isys intel_ipu7.isys.40: stream close time out
  (The firmware does not acknowledge flush/close of a stream whose source
  never started, so both calls time out; stream_opened is still dropped.)
- The same capture node then streamed normally again (20 frames).
- s2idle suspend/resume afterwards succeeded (suspend_stats: fail 0,
  last_hw_sleep 8.4 s). Without the patch, real -121 failures of the same
  kind made every later suspend fail with -EBUSY until reboot.

Build-tested on media-committers/next (W=1, allmodconfig, drivers/staging/media/ipu7/).

AI assistance: the leak was found while debugging failed suspend with
Claude Code (Claude Opus 5.5), which proposed the fix, the reproducer and
this description; I reviewed and tested them.
---
 drivers/staging/media/ipu7/ipu7-isys-video.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/staging/media/ipu7/ipu7-isys-video.c b/drivers/staging/media/ipu7/ipu7-isys-video.c
index 8c6730833..024d43f60 100644
--- a/drivers/staging/media/ipu7/ipu7-isys-video.c
+++ b/drivers/staging/media/ipu7/ipu7-isys-video.c
@@ -831,6 +831,7 @@ int ipu7_isys_video_set_streaming(struct ipu7_isys_video *av, int state,
 
 out_media_entity_stop_streaming_firmware:
 	stop_streaming_firmware(av);
+	close_streaming_firmware(av);
 
 	return ret;
 }

---
base-commit: ad6549a46748d00818483b535e5cd2a704685c98
change-id: 20261113-ipu7-isys-close-on-enable-failure-6dc859692fc2

Best regards,
-- 
Davide Vitturini <mdvitturini@gmail.com>

