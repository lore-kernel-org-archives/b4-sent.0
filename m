From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:55 +0200
Subject: [PATCH 09/22] iio: imu: bmi160_core: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-9-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=968;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=FCLyiHnQTa3nd6JpFgp4oW46A/SnReH0cNLG6fHRNAw=;
 b=wAqC8oxgdozzLH8C2SfoiJq+6J85sx9mKJ7L2mzkWOcQ7si6k3ztMmcr8CiKOqN1c2SQcYG7H
 MMc0dTolNgMD0ILZHAEaD1VDw5WrQNtVsdoN+BrQSQt7TWKLnzS5gD0
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/imu/bmi160/bmi160_core.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/imu/bmi160/bmi160_core.c b/drivers/iio/imu/bmi160/bmi160_core.c
index 90aa04d94da54..495e8a74ac676 100644
--- a/drivers/iio/imu/bmi160/bmi160_core.c
+++ b/drivers/iio/imu/bmi160/bmi160_core.c
@@ -435,8 +435,7 @@ static irqreturn_t bmi160_trigger_handler(int irq, void *p)
 	int i, ret, j = 0, base = BMI160_REG_DATA_MAGN_XOUT_L;
 	__le16 sample;
 
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-			 indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		ret = regmap_bulk_read(data->regmap, base + i * sizeof(sample),
 				       &sample, sizeof(sample));
 		if (ret)

-- 
2.45.2

