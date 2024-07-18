From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:57 +0200
Subject: [PATCH 11/22] iio: imu: kmx61: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-11-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=869;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ggyixMIF+6oukTLiM3iRmoyaIesgRCWO8VE0DMlpAmU=;
 b=29DDxZq8ouN0wfai8KNE5f2bmxSOgwxe26gNJUGhNOBvqQC7tl3Q4ycsxB0mpMCgWmLKEIgoC
 3OQtLIwVFxFDYaRTLJ4/PHBiNSzfkKW0aY+erQemUMed8sq8ejCWnni
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/imu/kmx61.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/imu/kmx61.c b/drivers/iio/imu/kmx61.c
index d37eca5ef761..c61c012e25bb 100644
--- a/drivers/iio/imu/kmx61.c
+++ b/drivers/iio/imu/kmx61.c
@@ -1200,8 +1200,7 @@ static irqreturn_t kmx61_trigger_handler(int irq, void *p)
 		base = KMX61_MAG_XOUT_L;
 
 	mutex_lock(&data->lock);
-	for_each_set_bit(bit, indio_dev->active_scan_mask,
-			 indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, bit) {
 		ret = kmx61_read_measurement(data, base, bit);
 		if (ret < 0) {
 			mutex_unlock(&data->lock);

-- 
2.45.2

