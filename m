From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 25 Feb 2025 14:08:42 +0100
Subject: [PATCH 3/3] media: i2c: ov9282: fix analogue gain maximum
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250225-b4-ov9282-gain-v1-3-a24af2820dde@linux.dev>
References: <20250225-b4-ov9282-gain-v1-0-a24af2820dde@linux.dev>
In-Reply-To: <20250225-b4-ov9282-gain-v1-0-a24af2820dde@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740488957; l=2508;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=KF5ZO6ejS0ACndO4NFjdXXOOXXaUCY9pfvk3vfNCGDc=;
 b=Wy3qIvcFnUZxA6mDs+WE167dDcqWuS83NVPC7MitfLarLKKapbyUYFnFzapJIgVl6JQsg2/Hf
 /irWAutIOKQCLac2qmTmi2mz9uo/8jG2Nwvy1oR3Vk8J40E43apvdXe
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sensors analogue gain is stored within two "LONG GAIN" registers
(0x3508 and 0x3509) where the first one holds the upper 5 bits of the
value. The second register (0x3509) holds the lower 4 bits of the gain
value in its upper 4 bits. The lower 4 register bits are fraction bits.

This patch changes the gain control to adhere to the datasheet and
make the "upper gain register" (0x3508) accessible via the gain control,
resulting in a new maximum of 0x1fff instead of 0xff.

As the "upper gain register" is now written during exposure/gain update
remove the hard-coded 0x00 write to it from common_regs.

We cover only the "real gain format" use-case. The "sensor gain
format" one is ignored as based on the hard-coded "AEC MANUAL" register
configuration it is disabled.

All values are based on the OV9281 datasheet v1.01 (09.18.2015).

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 17 ++++++++++-------
 1 file changed, 10 insertions(+), 7 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index c882a021cf18852237bf9b9524d3de0c5b48cbcb..e6effb2b42d4d5d0ca3d924df59c60512f9ce65d 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -54,11 +54,11 @@
 #define OV9282_AEC_MANUAL_DEFAULT	0x00
 
 /* Analog gain control */
-#define OV9282_REG_AGAIN	0x3509
-#define OV9282_AGAIN_MIN	0x10
-#define OV9282_AGAIN_MAX	0xff
-#define OV9282_AGAIN_STEP	1
-#define OV9282_AGAIN_DEFAULT	0x10
+#define OV9282_REG_AGAIN	0x3508
+#define OV9282_AGAIN_MIN	0x0010
+#define OV9282_AGAIN_MAX	0x1fff
+#define OV9282_AGAIN_STEP	0x0001
+#define OV9282_AGAIN_DEFAULT	0x0010
 
 /* Group hold register */
 #define OV9282_REG_HOLD		0x3308
@@ -226,7 +226,6 @@ static const struct ov9282_reg common_regs[] = {
 	{OV9282_REG_AEC_MANUAL, OV9282_GAIN_PREC16_EN},
 	{0x3505, 0x8c},
 	{0x3507, 0x03},
-	{0x3508, 0x00},
 	{0x3610, 0x80},
 	{0x3611, 0xa0},
 	{0x3620, 0x6e},
@@ -605,7 +604,11 @@ static int ov9282_update_exp_gain(struct ov9282 *ov9282, u32 exposure, u32 gain)
 	if (ret)
 		goto error_release_group_hold;
 
-	ret = ov9282_write_reg(ov9282, OV9282_REG_AGAIN, 1, gain);
+	ret = ov9282_write_reg(ov9282, OV9282_REG_AGAIN, 1, (gain >> 8) & 0x1f);
+	if (ret)
+		goto error_release_group_hold;
+
+	ret = ov9282_write_reg(ov9282, OV9282_REG_AGAIN + 1, 1, gain & 0xff);
 
 error_release_group_hold:
 	ov9282_write_reg(ov9282, OV9282_REG_HOLD, 1, 0);

-- 
2.47.2

