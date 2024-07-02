From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:40 +0200
Subject: [PATCH 08/20] iio: accel: cros_ec_accel_legacy: make use of
 iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-8-98193bf536a6@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936156; l=856;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Yooi1Y6tJJguy67GjA7GqDAjdHAGHhdREsMY2f86Dxo=;
 b=RBZcE+cYo3blVA2VGyLaJwUXflDQ6pPjo9mW6HflNYlGIxZLsMd2KyTAefDtDCYuqFOtd5yT7
 dRU0tYawuD3DUTmtGjIR9BLFCxRsRdf/aghHELirnJcWyKom2CvKcEO
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ue iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/accel/cros_ec_accel_legacy.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/accel/cros_ec_accel_legacy.c b/drivers/iio/accel/cros_ec_accel_legacy.c
index 0f403342b1fc..f7e4dc02b34d 100644
--- a/drivers/iio/accel/cros_ec_accel_legacy.c
+++ b/drivers/iio/accel/cros_ec_accel_legacy.c
@@ -62,7 +62,7 @@ static int cros_ec_accel_legacy_read_cmd(struct iio_dev *indio_dev,
 		return ret;
 	}
 
-	for_each_set_bit(i, &scan_mask, indio_dev->masklength) {
+	for_each_set_bit(i, &scan_mask, iio_get_masklength(indio_dev)) {
 		*data = st->resp->dump.sensor[sensor_num].data[i] *
 			st->sign[i];
 		data++;

-- 
2.45.2

