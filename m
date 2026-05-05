From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 05 May 2026 13:46:06 +0200
Subject: [PATCH v5 10/18] iio: magnetometer: ak8975: drop duplicate NULL
 check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-magnetometer-fixes-v5-10-831b9b5550fc@gmail.com>
References: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
In-Reply-To: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777981558; l=997;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=XCs0GN+NbiGoXI2dfBbrODJcBvdjPZeVOf17jMKlR/o=;
 b=dHnX2TM5lF4yuVOe+fssLPd8Vy7wN2ARVf04Zv71ct3NnRWHaMx6oTNgTU5h10ownvM7cYjFV
 +xqmgtS7nGaAECPiU5bEmyk2CZzCIMAcuchUpRTMHzVQAKnbZry4SQL
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

The gpiod_set_consumer_name() is NULL-aware, no need to perform the same
check in the caller.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index c36d068081066ef6b42cc2f9c3c2e8978ec51623..7a971de2eebf127fc8ab68300fb82f38d9476c0c 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -918,8 +918,7 @@ static int ak8975_probe(struct i2c_client *client)
 	eoc_gpiod = devm_gpiod_get_optional(&client->dev, NULL, GPIOD_IN);
 	if (IS_ERR(eoc_gpiod))
 		return PTR_ERR(eoc_gpiod);
-	if (eoc_gpiod)
-		gpiod_set_consumer_name(eoc_gpiod, "ak_8975");
+	gpiod_set_consumer_name(eoc_gpiod, "ak_8975");
 
 	/*
 	 * According to AK09911 datasheet, if reset GPIO is provided then

-- 
2.47.3

