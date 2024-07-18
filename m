From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:47 +0200
Subject: [PATCH 01/22] iio: adc: cc10001_adc: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-1-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=890;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=7KQilIgM9x/pjjV8IpQ1xKu+V2/UHH1gFTIwZPtjpgg=;
 b=fRsRXoEKF4YGid901q5e9xKkLzGZU67xeNH6uMS37BmezS6j0kxav4HD3+uCyY+mcWK8sNBm7
 rfEyY1iu9/PAdUVvUm+mus23ZkZs+gzMkemRa3Fk8xcUW8uNgmwBxoC
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/cc10001_adc.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/iio/adc/cc10001_adc.c b/drivers/iio/adc/cc10001_adc.c
index a432342348abe..2c51b90b71018 100644
--- a/drivers/iio/adc/cc10001_adc.c
+++ b/drivers/iio/adc/cc10001_adc.c
@@ -157,9 +157,7 @@ static irqreturn_t cc10001_adc_trigger_h(int irq, void *p)
 
 	i = 0;
 	sample_invalid = false;
-	for_each_set_bit(scan_idx, indio_dev->active_scan_mask,
-				  indio_dev->masklength) {
-
+	iio_for_each_active_channel(indio_dev, scan_idx) {
 		channel = indio_dev->channels[scan_idx].channel;
 		cc10001_adc_start(adc_dev, channel);
 

-- 
2.45.2

