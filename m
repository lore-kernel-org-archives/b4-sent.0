From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:38:00 +0200
Subject: [PATCH 14/22] iio: light: isl29125: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-14-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=899;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=44r1OBRTeVEJ/5KHZVThUvH1dW1shD4ej8y1KV3icWw=;
 b=3uR4X54aZ70UqR04TwiESV4WFPo/WoLMFnVDSgzhLJzHMYCMs1gQqO4QjKe1HvVgXICyXouTy
 WSm0Oas/rkKDEn6ViCoLXlQq/2lo27TK9TkcL4QAmCmHtlI2U/KOnN5
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/light/isl29125.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/light/isl29125.c b/drivers/iio/light/isl29125.c
index 59329546df58..b176bf4c884b 100644
--- a/drivers/iio/light/isl29125.c
+++ b/drivers/iio/light/isl29125.c
@@ -181,8 +181,7 @@ static irqreturn_t isl29125_trigger_handler(int irq, void *p)
 	struct isl29125_data *data = iio_priv(indio_dev);
 	int i, j = 0;
 
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-		indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		int ret = i2c_smbus_read_word_data(data->client,
 			isl29125_regs[i].data);
 		if (ret < 0)

-- 
2.45.2

