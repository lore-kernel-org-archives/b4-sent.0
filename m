From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 09 Oct 2024 16:16:45 +0200
Subject: [PATCH 3/4] iio: frequency: adf4371: drop clkin from struct
 adf4371_state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241009-dev-adf4371-minor-improv-v1-3-97f4f22ed941@analog.com>
References: <20241009-dev-adf4371-minor-improv-v1-0-97f4f22ed941@analog.com>
In-Reply-To: <20241009-dev-adf4371-minor-improv-v1-0-97f4f22ed941@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728483403; l=1585;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Ic4YOIeGuD72RBXK+dHg9LtJlzq6oNWChpWqVJAnaFo=;
 b=2YprnA4ytZoZwrfvBTYZRKMx95RMEyoGkdCylRl78UCBuU+49E2hYEX1lj6CnDG9JhT4Sdmou
 DlTD4ZFJ2xEC+TYXbQISqmXg+OlNF3zZ+3vKnWcacHhRdlyIALCyKwd
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We already cache clkin rate during probe and then never use the clk
object again. Hence, no point in saving in our global state struct.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/frequency/adf4371.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/frequency/adf4371.c b/drivers/iio/frequency/adf4371.c
index eb31f442566c..45c8398a45d0 100644
--- a/drivers/iio/frequency/adf4371.c
+++ b/drivers/iio/frequency/adf4371.c
@@ -158,7 +158,6 @@ struct adf4371_chip_info {
 struct adf4371_state {
 	struct spi_device *spi;
 	struct regmap *regmap;
-	struct clk *clkin;
 	/*
 	 * Lock for accessing device registers. Some operations require
 	 * multiple consecutive R/W operations, during which the device
@@ -547,6 +546,7 @@ static int adf4371_probe(struct spi_device *spi)
 	struct iio_dev *indio_dev;
 	struct adf4371_state *st;
 	struct regmap *regmap;
+	struct clk *clkin;
 	int ret;
 
 	indio_dev = devm_iio_device_alloc(&spi->dev, sizeof(*st));
@@ -575,11 +575,11 @@ static int adf4371_probe(struct spi_device *spi)
 	indio_dev->channels = st->chip_info->channels;
 	indio_dev->num_channels = st->chip_info->num_channels;
 
-	st->clkin = devm_clk_get_enabled(&spi->dev, "clkin");
-	if (IS_ERR(st->clkin))
-		return PTR_ERR(st->clkin);
+	clkin = devm_clk_get_enabled(&spi->dev, "clkin");
+	if (IS_ERR(clkin))
+		return PTR_ERR(clkin);
 
-	st->clkin_freq = clk_get_rate(st->clkin);
+	st->clkin_freq = clk_get_rate(clkin);
 
 	ret = adf4371_setup(st);
 	if (ret < 0) {

-- 
2.46.1

