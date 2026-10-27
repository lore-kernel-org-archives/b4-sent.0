From: Marco Ziliani <rylos78@gmail.com>
Date: Tue, 27 Oct 2026 21:29:45 +0100
Subject: [PATCH 1/3] media: i2c: ov5693: Program the mode registers on
 stream start
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-ov5693-fixes-v1-1-3c8ab1ae104d@gmail.com>
References: <20261027-ov5693-fixes-v1-0-3c8ab1ae104d@gmail.com>
In-Reply-To: <20261027-ov5693-fixes-v1-0-3c8ab1ae104d@gmail.com>
To: Daniel Scally <dan.scally@ideasonboard.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, Chris Simpson <chris@nilk.net>, 
 Simon Kruse <simon0x+git@proton.me>, "D. Manresa" <dmanresa@gmail.com>, 
 linux-kernel@vger.kernel.org, Marco Ziliani <rylos78@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793132984; l=2580;
 i=rylos78@gmail.com; s=20261027; h=from:subject:message-id;
 bh=vr4kUaykaNDDTvI/XPwM7e2iqb7XHZfVu3/G5P8saTI=;
 b=KEbjbj4KD+HU3Jj/r8hT87ZGcaPSoRdLqR0IID7Onp7iL1z1AJquILfFx5czVp/hu8n+pe0zz
 ZW+D/64usIrBl4yOySMrymilFd9USnYeQ+VhAUdM6CDlJuZacGEKZUh
X-Developer-Key: i=rylos78@gmail.com; a=ed25519;
 pk=nXCfiK5yExPZCMp+lfKif3gdXkfjkUK2qk7bDW+ixMo=
X-Endpoint-Received: by B4 Relay for rylos78@gmail.com/20261027 with auth_id=1333
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mode registers (readout window, binning and subsampling) are only
written from the runtime PM resume handler, and ov5693_set_fmt() merely
stores the requested mode. If the sensor stays powered between two
streams, the new mode never reaches the chip: the sensor keeps
streaming the previous mode while the CSI-2 receiver expects the newly
negotiated format.

This happens whenever the format is changed while the sensor is still
powered. On a Surface Pro 7+ (IPU6), with the sensor held powered
between two streams, OUTPUT_SIZE_X read back over I2C showed the sensor
stuck in the mode it was powered up in, and 0 of 16 streams that asked
for a different mode produced a frame. With this change, 32 of 32
streams completed and the register followed the requested mode. A
Surface Pro 9 (IPU6) gave the same result: without the change
OUTPUT_SIZE stayed at 2592x1944 in all 32 streams of 16 such switches,
with it the register matched the requested size in all 32. On a
Surface Pro 5 (IPU3), switching between 2592x1944 and a 1920x1080 crop
the same way, OUTPUT_SIZE_X stayed at 2592 and none of the 16 streams
in the new size produced a frame; with this change, 32 of 32 streams
gave 10 of 10 frames at the requested size.

Program the mode on every stream start, before the controls, so that
the mode registers don't clobber them. This matches what commit
4e1446ac169a ("media: i2c: ov8865: Program the sensor on stream start")
does for the ov8865.

Fixes: 89aef879cb53 ("media: i2c: Add support for ov5693 sensor")
Link: https://github.com/linux-surface/kernel/pull/181
Signed-off-by: Marco Ziliani <rylos78@gmail.com>
---
 drivers/media/i2c/ov5693.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/media/i2c/ov5693.c b/drivers/media/i2c/ov5693.c
index 56599f9ca..579aa55b7 100644
--- a/drivers/media/i2c/ov5693.c
+++ b/drivers/media/i2c/ov5693.c
@@ -1000,6 +1000,19 @@ static int ov5693_s_stream(struct v4l2_subdev *sd, int enable)
 			return ret;
 
 		mutex_lock(&ov5693->lock);
+
+		/*
+		 * The mode registers are otherwise only written on runtime PM
+		 * resume, so a format change on a sensor that stays powered
+		 * would never reach the chip. Program the mode first, then the
+		 * controls, so the mode registers don't clobber them.
+		 */
+		ret = ov5693_mode_configure(ov5693);
+		if (ret) {
+			mutex_unlock(&ov5693->lock);
+			goto err_power_down;
+		}
+
 		ret = __v4l2_ctrl_handler_setup(&ov5693->ctrls.handler);
 		if (ret) {
 			mutex_unlock(&ov5693->lock);

-- 
2.56.0

