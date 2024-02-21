From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 21 Feb 2024 14:26:52 +0100
Subject: [PATCH 1/5] iio: core: move to cleanup.h magic
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-iio-use-cleanup-magic-v1-1-f9c292666f26@analog.com>
References: <20240221-iio-use-cleanup-magic-v1-0-f9c292666f26@analog.com>
In-Reply-To: <20240221-iio-use-cleanup-magic-v1-0-f9c292666f26@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708522015; l=3677;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=WddubecxlqcyyhVh2mUw5FZVx2FoerYmAw/tQVz73zs=;
 b=WLgx2GUMCc5Wk5e8wIFDH5xyqW+5a4fp7NRA19EIZyL6qxrF9LHQop1+gAeTbgUEqL5M+RlQu
 6/vPEJA7rmZCyPFXsJomveMyiemCa8z03FijT5YUrKj17KuCdlYQCzS
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the new cleanup magic for handling mutexes in IIO. This allows us to
greatly simplify some code paths.

Note that we keep the plain mutex calls in the
iio_device_release|acquire() APIs since in there the macros would likely
not help much (as we want to keep the lock acquired when he leave the
APIs).

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/industrialio-core.c | 52 +++++++++++++++--------------------------
 1 file changed, 19 insertions(+), 33 deletions(-)

diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index 9b2877fe8689..7e6497828364 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -11,6 +11,7 @@
 
 #include <linux/anon_inodes.h>
 #include <linux/cdev.h>
+#include <linux/cleanup.h>
 #include <linux/debugfs.h>
 #include <linux/device.h>
 #include <linux/err.h>
@@ -268,20 +269,16 @@ EXPORT_SYMBOL(iio_read_const_attr);
  */
 int iio_device_set_clock(struct iio_dev *indio_dev, clockid_t clock_id)
 {
-	int ret;
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	const struct iio_event_interface *ev_int = iio_dev_opaque->event_interface;
 
-	ret = mutex_lock_interruptible(&iio_dev_opaque->mlock);
-	if (ret)
-		return ret;
-	if ((ev_int && iio_event_enabled(ev_int)) ||
-	    iio_buffer_enabled(indio_dev)) {
-		mutex_unlock(&iio_dev_opaque->mlock);
-		return -EBUSY;
+	scoped_cond_guard(mutex_intr, return -EINTR, &iio_dev_opaque->mlock) {
+		if ((ev_int && iio_event_enabled(ev_int)) ||
+		    iio_buffer_enabled(indio_dev))
+			return -EBUSY;
+
+		iio_dev_opaque->clock_id = clock_id;
 	}
-	iio_dev_opaque->clock_id = clock_id;
-	mutex_unlock(&iio_dev_opaque->mlock);
 
 	return 0;
 }
@@ -1806,31 +1803,22 @@ static long iio_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
 	struct iio_dev *indio_dev = ib->indio_dev;
 	struct iio_dev_opaque *iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	struct iio_ioctl_handler *h;
-	int ret = -ENODEV;
-
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
 
+	guard(mutex)(&iio_dev_opaque->info_exist_lock);
 	/*
 	 * The NULL check here is required to prevent crashing when a device
 	 * is being removed while userspace would still have open file handles
 	 * to try to access this device.
 	 */
 	if (!indio_dev->info)
-		goto out_unlock;
+		return -ENODEV;
 
 	list_for_each_entry(h, &iio_dev_opaque->ioctl_handlers, entry) {
-		ret = h->ioctl(indio_dev, filp, cmd, arg);
-		if (ret != IIO_IOCTL_UNHANDLED)
-			break;
+		if (h->ioctl(indio_dev, filp, cmd, arg) != IIO_IOCTL_UNHANDLED)
+			return 0;
 	}
 
-	if (ret == IIO_IOCTL_UNHANDLED)
-		ret = -ENODEV;
-
-out_unlock:
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
-
-	return ret;
+	return -ENODEV;
 }
 
 static const struct file_operations iio_buffer_fileops = {
@@ -2058,18 +2046,16 @@ void iio_device_unregister(struct iio_dev *indio_dev)
 
 	cdev_device_del(&iio_dev_opaque->chrdev, &indio_dev->dev);
 
-	mutex_lock(&iio_dev_opaque->info_exist_lock);
+	scoped_guard(mutex, &iio_dev_opaque->info_exist_lock) {
+		iio_device_unregister_debugfs(indio_dev);
 
-	iio_device_unregister_debugfs(indio_dev);
+		iio_disable_all_buffers(indio_dev);
 
-	iio_disable_all_buffers(indio_dev);
+		indio_dev->info = NULL;
 
-	indio_dev->info = NULL;
-
-	iio_device_wakeup_eventset(indio_dev);
-	iio_buffer_wakeup_poll(indio_dev);
-
-	mutex_unlock(&iio_dev_opaque->info_exist_lock);
+		iio_device_wakeup_eventset(indio_dev);
+		iio_buffer_wakeup_poll(indio_dev);
+	}
 
 	iio_buffers_free_sysfs_and_mask(indio_dev);
 }

-- 
2.43.0

