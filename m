From: Yedaya Katsman <yedaya.ka@gmail.com>
Date: Tue, 13 Jan 2026 21:12:36 +0200
Subject: [PATCH 2/3] drivers: input: touchscreen: edt-ft5x06: Add FocalTech
 FT3518
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260113-touchscreen-patches-v1-2-a10957f32dd8@gmail.com>
References: <20260113-touchscreen-patches-v1-0-a10957f32dd8@gmail.com>
In-Reply-To: <20260113-touchscreen-patches-v1-0-a10957f32dd8@gmail.com>
To: SzczurekYT <szczurek@szczurek.yt>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Yedaya Katsman <yedaya.ka@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768331572; l=2061;
 i=yedaya.ka@gmail.com; s=20260113; h=from:subject:message-id;
 bh=JnmTIk3Utyw1IEV6j9HoQE20ccGFIPQTbMPlc8S8rg0=;
 b=VefCILwUwN1yAOrpDgYDyZ004CW6l+cWN/xDEauZkH7eyqyWpwJ4YuU2xhvJKW9WvNwCmBBUt
 zdCsnhzEbsrBVwKTApZ+KAAxqjb+CT43foJ7bme5z82RiLw9CE1irVQ
X-Developer-Key: i=yedaya.ka@gmail.com; a=ed25519;
 pk=CgNmxD3tYSws5dZfpmJfc6re/bV/f47veVijddHLytk=
X-Endpoint-Received: by B4 Relay for yedaya.ka@gmail.com/20260113 with auth_id=601
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver also works with FT3518, which supports up to 10 touch points.
 Add compatible data for it.

Co-developed-by: SzczurekYT <szczurek@szczurek.yt>
Signed-off-by: SzczurekYT <szczurek@szczurek.yt>
Signed-off-by: Yedaya Katsman <yedaya.ka@gmail.com>
---
 drivers/input/touchscreen/edt-ft5x06.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/input/touchscreen/edt-ft5x06.c b/drivers/input/touchscreen/edt-ft5x06.c
index bf498bd4dea9651ac939fe137b1c0f05e8557962..d0ab644be0069b5ab29ed037fa090a4279870193 100644
--- a/drivers/input/touchscreen/edt-ft5x06.c
+++ b/drivers/input/touchscreen/edt-ft5x06.c
@@ -1475,6 +1475,10 @@ static const struct edt_i2c_chip_data edt_ft5x06_data = {
 	.max_support_points = 5,
 };
 
+static const struct edt_i2c_chip_data edt_ft3518_data = {
+	.max_support_points = 10,
+};
+
 static const struct edt_i2c_chip_data edt_ft5452_data = {
 	.max_support_points = 5,
 };
@@ -1503,6 +1507,7 @@ static const struct i2c_device_id edt_ft5x06_ts_id[] = {
 	{ .name = "edt-ft5x06", .driver_data = (long)&edt_ft5x06_data },
 	{ .name = "edt-ft5506", .driver_data = (long)&edt_ft5506_data },
 	{ .name = "ev-ft5726", .driver_data = (long)&edt_ft5506_data },
+	{ .name = "ft3518", .driver_data = (long)&edt_ft3518_data },
 	{ .name = "ft5452", .driver_data = (long)&edt_ft5452_data },
 	/* Note no edt- prefix for compatibility with the ft6236.c driver */
 	{ .name = "ft6236", .driver_data = (long)&edt_ft6236_data },
@@ -1519,6 +1524,7 @@ static const struct of_device_id edt_ft5x06_of_match[] = {
 	{ .compatible = "edt,edt-ft5406", .data = &edt_ft5x06_data },
 	{ .compatible = "edt,edt-ft5506", .data = &edt_ft5506_data },
 	{ .compatible = "evervision,ev-ft5726", .data = &edt_ft5506_data },
+	{ .compatible = "focaltech,ft3518", .data = &edt_ft3518_data },
 	{ .compatible = "focaltech,ft5426", .data = &edt_ft5506_data },
 	{ .compatible = "focaltech,ft5452", .data = &edt_ft5452_data },
 	/* Note focaltech vendor prefix for compatibility with ft6236.c */

-- 
2.52.0

