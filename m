From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:28 +0800
Subject: [PATCH 13/21] media: i2c: it6625: decode detected timings via
 typed register structs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-13-78d72d7886a5@ite.com.tw>
References: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
In-Reply-To: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=3215;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=5lnagqXC/VlYNEww2tkf1miEftUj9bs+qaABWCI/ZBM=;
 b=js8dL98lj0eF87rsg4Ox0NbHv+OH1DnkMHuBlo5SQ5dpCVei1YBzBKorMGvoIJIT/S+96ltfd
 gblkX3Ic9UlC9psDnfVxfTlBNuTKW+aZquOpK0WNQ2/HjmUMVNYcOlO
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_get_detected_timings() manually assembled each 16-bit field from
raw byte-buffer offsets with a shift-and-add sequence. Define two local
structs of __be16 fields matching the contiguous REG_H_ACTIVE_1..
REG_V_ACTIVE_0 and REG_H_FP_1..REG_V_BP_0 register layouts, read
directly into them, and decode each field with be16_to_cpu(). Guard
each struct's size with static_assert() against the expected register
range width.

Every member is 2 bytes wide and naturally aligned, so the struct is
laid out with no padding -- this is safe because the struct is the I2C
read target itself, not a cast over a pre-existing raw buffer.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 41 +++++++++++++++++++++++++----------------
 1 file changed, 25 insertions(+), 16 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 60c79a2277941621c7aa83189244b706a5505d66..90b87dbf54fcfc7ad2a1245d4594beee24a193ca 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -769,10 +769,22 @@ static int it6625_get_detected_timings(struct it6625 *it6625,
 				       struct v4l2_dv_timings *timings)
 {
 	struct v4l2_bt_timings *bt = &timings->bt;
+	struct {
+		__be16 h_active;
+		__be16 v_active;
+	} active;
+	struct {
+		__be16 hfrontporch;
+		__be16 hsync;
+		__be16 hbackporch;
+		__be16 vfrontporch;
+		__be16 vsync;
+		__be16 vbackporch;
+	} porch;
 	int val;
-	unsigned int width, height;
-	u8 buffer[4];
-	u8 buffer2[12];
+
+	static_assert(sizeof(active) == 4);
+	static_assert(sizeof(porch) == 12);
 
 	if (no_signal(it6625)) {
 		dev_err(it6625->dev, "no signal detected");
@@ -792,24 +804,21 @@ static int it6625_get_detected_timings(struct it6625 *it6625,
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

