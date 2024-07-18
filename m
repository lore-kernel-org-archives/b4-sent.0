From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:38:03 +0200
Subject: [PATCH 17/22] iio: light: tcs3472: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-17-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=848;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=IBjfNo1AV7gv+op6SVY6NxHjmyuB/chdo1N1zk6XKlA=;
 b=qjuMCDKJWXx9En8/g3lMf9uVczVE+z+w4k8wrugTSpL8hBd3GuU4316lKJMBqDNz5nfCKGjC7
 AtQTXgCza69D19og5UIt9mNcIZokc76dRaa+NFqwU9bod50fMjocKIj
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/light/tcs3472.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/light/tcs3472.c b/drivers/iio/light/tcs3472.c
index 89384dba83dd..04452b4664f3 100644
--- a/drivers/iio/light/tcs3472.c
+++ b/drivers/iio/light/tcs3472.c
@@ -383,8 +383,7 @@ static irqreturn_t tcs3472_trigger_handler(int irq, void *p)
 	if (ret < 0)
 		goto done;
 
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-		indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		ret = i2c_smbus_read_word_data(data->client,
 			TCS3472_CDATA + 2*i);
 		if (ret < 0)

-- 
2.45.2

