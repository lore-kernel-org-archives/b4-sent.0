From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 10 Nov 2026 14:10:16 +0100
Subject: [PATCH v3 7/8] media: i2c: ov9282: drop redundant vblank field
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-ov9282-fixes-v3-7-cb6df80cbc22@linux.dev>
References: <20261110-ov9282-fixes-v3-0-cb6df80cbc22@linux.dev>
In-Reply-To: <20261110-ov9282-fixes-v3-0-cb6df80cbc22@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Daniele Alessandrelli <daniele.alessandrelli@gmail.com>, 
 "Paul J. Murphy" <paul.j.murphy@intel.com>, 
 Martina Krasteva <martinax.krasteva@intel.com>, 
 Richard Leitner <richard.leitner@linux.dev>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 Gyula Kelemen <gyula.kelemen@advasolutions.com>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794316220; l=2587;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=crQJ9f8EsYTkvfucspMpYtviPUKObgIfvZ6RdzbwfZk=;
 b=mvndjk3+2li2lsiSbUa5cplumN//f8Jf9Y2dkcQWFutlUk/Qu8KRGX63rwhz9npI4dWesnkFx
 w1sJQUPeylwAuH4x/v3kCEn7VHvqM5IkXlKhAF0kBTv7UpnWBLhEBwO
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ov9282 main struct has a dedicated vblank field which was only used
to duplicate the value of the vblank v4l2 control.

Therefore drop this struct field.

Reviewed-by: Dave Stevenson <dave.stevenson@raspberrypi.com>
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 15 ++++-----------
 1 file changed, 4 insertions(+), 11 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index e46695d1377ed..d24fcdd4bcc33 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -196,7 +196,6 @@ struct ov9282_mode {
  * @again_ctrl: Pointer to analog gain control
  * @pixel_rate: Pointer to pixel rate control
  * @flash_duration: Pointer to flash duration control
- * @vblank: Vertical blanking in lines
  * @noncontinuous_clock: Selection of CSI2 noncontinuous clock mode
  * @cur_mode: Pointer to current selected sensor mode
  * @code: Mbus code currently selected
@@ -219,7 +218,6 @@ struct ov9282 {
 	};
 	struct v4l2_ctrl *pixel_rate;
 	struct v4l2_ctrl *flash_duration;
-	u32 vblank;
 	bool noncontinuous_clock;
 	const struct ov9282_mode *cur_mode;
 	u32 code;
@@ -629,17 +627,13 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 
 	switch (ctrl->id) {
 	case V4L2_CID_VBLANK:
-		ov9282->vblank = ov9282->vblank_ctrl->val;
-
+		lpfr = ctrl->val + ov9282->cur_mode->height;
 		dev_dbg(ov9282->dev, "Received vblank %u, new lpfr %u",
-			ov9282->vblank,
-			ov9282->vblank + ov9282->cur_mode->height);
+			ctrl->val, lpfr);
 
 		ret = __v4l2_ctrl_modify_range(ov9282->exp_ctrl,
 					       OV9282_EXPOSURE_MIN,
-					       ov9282->vblank +
-					       ov9282->cur_mode->height -
-					       OV9282_EXPOSURE_OFFSET,
+					       lpfr - OV9282_EXPOSURE_OFFSET,
 					       1, OV9282_EXPOSURE_DEFAULT);
 		if (ret)
 			return ret;
@@ -666,7 +660,7 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 		ret = ov9282_update_exp_gain(ov9282, exposure, analog_gain);
 		break;
 	case V4L2_CID_VBLANK:
-		lpfr = ov9282->vblank + ov9282->cur_mode->height;
+		lpfr = ctrl->val + ov9282->cur_mode->height;
 		ret = cci_write(ov9282->regmap, OV9282_REG_LPFR, lpfr, NULL);
 		break;
 	case V4L2_CID_HFLIP:
@@ -1384,7 +1378,6 @@ static int ov9282_probe(struct i2c_client *client)
 	/* Set default mode to first mode */
 	ov9282->cur_mode = &supported_modes[DEFAULT_MODE];
 	ov9282->code = MEDIA_BUS_FMT_Y10_1X10;
-	ov9282->vblank = ov9282->cur_mode->vblank;
 
 	ret = ov9282_init_controls(ov9282);
 	if (ret) {

-- 
2.53.0

