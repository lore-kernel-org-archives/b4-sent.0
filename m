From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 16 Feb 2026 17:10:49 +0000
Subject: [PATCH v5 05/11] iio: amplifiers: ad8366: use devm_mutex_init()
 and drop mutex_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-iio-ad8366-update-v5-5-7e6091357d02@analog.com>
References: <20260216-iio-ad8366-update-v5-0-7e6091357d02@analog.com>
In-Reply-To: <20260216-iio-ad8366-update-v5-0-7e6091357d02@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771261851; l=1096;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Hc2oDziDqm76kntTxzCYZxXGJ8oFjf16eqD+h6jkb6Y=;
 b=NbSdFlOD0YSqM+1UOH7XzHN/+6UynpQX/NRfeDM/C/2NDF/6kP0lO0zdVqMCVSO67Hew97HPW
 2EuuE90K/ALDcCIi4eADmbPLjwTwlP2WJFh4LXuhpRUG5FNWwxFJ0W1
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adopt proper mutex lifecycle with devm_mutex_init(), replacing
mutex_init(). Mutex init is moved up (before regulator init),
so that goto statement in the error path is avoided (which will
be cleaned up later).

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index 677d02f4f075..6466f3eb6bbc 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -259,6 +259,10 @@ static int ad8366_probe(struct spi_device *spi)
 
 	st = iio_priv(indio_dev);
 
+	ret = devm_mutex_init(dev, &st->lock);
+	if (ret)
+		return ret;
+
 	st->reg = devm_regulator_get(&spi->dev, "vcc");
 	if (!IS_ERR(st->reg)) {
 		ret = regulator_enable(st->reg);
@@ -267,7 +271,6 @@ static int ad8366_probe(struct spi_device *spi)
 	}
 
 	spi_set_drvdata(spi, indio_dev);
-	mutex_init(&st->lock);
 	st->spi = spi;
 	st->type = spi_get_device_id(spi)->driver_data;
 

-- 
2.43.0

