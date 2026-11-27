From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 27 Nov 2026 09:47:45 +0000
Subject: [PATCH v2 2/5] iio: buffer: add iio_attr_to_buffer() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-iio-core-attr-review-v2-2-e0aed1e8a81c@analog.com>
References: <20261127-iio-core-attr-review-v2-0-e0aed1e8a81c@analog.com>
In-Reply-To: <20261127-iio-core-attr-review-v2-0-e0aed1e8a81c@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795772875; l=3151;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=z0/ZhH1JujFCeJIP+q1ZFyWSGE6ClMob85zW1bLHCIE=;
 b=X3Kdpmm5PWlbvnczml4Fu50JOjG2krSo/JGxluHrFfmaGvtyoRkkFoUGz9M3aFuEUMY4qxslo
 TxUhnWPnbQcAs/BibMdXRwL9Tu5kXysKXV37CsXZMkbc47WcdBRaD2f
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Buffer implementations providing their own attributes through
struct iio_buffer::attrs need to find the buffer an attribute belongs
to. The DMAengine buffer does that with to_iio_dev_attr(attr)->buffer,
which depends on the IIO buffer core wrapping those attributes into its
own copies and on the layout of struct iio_dev_attr.

Add iio_attr_to_buffer(), so buffer implementations no longer depend on
how the IIO core keeps track of the buffer, and use it in the DMAengine
buffer.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |  2 +-
 drivers/iio/industrialio-buffer.c                  | 15 +++++++++++++++
 include/linux/iio/buffer_impl.h                    |  3 +++
 3 files changed, 19 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dmaengine.c b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
index 7ecb9d875b8e..2e04cd5e3411 100644
--- a/drivers/iio/buffer/industrialio-buffer-dmaengine.c
+++ b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
@@ -226,7 +226,7 @@ static const struct iio_dma_buffer_ops iio_dmaengine_default_ops = {
 static ssize_t iio_dmaengine_buffer_get_length_align(struct device *dev,
 						     struct device_attribute *attr, char *buf)
 {
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = iio_attr_to_buffer(attr);
 	struct dmaengine_buffer *dmaengine_buffer =
 		iio_buffer_to_dmaengine_buffer(buffer);
 
diff --git a/drivers/iio/industrialio-buffer.c b/drivers/iio/industrialio-buffer.c
index 4294101810fd..2d7759325eb3 100644
--- a/drivers/iio/industrialio-buffer.c
+++ b/drivers/iio/industrialio-buffer.c
@@ -69,6 +69,21 @@ static const char * const iio_endian_prefix[] = {
 	[IIO_LE] = "le",
 };
 
+/**
+ * iio_attr_to_buffer() - Get the IIO buffer a buffer attribute belongs to
+ * @attr: Device attribute of the buffer, as passed to its show/store callbacks
+ *
+ * Only valid for attributes registered through &struct iio_buffer.attrs or
+ * created by the IIO buffer core.
+ *
+ * Returns: Pointer to the IIO buffer.
+ */
+struct iio_buffer *iio_attr_to_buffer(struct device_attribute *attr)
+{
+	return to_iio_dev_attr(attr)->buffer;
+}
+EXPORT_SYMBOL_GPL(iio_attr_to_buffer);
+
 static bool iio_buffer_is_active(struct iio_buffer *buf)
 {
 	return !list_empty(&buf->buffer_list);
diff --git a/include/linux/iio/buffer_impl.h b/include/linux/iio/buffer_impl.h
index 9442c165561a..c259dfdf46a2 100644
--- a/include/linux/iio/buffer_impl.h
+++ b/include/linux/iio/buffer_impl.h
@@ -9,6 +9,7 @@
 #include <uapi/linux/iio/buffer.h>
 #include <linux/iio/buffer.h>
 
+struct device_attribute;
 struct dma_buf_attachment;
 struct dma_fence;
 struct iio_dev;
@@ -197,6 +198,8 @@ void iio_buffer_put(struct iio_buffer *buffer);
 
 void iio_buffer_signal_dmabuf_done(struct dma_fence *fence, int ret);
 
+struct iio_buffer *iio_attr_to_buffer(struct device_attribute *attr);
+
 #else /* CONFIG_IIO_BUFFER */
 
 static inline void iio_buffer_get(struct iio_buffer *buffer) {}

-- 
2.43.0

