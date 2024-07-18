From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:38:02 +0200
Subject: [PATCH 16/22] iio: light: tcs3414: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-16-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=895;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=FQPoPlxTckobGJ/E9BiUhJ3AOag6kmtMKp8GvAK96A8=;
 b=XGy1BTl3TvcwxZ924yiZ5ewtZ7TLHwoYgL6uYjfGMrZcrWxANdgK5Ym5e3BmjLr8bVWS9DWf0
 0jzfDRIuyT9CXSWCmTE9CkUUVQGnpjh9p+U6xjFEh2KwPnzWni6ujAg
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/light/tcs3414.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/light/tcs3414.c b/drivers/iio/light/tcs3414.c
index c9566615b964..4fecdf10aeb1 100644
--- a/drivers/iio/light/tcs3414.c
+++ b/drivers/iio/light/tcs3414.c
@@ -206,8 +206,7 @@ static irqreturn_t tcs3414_trigger_handler(int irq, void *p)
 	struct tcs3414_data *data = iio_priv(indio_dev);
 	int i, j = 0;
 
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-		indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		int ret = i2c_smbus_read_word_data(data->client,
 			TCS3414_DATA_GREEN + 2*i);
 		if (ret < 0)

-- 
2.45.2

