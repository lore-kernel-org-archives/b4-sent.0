From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:48 +0200
Subject: [PATCH 16/20] iio: adc: ad799x: make use of iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-16-98193bf536a6@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936157; l=791;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=wWndx9yRTDx49TztOjVCAJ5yEItwvGvV8lgnhI1efkk=;
 b=h45vVL4Ul2B1DhYLqcsnz1Wp/Q8mkB+/gpyHYoVmBZuWoZ1M6bMprsUorUO2yz6D8zWbYsDBz
 eOPXJHEaY5nDuJuHTISepLyyHz0WZG4h2xB9hbMrT1qh+vX3r4jOBxg
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad799x.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ad799x.c b/drivers/iio/adc/ad799x.c
index 0f0dcd9ca6b60..0f107e3fc2c85 100644
--- a/drivers/iio/adc/ad799x.c
+++ b/drivers/iio/adc/ad799x.c
@@ -237,7 +237,8 @@ static int ad799x_update_scan_mode(struct iio_dev *indio_dev,
 	if (!st->rx_buf)
 		return -ENOMEM;
 
-	st->transfer_size = bitmap_weight(scan_mask, indio_dev->masklength) * 2;
+	st->transfer_size = bitmap_weight(scan_mask,
+					  iio_get_masklength(indio_dev)) * 2;
 
 	switch (st->id) {
 	case ad7992:

-- 
2.45.2

