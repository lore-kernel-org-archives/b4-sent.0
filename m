From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 07 Dec 2023 13:39:29 +0100
Subject: [PATCH v2 6/8] iio: adc: ad9467: use chip_info variables instead
 of array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231207-iio-backend-prep-v2-6-a4a33bc4d70e@analog.com>
References: <20231207-iio-backend-prep-v2-0-a4a33bc4d70e@analog.com>
In-Reply-To: <20231207-iio-backend-prep-v2-0-a4a33bc4d70e@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701952767; l=4509;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=riYJelE0bSqiNBWWjJOFgchXLTiMtMc12CKUzjlbVCk=;
 b=9C+cJYPNSSwEg+mlPbf2bcW4ZVDToDkUPiDZu8LEOeHHpJQ+k9C7fHeGuB4/phte35rqG5qYa
 bmJr5GUbxIoB/RPp27tX2mWBPgkKPciETspR3ihwhZGySFMdef0/d3R
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of having an array and keeping IDs for each entry of the array,
just have a chip_info struct per device.

Reviewed-by: David Lechner <dlechner@baylibre.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 89 +++++++++++++++++++++++-------------------------
 1 file changed, 43 insertions(+), 46 deletions(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index b16d28c1adcb..c5ed62cc8646 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -101,12 +101,6 @@
 #define AD9467_DEF_OUTPUT_MODE		0x08
 #define AD9467_REG_VREF_MASK		0x0F
 
-enum {
-	ID_AD9265,
-	ID_AD9434,
-	ID_AD9467,
-};
-
 struct ad9467_chip_info {
 	struct adi_axi_adc_chip_info	axi_adc_info;
 	unsigned int			default_output_mode;
@@ -234,43 +228,46 @@ static const struct iio_chan_spec ad9467_channels[] = {
 	AD9467_CHAN(0, 0, 16, 'S'),
 };
 
-static const struct ad9467_chip_info ad9467_chip_tbl[] = {
-	[ID_AD9265] = {
-		.axi_adc_info = {
-			.id = CHIPID_AD9265,
-			.max_rate = 125000000UL,
-			.scale_table = ad9265_scale_table,
-			.num_scales = ARRAY_SIZE(ad9265_scale_table),
-			.channels = ad9467_channels,
-			.num_channels = ARRAY_SIZE(ad9467_channels),
-		},
-		.default_output_mode = AD9265_DEF_OUTPUT_MODE,
-		.vref_mask = AD9265_REG_VREF_MASK,
+static const struct ad9467_chip_info ad9467_chip_tbl = {
+	.axi_adc_info = {
+		.name = "ad9467",
+		.id = CHIPID_AD9467,
+		.max_rate = 250000000UL,
+		.scale_table = ad9467_scale_table,
+		.num_scales = ARRAY_SIZE(ad9467_scale_table),
+		.channels = ad9467_channels,
+		.num_channels = ARRAY_SIZE(ad9467_channels),
 	},
-	[ID_AD9434] = {
-		.axi_adc_info = {
-			.id = CHIPID_AD9434,
-			.max_rate = 500000000UL,
-			.scale_table = ad9434_scale_table,
-			.num_scales = ARRAY_SIZE(ad9434_scale_table),
-			.channels = ad9434_channels,
-			.num_channels = ARRAY_SIZE(ad9434_channels),
-		},
-		.default_output_mode = AD9434_DEF_OUTPUT_MODE,
-		.vref_mask = AD9434_REG_VREF_MASK,
+	.default_output_mode = AD9467_DEF_OUTPUT_MODE,
+	.vref_mask = AD9467_REG_VREF_MASK,
+};
+
+static const struct ad9467_chip_info ad9434_chip_tbl = {
+	.axi_adc_info = {
+		.name = "ad9434",
+		.id = CHIPID_AD9434,
+		.max_rate = 500000000UL,
+		.scale_table = ad9434_scale_table,
+		.num_scales = ARRAY_SIZE(ad9434_scale_table),
+		.channels = ad9434_channels,
+		.num_channels = ARRAY_SIZE(ad9434_channels),
 	},
-	[ID_AD9467] = {
-		.axi_adc_info = {
-			.id = CHIPID_AD9467,
-			.max_rate = 250000000UL,
-			.scale_table = ad9467_scale_table,
-			.num_scales = ARRAY_SIZE(ad9467_scale_table),
-			.channels = ad9467_channels,
-			.num_channels = ARRAY_SIZE(ad9467_channels),
-		},
-		.default_output_mode = AD9467_DEF_OUTPUT_MODE,
-		.vref_mask = AD9467_REG_VREF_MASK,
+	.default_output_mode = AD9434_DEF_OUTPUT_MODE,
+	.vref_mask = AD9434_REG_VREF_MASK,
+};
+
+static const struct ad9467_chip_info ad9265_chip_tbl = {
+	.axi_adc_info = {
+		.name = "ad9265",
+		.id = CHIPID_AD9265,
+		.max_rate = 125000000UL,
+		.scale_table = ad9265_scale_table,
+		.num_scales = ARRAY_SIZE(ad9265_scale_table),
+		.channels = ad9467_channels,
+		.num_channels = ARRAY_SIZE(ad9467_channels),
 	},
+	.default_output_mode = AD9265_DEF_OUTPUT_MODE,
+	.vref_mask = AD9265_REG_VREF_MASK,
 };
 
 static int ad9467_get_scale(struct adi_axi_adc_conv *conv, int *val, int *val2)
@@ -504,17 +501,17 @@ static int ad9467_probe(struct spi_device *spi)
 }
 
 static const struct of_device_id ad9467_of_match[] = {
-	{ .compatible = "adi,ad9265", .data = &ad9467_chip_tbl[ID_AD9265], },
-	{ .compatible = "adi,ad9434", .data = &ad9467_chip_tbl[ID_AD9434], },
-	{ .compatible = "adi,ad9467", .data = &ad9467_chip_tbl[ID_AD9467], },
+	{ .compatible = "adi,ad9265", .data = &ad9265_chip_tbl, },
+	{ .compatible = "adi,ad9434", .data = &ad9434_chip_tbl, },
+	{ .compatible = "adi,ad9467", .data = &ad9467_chip_tbl, },
 	{}
 };
 MODULE_DEVICE_TABLE(of, ad9467_of_match);
 
 static const struct spi_device_id ad9467_ids[] = {
-	{ "ad9265", (kernel_ulong_t)&ad9467_chip_tbl[ID_AD9265] },
-	{ "ad9434", (kernel_ulong_t)&ad9467_chip_tbl[ID_AD9434] },
-	{ "ad9467", (kernel_ulong_t)&ad9467_chip_tbl[ID_AD9467] },
+	{ "ad9265", (kernel_ulong_t)&ad9265_chip_tbl },
+	{ "ad9434", (kernel_ulong_t)&ad9434_chip_tbl },
+	{ "ad9467", (kernel_ulong_t)&ad9467_chip_tbl },
 	{}
 };
 MODULE_DEVICE_TABLE(spi, ad9467_ids);

-- 
2.43.0

