From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 23 Nov 2026 15:25:27 +0200
Subject: [PATCH 3/7] iio: imu: adis16475: Pass the device and timestamp to
 the sample helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-adis-fifo-v1-3-f6ad9e493e19@analog.com>
References: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
In-Reply-To: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Ramona Gradinariu <ramona.bolboaca13@gmail.com>, 
 Radu Sabau <radu.sabau@analog.com>
Cc: linux-iio@vger.kernel.org, linux@analog.com, 
 linux-kernel@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795440327; l=3328;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=5BQh5nF/fg8PKi8MMyTgUuL98vgwuiTzBq54Q+UqpWE=;
 b=q2YFzwSQWfu2gHQwKBpHl5wuv4anAQhOy+JEIIRBzIuzaEN2C83xXwkjK/xthkSrgiid9zMyF
 PHzStZfAEqkAgwwpcHm1AnowuvJqGuYXbv+Ew+oJJCu28GShbFSiNSa
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

adis16475_push_single_sample() and adis16575_custom_burst_read() take the
struct iio_poll_func only to get the IIO device and the timestamp from it.
Pass those two instead, so the helpers don't depend on being called from a
trigger handler.

No functional change.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16475.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/iio/imu/adis16475.c b/drivers/iio/imu/adis16475.c
index 44520d9216a2..6922ffb48516 100644
--- a/drivers/iio/imu/adis16475.c
+++ b/drivers/iio/imu/adis16475.c
@@ -1561,9 +1561,8 @@ static void adis16475_burst32_check(struct adis16475 *st)
 	}
 }
 
-static int adis16475_push_single_sample(struct iio_poll_func *pf)
+static int adis16475_push_single_sample(struct iio_dev *indio_dev, s64 timestamp)
 {
-	struct iio_dev *indio_dev = pf->indio_dev;
 	struct adis16475 *st = iio_priv(indio_dev);
 	struct adis *adis = &st->adis;
 	int ret, bit, buff_offset = 0, i = 0;
@@ -1652,7 +1651,7 @@ static int adis16475_push_single_sample(struct iio_poll_func *pf)
 	}
 
 	/* There might not be a timestamp option for some devices. */
-	iio_push_to_buffers_with_timestamp(indio_dev, st->data, pf->timestamp);
+	iio_push_to_buffers_with_timestamp(indio_dev, st->data, timestamp);
 
 	return 0;
 }
@@ -1663,7 +1662,7 @@ static irqreturn_t adis16475_trigger_handler(int irq, void *p)
 	struct iio_dev *indio_dev = pf->indio_dev;
 	struct adis16475 *st = iio_priv(indio_dev);
 
-	adis16475_push_single_sample(pf);
+	adis16475_push_single_sample(indio_dev, pf->timestamp);
 	/*
 	 * We only check the burst mode at the end of the current capture since
 	 * it takes a full data ready cycle for the device to update the burst
@@ -1694,9 +1693,9 @@ static void adis16575_update_msg_for_burst(struct adis *adis, u8 burst_req)
 	tx[0] = ADIS_READ_REG(burst_req);
 }
 
-static int adis16575_custom_burst_read(struct iio_poll_func *pf, u8 burst_req)
+static int adis16575_custom_burst_read(struct iio_dev *indio_dev, u8 burst_req,
+				       s64 timestamp)
 {
-	struct iio_dev *indio_dev = pf->indio_dev;
 	struct adis16475 *st = iio_priv(indio_dev);
 	struct adis *adis = &st->adis;
 
@@ -1705,7 +1704,7 @@ static int adis16575_custom_burst_read(struct iio_poll_func *pf, u8 burst_req)
 	if (burst_req)
 		return spi_sync(adis->spi, &adis->msg);
 
-	return adis16475_push_single_sample(pf);
+	return adis16475_push_single_sample(indio_dev, timestamp);
 }
 
 /*
@@ -1748,18 +1747,19 @@ static irqreturn_t adis16475_trigger_handler_with_fifo(int irq, void *p)
 	 * First burst request - FIFO pop: popped data will be returned in the
 	 * next burst request.
 	 */
-	ret = adis16575_custom_burst_read(pf, adis->data->burst_reg_cmd);
+	ret = adis16575_custom_burst_read(indio_dev, adis->data->burst_reg_cmd,
+					  pf->timestamp);
 	if (ret)
 		goto unlock;
 
 	for (i = 0; i < fifo_cnt - 1; i++) {
-		ret = adis16475_push_single_sample(pf);
+		ret = adis16475_push_single_sample(indio_dev, pf->timestamp);
 		if (ret)
 			goto unlock;
 	}
 
 	/* FIFO read without popping */
-	ret = adis16575_custom_burst_read(pf, 0);
+	ret = adis16575_custom_burst_read(indio_dev, 0, pf->timestamp);
 
 unlock:
 	/*

-- 
2.43.0

