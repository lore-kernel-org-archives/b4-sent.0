From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 03 Feb 2026 11:24:10 +0000
Subject: [PATCH v3 4/9] iio: amplifiers: ad8366: drop reset_gpio from
 private struct
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260203-iio-ad8366-update-v3-4-5d5636b5181a@analog.com>
References: <20260203-iio-ad8366-update-v3-0-5d5636b5181a@analog.com>
In-Reply-To: <20260203-iio-ad8366-update-v3-0-5d5636b5181a@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770117857; l=1514;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=7IwKgsiwuYgVI5syKodj5406ItZPM82hCN9tX04mYFY=;
 b=i15+QkMb3ey0jb7qHzqL41jsRwkIBTZZPa6FPCCPautCrcfENc09gcuKI8Tzvrri6MBRTsYV5
 2BBjchX6bsqAQidMDp/bQKMKEJzBIsrvwet+mcb+x1aZ7AxYHSzDK6f
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove reset_gpio from the device state struct and turn it
into a local variable, as it is not being used anywhere else.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index f0d44f2769ca..d6e18eb71bc8 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -42,7 +42,6 @@ struct ad8366_state {
 	struct spi_device	*spi;
 	struct regulator	*reg;
 	struct mutex            lock; /* protect sensor state */
-	struct gpio_desc	*reset_gpio;
 	unsigned char		ch[2];
 	enum ad8366_type	type;
 	const struct ad8366_info *info;
@@ -245,6 +244,7 @@ static const struct iio_chan_spec ada4961_channels[] = {
 
 static int ad8366_probe(struct spi_device *spi)
 {
+	struct gpio_desc *reset_gpio;
 	struct iio_dev *indio_dev;
 	struct ad8366_state *st;
 	int ret;
@@ -279,9 +279,9 @@ static int ad8366_probe(struct spi_device *spi)
 	case ID_ADL5240:
 	case ID_HMC792:
 	case ID_HMC1119:
-		st->reset_gpio = devm_gpiod_get_optional(&spi->dev, "reset", GPIOD_OUT_HIGH);
-		if (IS_ERR(st->reset_gpio)) {
-			ret = PTR_ERR(st->reset_gpio);
+		reset_gpio = devm_gpiod_get_optional(&spi->dev, "reset", GPIOD_OUT_HIGH);
+		if (IS_ERR(reset_gpio)) {
+			ret = PTR_ERR(reset_gpio);
 			goto error_disable_reg;
 		}
 		indio_dev->channels = ada4961_channels;

-- 
2.43.0

