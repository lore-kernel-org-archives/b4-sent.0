From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:54 +0200
Subject: [PATCH 08/22] iio: humidity: am2315: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-8-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=916;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=v1J9CeLrZGFCPkvoSSiWK6wlv3vsQ+PI5KbphUEl53U=;
 b=Ztg7v5y8eCCuJgT3EaRbFW3AJPABX5Sgl2lxvBXdr+eYOxsmItf/J/RBrmmwM61bKR5PmqtCx
 +3ZkoWmV+N8DQBCyJvsclCOEYiark1NI9T6mll66N+WOKE/QwNQ8w6O
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/humidity/am2315.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/iio/humidity/am2315.c b/drivers/iio/humidity/am2315.c
index a56474be5dd2..6b0aa3a3f025 100644
--- a/drivers/iio/humidity/am2315.c
+++ b/drivers/iio/humidity/am2315.c
@@ -174,8 +174,7 @@ static irqreturn_t am2315_trigger_handler(int irq, void *p)
 		data->scan.chans[1] = sensor_data.temp_data;
 	} else {
 		i = 0;
-		for_each_set_bit(bit, indio_dev->active_scan_mask,
-				 indio_dev->masklength) {
+		iio_for_each_active_channel(indio_dev, bit) {
 			data->scan.chans[i] = (bit ? sensor_data.temp_data :
 					       sensor_data.hum_data);
 			i++;

-- 
2.45.2

