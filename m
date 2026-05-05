From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 05 May 2026 13:46:05 +0200
Subject: [PATCH v5 09/18] iio: magnetometer: ak8975: avoid using temporary
 variable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-magnetometer-fixes-v5-9-831b9b5550fc@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777981558; l=1365;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=8tLL2kiAufULoRZYDYBqjmCH5Df7RX705WCjX2nmy9g=;
 b=HLjOdUCGBtz8iLcZ+OEaf1xTWD7x6kYzf+n26VECoqWCYM3it9G6K88sc0rW0u/ZIVMsl5cmN
 dM0foXTlMeNCzMmKQTJGuFZ5U1LgQ8mu/uBogWI3uu3vkvCIzoRZIWw
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
index b3caf5f3ebf29bf701bb214aa480fa7afb2651c6..c36d068081066ef6b42cc2f9c3c2e8978ec51623 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -741,7 +741,6 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 	const struct i2c_client *client = data->client;
 	const struct ak_def *def = data->def;
 	__le16 rval;
-	u16 buff;
 	int ret;
 
 	pm_runtime_get_sync(&data->client->dev);
@@ -778,8 +777,8 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
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

