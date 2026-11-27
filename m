From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 27 Nov 2026 09:47:46 +0000
Subject: [PATCH v2 3/5] iio: core: add struct iio_chan_attr and split
 attribute creation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-iio-core-attr-review-v2-3-e0aed1e8a81c@analog.com>
References: <20261127-iio-core-attr-review-v2-0-e0aed1e8a81c@analog.com>
In-Reply-To: <20261127-iio-core-attr-review-v2-0-e0aed1e8a81c@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795772875; l=33588;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=PWHNLv1jo6fnRDMlEsTzo3vEXYo1c018tf/nx+ZXqZA=;
 b=46foB21DxHoKBj5aI9gnlSOGEXi1h/qzhfgt/xxp/uUJfAwmUkuH2EQUDqteB3+lMKAtiqVwN
 KoKLZkt14BLCwVwNoP/hY35pe1B+TyURowASXQyPe4+Qtj0Ah9ovH6H
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Channel, event and buffer attributes are all created through
__iio_add_chan_devattr(), which allocates a struct iio_dev_attr and its
name, and only then walks the attribute list looking for a duplicate.
For shared attributes (info_mask_shared_by_*, shared ext_info and shared
event info) every channel after the first one allocates the attribute
and its name just to find the duplicate and free both again. The
function also takes a buffer pointer that only buffer attributes use.

Introduce struct iio_chan_attr for the attributes created by the IIO
core. It embeds struct iio_dev_attr and adds the channel spec and the
list node, so that the core-only state no longer needs to live in the
structure drivers use for their own attributes. Other attribute types
can extend it further.

Replace __iio_add_chan_devattr() with two steps:

 - iio_chan_attr_prepare() builds the full attribute name on the stack
   and checks it against the attribute list.
 - iio_chan_attr_add() initializes an attribute allocated by the caller
   and adds it to the list.

The caller allocates its own attribute type in between, so the core
needs no size or context pointer, and duplicates are detected before
anything is allocated.

Also add iio_attr_show_t and iio_attr_store_t, so the show and store
callback prototypes are not spelled out in every helper.

Event and buffer attributes are converted to struct iio_chan_attr, but
otherwise keep their current behavior.

The list node and channel spec of struct iio_dev_attr are no longer used,
so remove them. Attributes declared by drivers through IIO_DEVICE_ATTR*()
and friends no longer carry them.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/iio_core.h            |  58 ++++++--
 drivers/iio/industrialio-buffer.c |  96 ++++++-------
 drivers/iio/industrialio-core.c   | 275 ++++++++++++++++++++------------------
 drivers/iio/industrialio-event.c  |  72 +++++++---
 include/linux/iio/sysfs.h         |   5 -
 5 files changed, 287 insertions(+), 219 deletions(-)

diff --git a/drivers/iio/iio_core.h b/drivers/iio/iio_core.h
index 59fa1bd9924b..6a391a604bf9 100644
--- a/drivers/iio/iio_core.h
+++ b/drivers/iio/iio_core.h
@@ -11,6 +11,9 @@
 #define _IIO_CORE_H_
 #include <linux/kernel.h>
 #include <linux/device.h>
+#include <linux/limits.h>
+#include <linux/list.h>
+#include <linux/iio/sysfs.h>
 
 struct iio_buffer;
 struct iio_chan_spec;
@@ -38,20 +41,47 @@ ssize_t do_iio_read_channel_label(struct iio_dev *indio_dev,
 				  const struct iio_chan_spec *c,
 				  char *buf);
 
-int __iio_add_chan_devattr(const char *postfix,
-			   struct iio_chan_spec const *chan,
-			   ssize_t (*func)(struct device *dev,
-					   struct device_attribute *attr,
-					   char *buf),
-			   ssize_t (*writefunc)(struct device *dev,
-						struct device_attribute *attr,
-						const char *buf,
-						size_t len),
-			   u64 mask,
-			   enum iio_shared_by shared_by,
-			   struct device *dev,
-			   struct iio_buffer *buffer,
-			   struct list_head *attr_list);
+typedef typeof_member(struct device_attribute, show) iio_attr_show_t;
+typedef typeof_member(struct device_attribute, store) iio_attr_store_t;
+
+/**
+ * struct iio_chan_attr - IIO core managed channel attribute
+ * @iio_attr:	underlying IIO device attribute
+ * @c:		specification for the underlying channel (if any)
+ * @l:		list head for maintaining list of dynamically created attrs
+ *
+ * Other IIO core attribute types extend this one and must embed it as their
+ * first member, since attribute lists are freed through this type.
+ */
+struct iio_chan_attr {
+	struct iio_dev_attr iio_attr;
+	const struct iio_chan_spec *c;
+	struct list_head l;
+};
+
+#define to_iio_chan_attr(_dev_attr)					\
+	container_of(to_iio_dev_attr(_dev_attr), struct iio_chan_attr, iio_attr)
+
+/**
+ * struct iio_chan_attr_ctx - context for creating an IIO channel attribute
+ * @chan:	specification for the underlying channel
+ * @attr_list:	list the attribute is added to
+ * @name:	full attribute name
+ */
+struct iio_chan_attr_ctx {
+	const struct iio_chan_spec *chan;
+	struct list_head *attr_list;
+	char name[NAME_MAX + 1];
+};
+
+int iio_chan_attr_prepare(struct iio_chan_attr_ctx *ctx, struct device *dev,
+			  const struct iio_chan_spec *chan,
+			  enum iio_shared_by shared_by, const char *postfix,
+			  struct list_head *attr_list);
+int iio_chan_attr_add(const struct iio_chan_attr_ctx *ctx,
+		      struct iio_chan_attr *attr,
+		      iio_attr_show_t readfunc, iio_attr_store_t writefunc,
+		      u64 mask);
 void iio_free_chan_devattr_list(struct list_head *attr_list);
 
 int iio_device_register_sysfs_group(struct iio_dev *indio_dev,
diff --git a/drivers/iio/industrialio-buffer.c b/drivers/iio/industrialio-buffer.c
index 2d7759325eb3..52025d60052b 100644
--- a/drivers/iio/industrialio-buffer.c
+++ b/drivers/iio/industrialio-buffer.c
@@ -412,7 +412,7 @@ static ssize_t iio_show_scan_index(struct device *dev,
 				   struct device_attribute *attr,
 				   char *buf)
 {
-	return sysfs_emit(buf, "%u\n", to_iio_dev_attr(attr)->c->scan_index);
+	return sysfs_emit(buf, "%u\n", to_iio_chan_attr(attr)->c->scan_index);
 }
 
 static ssize_t iio_show_fixed_type(struct device *dev,
@@ -420,7 +420,7 @@ static ssize_t iio_show_fixed_type(struct device *dev,
 				   char *buf)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	const struct iio_scan_type *scan_type;
 	u8 type;
 
@@ -651,56 +651,61 @@ static ssize_t iio_scan_el_ts_store(struct device *dev,
 	return len;
 }
 
+static int iio_buffer_add_chan_devattr(struct iio_dev *indio_dev,
+				       struct iio_buffer *buffer,
+				       const char *postfix,
+				       const struct iio_chan_spec *chan,
+				       iio_attr_show_t readfunc,
+				       iio_attr_store_t writefunc,
+				       u64 mask)
+{
+	struct iio_chan_attr *buf_attr;
+	struct iio_chan_attr_ctx ctx;
+	int ret;
+
+	ret = iio_chan_attr_prepare(&ctx, &indio_dev->dev, chan, IIO_SEPARATE,
+				    postfix, &buffer->buffer_attr_list);
+	if (ret)
+		return ret;
+
+	buf_attr = kzalloc_obj(*buf_attr);
+	if (!buf_attr)
+		return -ENOMEM;
+
+	buf_attr->iio_attr.buffer = buffer;
+	ret = iio_chan_attr_add(&ctx, buf_attr, readfunc, writefunc, mask);
+	if (ret)
+		kfree(buf_attr);
+
+	return ret;
+}
+
 static int iio_buffer_add_channel_sysfs(struct iio_dev *indio_dev,
 					struct iio_buffer *buffer,
 					const struct iio_chan_spec *chan)
 {
 	int ret, attrcount = 0;
 
-	ret = __iio_add_chan_devattr("index",
-				     chan,
-				     &iio_show_scan_index,
-				     NULL,
-				     0,
-				     IIO_SEPARATE,
-				     &indio_dev->dev,
-				     buffer,
-				     &buffer->buffer_attr_list);
+	ret = iio_buffer_add_chan_devattr(indio_dev, buffer, "index", chan,
+					  &iio_show_scan_index, NULL, 0);
 	if (ret)
 		return ret;
 	attrcount++;
-	ret = __iio_add_chan_devattr("type",
-				     chan,
-				     &iio_show_fixed_type,
-				     NULL,
-				     0,
-				     IIO_SEPARATE,
-				     &indio_dev->dev,
-				     buffer,
-				     &buffer->buffer_attr_list);
+	ret = iio_buffer_add_chan_devattr(indio_dev, buffer, "type", chan,
+					  &iio_show_fixed_type, NULL, 0);
 	if (ret)
 		return ret;
 	attrcount++;
 	if (chan->type != IIO_TIMESTAMP)
-		ret = __iio_add_chan_devattr("en",
-					     chan,
-					     &iio_scan_el_show,
-					     &iio_scan_el_store,
-					     chan->scan_index,
-					     IIO_SEPARATE,
-					     &indio_dev->dev,
-					     buffer,
-					     &buffer->buffer_attr_list);
+		ret = iio_buffer_add_chan_devattr(indio_dev, buffer, "en", chan,
+						  &iio_scan_el_show,
+						  &iio_scan_el_store,
+						  chan->scan_index);
 	else
-		ret = __iio_add_chan_devattr("en",
-					     chan,
-					     &iio_scan_el_ts_show,
-					     &iio_scan_el_ts_store,
-					     chan->scan_index,
-					     IIO_SEPARATE,
-					     &indio_dev->dev,
-					     buffer,
-					     &buffer->buffer_attr_list);
+		ret = iio_buffer_add_chan_devattr(indio_dev, buffer, "en", chan,
+						  &iio_scan_el_ts_show,
+						  &iio_scan_el_ts_store,
+						  chan->scan_index);
 	if (ret)
 		return ret;
 	attrcount++;
@@ -1520,24 +1525,23 @@ static struct attribute *iio_buffer_attrs[] = {
 static struct attribute *iio_buffer_wrap_attr(struct iio_buffer *buffer,
 					      struct attribute *attr)
 {
+	struct iio_chan_attr *buf_attr __free(kfree) = kzalloc_obj(*buf_attr);
 	struct device_attribute *dattr = to_dev_attr(attr);
 	struct iio_dev_attr *iio_attr;
 
-	iio_attr = kzalloc_obj(*iio_attr);
-	if (!iio_attr)
+	if (!buf_attr)
 		return NULL;
 
+	iio_attr = &buf_attr->iio_attr;
 	iio_attr->buffer = buffer;
 	memcpy(&iio_attr->dev_attr, dattr, sizeof(iio_attr->dev_attr));
 	iio_attr->dev_attr.attr.name = kstrdup_const(attr->name, GFP_KERNEL);
-	if (!iio_attr->dev_attr.attr.name) {
-		kfree(iio_attr);
+	if (!iio_attr->dev_attr.attr.name)
 		return NULL;
-	}
 
 	sysfs_attr_init(&iio_attr->dev_attr.attr);
 
-	list_add(&iio_attr->l, &buffer->buffer_attr_list);
+	list_add(&no_free_ptr(buf_attr)->l, &buffer->buffer_attr_list);
 
 	return &iio_attr->dev_attr.attr;
 }
@@ -2151,7 +2155,7 @@ static int __iio_buffer_alloc_sysfs_and_mask(struct iio_buffer *buffer,
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	unsigned int masklength = iio_get_masklength(indio_dev);
-	struct iio_dev_attr *p;
+	struct iio_chan_attr *p;
 	const struct iio_dev_attr *id_attr;
 	struct attribute **attr;
 	int ret, i, attrn, scan_el_attrcount, buffer_attrcount;
@@ -2258,7 +2262,7 @@ static int __iio_buffer_alloc_sysfs_and_mask(struct iio_buffer *buffer,
 
 	attrn = 0;
 	list_for_each_entry(p, &buffer->buffer_attr_list, l)
-		attr[attrn++] = &p->dev_attr.attr;
+		attr[attrn++] = &p->iio_attr.dev_attr.attr;
 
 	buffer->buffer_group.name = kasprintf(GFP_KERNEL, "buffer%d", index);
 	if (!buffer->buffer_group.name) {
diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index 5267a9c5908c..0bef03cb9fd4 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -594,10 +594,10 @@ static ssize_t iio_read_channel_ext_info(struct device *dev,
 				     char *buf)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	const struct iio_chan_spec_ext_info *ext_info;
 
-	ext_info = &this_attr->c->ext_info[this_attr->address];
+	ext_info = &this_attr->c->ext_info[this_attr->iio_attr.address];
 
 	return ext_info->read(indio_dev, ext_info->private, this_attr->c, buf);
 }
@@ -607,10 +607,10 @@ static ssize_t iio_write_channel_ext_info(struct device *dev,
 				     const char *buf, size_t len)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	const struct iio_chan_spec_ext_info *ext_info;
 
-	ext_info = &this_attr->c->ext_info[this_attr->address];
+	ext_info = &this_attr->c->ext_info[this_attr->iio_attr.address];
 
 	return ext_info->write(indio_dev, ext_info->private,
 			       this_attr->c, buf, len);
@@ -889,14 +889,14 @@ static ssize_t iio_read_channel_label(struct device *dev,
 				      char *buf)
 {
 	return do_iio_read_channel_label(dev_to_iio_dev(dev),
-					 to_iio_dev_attr(attr)->c, buf);
+					 to_iio_chan_attr(attr)->c, buf);
 }
 
 static ssize_t iio_read_channel_parent(struct device *dev,
 				       struct device_attribute *attr,
 				       char *buf)
 {
-	const struct iio_chan_spec *chan = to_iio_dev_attr(attr)->c->parent;
+	const struct iio_chan_spec *chan = to_iio_chan_attr(attr)->c->parent;
 	ssize_t len;
 
 	len = __iio_chan_prefix_emit(dev, chan, IIO_SEPARATE, buf, PAGE_SIZE - 1);
@@ -911,7 +911,7 @@ static ssize_t iio_read_channel_info(struct device *dev,
 				     char *buf)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	int vals[INDIO_MAX_RAW_ELEMENTS];
 	int ret;
 	int val_len = 2;
@@ -920,10 +920,10 @@ static ssize_t iio_read_channel_info(struct device *dev,
 		ret = indio_dev->info->read_raw_multi(indio_dev, this_attr->c,
 							INDIO_MAX_RAW_ELEMENTS,
 							vals, &val_len,
-							this_attr->address);
+							this_attr->iio_attr.address);
 	else if (indio_dev->info->read_raw)
 		ret = indio_dev->info->read_raw(indio_dev, this_attr->c,
-				    &vals[0], &vals[1], this_attr->address);
+				    &vals[0], &vals[1], this_attr->iio_attr.address);
 	else
 		return -EINVAL;
 
@@ -1002,7 +1002,7 @@ static ssize_t iio_read_channel_info_avail(struct device *dev,
 					   char *buf)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	const int *vals;
 	int ret;
 	int length;
@@ -1013,7 +1013,7 @@ static ssize_t iio_read_channel_info_avail(struct device *dev,
 
 	ret = indio_dev->info->read_avail(indio_dev, this_attr->c,
 					  &vals, &type, &length,
-					  this_attr->address);
+					  this_attr->iio_attr.address);
 
 	if (ret < 0)
 		return ret;
@@ -1122,7 +1122,7 @@ static ssize_t iio_write_channel_info(struct device *dev,
 				      size_t len)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	int ret, fract_mult = 100000;
 	int type, dec_scale = 0;
 	int integer, fract = 0;
@@ -1138,7 +1138,7 @@ static ssize_t iio_write_channel_info(struct device *dev,
 	if (indio_dev->info->write_raw_get_fmt) {
 		type = indio_dev->info->write_raw_get_fmt(indio_dev,
 							  this_attr->c,
-							  this_attr->address);
+							  this_attr->iio_attr.address);
 		switch (type) {
 		case IIO_VAL_INT:
 			fract_mult = 0;
@@ -1196,40 +1196,96 @@ static ssize_t iio_write_channel_info(struct device *dev,
 	}
 
 	ret = indio_dev->info->write_raw(indio_dev, this_attr->c,
-					 integer, fract, this_attr->address);
+					 integer, fract, this_attr->iio_attr.address);
 	if (ret)
 		return ret;
 
 	return len;
 }
 
-static
-int __iio_device_attr_init(struct device *dev,
-			   struct device_attribute *dev_attr,
-			   const char *postfix,
-			   struct iio_chan_spec const *chan,
-			   ssize_t (*readfunc)(struct device *dev,
-					       struct device_attribute *attr,
-					       char *buf),
-			   ssize_t (*writefunc)(struct device *dev,
-						struct device_attribute *attr,
-						const char *buf,
-						size_t len),
-			   enum iio_shared_by shared_by)
+static int iio_chan_attr_name_emit(struct device *dev,
+				   const struct iio_chan_spec *chan,
+				   enum iio_shared_by shared_by,
+				   const char *postfix,
+				   char *buf, size_t len)
 {
-	char prefix[NAME_MAX + 1];
+	struct seq_buf s;
 	ssize_t ret;
 
+	seq_buf_init(&s, buf, len);
+	ret = iio_chan_prefix_seq_buf(dev, chan, shared_by, &s);
+	if (ret < 0)
+		return ret;
+
+	seq_buf_printf(&s, ret ? "_%s" : "%s", postfix);
+
+	return seq_buf_has_overflowed(&s) ? -EOVERFLOW : 0;
+}
+
+/**
+ * iio_chan_attr_prepare() - Prepare the creation of an IIO channel attribute
+ * @ctx: Context to be filled in
+ * @dev: Device used for error reporting
+ * @chan: Specification for the underlying channel
+ * @shared_by: Sharing scope of the attribute
+ * @postfix: Attribute name postfix, appended to the channel prefix
+ * @attr_list: List the attribute is going to be added to
+ *
+ * Builds the full attribute name and makes sure it is not on @attr_list yet,
+ * so that the caller only allocates the attribute if it is going to be used.
+ *
+ * Returns: 0 on success, -EBUSY if the attribute already exists, or another
+ * negative error code on failure.
+ */
+int iio_chan_attr_prepare(struct iio_chan_attr_ctx *ctx, struct device *dev,
+			  const struct iio_chan_spec *chan,
+			  enum iio_shared_by shared_by, const char *postfix,
+			  struct list_head *attr_list)
+{
+	struct iio_chan_attr *t;
+	int ret;
+
+	ret = iio_chan_attr_name_emit(dev, chan, shared_by, postfix,
+				      ctx->name, sizeof(ctx->name));
+	if (ret)
+		return ret;
+
+	list_for_each_entry(t, attr_list, l)
+		if (strcmp(t->iio_attr.dev_attr.attr.name, ctx->name) == 0) {
+			if (shared_by == IIO_SEPARATE)
+				dev_err(dev, "tried to double register : %s\n",
+					ctx->name);
+			return -EBUSY;
+		}
+
+	ctx->chan = chan;
+	ctx->attr_list = attr_list;
+
+	return 0;
+}
+
+/**
+ * iio_chan_attr_add() - Initialize an IIO channel attribute and add it
+ * @ctx: Context filled in by iio_chan_attr_prepare()
+ * @attr: Zeroed attribute allocated by the caller
+ * @readfunc: Show callback, if any
+ * @writefunc: Store callback, if any
+ * @mask: Value for the attribute address
+ *
+ * On success, the attribute is owned by the list it was added to and gets
+ * freed by iio_free_chan_devattr_list(). On failure, the caller still owns it.
+ *
+ * Returns: 0 on success, negative error code on failure.
+ */
+int iio_chan_attr_add(const struct iio_chan_attr_ctx *ctx,
+		      struct iio_chan_attr *attr,
+		      iio_attr_show_t readfunc, iio_attr_store_t writefunc,
+		      u64 mask)
+{
+	struct device_attribute *dev_attr = &attr->iio_attr.dev_attr;
+
 	sysfs_attr_init(&dev_attr->attr);
-
-	ret = __iio_chan_prefix_emit(dev, chan, shared_by, prefix, sizeof(prefix));
-	if (ret < 0)
-		return ret;
-
-	if (ret)
-		dev_attr->attr.name = kasprintf(GFP_KERNEL, "%s_%s", prefix, postfix);
-	else
-		dev_attr->attr.name = kstrdup(postfix, GFP_KERNEL);
+	dev_attr->attr.name = kstrdup(ctx->name, GFP_KERNEL);
 	if (!dev_attr->attr.name)
 		return -ENOMEM;
 
@@ -1243,81 +1299,53 @@ int __iio_device_attr_init(struct device *dev,
 		dev_attr->store = writefunc;
 	}
 
+	attr->c = ctx->chan;
+	attr->iio_attr.address = mask;
+	list_add(&attr->l, ctx->attr_list);
+
 	return 0;
 }
 
-static void __iio_device_attr_deinit(struct device_attribute *dev_attr)
-{
-	kfree(dev_attr->attr.name);
-}
-
-int __iio_add_chan_devattr(const char *postfix,
-			   struct iio_chan_spec const *chan,
-			   ssize_t (*readfunc)(struct device *dev,
-					       struct device_attribute *attr,
-					       char *buf),
-			   ssize_t (*writefunc)(struct device *dev,
-						struct device_attribute *attr,
-						const char *buf,
-						size_t len),
-			   u64 mask,
-			   enum iio_shared_by shared_by,
-			   struct device *dev,
-			   struct iio_buffer *buffer,
-			   struct list_head *attr_list)
+static int iio_device_add_chan_devattr(struct iio_dev *indio_dev,
+				       const char *postfix,
+				       struct iio_chan_spec const *chan,
+				       iio_attr_show_t readfunc,
+				       iio_attr_store_t writefunc,
+				       u64 mask,
+				       enum iio_shared_by shared_by)
 {
+	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
+	struct iio_chan_attr *iio_attr;
+	struct iio_chan_attr_ctx ctx;
 	int ret;
-	struct iio_dev_attr *iio_attr, *t;
+
+	ret = iio_chan_attr_prepare(&ctx, &indio_dev->dev, chan, shared_by,
+				    postfix, &iio_dev_opaque->channel_attr_list);
+	if (ret)
+		return ret;
 
 	iio_attr = kzalloc_obj(*iio_attr);
-	if (iio_attr == NULL)
+	if (!iio_attr)
 		return -ENOMEM;
-	ret = __iio_device_attr_init(dev, &iio_attr->dev_attr,
-				     postfix, chan,
-				     readfunc, writefunc, shared_by);
+
+	ret = iio_chan_attr_add(&ctx, iio_attr, readfunc, writefunc, mask);
 	if (ret)
-		goto error_iio_dev_attr_free;
-	iio_attr->c = chan;
-	iio_attr->address = mask;
-	iio_attr->buffer = buffer;
-	list_for_each_entry(t, attr_list, l)
-		if (strcmp(t->dev_attr.attr.name,
-			   iio_attr->dev_attr.attr.name) == 0) {
-			if (shared_by == IIO_SEPARATE)
-				dev_err(dev, "tried to double register : %s\n",
-					t->dev_attr.attr.name);
-			ret = -EBUSY;
-			goto error_device_attr_deinit;
-		}
-	list_add(&iio_attr->l, attr_list);
+		kfree(iio_attr);
 
-	return 0;
-
-error_device_attr_deinit:
-	__iio_device_attr_deinit(&iio_attr->dev_attr);
-error_iio_dev_attr_free:
-	kfree(iio_attr);
 	return ret;
 }
 
 static int iio_device_add_channel_label(struct iio_dev *indio_dev,
 					 struct iio_chan_spec const *chan)
 {
-	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	int ret;
 
 	if (!indio_dev->info->read_label && !chan->extend_name)
 		return 0;
 
-	ret = __iio_add_chan_devattr("label",
-				     chan,
-				     &iio_read_channel_label,
-				     NULL,
-				     0,
-				     IIO_SEPARATE,
-				     &indio_dev->dev,
-				     NULL,
-				     &iio_dev_opaque->channel_attr_list);
+	ret = iio_device_add_chan_devattr(indio_dev, "label", chan,
+					  &iio_read_channel_label, NULL,
+					  0, IIO_SEPARATE);
 	if (ret < 0)
 		return ret;
 
@@ -1327,16 +1355,14 @@ static int iio_device_add_channel_label(struct iio_dev *indio_dev,
 static int iio_device_add_channel_parent_attr(struct iio_dev *indio_dev,
 					      struct iio_chan_spec const *chan)
 {
-	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	int ret;
 
 	if (!chan->parent)
 		return 0;
 
-	ret = __iio_add_chan_devattr("parent", chan,
-				     &iio_read_channel_parent, NULL,
-				     0, IIO_SEPARATE, &indio_dev->dev, NULL,
-				     &iio_dev_opaque->channel_attr_list);
+	ret = iio_device_add_chan_devattr(indio_dev, "parent", chan,
+					  &iio_read_channel_parent, NULL,
+					  0, IIO_SEPARATE);
 	if (ret < 0)
 		return ret;
 
@@ -1348,21 +1374,17 @@ static int iio_device_add_info_mask_type(struct iio_dev *indio_dev,
 					 enum iio_shared_by shared_by,
 					 const unsigned long *infomask)
 {
-	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	int i, ret, attrcount = 0;
 
 	for_each_set_bit(i, infomask, sizeof(*infomask)*8) {
 		if (i >= ARRAY_SIZE(iio_chan_info_postfix))
 			return -EINVAL;
-		ret = __iio_add_chan_devattr(iio_chan_info_postfix[i],
-					     chan,
-					     &iio_read_channel_info,
-					     &iio_write_channel_info,
-					     i,
-					     shared_by,
-					     &indio_dev->dev,
-					     NULL,
-					     &iio_dev_opaque->channel_attr_list);
+		ret = iio_device_add_chan_devattr(indio_dev,
+						  iio_chan_info_postfix[i],
+						  chan,
+						  &iio_read_channel_info,
+						  &iio_write_channel_info,
+						  i, shared_by);
 		if ((ret == -EBUSY) && (shared_by != IIO_SEPARATE))
 			continue;
 		if (ret < 0)
@@ -1378,7 +1400,6 @@ static int iio_device_add_info_mask_type_avail(struct iio_dev *indio_dev,
 					       enum iio_shared_by shared_by,
 					       const unsigned long *infomask)
 {
-	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	int i, ret, attrcount = 0;
 	char *avail_postfix;
 
@@ -1391,15 +1412,10 @@ static int iio_device_add_info_mask_type_avail(struct iio_dev *indio_dev,
 		if (!avail_postfix)
 			return -ENOMEM;
 
-		ret = __iio_add_chan_devattr(avail_postfix,
-					     chan,
-					     &iio_read_channel_info_avail,
-					     NULL,
-					     i,
-					     shared_by,
-					     &indio_dev->dev,
-					     NULL,
-					     &iio_dev_opaque->channel_attr_list);
+		ret = iio_device_add_chan_devattr(indio_dev, avail_postfix,
+						  chan,
+						  &iio_read_channel_info_avail,
+						  NULL, i, shared_by);
 		kfree(avail_postfix);
 		if ((ret == -EBUSY) && (shared_by != IIO_SEPARATE))
 			continue;
@@ -1414,7 +1430,6 @@ static int iio_device_add_info_mask_type_avail(struct iio_dev *indio_dev,
 static int iio_device_add_channel_sysfs(struct iio_dev *indio_dev,
 					struct iio_chan_spec const *chan)
 {
-	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	int ret, attrcount = 0;
 	const struct iio_chan_spec_ext_info *ext_info;
 
@@ -1490,17 +1505,13 @@ static int iio_device_add_channel_sysfs(struct iio_dev *indio_dev,
 		unsigned int i = 0;
 
 		for (ext_info = chan->ext_info; ext_info->name; ext_info++) {
-			ret = __iio_add_chan_devattr(ext_info->name,
-					chan,
-					ext_info->read ?
-					    &iio_read_channel_ext_info : NULL,
-					ext_info->write ?
-					    &iio_write_channel_ext_info : NULL,
-					i,
-					ext_info->shared,
-					&indio_dev->dev,
-					NULL,
-					&iio_dev_opaque->channel_attr_list);
+			ret = iio_device_add_chan_devattr(indio_dev,
+							  ext_info->name, chan,
+							  ext_info->read ?
+							  &iio_read_channel_ext_info : NULL,
+							  ext_info->write ?
+							  &iio_write_channel_ext_info : NULL,
+							  i, ext_info->shared);
 			i++;
 			if (ret == -EBUSY && ext_info->shared)
 				continue;
@@ -1524,10 +1535,10 @@ static int iio_device_add_channel_sysfs(struct iio_dev *indio_dev,
  */
 void iio_free_chan_devattr_list(struct list_head *attr_list)
 {
-	struct iio_dev_attr *p, *n;
+	struct iio_chan_attr *p, *n;
 
 	list_for_each_entry_safe(p, n, attr_list, l) {
-		kfree_const(p->dev_attr.attr.name);
+		kfree_const(p->iio_attr.dev_attr.attr.name);
 		list_del(&p->l);
 		kfree(p);
 	}
@@ -1649,7 +1660,7 @@ static int iio_device_register_sysfs(struct iio_dev *indio_dev)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	int i, ret = 0, attrcount, attrn, attrcount_orig = 0;
-	struct iio_dev_attr *p;
+	struct iio_chan_attr *p;
 	struct attribute **attr, *clk = NULL;
 
 	/* First count elements in any existing group */
@@ -1708,7 +1719,7 @@ static int iio_device_register_sysfs(struct iio_dev *indio_dev)
 	attrn = attrcount_orig;
 	/* Add all elements from the list. */
 	list_for_each_entry(p, &iio_dev_opaque->channel_attr_list, l)
-		iio_dev_opaque->chan_attr_group.attrs[attrn++] = &p->dev_attr.attr;
+		iio_dev_opaque->chan_attr_group.attrs[attrn++] = &p->iio_attr.dev_attr.attr;
 	if (indio_dev->name)
 		iio_dev_opaque->chan_attr_group.attrs[attrn++] = &dev_attr_name.attr;
 	if (indio_dev->label)
diff --git a/drivers/iio/industrialio-event.c b/drivers/iio/industrialio-event.c
index e6730f52262a..e72b665cc79b 100644
--- a/drivers/iio/industrialio-event.c
+++ b/drivers/iio/industrialio-event.c
@@ -258,19 +258,19 @@ static const char * const iio_ev_info_text[] = {
 	[IIO_EV_INFO_SCALE] = "scale",
 };
 
-static enum iio_event_direction iio_ev_attr_dir(struct iio_dev_attr *attr)
+static enum iio_event_direction iio_ev_attr_dir(struct iio_chan_attr *attr)
 {
-	return attr->c->event_spec[attr->address & 0xffff].dir;
+	return attr->c->event_spec[attr->iio_attr.address & 0xffff].dir;
 }
 
-static enum iio_event_type iio_ev_attr_type(struct iio_dev_attr *attr)
+static enum iio_event_type iio_ev_attr_type(struct iio_chan_attr *attr)
 {
-	return attr->c->event_spec[attr->address & 0xffff].type;
+	return attr->c->event_spec[attr->iio_attr.address & 0xffff].type;
 }
 
-static enum iio_event_info iio_ev_attr_info(struct iio_dev_attr *attr)
+static enum iio_event_info iio_ev_attr_info(struct iio_chan_attr *attr)
 {
-	return (attr->address >> 16) & 0xffff;
+	return (attr->iio_attr.address >> 16) & 0xffff;
 }
 
 static ssize_t iio_ev_state_store(struct device *dev,
@@ -279,7 +279,7 @@ static ssize_t iio_ev_state_store(struct device *dev,
 				  size_t len)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	int ret;
 	bool val;
 
@@ -302,7 +302,7 @@ static ssize_t iio_ev_state_show(struct device *dev,
 				 char *buf)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	int val;
 
 	if (!indio_dev->info->read_event_config)
@@ -322,7 +322,7 @@ static ssize_t iio_ev_value_show(struct device *dev,
 				 char *buf)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	int val, val2, val_arr[2];
 	int ret;
 
@@ -346,7 +346,7 @@ static ssize_t iio_ev_value_store(struct device *dev,
 				  size_t len)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 	int val, val2;
 	int ret;
 
@@ -371,7 +371,7 @@ static ssize_t iio_ev_label_show(struct device *dev,
 				 char *buf)
 {
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
-	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
+	struct iio_chan_attr *this_attr = to_iio_chan_attr(attr);
 
 	if (indio_dev->info->read_event_label)
 		return indio_dev->info->read_event_label(indio_dev,
@@ -381,12 +381,41 @@ static ssize_t iio_ev_label_show(struct device *dev,
 	return -EINVAL;
 }
 
+static int iio_device_add_event_attr(struct iio_dev *indio_dev,
+				     const char *postfix,
+				     const struct iio_chan_spec *chan,
+				     iio_attr_show_t show,
+				     iio_attr_store_t store,
+				     u64 mask,
+				     enum iio_shared_by shared_by)
+{
+	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
+	struct iio_chan_attr *ev_attr;
+	struct iio_chan_attr_ctx ctx;
+	int ret;
+
+	ret = iio_chan_attr_prepare(&ctx, &indio_dev->dev, chan, shared_by,
+				    postfix,
+				    &iio_dev_opaque->event_interface->dev_attr_list);
+	if (ret)
+		return ret;
+
+	ev_attr = kzalloc_obj(*ev_attr);
+	if (!ev_attr)
+		return -ENOMEM;
+
+	ret = iio_chan_attr_add(&ctx, ev_attr, show, store, mask);
+	if (ret)
+		kfree(ev_attr);
+
+	return ret;
+}
+
 static int iio_device_add_event(struct iio_dev *indio_dev,
 	const struct iio_chan_spec *chan, unsigned int spec_index,
 	enum iio_event_type type, enum iio_event_direction dir,
 	enum iio_shared_by shared_by, const unsigned long *mask)
 {
-	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	ssize_t (*show)(struct device *dev, struct device_attribute *attr,
 		char *buf);
 	ssize_t (*store)(struct device *dev, struct device_attribute *attr,
@@ -419,10 +448,10 @@ static int iio_device_add_event(struct iio_dev *indio_dev,
 			store = iio_ev_value_store;
 		}
 
-		ret = __iio_add_chan_devattr(postfix, chan, show, store,
-			 (i << 16) | spec_index, shared_by, &indio_dev->dev,
-			 NULL,
-			&iio_dev_opaque->event_interface->dev_attr_list);
+		ret = iio_device_add_event_attr(indio_dev, postfix, chan,
+						show, store,
+						(i << 16) | spec_index,
+						shared_by);
 		kfree(postfix);
 
 		if ((ret == -EBUSY) && (shared_by != IIO_SEPARATE))
@@ -443,7 +472,6 @@ static int iio_device_add_event_label(struct iio_dev *indio_dev,
 				      enum iio_event_type type,
 				      enum iio_event_direction dir)
 {
-	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	char *postfix;
 	int ret;
 
@@ -460,9 +488,9 @@ static int iio_device_add_event_label(struct iio_dev *indio_dev,
 	if (postfix == NULL)
 		return -ENOMEM;
 
-	ret = __iio_add_chan_devattr(postfix, chan, &iio_ev_label_show, NULL,
-				spec_index, IIO_SEPARATE, &indio_dev->dev, NULL,
-				&iio_dev_opaque->event_interface->dev_attr_list);
+	ret = iio_device_add_event_attr(indio_dev, postfix, chan,
+					&iio_ev_label_show, NULL, spec_index,
+					IIO_SEPARATE);
 
 	kfree(postfix);
 
@@ -575,7 +603,7 @@ int iio_device_register_eventset(struct iio_dev *indio_dev)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	struct iio_event_interface *ev_int;
-	struct iio_dev_attr *p;
+	struct iio_chan_attr *p;
 	int ret = 0, attrcount_orig = 0, attrcount, attrn;
 	struct attribute **attr;
 
@@ -619,7 +647,7 @@ int iio_device_register_eventset(struct iio_dev *indio_dev)
 	attrn = attrcount_orig;
 	/* Add all elements from the list. */
 	list_for_each_entry(p, &ev_int->dev_attr_list, l)
-		ev_int->group.attrs[attrn++] = &p->dev_attr.attr;
+		ev_int->group.attrs[attrn++] = &p->iio_attr.dev_attr.attr;
 
 	ret = iio_device_register_sysfs_group(indio_dev, &ev_int->group);
 	if (ret)
diff --git a/include/linux/iio/sysfs.h b/include/linux/iio/sysfs.h
index de5bb125815c..26c88767afe6 100644
--- a/include/linux/iio/sysfs.h
+++ b/include/linux/iio/sysfs.h
@@ -10,21 +10,16 @@
 #define _INDUSTRIAL_IO_SYSFS_H_
 
 struct iio_buffer;
-struct iio_chan_spec;
 
 /**
  * struct iio_dev_attr - iio specific device attribute
  * @dev_attr:	underlying device attribute
  * @address:	associated register address
- * @l:		list head for maintaining list of dynamically created attrs
- * @c:		specification for the underlying channel
  * @buffer:	the IIO buffer to which this attribute belongs to (if any)
  */
 struct iio_dev_attr {
 	struct device_attribute dev_attr;
 	u64 address;
-	struct list_head l;
-	struct iio_chan_spec const *c;
 	struct iio_buffer *buffer;
 };
 

-- 
2.43.0

