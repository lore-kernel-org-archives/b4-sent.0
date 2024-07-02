From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:51 +0200
Subject: [PATCH 19/20] iio: imu: adis16475: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-19-98193bf536a6@analog.com>
References: <20240702-dev-iio-masklength-private-v1-0-98193bf536a6@analog.com>
In-Reply-To: <20240702-dev-iio-masklength-private-v1-0-98193bf536a6@analog.com>
To: linux-iio@vger.kernel.org, chrome-platform@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Cosmin Tanislav <cosmin.tanislav@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Benson Leung <bleung@chromium.org>, Guenter Roeck <groeck@chromium.org>, 
 Dmitry Rokosov <ddrokosov@sberdevices.ru>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936157; l=891;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=R0wwlEsuLBVxnsU+A/xQqthiBloXGcKrV9R2Xe/WNOk=;
 b=ig8hNaFeuY+6AqHCCCLWYv++S5uIRb3T50cfV7rToGdVwa4/sz19fb3vXj3FPvwcRRv4fEkYs
 ipUbY1hCjTzBb5+pF1iDYBRZBlX4YQe8ZMXCQhzqRwIWF+ie83Ry+8w
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/imu/adis16475.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/imu/adis16475.c b/drivers/iio/imu/adis16475.c
index cf73c6f46c79d..1cc2a66a78ff3 100644
--- a/drivers/iio/imu/adis16475.c
+++ b/drivers/iio/imu/adis16475.c
@@ -1608,8 +1608,7 @@ static int adis16475_push_single_sample(struct iio_poll_func *pf)
 		return -EINVAL;
 	}
 
-	for_each_set_bit(bit, indio_dev->active_scan_mask,
-			 indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, bit) {
 		/*
 		 * When burst mode is used, system flags is the first data
 		 * channel in the sequence, but the scan index is 7.

-- 
2.45.2

