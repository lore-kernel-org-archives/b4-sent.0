From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:49 +0200
Subject: [PATCH 03/22] iio: adc: hx711: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-3-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=905;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=KAnU15Hk8iF1wb61OpyPO1VDqtC2h7HwECBSLVsPXIk=;
 b=i+RDahg3yTWSGz+G1qvNnmyIo/4Ra40gyIXDQbVIvpQWJPJ9J03N3niYrlONx1IpHfxvWDUzT
 nSrem2VyLyiCcRXlt2Z2CMZUjTHq/hovWoD9KWa1pU6dQHWyEBXreqw
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/hx711.c | 5 +----
 1 file changed, 1 insertion(+), 4 deletions(-)

diff --git a/drivers/iio/adc/hx711.c b/drivers/iio/adc/hx711.c
index b3372ccff7d5..376f4e02de97 100644
--- a/drivers/iio/adc/hx711.c
+++ b/drivers/iio/adc/hx711.c
@@ -363,10 +363,7 @@ static irqreturn_t hx711_trigger(int irq, void *p)
 
 	memset(hx711_data->buffer, 0, sizeof(hx711_data->buffer));
 
-	for (i = 0; i < indio_dev->masklength; i++) {
-		if (!test_bit(i, indio_dev->active_scan_mask))
-			continue;
-
+	iio_for_each_active_channel(indio_dev, i) {
 		hx711_data->buffer[j] = hx711_reset_read(hx711_data,
 					indio_dev->channels[i].channel);
 		j++;

-- 
2.45.2

