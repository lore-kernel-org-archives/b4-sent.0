From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:47 +0200
Subject: [PATCH 15/20] iio: adc: ad7298: make use of iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-15-98193bf536a6@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936157; l=801;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ZK5+aMXYaMNYV9d90opMtFfRkoEJrZPm17fO7HBXKCg=;
 b=bBdOYmZMjoXy8dHw5U5DCzkC1MW642k0qxtGkPbdxSpudzdrcC1SyHkq1BXJDjzSOQsc2EYqH
 PKMs/R0+RzqB2zgmUTR43u8A7wBZFCtENhKKATYeu6u68vHJTWB0Imh
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad7298.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ad7298.c b/drivers/iio/adc/ad7298.c
index c0430f71f592..0128436367db 100644
--- a/drivers/iio/adc/ad7298.c
+++ b/drivers/iio/adc/ad7298.c
@@ -109,7 +109,8 @@ static int ad7298_update_scan_mode(struct iio_dev *indio_dev,
 	int scan_count;
 
 	/* Now compute overall size */
-	scan_count = bitmap_weight(active_scan_mask, indio_dev->masklength);
+	scan_count = bitmap_weight(active_scan_mask,
+				   iio_get_masklength(indio_dev));
 
 	command = AD7298_WRITE | st->ext_ref;
 

-- 
2.45.2

