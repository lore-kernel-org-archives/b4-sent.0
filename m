From: Richard Leitner <richard.leitner@linux.dev>
Date: Wed, 14 Oct 2026 08:49:13 +0200
Subject: [PATCH v2 6/8] media: i2c: ov9282: recalculate strobe span on
 HBLANK change
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-ov9282-fixes-v2-6-3bb376d8b1a9@linux.dev>
References: <20261014-ov9282-fixes-v2-0-3bb376d8b1a9@linux.dev>
In-Reply-To: <20261014-ov9282-fixes-v2-0-3bb376d8b1a9@linux.dev>
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
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791960586; l=2043;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=/8aCB8InGPf7oWbj3PBJDIqHWuBXL5wzuxlJ0asuDZs=;
 b=JJINLnGzvY7c8vlM95QwHgeq1N+deUVyntB15s6yJykmSD+DO2eIsBYrLVMsOAYAQMRMlKEUp
 rtiRnCqUkYRCg/MYnTtKekOjRl+bjdh5wxp/4tewcS1KtlTY3pdmM2l
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When HBLANK changes the line time changes. This means the time base for
the strobe duration calculation changed. This results in the v4l2
strobe_duration control value and the strobe_span register value being
out of sync.

Fix this by recalculating the strobe_span register value on HBLANK
writes using the currently configured strobe_duration. This results in
the strobe_duration configured by userspace being kept, but the
underlying register value being changed. To ensure the values are
applied on the same frame guard the writes with OV9282_REG_HOLD.

Fixes: 84ec7597ae1af ("media: i2c: ov9282: add strobe_duration v4l2 control")
Cc: stable@vger.kernel.org
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index b48c959b9c908..5114fbf28a26c 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -625,6 +625,7 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 	u32 exposure;
 	u32 lpfr;
 	int ret;
+	int ret_hold;
 
 	switch (ctrl->id) {
 	case V4L2_CID_VBLANK:
@@ -677,8 +678,14 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 				      OV9282_FLIP_BIT, ctrl->val ? OV9282_FLIP_BIT : 0, NULL);
 		break;
 	case V4L2_CID_HBLANK:
-		ret = cci_write(ov9282->regmap, OV9282_REG_TIMING_HTS,
-				(ctrl->val + ov9282->cur_mode->width) >> 1, NULL);
+		ret = cci_write(ov9282->regmap, OV9282_REG_HOLD, 0x01, NULL);
+		cci_write(ov9282->regmap, OV9282_REG_TIMING_HTS,
+			  (ctrl->val + ov9282->cur_mode->width) >> 1, &ret);
+		cci_write(ov9282->regmap, OV9282_REG_STROBE_FRAME_SPAN,
+			  ov9282_us_to_lines(ov9282, ov9282->flash_duration->cur.val),
+			  &ret);
+		ret_hold = cci_write(ov9282->regmap, OV9282_REG_HOLD, 0, NULL);
+		ret = ret ? ret : ret_hold;
 		break;
 	case V4L2_CID_FLASH_STROBE_OE:
 		ret = cci_update_bits(ov9282->regmap, OV9282_REG_OUTPUT_ENABLE6,

-- 
2.53.0

