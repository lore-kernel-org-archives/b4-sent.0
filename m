From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 04 May 2026 11:48:21 +0200
Subject: [PATCH v4 09/17] iio: magnetometer: ak8975: drop duplicate NULL
 check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-magnetometer-fixes-v4-9-a291c2a7c71a@gmail.com>
References: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
In-Reply-To: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777888112; l=997;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=e2CslTguZFmECHppHhG6NXJjVTcak+Q+ZmfU6/H6/tw=;
 b=wVYp6pg8pGZRPku/IJeaLIlVYeKFKmI5Eb+i2xowE+v/WJpsssvOKlwPcmiLV8TIR2yVjbGOL
 WTuSECFwctHBrG+dqQrfPa4m3qi0evCA8t+eCRL2hVznoM8j5IL6mTE
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
index 00bee434432f07e8e0bd7fb2b4c97cd2995af7a7..b94b0486421873a4afa41949d956e0bb5dafdb9d 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -916,8 +916,7 @@ static int ak8975_probe(struct i2c_client *client)
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

