From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:38:04 +0200
Subject: [PATCH 18/22] iio: magnetometer: rm3100-core: make use of
 iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-18-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=963;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=frSUer5X5YE5lOu3IYnGGZx2ucpdgn6sI7LuCnpdktI=;
 b=xdOL+QwavzRfy2D5EBRZBhvnsu2mRXMY8ENP4T+7uGuWmJp+6F/vunrkUg2ztPxgk57BMQnam
 KvMDhgZR9ChAIDHSxRTeBFFXFrMp9KI6H1M9oATqvQ3f+HnCpTrQ4XP
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/magnetometer/rm3100-core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/magnetometer/rm3100-core.c b/drivers/iio/magnetometer/rm3100-core.c
index 42b70cd42b393..0e03a772fa43d 100644
--- a/drivers/iio/magnetometer/rm3100-core.c
+++ b/drivers/iio/magnetometer/rm3100-core.c
@@ -464,7 +464,7 @@ static irqreturn_t rm3100_trigger_handler(int irq, void *p)
 	struct iio_poll_func *pf = p;
 	struct iio_dev *indio_dev = pf->indio_dev;
 	unsigned long scan_mask = *indio_dev->active_scan_mask;
-	unsigned int mask_len = indio_dev->masklength;
+	unsigned int mask_len = iio_get_masklength(indio_dev);
 	struct rm3100_data *data = iio_priv(indio_dev);
 	struct regmap *regmap = data->regmap;
 	int ret, i, bit;

-- 
2.45.2

