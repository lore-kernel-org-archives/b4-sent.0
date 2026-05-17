From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 17 May 2026 19:37:47 +0100
Subject: [PATCH v5 03/13] iio: core: add hierarchical channel relationships
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260517-ad9910-iio-driver-v5-3-31599c88314a@analog.com>
References: <20260517-ad9910-iio-driver-v5-0-31599c88314a@analog.com>
In-Reply-To: <20260517-ad9910-iio-driver-v5-0-31599c88314a@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779043094; l=3380;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=A7fhI4etUphuvUOLbYT+tvvvSQiaXddEibbLDuTWMKQ=;
 b=O166oJxTAzSETzOt/aK2ziw8mQeBeTOK5BgBoxWQh9PTsv+5c8xmim0lhMPYWXWmqwJ3rwPtr
 R2rn8X3X8VmDxfHjtsa4meQ9o7lZHkZGYcPqwyIIh6w4TSiSHScY2vg
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add parent-child relationship between iio channels by creating a parent
pointer field in iio_chan_spec struct and exposing a sysfs attribute that
returns the parent channel label.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-core.c | 38 ++++++++++++++++++++++++++++++++++++++
 include/linux/iio/iio.h         |  5 +++++
 2 files changed, 43 insertions(+)

diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index 5c8404efd0a5..348ac7a59738 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -776,6 +776,14 @@ static ssize_t iio_read_channel_label(struct device *dev,
 					 to_iio_dev_attr(attr)->c, buf);
 }
 
+static ssize_t iio_read_channel_parent(struct device *dev,
+				       struct device_attribute *attr,
+				       char *buf)
+{
+	return do_iio_read_channel_label(dev_to_iio_dev(dev),
+					 to_iio_dev_attr(attr)->c->parent, buf);
+}
+
 static ssize_t iio_read_channel_info(struct device *dev,
 				     struct device_attribute *attr,
 				     char *buf)
@@ -1263,6 +1271,31 @@ static int iio_device_add_channel_label(struct iio_dev *indio_dev,
 	return 1;
 }
 
+static int iio_device_add_channel_parent(struct iio_dev *indio_dev,
+					 struct iio_chan_spec const *chan)
+{
+	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
+	int ret;
+
+	if (!chan->parent || (!indio_dev->info->read_label &&
+			      !chan->parent->extend_name))
+		return 0;
+
+	ret = __iio_add_chan_devattr("parent",
+				     chan,
+				     &iio_read_channel_parent,
+				     NULL,
+				     0,
+				     IIO_SEPARATE,
+				     &indio_dev->dev,
+				     NULL,
+				     &iio_dev_opaque->channel_attr_list);
+	if (ret < 0)
+		return ret;
+
+	return 1;
+}
+
 static int iio_device_add_info_mask_type(struct iio_dev *indio_dev,
 					 struct iio_chan_spec const *chan,
 					 enum iio_shared_by shared_by,
@@ -1401,6 +1434,11 @@ static int iio_device_add_channel_sysfs(struct iio_dev *indio_dev,
 		return ret;
 	attrcount += ret;
 
+	ret = iio_device_add_channel_parent(indio_dev, chan);
+	if (ret < 0)
+		return ret;
+	attrcount += ret;
+
 	if (chan->ext_info) {
 		unsigned int i = 0;
 
diff --git a/include/linux/iio/iio.h b/include/linux/iio/iio.h
index 86d17ee69e05..09a97518e4bd 100644
--- a/include/linux/iio/iio.h
+++ b/include/linux/iio/iio.h
@@ -258,6 +258,10 @@ struct iio_scan_type {
  *			by all channels.
  * @info_mask_shared_by_all_available: What availability information is to be
  *			exported that is shared by all channels.
+ * @parent:		Optional pointer to the parent channel spec for
+ *			hierarchical channel relationships. When set, a read-only
+ *			"parent" sysfs attribute is created containing the
+ *			parent channel's label.
  * @event_spec:		Array of events which should be registered for this
  *			channel.
  * @num_event_specs:	Size of the event_spec array.
@@ -306,6 +310,7 @@ struct iio_chan_spec {
 	unsigned long			info_mask_shared_by_dir_available;
 	unsigned long			info_mask_shared_by_all;
 	unsigned long			info_mask_shared_by_all_available;
+	const struct iio_chan_spec *parent;
 	const struct iio_event_spec *event_spec;
 	unsigned int		num_event_specs;
 	const struct iio_chan_spec_ext_info *ext_info;

-- 
2.43.0

