From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 27 Nov 2026 09:47:48 +0000
Subject: [PATCH v2 5/5] iio: buffer: add struct iio_buffer_attr
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-iio-core-attr-review-v2-5-e0aed1e8a81c@analog.com>
References: <20261127-iio-core-attr-review-v2-0-e0aed1e8a81c@analog.com>
In-Reply-To: <20261127-iio-core-attr-review-v2-0-e0aed1e8a81c@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795772875; l=9239;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=AjefUpsQT2H2WqYhIME2iAOH/52Q2zSYZTt5ZE8OoKs=;
 b=QcR3EFN05p3M4mUwwtEWLUxtnqyvqVr7NhREt0RrcpoMjO2TPU5flGuZmN3BCjEvM3fgeRcMd
 8BFG2VteZM/Am+1R7AAasuRLlqsL0B8k1OuiUjwLsW4vO7kE+K61g5D
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Buffer attributes find their buffer through the buffer field of
struct iio_dev_attr, which is unused by every other attribute.

Add struct iio_buffer_attr, extending struct iio_chan_attr with the
buffer the attribute belongs to, and use it both for the scan element
attributes and for the buffer attributes wrapped by the buffer core.
iio_attr_to_buffer() now resolves the buffer through it.

The buffer pointer was the last core-only field of struct iio_dev_attr,
so remove it. On 64-bit, without lockdep, struct iio_dev_attr is now 40
bytes instead of 72, which every attribute declared through
IIO_DEVICE_ATTR*() and friends benefits from.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-buffer.c | 57 +++++++++++++++++++++++++--------------
 include/linux/iio/sysfs.h         |  4 ---
 2 files changed, 37 insertions(+), 24 deletions(-)

diff --git a/drivers/iio/industrialio-buffer.c b/drivers/iio/industrialio-buffer.c
index 52025d60052b..16629344410e 100644
--- a/drivers/iio/industrialio-buffer.c
+++ b/drivers/iio/industrialio-buffer.c
@@ -69,6 +69,22 @@ static const char * const iio_endian_prefix[] = {
 	[IIO_LE] = "le",
 };
 
+/**
+ * struct iio_buffer_attr - IIO buffer attribute
+ * @chan_attr:	underlying IIO channel attribute (channel is NULL for buffer
+ *		wide attributes)
+ * @buffer:	the IIO buffer to which this attribute belongs to
+ */
+struct iio_buffer_attr {
+	struct iio_chan_attr chan_attr;
+	struct iio_buffer *buffer;
+};
+
+static_assert(offsetof(struct iio_buffer_attr, chan_attr) == 0);
+
+#define to_iio_buffer_attr(_dev_attr)					\
+	container_of(to_iio_chan_attr(_dev_attr), struct iio_buffer_attr, chan_attr)
+
 /**
  * iio_attr_to_buffer() - Get the IIO buffer a buffer attribute belongs to
  * @attr: Device attribute of the buffer, as passed to its show/store callbacks
@@ -80,7 +96,7 @@ static const char * const iio_endian_prefix[] = {
  */
 struct iio_buffer *iio_attr_to_buffer(struct device_attribute *attr)
 {
-	return to_iio_dev_attr(attr)->buffer;
+	return to_iio_buffer_attr(attr)->buffer;
 }
 EXPORT_SYMBOL_GPL(iio_attr_to_buffer);
 
@@ -459,7 +475,7 @@ static ssize_t iio_scan_el_show(struct device *dev,
 				char *buf)
 {
 	int ret;
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 
 	/* Ensure ret is 0 or 1. */
 	ret = !!test_bit(to_iio_dev_attr(attr)->address,
@@ -591,7 +607,7 @@ static ssize_t iio_scan_el_store(struct device *dev,
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
-	struct iio_buffer *buffer = this_attr->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 
 	ret = kstrtobool(buf, &state);
 	if (ret < 0)
@@ -622,7 +638,7 @@ static ssize_t iio_scan_el_ts_show(struct device *dev,
 				   struct device_attribute *attr,
 				   char *buf)
 {
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 
 	return sysfs_emit(buf, "%d\n", buffer->scan_timestamp);
 }
@@ -635,7 +651,7 @@ static ssize_t iio_scan_el_ts_store(struct device *dev,
 	int ret;
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 	bool state;
 
 	ret = kstrtobool(buf, &state);
@@ -659,7 +675,7 @@ static int iio_buffer_add_chan_devattr(struct iio_dev *indio_dev,
 				       iio_attr_store_t writefunc,
 				       u64 mask)
 {
-	struct iio_chan_attr *buf_attr;
+	struct iio_buffer_attr *buf_attr;
 	struct iio_chan_attr_ctx ctx;
 	int ret;
 
@@ -672,8 +688,9 @@ static int iio_buffer_add_chan_devattr(struct iio_dev *indio_dev,
 	if (!buf_attr)
 		return -ENOMEM;
 
-	buf_attr->iio_attr.buffer = buffer;
-	ret = iio_chan_attr_add(&ctx, buf_attr, readfunc, writefunc, mask);
+	buf_attr->buffer = buffer;
+	ret = iio_chan_attr_add(&ctx, &buf_attr->chan_attr, readfunc, writefunc,
+				mask);
 	if (ret)
 		kfree(buf_attr);
 
@@ -716,7 +733,7 @@ static int iio_buffer_add_channel_sysfs(struct iio_dev *indio_dev,
 static ssize_t length_show(struct device *dev, struct device_attribute *attr,
 			   char *buf)
 {
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 
 	return sysfs_emit(buf, "%d\n", buffer->length);
 }
@@ -726,7 +743,7 @@ static ssize_t length_store(struct device *dev, struct device_attribute *attr,
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 	unsigned int val;
 	int ret;
 
@@ -752,7 +769,7 @@ static ssize_t length_store(struct device *dev, struct device_attribute *attr,
 static ssize_t enable_show(struct device *dev, struct device_attribute *attr,
 			   char *buf)
 {
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 
 	return sysfs_emit(buf, "%d\n", iio_buffer_is_active(buffer));
 }
@@ -1412,7 +1429,7 @@ static ssize_t enable_store(struct device *dev, struct device_attribute *attr,
 	bool requested_state;
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 	bool inlist;
 
 	ret = kstrtobool(buf, &requested_state);
@@ -1440,7 +1457,7 @@ static ssize_t enable_store(struct device *dev, struct device_attribute *attr,
 static ssize_t watermark_show(struct device *dev, struct device_attribute *attr,
 			      char *buf)
 {
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 
 	return sysfs_emit(buf, "%u\n", buffer->watermark);
 }
@@ -1451,7 +1468,7 @@ static ssize_t watermark_store(struct device *dev,
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 	unsigned int val;
 	int ret;
 
@@ -1477,7 +1494,7 @@ static ssize_t watermark_store(struct device *dev,
 static ssize_t data_available_show(struct device *dev,
 				   struct device_attribute *attr, char *buf)
 {
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 
 	return sysfs_emit(buf, "%zu\n", iio_buffer_data_available(buffer));
 }
@@ -1486,7 +1503,7 @@ static ssize_t direction_show(struct device *dev,
 			      struct device_attribute *attr,
 			      char *buf)
 {
-	struct iio_buffer *buffer = to_iio_dev_attr(attr)->buffer;
+	struct iio_buffer *buffer = to_iio_buffer_attr(attr)->buffer;
 
 	switch (buffer->direction) {
 	case IIO_BUFFER_DIRECTION_IN:
@@ -1525,15 +1542,15 @@ static struct attribute *iio_buffer_attrs[] = {
 static struct attribute *iio_buffer_wrap_attr(struct iio_buffer *buffer,
 					      struct attribute *attr)
 {
-	struct iio_chan_attr *buf_attr __free(kfree) = kzalloc_obj(*buf_attr);
+	struct iio_buffer_attr *buf_attr __free(kfree) = kzalloc_obj(*buf_attr);
 	struct device_attribute *dattr = to_dev_attr(attr);
 	struct iio_dev_attr *iio_attr;
 
 	if (!buf_attr)
 		return NULL;
 
-	iio_attr = &buf_attr->iio_attr;
-	iio_attr->buffer = buffer;
+	buf_attr->buffer = buffer;
+	iio_attr = &buf_attr->chan_attr.iio_attr;
 	memcpy(&iio_attr->dev_attr, dattr, sizeof(iio_attr->dev_attr));
 	iio_attr->dev_attr.attr.name = kstrdup_const(attr->name, GFP_KERNEL);
 	if (!iio_attr->dev_attr.attr.name)
@@ -1541,7 +1558,7 @@ static struct attribute *iio_buffer_wrap_attr(struct iio_buffer *buffer,
 
 	sysfs_attr_init(&iio_attr->dev_attr.attr);
 
-	list_add(&no_free_ptr(buf_attr)->l, &buffer->buffer_attr_list);
+	list_add(&no_free_ptr(buf_attr)->chan_attr.l, &buffer->buffer_attr_list);
 
 	return &iio_attr->dev_attr.attr;
 }
diff --git a/include/linux/iio/sysfs.h b/include/linux/iio/sysfs.h
index 26c88767afe6..1e4122b8c13a 100644
--- a/include/linux/iio/sysfs.h
+++ b/include/linux/iio/sysfs.h
@@ -9,18 +9,14 @@
 #ifndef _INDUSTRIAL_IO_SYSFS_H_
 #define _INDUSTRIAL_IO_SYSFS_H_
 
-struct iio_buffer;
-
 /**
  * struct iio_dev_attr - iio specific device attribute
  * @dev_attr:	underlying device attribute
  * @address:	associated register address
- * @buffer:	the IIO buffer to which this attribute belongs to (if any)
  */
 struct iio_dev_attr {
 	struct device_attribute dev_attr;
 	u64 address;
-	struct iio_buffer *buffer;
 };
 
 #define to_iio_dev_attr(_dev_attr)				\

-- 
2.43.0

