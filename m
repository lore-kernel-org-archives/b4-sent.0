From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:37 +0200
Subject: [PATCH 05/20] iio: accel: adx1372: make use of
 iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-5-98193bf536a6@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936156; l=915;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=2EHdpJoQbj+k3J/CWxWS22/x7Zsq5ayA38mR5vpDteM=;
 b=HqGJD3hvrnZvHwYeCHrVGiJTDHQ7E6p+zcjNhkmu9gmiIdn8ADUJohk+uNH00HrlnzDF3XAXL
 +0ew+gitwztA3oLuTgEsLnowhzmOXwPzxz0T+g+HI0QTHeOapeqk/uh
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/accel/adxl372.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/accel/adxl372.c b/drivers/iio/accel/adxl372.c
index c4193286eb05..ef8dd557877b 100644
--- a/drivers/iio/accel/adxl372.c
+++ b/drivers/iio/accel/adxl372.c
@@ -1050,7 +1050,7 @@ static int adxl372_buffer_postenable(struct iio_dev *indio_dev)
 	st->fifo_format = adxl372_axis_lookup_table[i].fifo_format;
 	st->fifo_axis_mask = adxl372_axis_lookup_table[i].bits;
 	st->fifo_set_size = bitmap_weight(indio_dev->active_scan_mask,
-					  indio_dev->masklength);
+					  iio_get_masklength(indio_dev));
 
 	/* Configure the FIFO to store sets of impact event peak. */
 	if (st->peak_fifo_mode_en) {

-- 
2.45.2

