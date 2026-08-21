From: Markuss Broks <markuss.broks@gmail.com>
Date: Sat, 22 Aug 2026 00:30:17 +0300
Subject: [PATCH 5/5] Input: imagis - add support for IST4050
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-imagis-40xx-v1-5-73e6d6cdf110@gmail.com>
References: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
In-Reply-To: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Markuss Broks <markuss.broks@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787347843; l=2500;
 i=markuss.broks@gmail.com; s=20260803; h=from:subject:message-id;
 bh=UyRIydLek5fXGaLKcikWjx0AWVlXprKtHklwuZw8lBY=;
 b=ctEYCAqRbPnvqlBuV9ssbb0NokAiCtEwBZaZLprPpKtNGM6pUchmWwzrYqwGTF08a/9khUvHn
 sXYecFl38uFCXfbSRwgzL6s5/GhLQD3fjtBewApPhS2AaFAv33tqbRa
X-Developer-Key: i=markuss.broks@gmail.com; a=ed25519;
 pk=oKzGUTm30BCDqinRMpiHQqByOx1mp2mwmhg80Mv7Zg4=
X-Endpoint-Received: by B4 Relay for markuss.broks@gmail.com/20260803 with auth_id=911
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Imagis IST4050 shares the register interface and the power-up
sequence with IST3038C, and reports touches using the IST40xx touch
reporting format. Its chip ID register reads back 0x4050.

Also mention the IST40xx family in the Kconfig help text, and refer to
the older chips as IST30xx, since the driver supports more than the C
variants.

Signed-off-by: Markuss Broks <markuss.broks@gmail.com>
---
 drivers/input/touchscreen/Kconfig  |  2 +-
 drivers/input/touchscreen/imagis.c | 10 ++++++++++
 2 files changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/Kconfig b/drivers/input/touchscreen/Kconfig
index 9b9ae8ac3f7f..96fdc4384a75 100644
--- a/drivers/input/touchscreen/Kconfig
+++ b/drivers/input/touchscreen/Kconfig
@@ -705,7 +705,7 @@ config TOUCHSCREEN_IMAGIS
 	tristate "Imagis touchscreen support"
 	depends on I2C
 	help
-	  Say Y here if you have an Imagis IST30xxC touchscreen.
+	  Say Y here if you have an Imagis IST30xx or IST40xx touchscreen.
 	  If unsure, say N.
 
 	  To compile this driver as a module, choose M here: the
diff --git a/drivers/input/touchscreen/imagis.c b/drivers/input/touchscreen/imagis.c
index 5254cccdd653..9bf5afd43848 100644
--- a/drivers/input/touchscreen/imagis.c
+++ b/drivers/input/touchscreen/imagis.c
@@ -23,6 +23,7 @@
 #define IST3032C_WHOAMI			0x32c
 #define IST3038C_WHOAMI			0x38c
 #define IST3038H_WHOAMI			0x38d
+#define IST4050_WHOAMI			0x4050
 
 #define IST3038B_REG_CHIPID		0x30
 #define IST3038B_WHOAMI			0x30380b
@@ -491,12 +492,21 @@ static const struct imagis_properties imagis_3038h_data = {
 	.protocol = IMAGIS_PROTOCOL_SHARED_REGISTER,
 };
 
+static const struct imagis_properties imagis_4050_data = {
+	.interrupt_msg_cmd = IST3038C_REG_INTR_MESSAGE,
+	.touch_coord_cmd = IST3038C_REG_TOUCH_COORD,
+	.whoami_cmd = IST3038C_REG_CHIPID,
+	.whoami_val = IST4050_WHOAMI,
+	.protocol = IMAGIS_PROTOCOL_TOUCH_EVENTS,
+};
+
 static const struct of_device_id imagis_of_match[] = {
 	{ .compatible = "imagis,ist3032c", .data = &imagis_3032c_data },
 	{ .compatible = "imagis,ist3038", .data = &imagis_3038_data },
 	{ .compatible = "imagis,ist3038b", .data = &imagis_3038b_data },
 	{ .compatible = "imagis,ist3038c", .data = &imagis_3038c_data },
 	{ .compatible = "imagis,ist3038h", .data = &imagis_3038h_data },
+	{ .compatible = "imagis,ist4050", .data = &imagis_4050_data },
 	{ },
 };
 MODULE_DEVICE_TABLE(of, imagis_of_match);

-- 
2.55.0

