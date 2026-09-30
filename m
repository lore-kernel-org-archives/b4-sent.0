From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:31 +0800
Subject: [PATCH v2 13/21] media: i2c: it6625: decode detected timings via
 typed register structs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-13-e353f887e7fa@ite.com.tw>
References: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
In-Reply-To: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=3738;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=Uzr9QZMp3XmUfUWG5ocFDWtRwwDwuGi09aTo3qivrQg=;
 b=v/2lUIbyrSOPnXLvCZcVhA9UU1oMcSxNdN2f6XQYW0BjsfQ0ahghjNbLDuQ7Gnfj0PVYiON05
 2F1nzqjzAmsDpX8UY8lcYROMIPkcotlScfY8HRcQAib/9U0jgsuinQD
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_get_detected_timings() manually assembled each 16-bit field from
raw byte-buffer offsets with a shift-and-add sequence. Define two named
structs of __be16 fields matching the contiguous REG_H_ACTIVE_1..
REG_V_ACTIVE_0 and REG_H_FP_1..REG_V_BP_0 register layouts at file
scope, immediately above the function that uses them -- this driver
accesses many such register areas, so keep the layout struct separate
from its one caller instead of declaring it locally. Read directly into
them, and decode each field with be16_to_cpu(). Guard each struct's
size with static_assert() against the expected register range width.

Every member is 2 bytes wide and naturally aligned, so the struct is
laid out with no padding -- this is safe because the struct is the I2C
read target itself, not a cast over a pre-existing raw buffer.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 48 ++++++++++++++++++++++++++++++----------------
 1 file changed, 32 insertions(+), 16 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index f77eb3ed63f7695cf9da277b46d9bab4a526e065..7582c12c268e1878f15c0f3c6030aacf8e78a5a4 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -765,14 +765,33 @@ static void it6625_hpd_delayed_work(struct work_struct *work)
 	it6625_update_config(it6625);
 }
 
+/* REG_H_ACTIVE_1..REG_V_ACTIVE_0 */
+struct it6625_active_size_regs {
+	__be16 h_active;
+	__be16 v_active;
+};
+
+static_assert(sizeof(struct it6625_active_size_regs) == 4);
+
+/* REG_H_FP_1..REG_V_BP_0 */
+struct it6625_porch_regs {
+	__be16 hfrontporch;
+	__be16 hsync;
+	__be16 hbackporch;
+	__be16 vfrontporch;
+	__be16 vsync;
+	__be16 vbackporch;
+};
+
+static_assert(sizeof(struct it6625_porch_regs) == 12);
+
 static int it6625_get_detected_timings(struct it6625 *it6625,
 				       struct v4l2_dv_timings *timings)
 {
 	struct v4l2_bt_timings *bt = &timings->bt;
+	struct it6625_active_size_regs active;
+	struct it6625_porch_regs porch;
 	int val;
-	unsigned int width, height;
-	u8 buffer[4];
-	u8 buffer2[12];
 
 	if (no_signal(it6625)) {
 		dev_err(it6625->dev, "no signal detected");
@@ -792,24 +811,21 @@ static int it6625_get_detected_timings(struct it6625 *it6625,
 	bt->interlaced = val & B_INTERLACE ?
 			 V4L2_DV_INTERLACED : V4L2_DV_PROGRESSIVE;
 
-	if (it6625_read_bytes(it6625, REG_H_ACTIVE_1, buffer, 4) < 0)
+	if (it6625_read_bytes(it6625, REG_H_ACTIVE_1, (u8 *)&active, sizeof(active)) < 0)
 		return -EIO;
 
-	width = ((buffer[0] & 0xff) << 8) + buffer[1];
-	height = ((buffer[2] & 0xff) << 8) + buffer[3];
-
-	bt->width = width;
-	bt->height = height;
+	bt->width = be16_to_cpu(active.h_active);
+	bt->height = be16_to_cpu(active.v_active);
 
-	if (it6625_read_bytes(it6625, REG_H_FP_1, buffer2, 12) < 0)
+	if (it6625_read_bytes(it6625, REG_H_FP_1, (u8 *)&porch, sizeof(porch)) < 0)
 		return -EIO;
 
-	bt->hfrontporch = ((buffer2[0] & 0xff) << 8) + buffer2[1];
-	bt->hsync = ((buffer2[2] & 0xff) << 8) + buffer2[3];
-	bt->hbackporch = ((buffer2[4] & 0xff) << 8) + buffer2[5];
-	bt->vfrontporch = ((buffer2[6] & 0xff) << 8) + buffer2[7];
-	bt->vsync = ((buffer2[8] & 0xff) << 8) + buffer2[9];
-	bt->vbackporch = ((buffer2[10] & 0xff) << 8) + buffer2[11];
+	bt->hfrontporch = be16_to_cpu(porch.hfrontporch);
+	bt->hsync = be16_to_cpu(porch.hsync);
+	bt->hbackporch = be16_to_cpu(porch.hbackporch);
+	bt->vfrontporch = be16_to_cpu(porch.vfrontporch);
+	bt->vsync = be16_to_cpu(porch.vsync);
+	bt->vbackporch = be16_to_cpu(porch.vbackporch);
 
 	bt->pixelclock = it6625_get_pclk(it6625);
 	if (bt->interlaced == V4L2_DV_INTERLACED) {

-- 
2.34.1

