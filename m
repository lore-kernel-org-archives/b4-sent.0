From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 12 Apr 2024 15:36:11 +0200
Subject: [PATCH v3 04/10] iio: buffer-dmaengine: Support specifying buffer
 direction
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240412-iio-backend-axi-dac-v3-4-3e9d4c5201fb@analog.com>
References: <20240412-iio-backend-axi-dac-v3-0-3e9d4c5201fb@analog.com>
In-Reply-To: <20240412-iio-backend-axi-dac-v3-0-3e9d4c5201fb@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Dragos Bogdan <dragos.bogdan@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Paul Cercueil <paul@crapouillou.net>, 
 Alexandru Ardelean <ardeleanalex@gmail.com>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712928968; l=5579;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=u23I6KLSCcrBhm4fnCuOy4udHamrKg4Ga64h2+KE9cI=;
 b=o4ov9FQs7q4blM0s0tSG0ebtZnLZq7Tcphk+YhIKrGDMwKIJrorVL4jzsC4/a2J/anbbA8//o
 fdJ8JqEFyCVCJUeC+IadVKM4B5L6NVhtVS/FfTnBmwJ3BdGHfo7rYlh
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Paul Cercueil <paul@crapouillou.net>

Update the devm_iio_dmaengine_buffer_setup() function to support
specifying the buffer direction.

Update the iio_dmaengine_buffer_submit() function to handle input
buffers as well as output buffers.

Signed-off-by: Paul Cercueil <paul@crapouillou.net>
Reviewed-by: Alexandru Ardelean <ardeleanalex@gmail.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-dmaengine.c | 41 +++++++++++++++-------
 include/linux/iio/buffer-dmaengine.h               | 25 +++++++++----
 2 files changed, 47 insertions(+), 19 deletions(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dmaengine.c b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
index df05d66afff9..051e1758e020 100644
--- a/drivers/iio/buffer/industrialio-buffer-dmaengine.c
+++ b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
@@ -64,14 +64,25 @@ static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
 	struct dmaengine_buffer *dmaengine_buffer =
 		iio_buffer_to_dmaengine_buffer(&queue->buffer);
 	struct dma_async_tx_descriptor *desc;
+	enum dma_transfer_direction dma_dir;
+	size_t max_size;
 	dma_cookie_t cookie;
 
-	block->bytes_used = min(block->size, dmaengine_buffer->max_size);
-	block->bytes_used = round_down(block->bytes_used,
-			dmaengine_buffer->align);
+	max_size = min(block->size, dmaengine_buffer->max_size);
+	max_size = round_down(max_size, dmaengine_buffer->align);
+
+	if (queue->buffer.direction == IIO_BUFFER_DIRECTION_IN) {
+		block->bytes_used = max_size;
+		dma_dir = DMA_DEV_TO_MEM;
+	} else {
+		dma_dir = DMA_MEM_TO_DEV;
+	}
+
+	if (!block->bytes_used || block->bytes_used > max_size)
+		return -EINVAL;
 
 	desc = dmaengine_prep_slave_single(dmaengine_buffer->chan,
-		block->phys_addr, block->bytes_used, DMA_DEV_TO_MEM,
+		block->phys_addr, block->bytes_used, dma_dir,
 		DMA_PREP_INTERRUPT);
 	if (!desc)
 		return -ENOMEM;
@@ -229,9 +240,10 @@ void iio_dmaengine_buffer_free(struct iio_buffer *buffer)
 }
 EXPORT_SYMBOL_NS_GPL(iio_dmaengine_buffer_free, IIO_DMAENGINE_BUFFER);
 
-struct iio_buffer *iio_dmaengine_buffer_setup(struct device *dev,
-					      struct iio_dev *indio_dev,
-					      const char *channel)
+struct iio_buffer *iio_dmaengine_buffer_setup_ext(struct device *dev,
+						  struct iio_dev *indio_dev,
+						  const char *channel,
+						  enum iio_buffer_direction dir)
 {
 	struct iio_buffer *buffer;
 	int ret;
@@ -242,6 +254,8 @@ struct iio_buffer *iio_dmaengine_buffer_setup(struct device *dev,
 
 	indio_dev->modes |= INDIO_BUFFER_HARDWARE;
 
+	buffer->direction = dir;
+
 	ret = iio_device_attach_buffer(indio_dev, buffer);
 	if (ret) {
 		iio_dmaengine_buffer_free(buffer);
@@ -250,7 +264,7 @@ struct iio_buffer *iio_dmaengine_buffer_setup(struct device *dev,
 
 	return buffer;
 }
-EXPORT_SYMBOL_NS_GPL(iio_dmaengine_buffer_setup, IIO_DMAENGINE_BUFFER);
+EXPORT_SYMBOL_NS_GPL(iio_dmaengine_buffer_setup_ext, IIO_DMAENGINE_BUFFER);
 
 static void __devm_iio_dmaengine_buffer_free(void *buffer)
 {
@@ -268,20 +282,21 @@ static void __devm_iio_dmaengine_buffer_free(void *buffer)
  * It also appends the INDIO_BUFFER_HARDWARE mode to the supported modes of the
  * IIO device.
  */
-int devm_iio_dmaengine_buffer_setup(struct device *dev,
-				    struct iio_dev *indio_dev,
-				    const char *channel)
+int devm_iio_dmaengine_buffer_setup_ext(struct device *dev,
+					struct iio_dev *indio_dev,
+					const char *channel,
+					enum iio_buffer_direction dir)
 {
 	struct iio_buffer *buffer;
 
-	buffer = iio_dmaengine_buffer_setup(dev, indio_dev, channel);
+	buffer = iio_dmaengine_buffer_setup_ext(dev, indio_dev, channel, dir);
 	if (IS_ERR(buffer))
 		return PTR_ERR(buffer);
 
 	return devm_add_action_or_reset(dev, __devm_iio_dmaengine_buffer_free,
 					buffer);
 }
-EXPORT_SYMBOL_NS_GPL(devm_iio_dmaengine_buffer_setup, IIO_DMAENGINE_BUFFER);
+EXPORT_SYMBOL_NS_GPL(devm_iio_dmaengine_buffer_setup_ext, IIO_DMAENGINE_BUFFER);
 
 MODULE_AUTHOR("Lars-Peter Clausen <lars@metafoo.de>");
 MODULE_DESCRIPTION("DMA buffer for the IIO framework");
diff --git a/include/linux/iio/buffer-dmaengine.h b/include/linux/iio/buffer-dmaengine.h
index acb60f9a3fff..81d9a19aeb91 100644
--- a/include/linux/iio/buffer-dmaengine.h
+++ b/include/linux/iio/buffer-dmaengine.h
@@ -7,15 +7,28 @@
 #ifndef __IIO_DMAENGINE_H__
 #define __IIO_DMAENGINE_H__
 
+#include <linux/iio/buffer.h>
+
 struct iio_dev;
 struct device;
 
 void iio_dmaengine_buffer_free(struct iio_buffer *buffer);
-struct iio_buffer *iio_dmaengine_buffer_setup(struct device *dev,
-					      struct iio_dev *indio_dev,
-					      const char *channel);
-int devm_iio_dmaengine_buffer_setup(struct device *dev,
-				    struct iio_dev *indio_dev,
-				    const char *channel);
+struct iio_buffer *iio_dmaengine_buffer_setup_ext(struct device *dev,
+						  struct iio_dev *indio_dev,
+						  const char *channel,
+						  enum iio_buffer_direction dir);
+
+#define iio_dmaengine_buffer_setup(dev, indio_dev, channel)	\
+	iio_dmaengine_buffer_setup_ext(dev, indio_dev, channel,	\
+				       IIO_BUFFER_DIRECTION_IN)
+
+int devm_iio_dmaengine_buffer_setup_ext(struct device *dev,
+					struct iio_dev *indio_dev,
+					const char *channel,
+					enum iio_buffer_direction dir);
+
+#define devm_iio_dmaengine_buffer_setup(dev, indio_dev, channel)	\
+	devm_iio_dmaengine_buffer_setup_ext(dev, indio_dev, channel,	\
+					    IIO_BUFFER_DIRECTION_IN)
 
 #endif

-- 
2.44.0

