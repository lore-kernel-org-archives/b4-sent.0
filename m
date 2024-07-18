From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:38:08 +0200
Subject: [PATCH 22/22] iio: proximity: sx_common: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-22-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=1313;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=NYWZa2/XbLLl1ArjhpZ1nSWe6IAZWkml4RKT6VvzD7U=;
 b=u8mmgUBYXjarv3tjrit26WZcPRYGU2UZ90hedz8bkTFDWCWbVuWtwSe6OL5UGBmHoaNWXOZlu
 ndxSYU+hs/dBWluJWGbam9H65JvN7Esn9VWxSJr25rSI1IBqyfYN4u9
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/proximity/sx_common.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/proximity/sx_common.c b/drivers/iio/proximity/sx_common.c
index a95e9814aaf2..71aa6dced7d3 100644
--- a/drivers/iio/proximity/sx_common.c
+++ b/drivers/iio/proximity/sx_common.c
@@ -369,8 +369,7 @@ static irqreturn_t sx_common_trigger_handler(int irq, void *private)
 
 	mutex_lock(&data->mutex);
 
-	for_each_set_bit(bit, indio_dev->active_scan_mask,
-			 indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, bit) {
 		ret = data->chip_info->ops.read_prox_data(data,
 						     &indio_dev->channels[bit],
 						     &val);
@@ -398,8 +397,7 @@ static int sx_common_buffer_preenable(struct iio_dev *indio_dev)
 	int bit, ret;
 
 	mutex_lock(&data->mutex);
-	for_each_set_bit(bit, indio_dev->active_scan_mask,
-			 indio_dev->masklength)
+	iio_for_each_active_channel(indio_dev, bit)
 		__set_bit(indio_dev->channels[bit].channel, &channels);
 
 	ret = sx_common_update_chan_en(data, channels, data->chan_event);

-- 
2.45.2

