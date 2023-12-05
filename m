From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 05 Dec 2023 18:06:42 +0100
Subject: [PATCH 2/8] iio: adc: ad9467: don't ignore error codes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231205-iio-backend-prep-v1-2-7c9bc18d612b@analog.com>
References: <20231205-iio-backend-prep-v1-0-7c9bc18d612b@analog.com>
In-Reply-To: <20231205-iio-backend-prep-v1-0-7c9bc18d612b@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701796004; l=2369;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Yp88xt+p4CeVtKT4sRsURqn6TKhQ4aZcgz2tzeg6i/s=;
 b=aPjXwGNyNzaF6mAwYtziiGvIbC+zEmbfuA2K/pwV3e9T0nnGKVnXQcUHfCbLpbj187IRy2p3t
 bvrOuPWC8EjCEgZTXkd4nifiQZmZL7P8NG+xJrs3OlicQBP9GX5JcwL
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure functions that return errors are not ignored.

Fixes: ad6797120238 ("iio: adc: ad9467: add support AD9467 ADC")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 27 +++++++++++++++++----------
 1 file changed, 17 insertions(+), 10 deletions(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index 5ecf486bf5d1..0f2dce730a0a 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -162,9 +162,10 @@ static int ad9467_reg_access(struct adi_axi_adc_conv *conv, unsigned int reg,
 
 	if (readval == NULL) {
 		ret = ad9467_spi_write(spi, reg, writeval);
-		ad9467_spi_write(spi, AN877_ADC_REG_TRANSFER,
-				 AN877_ADC_TRANSFER_SYNC);
-		return ret;
+		if (ret)
+			return ret;
+		return ad9467_spi_write(spi, AN877_ADC_REG_TRANSFER,
+					AN877_ADC_TRANSFER_SYNC);
 	}
 
 	ret = ad9467_spi_read(spi, reg);
@@ -272,10 +273,13 @@ static int ad9467_get_scale(struct adi_axi_adc_conv *conv, int *val, int *val2)
 	const struct ad9467_chip_info *info1 = to_ad9467_chip_info(info);
 	struct ad9467_state *st = adi_axi_adc_conv_priv(conv);
 	unsigned int i, vref_val;
+	int ret;
 
-	vref_val = ad9467_spi_read(st->spi, AN877_ADC_REG_VREF);
+	ret = ad9467_spi_read(st->spi, AN877_ADC_REG_VREF);
+	if (ret < 0)
+		return ret;
 
-	vref_val &= info1->vref_mask;
+	vref_val = ret & info1->vref_mask;
 
 	for (i = 0; i < info->num_scales; i++) {
 		if (vref_val == info->scale_table[i][1])
@@ -296,6 +300,7 @@ static int ad9467_set_scale(struct adi_axi_adc_conv *conv, int val, int val2)
 	struct ad9467_state *st = adi_axi_adc_conv_priv(conv);
 	unsigned int scale_val[2];
 	unsigned int i;
+	int ret;
 
 	if (val != 0)
 		return -EINVAL;
@@ -305,11 +310,13 @@ static int ad9467_set_scale(struct adi_axi_adc_conv *conv, int val, int val2)
 		if (scale_val[0] != val || scale_val[1] != val2)
 			continue;
 
-		ad9467_spi_write(st->spi, AN877_ADC_REG_VREF,
-				 info->scale_table[i][1]);
-		ad9467_spi_write(st->spi, AN877_ADC_REG_TRANSFER,
-				 AN877_ADC_TRANSFER_SYNC);
-		return 0;
+		ret = ad9467_spi_write(st->spi, AN877_ADC_REG_VREF,
+				       info->scale_table[i][1]);
+		if (ret < 0)
+			return ret;
+
+		return ad9467_spi_write(st->spi, AN877_ADC_REG_TRANSFER,
+					AN877_ADC_TRANSFER_SYNC);
 	}
 
 	return -EINVAL;

-- 
2.43.0

