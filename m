From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:59 +0200
Subject: [PATCH 13/22] iio: light: gp2ap020a00f: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-13-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=1716;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=iVAdgQB+Z4IwxRK4KcX4smk+miW5axW1/Zjw6uLW21E=;
 b=7K8V1J0806sMudf1VLaWcWBtMWSwCfjZ1Mly0z4YAGqDqP/2zcvrxhbjm8eAGWGeBRexmZ29P
 /i01BwZhG1VBTPVO4Oc6bvSC29pJ6D9t7jE78bSzDlT27WA+/yhKddQ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/light/gp2ap020a00f.c | 9 +++------
 1 file changed, 3 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/light/gp2ap020a00f.c b/drivers/iio/light/gp2ap020a00f.c
index 757383456da6..b3f87dded040 100644
--- a/drivers/iio/light/gp2ap020a00f.c
+++ b/drivers/iio/light/gp2ap020a00f.c
@@ -965,8 +965,7 @@ static irqreturn_t gp2ap020a00f_trigger_handler(int irq, void *data)
 	size_t d_size = 0;
 	int i, out_val, ret;
 
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-		indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		ret = regmap_bulk_read(priv->regmap,
 				GP2AP020A00F_DATA_REG(i),
 				&priv->buffer[d_size], 2);
@@ -1397,8 +1396,7 @@ static int gp2ap020a00f_buffer_postenable(struct iio_dev *indio_dev)
 	 * two separate IIO channels they are treated in the driver logic
 	 * as if they were controlled independently.
 	 */
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-		indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		switch (i) {
 		case GP2AP020A00F_SCAN_MODE_LIGHT_CLEAR:
 			err = gp2ap020a00f_exec_cmd(data,
@@ -1435,8 +1433,7 @@ static int gp2ap020a00f_buffer_predisable(struct iio_dev *indio_dev)
 
 	mutex_lock(&data->lock);
 
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-		indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		switch (i) {
 		case GP2AP020A00F_SCAN_MODE_LIGHT_CLEAR:
 			err = gp2ap020a00f_exec_cmd(data,

-- 
2.45.2

