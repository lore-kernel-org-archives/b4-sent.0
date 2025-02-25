From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 25 Feb 2025 14:08:41 +0100
Subject: [PATCH 2/3] media: i2c: ov9282: add AEC Manual register definition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250225-b4-ov9282-gain-v1-2-a24af2820dde@linux.dev>
References: <20250225-b4-ov9282-gain-v1-0-a24af2820dde@linux.dev>
In-Reply-To: <20250225-b4-ov9282-gain-v1-0-a24af2820dde@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740488957; l=1395;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=0V1L6sP8vB21+gdfkiLRWy2BgxHEUONyy6cQBO3kICc=;
 b=yj6uHHm+94J4ghnUEWM6JwZOohXI11I/NXqPMuxTt7FGq2sELE3AbEu8DvcPO4ZjRaauCzc//
 ZDim+VzxNYKC2iHZPhLixbeb28F9ZaiLNQM0+SnKbTApIwyDmVZcqpf
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add #define's for the "AEC MANUAL" (0x3503) register and its
values/flags. Use those in the registers single usage within the
`common_regs` struct.

All values are based on the OV9281 datasheet v1.01 (09.18.2015).

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index c926842257893c4da3319b847fab9908b5bdaec6..c882a021cf18852237bf9b9524d3de0c5b48cbcb 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -44,6 +44,15 @@
 #define OV9282_EXPOSURE_STEP	1
 #define OV9282_EXPOSURE_DEFAULT	0x0282
 
+/* AEC/AGC manual */
+#define OV9282_REG_AEC_MANUAL		0x3503
+#define OV9282_DIGFRAC_GAIN_DELAY	BIT(6)
+#define OV9282_GAIN_CHANGE_DELAY	BIT(5)
+#define OV9282_GAIN_DELAY		BIT(4)
+#define OV9282_GAIN_PREC16_EN		BIT(3)
+#define OV9282_GAIN_MANUAL_AS_SENSGAIN	BIT(2)
+#define OV9282_AEC_MANUAL_DEFAULT	0x00
+
 /* Analog gain control */
 #define OV9282_REG_AGAIN	0x3509
 #define OV9282_AGAIN_MIN	0x10
@@ -214,7 +223,7 @@ static const struct ov9282_reg common_regs[] = {
 	{0x3030, 0x10},
 	{0x3039, 0x32},
 	{0x303a, 0x00},
-	{0x3503, 0x08},
+	{OV9282_REG_AEC_MANUAL, OV9282_GAIN_PREC16_EN},
 	{0x3505, 0x8c},
 	{0x3507, 0x03},
 	{0x3508, 0x00},

-- 
2.47.2

