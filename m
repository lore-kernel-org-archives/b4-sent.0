From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:51 +0200
Subject: [PATCH 05/22] iio: health: afe4403: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-5-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=875;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=6tp4obCLiDRZ8R0W142pAzIZiL2MQwENy2R1UHKy5HY=;
 b=yuLejtozZFgSU4xKAxP2iidJUylcr49KdPtdA4shuLIIzE6LFDLJrQykH89vmClPIqhhVwgyl
 G6fgUkk8OVmDryS06iCSehJDrTeowtp9Z2ehJ5BLtQti0Xvj8MLH1xT
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/health/afe4403.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/health/afe4403.c b/drivers/iio/health/afe4403.c
index 52326dc521ac..85637e8ac45f 100644
--- a/drivers/iio/health/afe4403.c
+++ b/drivers/iio/health/afe4403.c
@@ -321,8 +321,7 @@ static irqreturn_t afe4403_trigger_handler(int irq, void *private)
 	if (ret)
 		goto err;
 
-	for_each_set_bit(bit, indio_dev->active_scan_mask,
-			 indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, bit) {
 		ret = spi_write_then_read(afe->spi,
 					  &afe4403_channel_values[bit], 1,
 					  rx, sizeof(rx));

-- 
2.45.2

