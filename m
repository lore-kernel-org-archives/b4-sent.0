From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 03 Feb 2026 11:24:09 +0000
Subject: [PATCH v3 3/9] iio: amplifiers: ad8366: use devm_mutex_init() and
 drop mutex_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260203-iio-ad8366-update-v3-3-5d5636b5181a@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770117857; l=966;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=i1uZPY/+9TFsjqSIU1LFXWflhkq05R0JInppwz60DI0=;
 b=XEQOgfJvTdu75yedpZWp7uhgPEHCuQp7kFnG45x0KqJp1Rz9hi0+ZlbTLkwVALJ1fsMzVuyj/
 08Z8XVNkGD3BYcjYh9P6ksLh/l8uN4/F1PJDkKgTdLU9VY5I3BOv4xW
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adopt proper mutex lifecycle with devm_mutex_init(),
replacing mutex_init().

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index d06ac786501c..f0d44f2769ca 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -255,6 +255,10 @@ static int ad8366_probe(struct spi_device *spi)
 
 	st = iio_priv(indio_dev);
 
+	ret = devm_mutex_init(&spi->dev, &st->lock);
+	if (ret)
+		return ret;
+
 	st->reg = devm_regulator_get(&spi->dev, "vcc");
 	if (!IS_ERR(st->reg)) {
 		ret = regulator_enable(st->reg);
@@ -263,7 +267,6 @@ static int ad8366_probe(struct spi_device *spi)
 	}
 
 	spi_set_drvdata(spi, indio_dev);
-	mutex_init(&st->lock);
 	st->spi = spi;
 	st->type = spi_get_device_id(spi)->driver_data;
 

-- 
2.43.0

