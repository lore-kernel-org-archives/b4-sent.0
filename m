From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:50 +0200
Subject: [PATCH 18/20] iio: adc: at91_adc: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-18-98193bf536a6@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936157; l=908;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=W/t1QLnOMBghJ3cBP0Sz8vy2Yubdg+XmvmGHI/DD3L0=;
 b=UgykRrQ4gxnOiL92MVtaXiv5JRu0qLvRXJ3en/zfBLdcF1+6f4aouctfdqT139Xlq0n1yySoq
 /o3KRpCxAeyDCNviZtJkLh3MEekKinZgzRRLzBwuc1kxonACiBumgdF
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/at91_adc.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/iio/adc/at91_adc.c b/drivers/iio/adc/at91_adc.c
index eb501e3c86a5..af4b0224076f 100644
--- a/drivers/iio/adc/at91_adc.c
+++ b/drivers/iio/adc/at91_adc.c
@@ -268,9 +268,7 @@ static irqreturn_t at91_adc_trigger_handler(int irq, void *p)
 	struct iio_chan_spec const *chan;
 	int i, j = 0;
 
-	for (i = 0; i < idev->masklength; i++) {
-		if (!test_bit(i, idev->active_scan_mask))
-			continue;
+	iio_for_each_active_channel(idev, i) {
 		chan = idev->channels + i;
 		st->buffer[j] = at91_adc_readl(st, AT91_ADC_CHAN(st, chan->channel));
 		j++;

-- 
2.45.2

