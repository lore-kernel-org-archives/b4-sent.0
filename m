From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 03 Dec 2025 15:11:41 +0000
Subject: [PATCH 6/6] iio: buffer-dmaengine: Fix coding style complains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251203-iio-dmabuf-improvs-v1-6-0e4907ce7322@analog.com>
References: <20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com>
In-Reply-To: <20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764774697; l=2281;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=69+dyLooRn338nP8fU7ume5QNFgzBMAZG9jZvwNJ6yg=;
 b=crtyyF90MwMdaQqi0OClvYRurthYmZQqItNBMwvtn7EuG3wG7qTnrzo+BOFOgz8DtLM6AE1Ap
 0TPUGDQbZkmBTDs+0tzTZ6gFdNWA3I2dbMAmlLmJNbTJ4sv5A5HIn/k
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just making sure checkpatch is happy. No functional change intended.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-dmaengine.c | 11 +++++------
 1 file changed, 5 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dmaengine.c b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
index a8a4adb5ed3a..b906ceaff9e1 100644
--- a/drivers/iio/buffer/industrialio-buffer-dmaengine.c
+++ b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
@@ -39,14 +39,13 @@ struct dmaengine_buffer {
 	size_t max_size;
 };
 
-static struct dmaengine_buffer *iio_buffer_to_dmaengine_buffer(
-		struct iio_buffer *buffer)
+static struct dmaengine_buffer *iio_buffer_to_dmaengine_buffer(struct iio_buffer *buffer)
 {
 	return container_of(buffer, struct dmaengine_buffer, queue.buffer);
 }
 
 static void iio_dmaengine_buffer_block_done(void *data,
-		const struct dmaengine_result *result)
+					    const struct dmaengine_result *result)
 {
 	struct iio_dma_buffer_block *block = data;
 
@@ -57,7 +56,7 @@ static void iio_dmaengine_buffer_block_done(void *data,
 }
 
 static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
-	struct iio_dma_buffer_block *block)
+					     struct iio_dma_buffer_block *block)
 {
 	struct dmaengine_buffer *dmaengine_buffer =
 		iio_buffer_to_dmaengine_buffer(&queue->buffer);
@@ -184,7 +183,7 @@ static const struct iio_dma_buffer_ops iio_dmaengine_default_ops = {
 };
 
 static ssize_t iio_dmaengine_buffer_get_length_align(struct device *dev,
-	struct device_attribute *attr, char *buf)
+						     struct device_attribute *attr, char *buf)
 {
 	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
 	struct dmaengine_buffer *dmaengine_buffer =
@@ -243,7 +242,7 @@ static struct iio_buffer *iio_dmaengine_buffer_alloc(struct dma_chan *chan)
 	dmaengine_buffer->max_size = dma_get_max_seg_size(chan->device->dev);
 
 	iio_dma_buffer_init(&dmaengine_buffer->queue, chan->device->dev,
-		&iio_dmaengine_default_ops);
+			    &iio_dmaengine_default_ops);
 
 	dmaengine_buffer->queue.buffer.attrs = iio_dmaengine_buffer_attrs;
 	dmaengine_buffer->queue.buffer.access = &iio_dmaengine_buffer_ops;

-- 
2.52.0

