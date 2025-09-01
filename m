From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 01 Sep 2025 17:05:15 +0200
Subject: [PATCH v7 10/10] media: i2c: ov9282: dynamic flash_duration
 maximum
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250901-ov9282-flash-strobe-v7-10-d58d5a694afc@linux.dev>
References: <20250901-ov9282-flash-strobe-v7-0-d58d5a694afc@linux.dev>
In-Reply-To: <20250901-ov9282-flash-strobe-v7-0-d58d5a694afc@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-leds@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756739145; l=3617;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=I5haGetjk5CR5fMUuZoz3rwX2PVyWVsn8Vb9i7Affcg=;
 b=89ndo5Sw4zw/nKvZB93fs7yxRCVJKeS0iI6Otle9lIxMlvzB4Rz3LpY2Aqd3yHiHOnyYVrQ0u
 CqGOYzBWPUMBWG+AdLax193OsQiKxpneeKn3J0jH2JyXxGI5vJtkd8H
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch sets the current exposure time as maximum for the
flash_duration control. As Flash/Strobes which are longer than the
exposure time have no effect.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 30 ++++++++++++++++++++++++++----
 1 file changed, 26 insertions(+), 4 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index b104ae77f00e9e7777342e48b7bf3caa6d297f69..3253d9f271cb3caef6d85837ebec4f5beb466a4d 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -198,6 +198,7 @@ struct ov9282_mode {
  * @exp_ctrl: Pointer to exposure control
  * @again_ctrl: Pointer to analog gain control
  * @pixel_rate: Pointer to pixel rate control
+ * @flash_duration: Pointer to flash duration control
  * @vblank: Vertical blanking in lines
  * @noncontinuous_clock: Selection of CSI2 noncontinuous clock mode
  * @cur_mode: Pointer to current selected sensor mode
@@ -220,6 +221,7 @@ struct ov9282 {
 		struct v4l2_ctrl *again_ctrl;
 	};
 	struct v4l2_ctrl *pixel_rate;
+	struct v4l2_ctrl *flash_duration;
 	u32 vblank;
 	bool noncontinuous_clock;
 	const struct ov9282_mode *cur_mode;
@@ -611,6 +613,15 @@ static int ov9282_update_controls(struct ov9282 *ov9282,
 					mode->vblank_max, 1, mode->vblank);
 }
 
+static u32 ov9282_exposure_to_us(struct ov9282 *ov9282, u32 exposure)
+{
+	/* calculate exposure time in µs */
+	u32 frame_width = ov9282->cur_mode->width + ov9282->hblank_ctrl->val;
+	u32 trow_us = (frame_width * 1000000UL) / ov9282->pixel_rate->val;
+
+	return exposure * trow_us;
+}
+
 /**
  * ov9282_update_exp_gain() - Set updated exposure and gain
  * @ov9282: pointer to ov9282 device
@@ -622,9 +633,10 @@ static int ov9282_update_controls(struct ov9282 *ov9282,
 static int ov9282_update_exp_gain(struct ov9282 *ov9282, u32 exposure, u32 gain)
 {
 	int ret;
+	u32 exposure_us = ov9282_exposure_to_us(ov9282, exposure);
 
-	dev_dbg(ov9282->dev, "Set exp %u, analog gain %u",
-		exposure, gain);
+	dev_dbg(ov9282->dev, "Set exp %u (~%u us), analog gain %u",
+		exposure, exposure_us, gain);
 
 	ret = ov9282_write_reg(ov9282, OV9282_REG_HOLD, 1, 1);
 	if (ret)
@@ -635,6 +647,12 @@ static int ov9282_update_exp_gain(struct ov9282 *ov9282, u32 exposure, u32 gain)
 		goto error_release_group_hold;
 
 	ret = ov9282_write_reg(ov9282, OV9282_REG_AGAIN, 1, gain);
+	if (ret)
+		goto error_release_group_hold;
+
+	ret = __v4l2_ctrl_modify_range(ov9282->flash_duration,
+				       0, exposure_us, 1,
+				       OV9282_FLASH_DURATION_DEFAULT);
 
 error_release_group_hold:
 	ov9282_write_reg(ov9282, OV9282_REG_HOLD, 1, 0);
@@ -1420,6 +1438,7 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	struct v4l2_fwnode_device_properties props;
 	struct v4l2_ctrl *ctrl;
 	u32 hblank_min;
+	u32 exposure_us;
 	u32 lpfr;
 	int ret;
 
@@ -1491,8 +1510,11 @@ static int ov9282_init_controls(struct ov9282 *ov9282)
 	/* Flash/Strobe controls */
 	v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops, V4L2_CID_FLASH_HW_STROBE_SIGNAL, 0, 1, 1, 0);
 
-	v4l2_ctrl_new_std(ctrl_hdlr, &ov9282_ctrl_ops, V4L2_CID_FLASH_DURATION,
-			  0, 13900, 1, 8);
+	exposure_us = ov9282_exposure_to_us(ov9282, OV9282_EXPOSURE_DEFAULT);
+	ov9282->flash_duration = v4l2_ctrl_new_std(ctrl_hdlr,
+						   &ov9282_ctrl_ops, V4L2_CID_FLASH_DURATION,
+						   0, exposure_us,
+						   1, OV9282_FLASH_DURATION_DEFAULT);
 
 	ctrl = v4l2_ctrl_new_std_menu(ctrl_hdlr, &ov9282_ctrl_ops,
 				      V4L2_CID_FLASH_STROBE_SOURCE,

-- 
2.47.2

