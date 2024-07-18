From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:53 +0200
Subject: [PATCH 07/22] iio: health: afe4404: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-7-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=921;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=T8qh+PucTketG3iHEIzNlvaeE66dT5WhEuTq3tBVE18=;
 b=87ThQexREmQD9OsoxEDEcew3xLfOuwEiZ/+vDMFUHIcctR38EC2SAIhjO7h4nvlXa6+C0G2f2
 Bh2KsGXQzDPAm+ihbhwBddTlt+siBg3PVwgjfbSMD0yhrB4QH4fmNtr
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/health/afe4404.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/health/afe4404.c b/drivers/iio/health/afe4404.c
index 7f69baa1ed53..d49e1572a439 100644
--- a/drivers/iio/health/afe4404.c
+++ b/drivers/iio/health/afe4404.c
@@ -333,8 +333,7 @@ static irqreturn_t afe4404_trigger_handler(int irq, void *private)
 	struct afe4404_data *afe = iio_priv(indio_dev);
 	int ret, bit, i = 0;
 
-	for_each_set_bit(bit, indio_dev->active_scan_mask,
-			 indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, bit) {
 		ret = regmap_read(afe->regmap, afe4404_channel_values[bit],
 				  &afe->buffer[i++]);
 		if (ret)

-- 
2.45.2

