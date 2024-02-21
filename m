From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 21 Feb 2024 14:26:56 +0100
Subject: [PATCH 5/5] iio: inkern: move to the cleanup.h magic
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-iio-use-cleanup-magic-v1-5-f9c292666f26@analog.com>
References: <20240221-iio-use-cleanup-magic-v1-0-f9c292666f26@analog.com>
In-Reply-To: <20240221-iio-use-cleanup-magic-v1-0-f9c292666f26@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708522015; l=12111;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=3+/f3kNp+MlxZLmwHTg9hfEYQ4QyDxWxMZCbaPjXvkM=;
 b=IGHcNbQno50QNX5rgt82AJXwjCqLN/WZlZwC67vFz0mQkEkE24odjy2KhjccpHcK8lMb+5RSY
 X5WVS+wq9c4B4vZoLtEYZNabuyD7Yu7QT5Wzml0qPb0RFK42bBRL9Lf
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the new cleanup magic for handling mutexes in IIO. This allows us to
greatly simplify some code paths.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/inkern.c | 224 ++++++++++++++++-----------------------------------
 1 file changed, 71 insertions(+), 153 deletions(-)

diff --git a/drivers/iio/inkern.c b/drivers/iio/inkern.c
index 7a1f6713318a..6a1d6ff8eb97 100644
--- a/drivers/iio/inkern.c
+++ b/drivers/iio/inkern.c
@@ -3,6 +3,7 @@
  *
  * Copyright (c) 2011 Jonathan Cameron
  */
+#include <linux/cleanup.h>
 #include <linux/err.h>
 #include <linux/export.h>
 #include <linux/minmax.h>
@@ -43,30 +44,26 @@ static int iio_map_array_unregister_locked(struct iio_dev *indio_dev)
 
 int iio_map_array_register(struct iio_dev *indio_dev, struct iio_map *maps)
 {
-	int i = 0, ret = 0;
+	int i = 0;
 	struct iio_map_internal *mapi;
 
 	if (!maps)
 		return 0;
 
-	mutex_lock(&iio_map_list_lock);
+	guard(mutex)(&iio_map_list_lock);
 	while (maps[i].consumer_dev_name) {
 		mapi = kzalloc(sizeof(*mapi), GFP_KERNEL);
 		if (!mapi) {
-			ret = -ENOMEM;
-			goto error_ret;
+			iio_map_array_unregister_locked(indio_dev);
+			return -ENOMEM;
 		}
 		mapi->map = &maps[i];
 		mapi->indio_dev = indio_dev;
 		list_add_tail(&mapi->l, &iio_map_list);
 		i++;
 	}
-error_ret:
-	if (ret)
-		iio_map_array_unregister_locked(indio_dev);
-	mutex_unlock(&iio_map_list_lock);
 
-	return ret;
+	return 0;
 }
 EXPORT_SYMBOL_GPL(iio_map_array_register);
 
@@ -75,13 +72,8 @@ EXPORT_SYMBOL_GPL(iio_map_array_register);
  */
 int iio_map_array_unregister(struct iio_dev *indio_dev)
 {
-	int ret;
-
-	mutex_lock(&iio_map_list_lock);
-	ret = iio_map_array_unregister_locked(indio_dev);
-	mutex_unlock(&iio_map_list_lock);
-
-	return ret;
+	guard(mutex)(&iio_map_list_lock);
+	return iio_map_array_unregister_locked(indio_dev);
 }
 EXPORT_SYMBOL_GPL(iio_map_array_unregister);
 
@@ -337,17 +329,17 @@ static struct iio_channel *iio_channel_get_sys(const char *name,
 		return ERR_PTR(-ENODEV);
 
 	/* first find matching entry the channel map */
-	mutex_lock(&iio_map_list_lock);
-	list_for_each_entry(c_i, &iio_map_list, l) {
-		if ((name && strcmp(name, c_i->map->consumer_dev_name) != 0) ||
-		    (channel_name &&
-		     strcmp(channel_name, c_i->map->consumer_channel) != 0))
-			continue;
-		c = c_i;
-		iio_device_get(c->indio_dev);
-		break;
+	scoped_guard(mutex, &iio_map_list_lock) {
+		list_for_each_entry(c_i, &iio_map_list, l) {
+			if ((name && strcmp(name, c_i->map->consumer_dev_name) != 0) ||
+			    (channel_name &&
+			     strcmp(channel_name, c_i->map->consumer_channel) != 0))
+				continue;
+			c = c_i;
+			iio_device_get(c->indio_dev);
+			break;
+		}
 	}
-	mutex_unlock(&iio_map_list_lock);
 	if (!c)
 		return ERR_PTR(-ENODEV);
 
@@ -469,7 +461,7 @@ struct iio_channel *iio_channel_get_all(struct device *dev)
 
 	name = dev_name(dev);
 
-	mutex_lock(&iio_map_list_lock);
+	guard(mutex)(&iio_map_list_lock);
 	/* first count the matching maps */
 	list_for_each_entry(c, &iio_map_list, l)
 		if (name && strcmp(name, c->map->consumer_dev_name) != 0)
@@ -477,17 +469,13 @@ struct iio_channel *iio_channel_get_all(struct device *dev)
 		else
 			nummaps++;
 
-	if (nummaps == 0) {
-		ret = -ENODEV;
-		goto error_ret;
-	}
+	if (nummaps == 0)
+		return ERR_PTR(-ENODEV);
 
 	/* NULL terminated array to save passing size */
 	chans = kcalloc(nummaps + 1, sizeof(*chans), GFP_KERNEL);
-	if (!chans) {
-		ret = -ENOMEM;
-		goto error_ret;
-	}
+	if (!chans)
+		return ERR_PTR(-ENOMEM);
 
 	/* for each map fill in the chans element */
 	list_for_each_entry(c, &iio_map_list, l) {
@@ -509,7 +497,6 @@ struct iio_channel *iio_channel_get_all(struct device *dev)
 		ret = -ENODEV;
 		goto error_free_chans;
 	}
-	mutex_unlock(&iio_map_list_lock);
 
 	return chans;
 
@@ -517,9 +504,6 @@ struct iio_channel *iio_channel_get_all(struct device *dev)
 	for (i = 0; i < nummaps; i++)
 		iio_device_put(chans[i].indio_dev);
 	kfree(chans);
-error_ret:
-	mutex_unlock(&iio_map_list_lock);
-
 	return ERR_PTR(ret);
 }
 EXPORT_SYMBOL_GPL(iio_channel_get_all);
@@ -590,38 +574,24 @@ static int iio_channel_read(struct iio_channel *chan, int *val, int *val2,
 int iio_read_channel_raw(struct iio_channel *chan, int *val)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
-	int ret;
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
-	ret = iio_channel_read(chan, val, NULL, IIO_CHAN_INFO_RAW);
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
-
-	return ret;
+	return iio_channel_read(chan, val, NULL, IIO_CHAN_INFO_RAW);
 }
 EXPORT_SYMBOL_GPL(iio_read_channel_raw);
 
 int iio_read_channel_average_raw(struct iio_channel *chan, int *val)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
-	int ret;
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
-	ret = iio_channel_read(chan, val, NULL, IIO_CHAN_INFO_AVERAGE_RAW);
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
-
-	return ret;
+	return iio_channel_read(chan, val, NULL, IIO_CHAN_INFO_AVERAGE_RAW);
 }
 EXPORT_SYMBOL_GPL(iio_read_channel_average_raw);
 
@@ -708,20 +678,13 @@ int iio_convert_raw_to_processed(struct iio_channel *chan, int raw,
 				 int *processed, unsigned int scale)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
-	int ret;
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
-	ret = iio_convert_raw_to_processed_unlocked(chan, raw, processed,
-						    scale);
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
-
-	return ret;
+	return iio_convert_raw_to_processed_unlocked(chan, raw, processed,
+						     scale);
 }
 EXPORT_SYMBOL_GPL(iio_convert_raw_to_processed);
 
@@ -729,19 +692,12 @@ int iio_read_channel_attribute(struct iio_channel *chan, int *val, int *val2,
 			       enum iio_chan_info_enum attribute)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
-	int ret;
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
-	ret = iio_channel_read(chan, val, val2, attribute);
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
-
-	return ret;
+	return iio_channel_read(chan, val, val2, attribute);
 }
 EXPORT_SYMBOL_GPL(iio_read_channel_attribute);
 
@@ -757,30 +713,25 @@ int iio_read_channel_processed_scale(struct iio_channel *chan, int *val,
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
 	int ret;
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
 	if (iio_channel_has_info(chan->channel, IIO_CHAN_INFO_PROCESSED)) {
 		ret = iio_channel_read(chan, val, NULL,
 				       IIO_CHAN_INFO_PROCESSED);
 		if (ret < 0)
-			goto err_unlock;
+			return ret;
+
 		*val *= scale;
-	} else {
-		ret = iio_channel_read(chan, val, NULL, IIO_CHAN_INFO_RAW);
-		if (ret < 0)
-			goto err_unlock;
-		ret = iio_convert_raw_to_processed_unlocked(chan, *val, val,
-							    scale);
+		return ret;
 	}
 
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
+	ret = iio_channel_read(chan, val, NULL, IIO_CHAN_INFO_RAW);
+	if (ret < 0)
+		return ret;
 
-	return ret;
+	return iio_convert_raw_to_processed_unlocked(chan, *val, val, scale);
 }
 EXPORT_SYMBOL_GPL(iio_read_channel_processed_scale);
 
@@ -813,19 +764,12 @@ int iio_read_avail_channel_attribute(struct iio_channel *chan,
 				     enum iio_chan_info_enum attribute)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
-	int ret;
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
-	ret = iio_channel_read_avail(chan, vals, type, length, attribute);
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
-
-	return ret;
+	return iio_channel_read_avail(chan, vals, type, length, attribute);
 }
 EXPORT_SYMBOL_GPL(iio_read_avail_channel_attribute);
 
@@ -892,20 +836,13 @@ static int iio_channel_read_max(struct iio_channel *chan,
 int iio_read_max_channel_raw(struct iio_channel *chan, int *val)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
-	int ret;
 	int type;
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
-	ret = iio_channel_read_max(chan, val, NULL, &type, IIO_CHAN_INFO_RAW);
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
-
-	return ret;
+	return iio_channel_read_max(chan, val, NULL, &type, IIO_CHAN_INFO_RAW);
 }
 EXPORT_SYMBOL_GPL(iio_read_max_channel_raw);
 
@@ -955,40 +892,28 @@ static int iio_channel_read_min(struct iio_channel *chan,
 int iio_read_min_channel_raw(struct iio_channel *chan, int *val)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
-	int ret;
 	int type;
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
-	ret = iio_channel_read_min(chan, val, NULL, &type, IIO_CHAN_INFO_RAW);
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
-
-	return ret;
+	return iio_channel_read_min(chan, val, NULL, &type, IIO_CHAN_INFO_RAW);
 }
 EXPORT_SYMBOL_GPL(iio_read_min_channel_raw);
 
 int iio_get_channel_type(struct iio_channel *chan, enum iio_chan_type *type)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
-	int ret = 0;
-	/* Need to verify underlying driver has not gone away */
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	/* Need to verify underlying driver has not gone away */
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
 	*type = chan->channel->type;
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
 
-	return ret;
+	return 0;
 }
 EXPORT_SYMBOL_GPL(iio_get_channel_type);
 
@@ -1003,19 +928,12 @@ int iio_write_channel_attribute(struct iio_channel *chan, int val, int val2,
 				enum iio_chan_info_enum attribute)
 {
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(chan->indio_dev);
-	int ret;
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
-	if (!chan->indio_dev->info) {
-		ret = -ENODEV;
-		goto err_unlock;
-	}
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
+	if (!chan->indio_dev->info)
+		return -ENODEV;
 
-	ret = iio_channel_write(chan, val, val2, attribute);
-err_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
-
-	return ret;
+	return iio_channel_write(chan, val, val2, attribute);
 }
 EXPORT_SYMBOL_GPL(iio_write_channel_attribute);
 

-- 
2.43.0

