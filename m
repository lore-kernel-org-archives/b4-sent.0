From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 16 Oct 2024 16:22:00 +0200
Subject: [PATCH 2/3] iio: addac: ad74413r: use
 devm_regulator_get_enable_read_voltage()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241016-dev-ad74413r-minor-improv-v1-2-13c9c769237d@analog.com>
References: <20241016-dev-ad74413r-minor-improv-v1-0-13c9c769237d@analog.com>
In-Reply-To: <20241016-dev-ad74413r-minor-improv-v1-0-13c9c769237d@analog.com>
To: linux-iio@vger.kernel.org
Cc: Cosmin Tanislav <cosmin.tanislav@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729088521; l=2669;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=jWsbLCxTUm/W19uTe2di1jluXpyIQzkCZn4CIrpSErI=;
 b=o1ytCpDTla7wfILFbxWK5oft0TJhYrU0CgFRdey37VvNztllXhr37TvyTg0gY286ptPai1UqV
 ORa4Ph+cWAeCAW3TKbUFeAtnHpM2jv/rEmPmuLeYlD6bfWYQmmJGC/f
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's highly unlikely for the converter ref voltage to change at runtime.
Hence, let's read the voltage and save it (instead of the regulator
struct). While at it, simplify the code by using
devm_regulator_get_enable_read_voltage().

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/addac/ad74413r.c | 28 +++++++---------------------
 1 file changed, 7 insertions(+), 21 deletions(-)

diff --git a/drivers/iio/addac/ad74413r.c b/drivers/iio/addac/ad74413r.c
index 550e2460e29c..cfe26a394465 100644
--- a/drivers/iio/addac/ad74413r.c
+++ b/drivers/iio/addac/ad74413r.c
@@ -60,7 +60,7 @@ struct ad74413r_state {
 	unsigned int			num_gpo_gpios;
 	unsigned int			num_comparator_gpios;
 	u32				sense_resistor_ohms;
-
+	int				refin_reg_uv;
 	/*
 	 * Synchronize consecutive operations when doing a one-shot
 	 * conversion and when updating the ADC samples SPI message.
@@ -69,7 +69,6 @@ struct ad74413r_state {
 
 	const struct ad74413r_chip_info	*chip_info;
 	struct spi_device		*spi;
-	struct regulator		*refin_reg;
 	struct regmap			*regmap;
 	struct device			*dev;
 	struct iio_trigger		*trig;
@@ -664,7 +663,7 @@ static int ad74413r_get_output_voltage_scale(struct ad74413r_state *st,
 static int ad74413r_get_output_current_scale(struct ad74413r_state *st,
 					     int *val, int *val2)
 {
-	*val = regulator_get_voltage(st->refin_reg);
+	*val = st->refin_reg_uv;
 	*val2 = st->sense_resistor_ohms * AD74413R_DAC_CODE_MAX * 1000;
 
 	return IIO_VAL_FRACTIONAL;
@@ -1351,11 +1350,6 @@ static int ad74413r_setup_gpios(struct ad74413r_state *st)
 	return 0;
 }
 
-static void ad74413r_regulator_disable(void *regulator)
-{
-	regulator_disable(regulator);
-}
-
 static int ad74413r_probe(struct spi_device *spi)
 {
 	struct ad74413r_state *st;
@@ -1382,19 +1376,11 @@ static int ad74413r_probe(struct spi_device *spi)
 	if (IS_ERR(st->regmap))
 		return PTR_ERR(st->regmap);
 
-	st->refin_reg = devm_regulator_get(st->dev, "refin");
-	if (IS_ERR(st->refin_reg))
-		return dev_err_probe(st->dev, PTR_ERR(st->refin_reg),
-				     "Failed to get refin regulator\n");
-
-	ret = regulator_enable(st->refin_reg);
-	if (ret)
-		return ret;
-
-	ret = devm_add_action_or_reset(st->dev, ad74413r_regulator_disable,
-				       st->refin_reg);
-	if (ret)
-		return ret;
+	ret = devm_regulator_get_enable_read_voltage(st->dev, "refin");
+	if (ret < 0)
+		return dev_err_probe(st->dev, ret,
+				     "Failed to get refin regulator voltage\n");
+	st->refin_reg_uv = ret;
 
 	st->sense_resistor_ohms = 100000000;
 	device_property_read_u32(st->dev, "shunt-resistor-micro-ohms",

-- 
2.46.1

