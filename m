From: Joel Selvaraj <joelselvaraj.oss@gmail.com>
Date: Tue, 21 May 2024 09:02:58 -0500
Subject: [PATCH 2/2] Input: edt-ft5x06 - add support for FocalTech FT5452
 and FT8719
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240521-add-support-ft5452-and-ft8719-touchscreen-v1-2-2a648ac7176b@gmail.com>
References: <20240521-add-support-ft5452-and-ft8719-touchscreen-v1-0-2a648ac7176b@gmail.com>
In-Reply-To: <20240521-add-support-ft5452-and-ft8719-touchscreen-v1-0-2a648ac7176b@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joel Selvaraj <joelselvaraj.oss@gmail.com>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716300186; l=2353;
 i=joelselvaraj.oss@gmail.com; s=20240420; h=from:subject:message-id;
 bh=nQ1HQkXEqDosRHt1dsb4w1mHu9DuJ+dY0jyixkP33Sg=;
 b=LHJ7zHKBvISv0qDMgtXQbhmmXEHNomIwmkjkw7JBM9rzrCbY9vOch4bBlQXVuDcL8WYJAm5Mi
 oCm9etvk9BPDPIMxoWd71ZEci7+JHmUPDpUweg8BcI3D1LHWp3LaxsG
X-Developer-Key: i=joelselvaraj.oss@gmail.com; a=ed25519;
 pk=qT4gsuVtlPE0Dpr+tQA/Fumm7wzVP6qfeVaY+6pX04s=
X-Endpoint-Received: by B4 Relay for joelselvaraj.oss@gmail.com/20240420 with auth_id=165
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver is compatible with FocalTech FT5452 and FT8719 touchscreens
too. FT5452 supports up to 5 touch points. FT8719 supports up to 10 touch
points. Add compatible data for both of them.

Signed-off-by: Joel Selvaraj <joelselvaraj.oss@gmail.com>
---
 drivers/input/touchscreen/edt-ft5x06.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/input/touchscreen/edt-ft5x06.c b/drivers/input/touchscreen/edt-ft5x06.c
index 2a1db11344766..06ec0f2e18ae3 100644
--- a/drivers/input/touchscreen/edt-ft5x06.c
+++ b/drivers/input/touchscreen/edt-ft5x06.c
@@ -1462,6 +1462,10 @@ static const struct edt_i2c_chip_data edt_ft5x06_data = {
 	.max_support_points = 5,
 };
 
+static const struct edt_i2c_chip_data edt_ft5452_data = {
+	.max_support_points = 5,
+};
+
 static const struct edt_i2c_chip_data edt_ft5506_data = {
 	.max_support_points = 10,
 };
@@ -1470,12 +1474,18 @@ static const struct edt_i2c_chip_data edt_ft6236_data = {
 	.max_support_points = 2,
 };
 
+static const struct edt_i2c_chip_data edt_ft8719_data = {
+	.max_support_points = 10,
+};
+
 static const struct i2c_device_id edt_ft5x06_ts_id[] = {
 	{ .name = "edt-ft5x06", .driver_data = (long)&edt_ft5x06_data },
 	{ .name = "edt-ft5506", .driver_data = (long)&edt_ft5506_data },
 	{ .name = "ev-ft5726", .driver_data = (long)&edt_ft5506_data },
+	{ .name = "ft5452", .driver_data = (long)&edt_ft5452_data },
 	/* Note no edt- prefix for compatibility with the ft6236.c driver */
 	{ .name = "ft6236", .driver_data = (long)&edt_ft6236_data },
+	{ .name = "ft8719", .driver_data = (long)&edt_ft8719_data },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(i2c, edt_ft5x06_ts_id);
@@ -1486,8 +1496,10 @@ static const struct of_device_id edt_ft5x06_of_match[] = {
 	{ .compatible = "edt,edt-ft5406", .data = &edt_ft5x06_data },
 	{ .compatible = "edt,edt-ft5506", .data = &edt_ft5506_data },
 	{ .compatible = "evervision,ev-ft5726", .data = &edt_ft5506_data },
+	{ .compatible = "focaltech,ft5452", .data = &edt_ft5452_data },
 	/* Note focaltech vendor prefix for compatibility with ft6236.c */
 	{ .compatible = "focaltech,ft6236", .data = &edt_ft6236_data },
+	{ .compatible = "focaltech,ft8719", .data = &edt_ft8719_data },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, edt_ft5x06_of_match);

-- 
2.45.1

