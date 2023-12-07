From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 07 Dec 2023 13:39:28 +0100
Subject: [PATCH v2 5/8] iio: adc: ad9467: use spi_get_device_match_data()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231207-iio-backend-prep-v2-5-a4a33bc4d70e@analog.com>
References: <20231207-iio-backend-prep-v2-0-a4a33bc4d70e@analog.com>
In-Reply-To: <20231207-iio-backend-prep-v2-0-a4a33bc4d70e@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701952767; l=738;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=n8Aav+VNN3B3YvMoVVGj82oY7GjyH/2D22CiUso8SJs=;
 b=92eEHBFLYZLpD9IC+HfCn/kfBeLmDxK0ICY5k4AUT6ZijpYMfrIQKCbZf96E1E9XQAmX2K0V+
 BOORfBP/YzwA1htqdTrbFkuLNfkHtFpYxMquthmK5W9BLpgCwt3D/c7
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of spi_get_device_match_data() to simplify things.

Reviewed-by: David Lechner <dlechner@baylibre.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index f668313730cb..b16d28c1adcb 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -454,9 +454,7 @@ static int ad9467_probe(struct spi_device *spi)
 	unsigned int id;
 	int ret;
 
-	info = of_device_get_match_data(&spi->dev);
-	if (!info)
-		info = (void *)spi_get_device_id(spi)->driver_data;
+	info = spi_get_device_match_data(spi);
 	if (!info)
 		return -ENODEV;
 

-- 
2.43.0

