From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 14 Jul 2026 12:02:46 +0100
Subject: [PATCH v8 06/17] iio: core: create local __iio_chan_prefix_emit()
 for reuse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-ad9910-iio-driver-v8-6-36939c3c07d2@analog.com>
References: <20260714-ad9910-iio-driver-v8-0-36939c3c07d2@analog.com>
In-Reply-To: <20260714-ad9910-iio-driver-v8-0-36939c3c07d2@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784026971; l=7103;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Cf5KZC7lI5UDQIeW/RGJX7Fxdw5QzQyuUSqfO/q7ZWk=;
 b=TSxZEIxuvpJSri+d6UL2BUrv5Mos9YFVh1qCv34Uixnn6SCtu+LIanqtf+E8KtXFZ0Nk+tV+w
 TdQybq9jvUEBbHxvkMOGiFICWk3jRq4Uno1nSZP1N3+i1zRNcP6DJ3J
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move logic to create a channel prefix for naming attribute files into a
separate __iio_chan_prefix_emit() function for reuse. The dev pointer is
passed to __iio_device_attr_init() so that dev_err() replaces WARN().
The new helper is going to be used to expose channel relationships as
sysfs attributes.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-core.c | 167 ++++++++++++++++------------------------
 1 file changed, 66 insertions(+), 101 deletions(-)

diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index 98fc00343dc5..b365922d8481 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -25,6 +25,7 @@
 #include <linux/poll.h>
 #include <linux/property.h>
 #include <linux/sched.h>
+#include <linux/seq_buf.h>
 #include <linux/slab.h>
 #include <linux/wait.h>
 
@@ -199,6 +200,56 @@ static const char * const iio_chan_info_postfix[] = {
 	[IIO_CHAN_INFO_CONVDELAY] = "convdelay",
 	[IIO_CHAN_INFO_POWERFACTOR] = "powerfactor",
 };
+
+static ssize_t __iio_chan_prefix_emit(struct device *dev,
+				      const struct iio_chan_spec *chan,
+				      enum iio_shared_by shared_by,
+				      char *buf, size_t len)
+{
+	const char *type = iio_chan_type_name_spec[chan->type];
+	const char *dir = iio_direction[chan->output];
+	struct seq_buf s;
+
+	seq_buf_init(&s, buf, len);
+
+	switch (shared_by) {
+	case IIO_SHARED_BY_ALL:
+		break;
+	case IIO_SHARED_BY_DIR:
+		seq_buf_printf(&s, "%s", dir);
+		break;
+	case IIO_SHARED_BY_TYPE:
+		seq_buf_printf(&s, "%s_%s", dir, type);
+		if (chan->differential)
+			seq_buf_printf(&s, "-%s", type);
+		break;
+	case IIO_SEPARATE:
+		seq_buf_printf(&s, "%s_%s", dir, type);
+		if (chan->indexed) {
+			seq_buf_printf(&s, "%d", chan->channel);
+			if (chan->differential)
+				seq_buf_printf(&s, "-%s%d", type, chan->channel2);
+		} else if (chan->differential) {
+			dev_err(dev, "Differential channels must be indexed\n");
+			return -EINVAL;
+		}
+
+		if (chan->modified) {
+			if (chan->differential) {
+				dev_err(dev, "Differential channels can not have modifier\n");
+				return -EINVAL;
+			}
+			seq_buf_printf(&s, "_%s", iio_modifier_names[chan->channel2]);
+		}
+
+		if (chan->extend_name)
+			seq_buf_printf(&s, "_%s", chan->extend_name);
+		break;
+	}
+
+	return seq_buf_has_overflowed(&s) ? -EOVERFLOW : s.len;
+}
+
 /**
  * iio_device_id() - query the unique ID for the device
  * @indio_dev:		Device structure whose ID is being queried
@@ -1088,7 +1139,8 @@ static ssize_t iio_write_channel_info(struct device *dev,
 }
 
 static
-int __iio_device_attr_init(struct device_attribute *dev_attr,
+int __iio_device_attr_init(struct device *dev,
+			   struct device_attribute *dev_attr,
 			   const char *postfix,
 			   struct iio_chan_spec const *chan,
 			   ssize_t (*readfunc)(struct device *dev,
@@ -1100,106 +1152,22 @@ int __iio_device_attr_init(struct device_attribute *dev_attr,
 						size_t len),
 			   enum iio_shared_by shared_by)
 {
-	int ret = 0;
-	char *name = NULL;
-	char *full_postfix;
+	char prefix[NAME_MAX + 1];
+	ssize_t ret;
 
 	sysfs_attr_init(&dev_attr->attr);
 
-	/* Build up postfix of <extend_name>_<modifier>_postfix */
-	if (chan->modified && (shared_by == IIO_SEPARATE)) {
-		if (chan->extend_name)
-			full_postfix = kasprintf(GFP_KERNEL, "%s_%s_%s",
-						 iio_modifier_names[chan->channel2],
-						 chan->extend_name,
-						 postfix);
-		else
-			full_postfix = kasprintf(GFP_KERNEL, "%s_%s",
-						 iio_modifier_names[chan->channel2],
-						 postfix);
-	} else {
-		if (chan->extend_name == NULL || shared_by != IIO_SEPARATE)
-			full_postfix = kstrdup(postfix, GFP_KERNEL);
-		else
-			full_postfix = kasprintf(GFP_KERNEL,
-						 "%s_%s",
-						 chan->extend_name,
-						 postfix);
-	}
-	if (full_postfix == NULL)
+	ret = __iio_chan_prefix_emit(dev, chan, shared_by, prefix, sizeof(prefix));
+	if (ret < 0)
+		return ret;
+
+	if (ret)
+		dev_attr->attr.name = kasprintf(GFP_KERNEL, "%s_%s", prefix, postfix);
+	else
+		dev_attr->attr.name = kstrdup(postfix, GFP_KERNEL);
+	if (!dev_attr->attr.name)
 		return -ENOMEM;
 
-	if (chan->differential) { /* Differential can not have modifier */
-		switch (shared_by) {
-		case IIO_SHARED_BY_ALL:
-			name = kasprintf(GFP_KERNEL, "%s", full_postfix);
-			break;
-		case IIO_SHARED_BY_DIR:
-			name = kasprintf(GFP_KERNEL, "%s_%s",
-						iio_direction[chan->output],
-						full_postfix);
-			break;
-		case IIO_SHARED_BY_TYPE:
-			name = kasprintf(GFP_KERNEL, "%s_%s-%s_%s",
-					    iio_direction[chan->output],
-					    iio_chan_type_name_spec[chan->type],
-					    iio_chan_type_name_spec[chan->type],
-					    full_postfix);
-			break;
-		case IIO_SEPARATE:
-			if (!chan->indexed) {
-				WARN(1, "Differential channels must be indexed\n");
-				ret = -EINVAL;
-				goto error_free_full_postfix;
-			}
-			name = kasprintf(GFP_KERNEL,
-					    "%s_%s%d-%s%d_%s",
-					    iio_direction[chan->output],
-					    iio_chan_type_name_spec[chan->type],
-					    chan->channel,
-					    iio_chan_type_name_spec[chan->type],
-					    chan->channel2,
-					    full_postfix);
-			break;
-		}
-	} else { /* Single ended */
-		switch (shared_by) {
-		case IIO_SHARED_BY_ALL:
-			name = kasprintf(GFP_KERNEL, "%s", full_postfix);
-			break;
-		case IIO_SHARED_BY_DIR:
-			name = kasprintf(GFP_KERNEL, "%s_%s",
-						iio_direction[chan->output],
-						full_postfix);
-			break;
-		case IIO_SHARED_BY_TYPE:
-			name = kasprintf(GFP_KERNEL, "%s_%s_%s",
-					    iio_direction[chan->output],
-					    iio_chan_type_name_spec[chan->type],
-					    full_postfix);
-			break;
-
-		case IIO_SEPARATE:
-			if (chan->indexed)
-				name = kasprintf(GFP_KERNEL, "%s_%s%d_%s",
-						    iio_direction[chan->output],
-						    iio_chan_type_name_spec[chan->type],
-						    chan->channel,
-						    full_postfix);
-			else
-				name = kasprintf(GFP_KERNEL, "%s_%s_%s",
-						    iio_direction[chan->output],
-						    iio_chan_type_name_spec[chan->type],
-						    full_postfix);
-			break;
-		}
-	}
-	if (name == NULL) {
-		ret = -ENOMEM;
-		goto error_free_full_postfix;
-	}
-	dev_attr->attr.name = name;
-
 	if (readfunc) {
 		dev_attr->attr.mode |= 0444;
 		dev_attr->show = readfunc;
@@ -1210,10 +1178,7 @@ int __iio_device_attr_init(struct device_attribute *dev_attr,
 		dev_attr->store = writefunc;
 	}
 
-error_free_full_postfix:
-	kfree(full_postfix);
-
-	return ret;
+	return 0;
 }
 
 static void __iio_device_attr_deinit(struct device_attribute *dev_attr)
@@ -1242,7 +1207,7 @@ int __iio_add_chan_devattr(const char *postfix,
 	iio_attr = kzalloc_obj(*iio_attr);
 	if (iio_attr == NULL)
 		return -ENOMEM;
-	ret = __iio_device_attr_init(&iio_attr->dev_attr,
+	ret = __iio_device_attr_init(dev, &iio_attr->dev_attr,
 				     postfix, chan,
 				     readfunc, writefunc, shared_by);
 	if (ret)

-- 
2.43.0

