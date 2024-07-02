From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:49 +0200
Subject: [PATCH 17/20] iio: adc: ad_sigma_delta: use new '.masklength'
 accessors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-17-98193bf536a6@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936157; l=1684;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=GoBEg3yNYVlK4uhicWAng1ZNnwcbQvwHl3xbhcuNjPI=;
 b=wH7sHfvZ2g43QU6gZdGIAYHosI3ta6a2Y2rX0bDLPTTZP8YUKYKEsPAHOiPLFkpEy6X8JewNQ
 inqywiBMXhEAwR5cClPLYIWa1ixv/6XnrnAEBltg4drZ+C/pVbkHVmn
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of iio_get_masklength) and iio_for_each_active_channel() to
access '.masklength' so it can be annotated as __private when there
are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad_sigma_delta.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/adc/ad_sigma_delta.c b/drivers/iio/adc/ad_sigma_delta.c
index a2b87f6b7a07..62653d7fe39b 100644
--- a/drivers/iio/adc/ad_sigma_delta.c
+++ b/drivers/iio/adc/ad_sigma_delta.c
@@ -350,7 +350,7 @@ static int ad_sd_buffer_postenable(struct iio_dev *indio_dev)
 
 	if (sigma_delta->num_slots == 1) {
 		channel = find_first_bit(indio_dev->active_scan_mask,
-					 indio_dev->masklength);
+					 iio_get_masklength(indio_dev));
 		ret = ad_sigma_delta_set_channel(sigma_delta,
 						 indio_dev->channels[channel].address);
 		if (ret)
@@ -363,7 +363,7 @@ static int ad_sd_buffer_postenable(struct iio_dev *indio_dev)
 		 * implementation is mandatory.
 		 */
 		slot = 0;
-		for_each_set_bit(i, indio_dev->active_scan_mask, indio_dev->masklength) {
+		iio_for_each_active_channel(indio_dev, i) {
 			sigma_delta->slots[slot] = indio_dev->channels[i].address;
 			slot++;
 		}
@@ -525,7 +525,7 @@ static bool ad_sd_validate_scan_mask(struct iio_dev *indio_dev, const unsigned l
 {
 	struct ad_sigma_delta *sigma_delta = iio_device_get_drvdata(indio_dev);
 
-	return bitmap_weight(mask, indio_dev->masklength) <= sigma_delta->num_slots;
+	return bitmap_weight(mask, iio_get_masklength(indio_dev)) <= sigma_delta->num_slots;
 }
 
 static const struct iio_buffer_setup_ops ad_sd_buffer_setup_ops = {

-- 
2.45.2

