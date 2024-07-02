From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:36 +0200
Subject: [PATCH 04/20] iio: accel: adxl367: make use of
 iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-4-98193bf536a6@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936156; l=721;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=f4PVshteDVZAwqATinUZmA3UwIta66xyxWFMtEAfYQg=;
 b=1jd1tko8JTt6ombBnrwWcAZplN7C74Nu1r8Ua45+V5Zh5KiUAiJVG3T2zgTbf3ehU5XCQW62l
 Tn8hVu93D49Apu1X0TW0t5tEspUjaokc84rDXaGMUk7V4hl1ov/rbc4
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/accel/adxl367.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/accel/adxl367.c b/drivers/iio/accel/adxl367.c
index 5cf4828a5eb5..1c046e96aef9 100644
--- a/drivers/iio/accel/adxl367.c
+++ b/drivers/iio/accel/adxl367.c
@@ -1220,7 +1220,7 @@ static int adxl367_update_scan_mode(struct iio_dev *indio_dev,
 		return ret;
 
 	st->fifo_set_size = bitmap_weight(active_scan_mask,
-					  indio_dev->masklength);
+					  iio_get_masklength(indio_dev));
 
 	return 0;
 }

-- 
2.45.2

