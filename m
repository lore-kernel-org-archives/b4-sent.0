From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 21 Feb 2024 14:26:53 +0100
Subject: [PATCH 2/5] iio: events: move to the cleanup.h magic
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-iio-use-cleanup-magic-v1-2-f9c292666f26@analog.com>
References: <20240221-iio-use-cleanup-magic-v1-0-f9c292666f26@analog.com>
In-Reply-To: <20240221-iio-use-cleanup-magic-v1-0-f9c292666f26@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708522015; l=2320;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ar4mjNbR1mkb3YDznQ99CF7o8RhZbjmjysmAiRM0D9s=;
 b=lhOpOc2oWqZWuKulvYHKNGnXpwEt0gEmEcdIqM7tzLpXSPwihJcyh8Fkbs8gkrd2f8FB5cWNW
 vSJyYUhoKPgDk//D4N6uTeRk3VlrS+yBDuIbue7IH/9l0xX4cVUvIfF
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the new cleanup magic for handling mutexes in IIO. This allows us to
greatly simplify some code paths.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/industrialio-event.c | 42 +++++++++++++++++-----------------------
 1 file changed, 18 insertions(+), 24 deletions(-)

diff --git a/drivers/iio/industrialio-event.c b/drivers/iio/industrialio-event.c
index 910c1f14abd5..ef3cecbce915 100644
--- a/drivers/iio/industrialio-event.c
+++ b/drivers/iio/industrialio-event.c
@@ -7,6 +7,7 @@
  */
 
 #include <linux/anon_inodes.h>
+#include <linux/cleanup.h>
 #include <linux/device.h>
 #include <linux/fs.h>
 #include <linux/kernel.h>
@@ -146,11 +147,10 @@ static ssize_t iio_event_chrdev_read(struct file *filep,
 				return -ENODEV;
 		}
 
-		if (mutex_lock_interruptible(&ev_int->read_lock))
-			return -ERESTARTSYS;
-		ret = kfifo_to_user(&ev_int->det_events, buf, count, &copied);
-		mutex_unlock(&ev_int->read_lock);
-
+		scoped_cond_guard(mutex_intr, return -ERESTARTSYS,
+				  &ev_int->read_lock)
+			ret = kfifo_to_user(&ev_int->det_events, buf, count,
+					    &copied);
 		if (ret)
 			return ret;
 
@@ -198,28 +198,22 @@ static int iio_event_getfd(struct iio_dev *indio_dev)
 	if (ev_int == NULL)
 		return -ENODEV;
 
-	fd = mutex_lock_interruptible(&iio_dev_opaque->mlock);
-	if (fd)
-		return fd;
+	scoped_cond_guard(mutex_intr, return -EINTR, &iio_dev_opaque->mlock) {
+		if (test_and_set_bit(IIO_BUSY_BIT_POS, &ev_int->flags))
+			return -EBUSY;
 
-	if (test_and_set_bit(IIO_BUSY_BIT_POS, &ev_int->flags)) {
-		fd = -EBUSY;
-		goto unlock;
+		iio_device_get(indio_dev);
+
+		fd = anon_inode_getfd("iio:event", &iio_event_chrdev_fileops,
+				      indio_dev, O_RDONLY | O_CLOEXEC);
+		if (fd < 0) {
+			clear_bit(IIO_BUSY_BIT_POS, &ev_int->flags);
+			iio_device_put(indio_dev);
+		} else {
+			kfifo_reset_out(&ev_int->det_events);
+		}
 	}
 
-	iio_device_get(indio_dev);
-
-	fd = anon_inode_getfd("iio:event", &iio_event_chrdev_fileops,
-				indio_dev, O_RDONLY | O_CLOEXEC);
-	if (fd < 0) {
-		clear_bit(IIO_BUSY_BIT_POS, &ev_int->flags);
-		iio_device_put(indio_dev);
-	} else {
-		kfifo_reset_out(&ev_int->det_events);
-	}
-
-unlock:
-	mutex_unlock(&iio_dev_opaque->mlock);
 	return fd;
 }
 

-- 
2.43.0

