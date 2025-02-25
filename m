From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 25 Feb 2025 14:08:40 +0100
Subject: [PATCH 1/3] media: i2c: ov9282: use register definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250225-b4-ov9282-gain-v1-1-a24af2820dde@linux.dev>
References: <20250225-b4-ov9282-gain-v1-0-a24af2820dde@linux.dev>
In-Reply-To: <20250225-b4-ov9282-gain-v1-0-a24af2820dde@linux.dev>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740488957; l=1452;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=mJB3OeO7yxJLnmoNvPHcVDUdgqbN6kyIO0TWpaVm7Sk=;
 b=KwJ/U+DQUyz7ELVGsgLc1ocM+cs3un14JD1rk6kPXywBfpHDvZJR25YOhrFecZc8jmbbA2RFs
 xfW0rTF4l9nDnottl1hg7hd9OZl/DVjcdwaQiX0IcWjlk+G0/6+WZHY
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For better readability use already available register definitions in
hard-coded common and mode register structs.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index 87e5d7ce5a47ee23a721ea39c0ab314c6fca6007..c926842257893c4da3319b847fab9908b5bdaec6 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -296,8 +296,8 @@ static const struct ov9282_reg mode_1280x800_regs[] = {
 	{0x3813, 0x08},
 	{0x3814, 0x11},
 	{0x3815, 0x11},
-	{0x3820, 0x40},
-	{0x3821, 0x00},
+	{OV9282_REG_TIMING_FORMAT_1, 0x40},
+	{OV9282_REG_TIMING_FORMAT_2, 0x00},
 	{0x4003, 0x40},
 	{0x4008, 0x04},
 	{0x4009, 0x0b},
@@ -327,8 +327,8 @@ static const struct ov9282_reg mode_1280x720_regs[] = {
 	{0x3813, 0x08},
 	{0x3814, 0x11},
 	{0x3815, 0x11},
-	{0x3820, 0x3c},
-	{0x3821, 0x84},
+	{OV9282_REG_TIMING_FORMAT_1, 0x3c},
+	{OV9282_REG_TIMING_FORMAT_2, 0x84},
 	{0x4003, 0x40},
 	{0x4008, 0x02},
 	{0x4009, 0x05},
@@ -358,8 +358,8 @@ static const struct ov9282_reg mode_640x400_regs[] = {
 	{0x3813, 0x04},
 	{0x3814, 0x31},
 	{0x3815, 0x22},
-	{0x3820, 0x60},
-	{0x3821, 0x01},
+	{OV9282_REG_TIMING_FORMAT_1, 0x60},
+	{OV9282_REG_TIMING_FORMAT_2, 0x01},
 	{0x4008, 0x02},
 	{0x4009, 0x05},
 	{0x400c, 0x00},

-- 
2.47.2

