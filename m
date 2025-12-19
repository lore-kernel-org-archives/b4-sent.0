From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 19 Dec 2025 15:28:16 +0000
Subject: [PATCH v2 5/6] iio: buffer-dmaengine: Use the cleanup.h API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251219-iio-dmabuf-improvs-v2-5-caa76de6e873@analog.com>
References: <20251219-iio-dmabuf-improvs-v2-0-caa76de6e873@analog.com>
In-Reply-To: <20251219-iio-dmabuf-improvs-v2-0-caa76de6e873@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766158092; l=1581;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=gczugKBMuRn3hTXaarzlLj4T2DQsus4YqNHHz8e8YNM=;
 b=NWjThoNq9zD9OXpQWVSE92t3Nxcv0sTl3BZougvG0cv8p5Mn4kevOCUd/vTwv4Au1Ziq7YXR1
 X2ALUq4KCueAsVah4ibyuOPgmbNkGsVGc1WXjNAI29BcqtvSbR27eiX
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of the cleanup.h API for locks in order to simplify some code
paths.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-dmaengine.c | 11 ++++-------
 1 file changed, 4 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dmaengine.c b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
index e9d9a7d39fe1..a8a4adb5ed3a 100644
--- a/drivers/iio/buffer/industrialio-buffer-dmaengine.c
+++ b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
@@ -49,11 +49,9 @@ static void iio_dmaengine_buffer_block_done(void *data,
 		const struct dmaengine_result *result)
 {
 	struct iio_dma_buffer_block *block = data;
-	unsigned long flags;
 
-	spin_lock_irqsave(&block->queue->list_lock, flags);
-	list_del(&block->head);
-	spin_unlock_irqrestore(&block->queue->list_lock, flags);
+	scoped_guard(spinlock_irqsave, &block->queue->list_lock)
+		list_del(&block->head);
 	block->bytes_used -= result->residue;
 	iio_dma_buffer_block_done(block);
 }
@@ -131,9 +129,8 @@ static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
 	if (dma_submit_error(cookie))
 		return dma_submit_error(cookie);
 
-	spin_lock_irq(&dmaengine_buffer->queue.list_lock);
-	list_add_tail(&block->head, &dmaengine_buffer->active);
-	spin_unlock_irq(&dmaengine_buffer->queue.list_lock);
+	scoped_guard(spinlock_irq, &dmaengine_buffer->queue.list_lock)
+		list_add_tail(&block->head, &dmaengine_buffer->active);
 
 	dma_async_issue_pending(dmaengine_buffer->chan);
 

-- 
2.52.0

