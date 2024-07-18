From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:58 +0200
Subject: [PATCH 12/22] iio: light: adjd_s311: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-12-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=864;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=TSHQtCAOvetS9PFuXHMtMqGj6a4Kr9MMSY7AM7lvy6E=;
 b=Ochlt3MUUEAbTKL3DZ+k2tTqiOIXNbQgvZgyAeiR73Zee8PSejrRu3z6DifLNXJhZsanab8xM
 kSIwYxFu1JzDikOBLBG4YLTmKtyXRUDeUnvltLAgo87N5B5A+nOj6p/
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/light/adjd_s311.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/light/adjd_s311.c b/drivers/iio/light/adjd_s311.c
index 5169f12c3ebaf..c1b43053fbc73 100644
--- a/drivers/iio/light/adjd_s311.c
+++ b/drivers/iio/light/adjd_s311.c
@@ -125,8 +125,7 @@ static irqreturn_t adjd_s311_trigger_handler(int irq, void *p)
 	if (ret < 0)
 		goto done;
 
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-		indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		ret = i2c_smbus_read_word_data(data->client,
 			ADJD_S311_DATA_REG(i));
 		if (ret < 0)

-- 
2.45.2

