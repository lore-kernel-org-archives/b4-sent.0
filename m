From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 09 Oct 2024 16:16:43 +0200
Subject: [PATCH 1/4] iio: frequency: adf4371: make use of
 spi_get_device_match_data()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241009-dev-adf4371-minor-improv-v1-1-97f4f22ed941@analog.com>
References: <20241009-dev-adf4371-minor-improv-v1-0-97f4f22ed941@analog.com>
In-Reply-To: <20241009-dev-adf4371-minor-improv-v1-0-97f4f22ed941@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728483403; l=3000;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=RYoxMVKivVHRi4vEh9sR2ScD/T6oh+PpIdTQe1TqOU0=;
 b=uZ8BDgksHm9dKp4T6D8ZAu1W0jqMbGoekYy9MQNCFUXtxDDvPMBbjBE4caIs0efahl8gUh/Bz
 2r2F5qqvlaRCO66K3ytrvzzHHsJLeEm1APGWUK3IexdLWbL7sy1+kgh
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To use spi_get_device_match_data(), add the chip_info structure to the
of_device_id table which is always a good thing to do.

While at it, added dedicated variables for each chip (instead of the
harder to maintain array) and added a new string variable for the part
name.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/frequency/adf4371.c | 36 ++++++++++++++++++++----------------
 1 file changed, 20 insertions(+), 16 deletions(-)

diff --git a/drivers/iio/frequency/adf4371.c b/drivers/iio/frequency/adf4371.c
index b270884648265..c8bf37f1679c3 100644
--- a/drivers/iio/frequency/adf4371.c
+++ b/drivers/iio/frequency/adf4371.c
@@ -150,6 +150,7 @@ static const struct regmap_config adf4371_regmap_config = {
 };
 
 struct adf4371_chip_info {
+	const char *name;
 	unsigned int num_channels;
 	const struct iio_chan_spec *channels;
 };
@@ -444,15 +445,16 @@ static const struct iio_chan_spec adf4371_chan[] = {
 	ADF4371_CHANNEL(ADF4371_CH_RF32),
 };
 
-static const struct adf4371_chip_info adf4371_chip_info[] = {
-	[ADF4371] = {
-		.channels = adf4371_chan,
-		.num_channels = 4,
-	},
-	[ADF4372] = {
-		.channels = adf4371_chan,
-		.num_channels = 3,
-	}
+static const struct adf4371_chip_info adf4371_chip_info = {
+	.name = "adf4371",
+	.channels = adf4371_chan,
+	.num_channels = 4,
+};
+
+static const struct adf4371_chip_info adf4372_chip_info = {
+	.name = "adf4372",
+	.channels = adf4371_chan,
+	.num_channels = 3,
 };
 
 static int adf4371_reg_access(struct iio_dev *indio_dev,
@@ -542,7 +544,6 @@ static int adf4371_setup(struct adf4371_state *st)
 
 static int adf4371_probe(struct spi_device *spi)
 {
-	const struct spi_device_id *id = spi_get_device_id(spi);
 	struct iio_dev *indio_dev;
 	struct adf4371_state *st;
 	struct regmap *regmap;
@@ -565,8 +566,11 @@ static int adf4371_probe(struct spi_device *spi)
 	st->regmap = regmap;
 	mutex_init(&st->lock);
 
-	st->chip_info = &adf4371_chip_info[id->driver_data];
-	indio_dev->name = id->name;
+	st->chip_info = spi_get_device_match_data(spi);
+	if (!st->chip_info)
+		return -ENODEV;
+
+	indio_dev->name = st->chip_info->name;
 	indio_dev->info = &adf4371_info;
 	indio_dev->modes = INDIO_DIRECT_MODE;
 	indio_dev->channels = st->chip_info->channels;
@@ -588,15 +592,15 @@ static int adf4371_probe(struct spi_device *spi)
 }
 
 static const struct spi_device_id adf4371_id_table[] = {
-	{ "adf4371", ADF4371 },
-	{ "adf4372", ADF4372 },
+	{ "adf4371", (kernel_ulong_t)&adf4371_chip_info },
+	{ "adf4372", (kernel_ulong_t)&adf4372_chip_info },
 	{}
 };
 MODULE_DEVICE_TABLE(spi, adf4371_id_table);
 
 static const struct of_device_id adf4371_of_match[] = {
-	{ .compatible = "adi,adf4371" },
-	{ .compatible = "adi,adf4372" },
+	{ .compatible = "adi,adf4371", .data = &adf4371_chip_info },
+	{ .compatible = "adi,adf4372", .data = &adf4372_chip_info},
 	{ },
 };
 MODULE_DEVICE_TABLE(of, adf4371_of_match);

-- 
2.46.1

