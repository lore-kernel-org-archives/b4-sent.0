From: Roman Vivchar <rva333@protonmail.com>
Date: Sun, 08 Nov 2026 00:15:06 +0200
Subject: [PATCH 4/4] iio: light: stk3310: add stk3337 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-6768-stk3337-v1-4-0340c99b0e33@protonmail.com>
References: <20261108-6768-stk3337-v1-0-0340c99b0e33@protonmail.com>
In-Reply-To: <20261108-6768-stk3337-v1-0-0340c99b0e33@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794089703; l=2938;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=vkuVuX7Kh+a32Ce53rYW7Noy/cT8I5Rr0hB0sazZ9U0=;
 b=BVVWONPWgfwMZ3LX/Pkg9r9ApSLTqDIgFATDUY/d3/zVa6QHpFc1lf35aCxYoDsy3FYrzW0Jv
 dwJXBwCeAjRDH6boSBucONKlubNmh9r9Katq0ZCIacES9LY24Gt1fJV
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the stk3337 sensor, found in the Xiaomi Redmi Note 9
phone.

In addition to the standard stk3310 ambient light and proximity
channels, the stk3337 provides a clear intensity channel, matching the
layout already used by the stk36c61.

Datasheet: https://www.bestmodulescorp.com/en/amfile/file/download/file/1699/product/1048/
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/iio/light/stk3310.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/iio/light/stk3310.c b/drivers/iio/light/stk3310.c
index 2f4747c06f43..6d629ce726fc 100644
--- a/drivers/iio/light/stk3310.c
+++ b/drivers/iio/light/stk3310.c
@@ -60,6 +60,7 @@
 #define STK3311S34_CHIP_ID_VAL			0x1E
 #define STK3311X_CHIP_ID_VAL			0x12
 #define STK3335_CHIP_ID_VAL			0x51
+#define STK3337_CHIP_ID_VAL			0x5F
 #define STK36C61_CHIP_ID_VAL			0x95
 #define STK3310_PSINT_EN			0x01
 #define STK3310_PS_MAX_VAL			0xFFFF
@@ -111,6 +112,7 @@ static const u8 stk3310_chip_ids[] = {
 	STK3311X_CHIP_ID_VAL,
 	STK3311_CHIP_ID_VAL,
 	STK3335_CHIP_ID_VAL,
+	STK3337_CHIP_ID_VAL,
 	STK36C61_CHIP_ID_VAL,
 };
 
@@ -233,6 +235,12 @@ static const struct iio_chan_spec stk3310_channels[] = {
 	STK3310_PROXIMITY_CHANNEL,
 };
 
+static const struct iio_chan_spec stk3337_channels[] = {
+	STK3310_LIGHT_CHANNEL,
+	STK3310_PROXIMITY_CHANNEL,
+	STK36C61_INTENSITY_CHANNEL(CLEAR, STK36C61_REG_CLEAR_DATA_MSB),
+};
+
 static const struct iio_chan_spec stk36c61_channels[] = {
 	STK3310_LIGHT_CHANNEL,
 	STK3310_PROXIMITY_CHANNEL,
@@ -260,6 +268,12 @@ static const struct stk3310_chip_info stk3310_chip_info = {
 	.num_channels = ARRAY_SIZE(stk3310_channels),
 };
 
+static const struct stk3310_chip_info stk3337_chip_info = {
+	.name = "stk3337",
+	.channels = stk3337_channels,
+	.num_channels = ARRAY_SIZE(stk3337_channels),
+};
+
 static const struct stk3310_chip_info stk36c61_chip_info = {
 	.name = "stk36c61",
 	.channels = stk36c61_channels,
@@ -870,6 +884,7 @@ static const struct i2c_device_id stk3310_i2c_id[] = {
 	{ .name = "stk3310", .driver_data = (kernel_ulong_t)&stk3310_chip_info },
 	{ .name = "stk3311", .driver_data = (kernel_ulong_t)&stk3310_chip_info },
 	{ .name = "stk3335", .driver_data = (kernel_ulong_t)&stk3310_chip_info },
+	{ .name = "stk3337", .driver_data = (kernel_ulong_t)&stk3337_chip_info },
 	{ .name = "stk36c61", .driver_data = (kernel_ulong_t)&stk36c61_chip_info },
 	{ }
 };
@@ -888,6 +903,7 @@ static const struct of_device_id stk3310_of_match[] = {
 	{ .compatible = "sensortek,stk3310", .data = &stk3310_chip_info },
 	{ .compatible = "sensortek,stk3311", .data = &stk3310_chip_info },
 	{ .compatible = "sensortek,stk3335", .data = &stk3310_chip_info },
+	{ .compatible = "sensortek,stk3337", .data = &stk3337_chip_info },
 	{ .compatible = "sensortek,stk36c61", .data = &stk36c61_chip_info },
 	{ }
 };

-- 
2.56.0

