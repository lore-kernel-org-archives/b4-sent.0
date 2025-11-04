From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 15:35:11 +0000
Subject: [PATCH v4 06/12] iio: dac: ad5456: Add missing DT compatibles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-dev-add-ad5542-v4-6-6fe35458bf8c@analog.com>
References: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
In-Reply-To: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762270508; l=3339;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=+u2TXIw9MQHDEuZGff76D9hZcdxsLW8+st7kGqLxaP0=;
 b=DmG8VffKrUNUx7os3JuynB9/G2nPZa44NsCQqRMCgDb4qnqQ1o4/4ZWAS4G1uw6ck3GgVCfKj
 9UgCR3z8fOeAPQ7hmXZ+F/T569WtXzJimLQJjsKCI/IOWafQRhFryWG
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add missing of_device_id compatibles for the i2c and spi drivers.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 41 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 41 insertions(+)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index 539a8fcc7078..01f934036185 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -440,6 +440,35 @@ static const struct spi_device_id ad5446_spi_ids[] = {
 MODULE_DEVICE_TABLE(spi, ad5446_spi_ids);
 
 static const struct of_device_id ad5446_of_ids[] = {
+	{ .compatible = "adi,ad5300", .data = &ad5300_chip_info },
+	{ .compatible = "adi,ad5310", .data = &ad5310_chip_info },
+	{ .compatible = "adi,ad5320", .data = &ad5320_chip_info },
+	{ .compatible = "adi,ad5444", .data = &ad5444_chip_info },
+	{ .compatible = "adi,ad5446", .data = &ad5446_chip_info },
+	{ .compatible = "adi,ad5450", .data = &ad5450_chip_info },
+	{ .compatible = "adi,ad5451", .data = &ad5451_chip_info },
+	{ .compatible = "adi,ad5452", .data = &ad5444_chip_info },
+	{ .compatible = "adi,ad5453", .data = &ad5446_chip_info },
+	{ .compatible = "adi,ad5512a", .data = &ad5512a_chip_info },
+	{ .compatible = "adi,ad5541a", .data = &ad5541a_chip_info },
+	{ .compatible = "adi,ad5542a", .data = &ad5541a_chip_info },
+	{ .compatible = "adi,ad5543", .data = &ad5541a_chip_info },
+	{ .compatible = "adi,ad5553", .data = &ad5553_chip_info },
+	{ .compatible = "adi,ad5600", .data = &ad5541a_chip_info },
+	{ .compatible = "adi,ad5601", .data = &ad5601_chip_info },
+	{ .compatible = "adi,ad5611", .data = &ad5611_chip_info },
+	{ .compatible = "adi,ad5621", .data = &ad5621_chip_info },
+	{ .compatible = "adi,ad5641", .data = &ad5641_chip_info },
+	{ .compatible = "adi,ad5620-2500", .data = &ad5620_2500_chip_info },
+	{ .compatible = "adi,ad5620-1250", .data = &ad5620_1250_chip_info },
+	{ .compatible = "adi,ad5640-2500", .data = &ad5640_2500_chip_info },
+	{ .compatible = "adi,ad5640-1250", .data = &ad5640_1250_chip_info },
+	{ .compatible = "adi,ad5660-2500", .data = &ad5660_2500_chip_info },
+	{ .compatible = "adi,ad5660-1250", .data = &ad5660_1250_chip_info },
+	{ .compatible = "adi,ad5662", .data = &ad5662_chip_info },
+	{ .compatible = "ti,dac081s101", .data = &ad5300_chip_info },
+	{ .compatible = "ti,dac101s101", .data = &ad5310_chip_info },
+	{ .compatible = "ti,dac121s101", .data = &ad5320_chip_info },
 	{ .compatible = "ti,dac7512" },
 	{ }
 };
@@ -546,9 +575,21 @@ static const struct i2c_device_id ad5446_i2c_ids[] = {
 };
 MODULE_DEVICE_TABLE(i2c, ad5446_i2c_ids);
 
+static const struct of_device_id ad5446_i2c_of_ids[] = {
+	{ .compatible = "adi,ad5301", .data = &ad5602_chip_info },
+	{ .compatible = "adi,ad5311", .data = &ad5612_chip_info },
+	{ .compatible = "adi,ad5321", .data = &ad5622_chip_info },
+	{ .compatible = "adi,ad5602", .data = &ad5602_chip_info },
+	{ .compatible = "adi,ad5612", .data = &ad5612_chip_info },
+	{ .compatible = "adi,ad5622", .data = &ad5622_chip_info },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ad5446_i2c_of_ids);
+
 static struct i2c_driver ad5446_i2c_driver = {
 	.driver = {
 		   .name = "ad5446",
+		   .of_match_table = ad5446_i2c_of_ids,
 	},
 	.probe = ad5446_i2c_probe,
 	.id_table = ad5446_i2c_ids,

-- 
2.51.0

