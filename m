From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 07 Oct 2025 10:15:22 +0100
Subject: [PATCH v3 2/3] iio: buffer-dma: support getting the DMA channel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251007-fix-iio-dmabuf-get-dma-device-v3-2-0c73e2c0653b@analog.com>
References: <20251007-fix-iio-dmabuf-get-dma-device-v3-0-0c73e2c0653b@analog.com>
In-Reply-To: <20251007-fix-iio-dmabuf-get-dma-device-v3-0-0c73e2c0653b@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759828521; l=2111;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=UeNxzat1eGNvUr3sMj3PKl6QY4MQ66nZwzV2A6/tUFQ=;
 b=dQoXcvR61sYTLqbDWDPZoeygYWDSj1moSPYvlHuQybbcJXsobNP5uh7FvkVAnwEoAA+Z2nqoC
 5KtHHpTMkCVAvEtNJdsunsKMtRi4u8dezPeDThc/pTPb53s6jj4NXiw
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the .get_dma_dev() callback for DMA buffers by returning the
device that owns the DMA channel. This allows the core DMABUF
infrastructure to properly map DMA buffers using the correct device,
avoiding the need for bounce buffers on systems where memory is mapped
above the 32-bit range.

The function returns the DMA queue's device, which is the actual device
responsible for DMA operations in buffer-dma implementations.

Cc: stable@vger.kernel.org
Reviewed-by: David Lechner <dlechner@baylibre.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-dma.c | 6 ++++++
 include/linux/iio/buffer-dma.h               | 1 +
 2 files changed, 7 insertions(+)

diff --git a/drivers/iio/buffer/industrialio-buffer-dma.c b/drivers/iio/buffer/industrialio-buffer-dma.c
index ee294a775e8aa050aca85e422de4c267adee1a33..7a7a9d37339bc1c2ffec58687a42dde16b1412bb 100644
--- a/drivers/iio/buffer/industrialio-buffer-dma.c
+++ b/drivers/iio/buffer/industrialio-buffer-dma.c
@@ -786,6 +786,12 @@ int iio_dma_buffer_enqueue_dmabuf(struct iio_buffer *buffer,
 }
 EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_enqueue_dmabuf, "IIO_DMA_BUFFER");
 
+struct device *iio_dma_buffer_get_dma_dev(struct iio_buffer *buffer)
+{
+	return iio_buffer_to_queue(buffer)->dev;
+}
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_get_dma_dev, "IIO_DMA_BUFFER");
+
 void iio_dma_buffer_lock_queue(struct iio_buffer *buffer)
 {
 	struct iio_dma_buffer_queue *queue = iio_buffer_to_queue(buffer);
diff --git a/include/linux/iio/buffer-dma.h b/include/linux/iio/buffer-dma.h
index 5eb66a3990021afb1821297e540656a65916daa7..4f33e6a39797d3ecfddc69c11d6d3985b9212920 100644
--- a/include/linux/iio/buffer-dma.h
+++ b/include/linux/iio/buffer-dma.h
@@ -174,5 +174,6 @@ int iio_dma_buffer_enqueue_dmabuf(struct iio_buffer *buffer,
 				  size_t size, bool cyclic);
 void iio_dma_buffer_lock_queue(struct iio_buffer *buffer);
 void iio_dma_buffer_unlock_queue(struct iio_buffer *buffer);
+struct device *iio_dma_buffer_get_dma_dev(struct iio_buffer *buffer);
 
 #endif

-- 
2.51.0

