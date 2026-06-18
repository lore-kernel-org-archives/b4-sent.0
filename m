From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 18 Jun 2026 14:27:22 +0100
Subject: [PATCH v6 06/16] iio: core: create local __iio_chan_prefix_emit()
 for reuse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260618-ad9910-iio-driver-v6-6-79125ffbe430@analog.com>
References: <20260618-ad9910-iio-driver-v6-0-79125ffbe430@analog.com>
In-Reply-To: <20260618-ad9910-iio-driver-v6-0-79125ffbe430@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781789267; l=6291;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=wT0KGQQPimCY8zSXPY5+HInU0joJdP+RzJwP5aY3uU4=;
 b=dFpE3sHOYqS+HybINRAJb9gwLLHCL2vUpS7QyWumMhPdSld4vHYq2S5biv5L12EehZgyZGEfg
 K1Sw+/aTIi5Cr6H2eKJ2cNo17pzREU0LxS6+taxtxDXu5erOusLdNtE
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move logic to create a channel prefix for naming attribute files into a
separate __iio_chan_prefix_emit() function for reuse.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-core.c | 167 ++++++++++++++++------------------------
 1 file changed, 68 insertions(+), 99 deletions(-)

diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index 03019bf9327b..9373006235c8 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -26,6 +26,7 @@
 #include <linux/property.h>
 #include <linux/sched.h>
 #include <linux/slab.h>
+#include <linux/sprintf.h>
 #include <linux/wait.h>
 
 #include <linux/iio/buffer.h>
@@ -199,6 +200,64 @@ static const char * const iio_chan_info_postfix[] = {
 	[IIO_CHAN_INFO_CONVDELAY] = "convdelay",
 	[IIO_CHAN_INFO_POWERFACTOR] = "powerfactor",
 };
+
+static int __iio_chan_prefix_emit(const struct iio_chan_spec *chan,
+				  enum iio_shared_by shared_by,
+				  char *buf, size_t len)
+{
+	const char *dir = iio_direction[chan->output];
+	const char *type = iio_chan_type_name_spec[chan->type];
+	int n = 0;
+
+	switch (shared_by) {
+	case IIO_SHARED_BY_ALL:
+		buf[0] = '\0'; /* empty channel prefix */
+		break;
+	case IIO_SHARED_BY_DIR:
+		n = scnprintf(buf, len, "%s", dir);
+		break;
+	case IIO_SHARED_BY_TYPE:
+		n = scnprintf(buf, len, "%s_%s", dir, type);
+		if (chan->differential)
+			n += scnprintf(buf + n, len - n, "-%s", type);
+		break;
+	case IIO_SEPARATE:
+		if (chan->indexed) {
+			n = scnprintf(buf, len, "%s_%s%d", dir, type,
+				      chan->channel);
+			if (chan->differential)
+				n += scnprintf(buf + n, len - n, "-%s%d", type,
+					       chan->channel2);
+		} else {
+			if (chan->differential) {
+				WARN(1, "Differential channels must be indexed\n");
+				return -EINVAL;
+			}
+			n = scnprintf(buf, len, "%s_%s", dir, type);
+		}
+
+		if (chan->modified) {
+			if (chan->differential) {
+				WARN(1, "Differential channels can not have modifier\n");
+				return -EINVAL;
+			}
+			n += scnprintf(buf + n, len - n, "_%s",
+				       iio_modifier_names[chan->channel2]);
+		}
+
+		if (chan->extend_name)
+			n += scnprintf(buf + n, len - n, "_%s", chan->extend_name);
+		break;
+	}
+
+	if (n > 0 && n < len - 1) { /* prefix termination if not empty */
+		buf[n++] = '_';
+		buf[n] = '\0';
+	}
+
+	return n;
+}
+
 /**
  * iio_device_id() - query the unique ID for the device
  * @indio_dev:		Device structure whose ID is being queried
@@ -1100,106 +1159,19 @@ int __iio_device_attr_init(struct device_attribute *dev_attr,
 						size_t len),
 			   enum iio_shared_by shared_by)
 {
-	int ret = 0;
-	char *name = NULL;
-	char *full_postfix;
+	char prefix[NAME_MAX + 1];
+	int ret;
 
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
+	ret = __iio_chan_prefix_emit(chan, shared_by, prefix, sizeof(prefix));
+	if (ret < 0)
+		return ret;
+
+	dev_attr->attr.name = kasprintf(GFP_KERNEL, "%s%s", prefix, postfix);
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
@@ -1210,10 +1182,7 @@ int __iio_device_attr_init(struct device_attribute *dev_attr,
 		dev_attr->store = writefunc;
 	}
 
-error_free_full_postfix:
-	kfree(full_postfix);
-
-	return ret;
+	return 0;
 }
 
 static void __iio_device_attr_deinit(struct device_attribute *dev_attr)

-- 
2.43.0

