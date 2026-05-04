From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 04 May 2026 11:48:20 +0200
Subject: [PATCH v4 08/17] iio: magnetometer: ak8975: avoid using temporary
 variable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-magnetometer-fixes-v4-8-a291c2a7c71a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777888112; l=1365;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=DJjDCl9JnP2nB2THH5DHs78YGFDKy3vPdtw59miyMxw=;
 b=4HuQSJ58ATnlexHcyGIojYi2gWz8oe9LlrfwqQAt5SsEWh81yrPSEQmZGp+CI7uGe23BPng2q
 DBXxdbBYblIB0p97Vybyf1Z5sqviZu2IcqI7hLGxkX2mZCv3z2VanPs
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

Avoid using temporary variable in ak8975_read_axis(). With that being done,
the clamp_t() call becomes idiomatic in the driver and can be factored out
to a helper later on (and if needed).

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index e399a6508a3e28931ec2efe07924d5f30cebf442..00bee434432f07e8e0bd7fb2b4c97cd2995af7a7 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -739,7 +739,6 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 	const struct i2c_client *client = data->client;
 	const struct ak_def *def = data->def;
 	__le16 rval;
-	u16 buff;
 	int ret;
 
 	pm_runtime_get_sync(&data->client->dev);
@@ -776,8 +775,8 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 	pm_runtime_put_autosuspend(&data->client->dev);
 
 	/* Swap bytes and convert to valid range. */
-	buff = le16_to_cpu(rval);
-	*val = clamp_t(s16, buff, -def->range, def->range);
+	*val = clamp_t(s16, le16_to_cpu(rval), -def->range, def->range);
+
 	return IIO_VAL_INT;
 
 exit:

-- 
2.47.3

