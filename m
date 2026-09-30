From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:34 +0800
Subject: [PATCH v2 16/21] media: i2c: it6625: drop the private CSI-format
 name table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-16-e353f887e7fa@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=2207;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=wCpy/UplelcFSxnwqg95Ja5ADbd8Nx3nmIgWYK2WAOg=;
 b=KRWq9lHLgL98Dn6Yq+yck1Q2RTntOj+L/nyWuJh0q7GEOKFUC/VLvTrqnJkSsYrIswG8Zi/LF
 dE7rOHskoCTC5mZowGrpZmYYjx358cL7JYrUYQ7+QJQUZ6uUXLSqlHI
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_csi_format_name(), used only by it6625_log_status(), maintains
a driver-local name table for a value V4L2 already exposes as a
media-bus format code. No in-kernel helper converts MEDIA_BUS_FMT_*
codes to printable names, so report the raw media-bus code as %#x
instead. it6625_log_status() now snapshots it6625->mbus_fmt_code
(the value actually used elsewhere as the driver's representation of
the current format) under it6625_lock instead of the separate
csi_format field.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 22 +++-------------------
 1 file changed, 3 insertions(+), 19 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index c972a74dd5d63655d531579cfd4e8dc3f72cb7ae..7637418c5a214d32f75d197a1e0ba1bffe7235f9 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -1366,26 +1366,12 @@ static void it6625_polling_work(struct work_struct *work)
 	it6625_interrupt_handler(it6625);
 }
 
-static const char *it6625_csi_format_name(u8 csi_format)
-{
-	switch (csi_format) {
-	case CSI_YUV422_8b:
-		return "YUV422 8bit";
-	case CSI_RGB888:
-		return "RGB888 8bit";
-	case CSI_YUV444_8b:
-		return "YUV444 8bit";
-	default:
-		return "unknown";
-	}
-}
-
 static int it6625_log_status(struct v4l2_subdev *sd)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
 	struct v4l2_dv_timings timings, configured_timings;
 	struct v4l2_bt_timings bt;
-	u8 csi_format;
+	u32 mbus_fmt_code;
 
 	if (it6625_get_detected_timings(it6625, &timings))
 		v4l2_info(sd, "No video detected");
@@ -1399,13 +1385,11 @@ static int it6625_log_status(struct v4l2_subdev *sd)
 
 	/* snapshot together so the reported pair was actually configured together */
 	scoped_guard(mutex, &it6625->it6625_lock) {
-		csi_format = it6625->csi_format;
+		mbus_fmt_code = it6625->mbus_fmt_code;
 		bt = it6625->timings.bt;
 	}
 
-	v4l2_info(sd, "CSI format: %s @ %uHz",
-		  it6625_csi_format_name(csi_format),
-		  fps_from_bt_timings(&bt));
+	v4l2_info(sd, "CSI format: %#x @ %uHz", mbus_fmt_code, fps_from_bt_timings(&bt));
 
 	it6625_show_avi_infoframe(it6625);
 

-- 
2.34.1

