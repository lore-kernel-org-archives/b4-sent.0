From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:38:06 +0200
Subject: [PATCH 20/22] iio: proximity: hx9023s: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-20-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=1284;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=5J4ljVqvZC41+4k0k0jyV5NtbaiSrOltZERqD/amCmU=;
 b=z9I/xVnWw4qFt7RCBPr3WfSWATEcbv+auOnEzZcGbCIRTxpe155iqa46TsHlFgR+7T6QgZOKx
 X5Wj80h+geGCIpOzDaibaIzmQXzQyr3OKHvSoG2Jk25w3ZZ5h3u2crE
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/proximity/hx9023s.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/proximity/hx9023s.c b/drivers/iio/proximity/hx9023s.c
index 63e3b56d4f4ce..fe14a62a13428 100644
--- a/drivers/iio/proximity/hx9023s.c
+++ b/drivers/iio/proximity/hx9023s.c
@@ -936,7 +936,7 @@ static irqreturn_t hx9023s_trigger_handler(int irq, void *private)
 		goto out;
 	}
 
-	for_each_set_bit(bit, indio_dev->active_scan_mask, indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, bit) {
 		index = indio_dev->channels[bit].channel;
 		data->buffer.channels[i++] = cpu_to_le16(data->ch_data[index].diff);
 	}
@@ -957,7 +957,7 @@ static int hx9023s_buffer_preenable(struct iio_dev *indio_dev)
 	unsigned int bit;
 
 	guard(mutex)(&data->mutex);
-	for_each_set_bit(bit, indio_dev->active_scan_mask, indio_dev->masklength)
+	iio_for_each_active_channel(indio_dev, bit)
 		__set_bit(indio_dev->channels[bit].channel, &channels);
 
 	hx9023s_update_chan_en(data, channels, data->chan_event);

-- 
2.45.2

