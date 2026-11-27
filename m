From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: jic23@kernel.org, dlechner@baylibre.com, nuno.sa@analog.com, 
 andy@kernel.org
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Arnav Kapoor <kapoorarnav43@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v3] iio: inkern: guard fwnode_xlate with info_exist_lock
Date: Fri, 27 Nov 2026 03:10:38 +0000
Message-Id: <20261127031038.12685-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795749038; l=3242;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=3eR7QjvwrqKPzzmBewRCZmPt+qJp/3aj6a2z0YLz8uc=;
 b=1HWWq8KlVlZ1BykCJj/4xM1SJQYVdLIt4MNmvvuSMq6O9dSdgGZM1KFsDfsPGEPFNWmwfMi3L
 7lylh1tHT4uC+kXXuUEdYYb2zWDUKX3eZ7ZdclH91OFp3nlRf0jldzb
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__fwnode_iio_channel_get() dereferences indio_dev->info->fwnode_xlate
and invokes it without holding info_exist_lock. Concurrent
iio_device_unregister() clears indio_dev->info under info_exist_lock,
allowing a NULL dereference or callback execution during provider
teardown.

Hold iio_dev_opaque->info_exist_lock with scoped_guard(mutex, ...)
matching the rest of inkern.c, and return -EPROBE_DEFER if
indio_dev->info is NULL. Since iio_device_unregister() calls
cdev_device_del() before clearing indio_dev->info, seeing a NULL info
pointer corresponds to racing right before device removal from
iio_bus_type, where !idev already returns -EPROBE_DEFER. Using
-EPROBE_DEFER also avoids colliding with the -ENODEV sentinel used by
callers to continue parent or map-list lookups and avoids the named
lookup -EINVAL fallback in __fwnode_iio_channel_get_by_name().

Fixes: acd8256723f2 ("iio: inkern: Add of_xlate function to struct iio_info")
Reviewed-by: Arnav Kapoor <kapoorarnav43@gmail.com>
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
Changes in v3:
- Place `struct iio_dev_opaque *iio_dev_opaque;` in reverse xmas tree
  order (Andy Shevchenko).
- Move `iio_dev_opaque = to_iio_dev_opaque(indio_dev);` right after
  `channel->indio_dev = indio_dev;` immediately before scoped_guard()
  (Andy Shevchenko).
- Carry Reviewed-by from Arnav Kapoor.

Changes in v2:
- Return -EPROBE_DEFER instead of -ENODEV when indio_dev->info is NULL
  so callers do not treat it as the "no channel on this node, keep
  looking" sentinel and named lookups do not overwrite it to -EINVAL
  (Arnav Kapoor).
- Drop the unrelated indio_dev->num_channels bounds check from this
  locking fix (Arnav Kapoor).
- Move the AI coding assistant note below the --- separator.

Link: https://lore.kernel.org/r/20261126060615.63790-1-iasnezhkov@gmail.com
Found and drafted with an AI coding assistant.

 drivers/iio/inkern.c | 15 ++++++++++-----
 1 file changed, 10 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/inkern.c b/drivers/iio/inkern.c
index 1f22275..92b6679 100644
--- a/drivers/iio/inkern.c
+++ b/drivers/iio/inkern.c
@@ -145,6 +145,7 @@ static int __fwnode_iio_channel_get(struct iio_channel *channel,
 				    struct fwnode_handle *fwnode, int index)
 {
+	struct iio_dev_opaque *iio_dev_opaque;
 	struct fwnode_reference_args iiospec;
 	struct device *idev;
 	struct iio_dev *indio_dev;
 	int err;
@@ -162,10 +163,15 @@ static int __fwnode_iio_channel_get(struct iio_channel *channel,
 	}
 
 	indio_dev = dev_to_iio_dev(idev);
 	channel->indio_dev = indio_dev;
-	if (indio_dev->info->fwnode_xlate)
-		index = indio_dev->info->fwnode_xlate(indio_dev, &iiospec);
-	else
-		index = __fwnode_iio_simple_xlate(indio_dev, &iiospec);
+	iio_dev_opaque = to_iio_dev_opaque(indio_dev);
+	scoped_guard(mutex, &iio_dev_opaque->info_exist_lock) {
+		if (!indio_dev->info)
+			index = -EPROBE_DEFER;
+		else if (indio_dev->info->fwnode_xlate)
+			index = indio_dev->info->fwnode_xlate(indio_dev, &iiospec);
+		else
+			index = __fwnode_iio_simple_xlate(indio_dev, &iiospec);
+	}
 	fwnode_handle_put(iiospec.fwnode);
 	if (index < 0)
 		goto err_put;
-- 
2.54.0 (Apple Git-157)

