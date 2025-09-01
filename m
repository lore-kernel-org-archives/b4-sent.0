From: Richard Leitner <richard.leitner@linux.dev>
Date: Mon, 01 Sep 2025 17:05:14 +0200
Subject: [PATCH v7 09/10] media: i2c: ov9282: implement try_ctrl for
 strobe_duration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250901-ov9282-flash-strobe-v7-9-d58d5a694afc@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756739145; l=3557;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=zpPHdpszebqthTo574ANivruP/PT3WTF/uH/e9F0K+Q=;
 b=fdpLvNSFQTEl59tQ4YakjWj1z05zOCV+ppEi1wuerOUr0783No1fAR5HN5UemEDEp2sPKBg5T
 IUi4JPUzkgHAn4LjpaiRldZVANfx4P4WAnHDgSSEAIrMxjOUzoF+doI
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As the granularity of the hardware supported values is lower than the
control value, implement a try_ctrl() function for
V4L2_CID_FLASH_DURATION. This function calculates the nearest possible
µs strobe duration for the given value and returns it back to the
caller.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 54 ++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 52 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index 9efc82a1929a76c6fb245e7dbfb5276a133d1c5d..b104ae77f00e9e7777342e48b7bf3caa6d297f69 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -128,6 +128,8 @@
 #define OV9282_REG_MIN		0x00
 #define OV9282_REG_MAX		0xfffff
 
+#define OV9282_STROBE_SPAN_FACTOR	192
+
 static const char * const ov9282_supply_names[] = {
 	"avdd",		/* Analog power */
 	"dovdd",	/* Digital I/O power */
@@ -691,7 +693,7 @@ static int ov9282_set_ctrl_flash_hw_strobe_signal(struct ov9282 *ov9282, bool en
 				current_val);
 }
 
-static int ov9282_set_ctrl_flash_duration(struct ov9282 *ov9282, u32 value)
+static u32 ov9282_us_to_flash_duration(struct ov9282 *ov9282, u32 value)
 {
 	/*
 	 * Calculate "strobe_frame_span" increments from a given value (µs).
@@ -702,7 +704,27 @@ static int ov9282_set_ctrl_flash_duration(struct ov9282 *ov9282, u32 value)
 	 * The formula below is interpolated from different modes/framerates
 	 * and should work quite well for most settings.
 	 */
-	u32 val = value * 192 / (ov9282->cur_mode->width + ov9282->hblank_ctrl->val);
+	u32 frame_width = ov9282->cur_mode->width + ov9282->hblank_ctrl->val;
+
+	return value * OV9282_STROBE_SPAN_FACTOR / frame_width;
+}
+
+static u32 ov9282_flash_duration_to_us(struct ov9282 *ov9282, u32 value)
+{
+	/*
+	 * As the calculation in ov9282_us_to_flash_duration uses an integer
+	 * divison calculate in ns here to get more precision. Then check if
+	 * we need to compensate that divison by incrementing the µs result.
+	 */
+	u32 frame_width = ov9282->cur_mode->width + ov9282->hblank_ctrl->val;
+	u64 ns = value * 1000 * frame_width / OV9282_STROBE_SPAN_FACTOR;
+
+	return DIV_ROUND_UP(ns, 1000);
+}
+
+static int ov9282_set_ctrl_flash_duration(struct ov9282 *ov9282, u32 value)
+{
+	u32 val = ov9282_us_to_flash_duration(ov9282, value);
 
 	ov9282_write_reg(ov9282, OV9282_REG_FLASH_DURATION, 1, (val >> 24) & 0xff);
 	ov9282_write_reg(ov9282, OV9282_REG_FLASH_DURATION + 1, 1, (val >> 16) & 0xff);
@@ -792,9 +814,37 @@ static int ov9282_set_ctrl(struct v4l2_ctrl *ctrl)
 	return ret;
 }
 
+static int ov9282_try_ctrl(struct v4l2_ctrl *ctrl)
+{
+	struct ov9282 *ov9282 =
+		container_of(ctrl->handler, struct ov9282, ctrl_handler);
+
+	if (ctrl->id == V4L2_CID_FLASH_DURATION) {
+		u32 fd = ov9282_us_to_flash_duration(ov9282, ctrl->val);
+		u32 us = ctrl->val;
+
+		/* get nearest strobe_duration value */
+		u32 us0 = ov9282_flash_duration_to_us(ov9282, fd);
+		u32 us1 = ov9282_flash_duration_to_us(ov9282, (fd + 1));
+
+		if (abs(us1 - us) < abs(us - us0))
+			ctrl->val = us1;
+		else
+			ctrl->val = us0;
+
+		if (us != ctrl->val) {
+			dev_dbg(ov9282->dev, "using next valid strobe_duration %u instead of %u\n",
+				ctrl->val, us);
+		}
+	}
+
+	return 0;
+}
+
 /* V4l2 subdevice control ops*/
 static const struct v4l2_ctrl_ops ov9282_ctrl_ops = {
 	.s_ctrl = ov9282_set_ctrl,
+	.try_ctrl = ov9282_try_ctrl,
 };
 
 /**

-- 
2.47.2

