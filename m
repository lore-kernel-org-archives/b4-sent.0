From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 20 Jul 2026 20:31:00 +0200
Subject: [PATCH] media: i2c: ov9282: restore flash duration calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-ov9282-fix-v1-1-0145062ec9f1@linux.dev>
X-B4-Tracking: v=1; b=H4sIAGNpXmoC/yXMQQ5AMBCF4as0s9aknQjlKmJBDcYCaWkkjbsrl
 t9L3h/Bk2PyUIsIjgJ73tYEnQmwc7dOJHlIBlRYqBKV3EKFBuXIlyRLRa4HW3bGQDrsjtL8xZr
 2tz/7hezxFuC+H7SMldVuAAAA
X-Change-ID: 20260720-ov9282-fix-ece641dc7a88
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Tarang Raval <tarang.raval@siliconsignals.io>, 
 Xiaolei Wang <xiaolei.wang@windriver.com>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784572267; l=1494;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=TF1Va7Kvd78gB/+nDw6b3xVkllExwoPZb7OdeLW7OqU=;
 b=tC0eEjcpW4RTuCluO4nHRi8JlMSZv3R8zhKpzfRiYD3RhCTPTAA+NABjr6oFhGRNtFhGs1VtH
 MqF77ZkKbBpBNTPtQppVIPuPBiYFuoXSgQ4SEgLCQM1gJwv0k7w5Qb9
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The migration to CCI helpers made V4L2_CID_FLASH_DURATION write the
requested duration directly to OV9282_REG_STROBE_FRAME_SPAN, dropping
the conversion from microseconds to the register value.

This made flash strobes too long and produced overly bright frames.
Restore the missing calculation so flash duration is programmed
correctly again.

Fixes: 273f52f3cbec ("media: i2c: ov9282: Convert to CCI register access helpers")
Cc: Xiaolei Wang <xiaolei.wang@windriver.com>
Cc: stable@vger.kernel.org
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index 5b6f897a74fcd..5abe51d21f89c 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -648,7 +648,8 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 				      ctrl->val ? OV9282_OUTPUT_ENABLE6_STROBE : 0, NULL);
 		break;
 	case V4L2_CID_FLASH_DURATION:
-		ret = cci_write(ov9282->regmap, OV9282_REG_STROBE_FRAME_SPAN, ctrl->val, NULL);
+		ret = cci_write(ov9282->regmap, OV9282_REG_STROBE_FRAME_SPAN,
+				ov9282_us_to_flash_duration(ov9282, ctrl->val), NULL);
 		break;
 	default:
 		dev_err(ov9282->dev, "Invalid control %d", ctrl->id);

---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260720-ov9282-fix-ece641dc7a88

Best regards,
--  
Richard Leitner <richard.leitner@linux.dev>

