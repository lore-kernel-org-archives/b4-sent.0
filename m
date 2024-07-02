From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:44 +0200
Subject: [PATCH 12/20] iio: accel: stk8312: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-12-98193bf536a6@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936157; l=860;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=sKvcghE5ThQXXY6IqazRh2jRyFRk4Gvhw2Dt6y9Vhp8=;
 b=kt0rMyqWMfymAI/q/Z0mnVnvXvK3GnHs++rHvCcBHM46WfZB++w555wevU7tgbbCqcgTdmB6j
 DpFqKVZfwP0AkzerK5hCIynsQ4wo/L0jH99Mjn/zsRlGOE0exxAh4Ko
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/accel/stk8312.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/accel/stk8312.c b/drivers/iio/accel/stk8312.c
index b3534d5751b95..abead190254b5 100644
--- a/drivers/iio/accel/stk8312.c
+++ b/drivers/iio/accel/stk8312.c
@@ -448,8 +448,7 @@ static irqreturn_t stk8312_trigger_handler(int irq, void *p)
 			goto err;
 		}
 	} else {
-		for_each_set_bit(bit, indio_dev->active_scan_mask,
-				 indio_dev->masklength) {
+		iio_for_each_active_channel(indio_dev, bit) {
 			ret = stk8312_read_accel(data, bit);
 			if (ret < 0) {
 				mutex_unlock(&data->lock);

-- 
2.45.2

