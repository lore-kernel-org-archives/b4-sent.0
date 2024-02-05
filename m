From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 05 Feb 2024 13:09:32 +0100
Subject: [PATCH v2 1/2] driver: core: add dedicated workqueue for devlink
 removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240205-fix-device-links-overlays-v2-1-5344f8c79d57@analog.com>
References: <20240205-fix-device-links-overlays-v2-0-5344f8c79d57@analog.com>
In-Reply-To: <20240205-fix-device-links-overlays-v2-0-5344f8c79d57@analog.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Rob Herring <robh+dt@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, Len Brown <lenb@kernel.org>
Cc: linux-acpi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707134972; l=3618;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=04lEYRnimMPlgUkTJm2JRaX4KnXuISPMtOvIVrmGT4w=;
 b=lwfkR/KxiRZUJunDSN14CeU4IP626N9hjJ6EcdvfTO3/wwBg6qH6hBZdyr82MOG6KDrEutXuL
 YwtUzVGk2I6DoMF8F9GU7korVSTuKL/kHovORS5XXoFa5y3Tbg+Bjzz
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let's use a dedicated queue for devlinks since releasing a link happens
asynchronously but some code paths, like DT overlays, have some
expectations regarding the of_node when being removed (the refcount must
be 1). Given how devlinks are released that cannot be assured. Hence, add a
dedicated queue so that it's easy to sync against devlinks removal.

While at it, make sure to explicitly include <linux/workqueue.h>.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/base/core.c    | 32 ++++++++++++++++++++++++++++----
 include/linux/fwnode.h |  1 +
 2 files changed, 29 insertions(+), 4 deletions(-)

diff --git a/drivers/base/core.c b/drivers/base/core.c
index 14d46af40f9a..4bb9c10489ed 100644
--- a/drivers/base/core.c
+++ b/drivers/base/core.c
@@ -31,6 +31,7 @@
 #include <linux/swiotlb.h>
 #include <linux/sysfs.h>
 #include <linux/dma-map-ops.h> /* for dma_default_coherent */
+#include <linux/workqueue.h>
 
 #include "base.h"
 #include "physical_location.h"
@@ -44,6 +45,7 @@ static bool fw_devlink_is_permissive(void);
 static void __fw_devlink_link_to_consumers(struct device *dev);
 static bool fw_devlink_drv_reg_done;
 static bool fw_devlink_best_effort;
+static struct workqueue_struct *devlink_release_queue __ro_after_init;
 
 /**
  * __fwnode_link_add - Create a link between two fwnode_handles.
@@ -235,6 +237,12 @@ static void __fw_devlink_pickup_dangling_consumers(struct fwnode_handle *fwnode,
 		__fw_devlink_pickup_dangling_consumers(child, new_sup);
 }
 
+void fwnode_links_flush_queue(void)
+{
+	if (devlink_release_queue)
+		flush_workqueue(devlink_release_queue);
+}
+
 static DEFINE_MUTEX(device_links_lock);
 DEFINE_STATIC_SRCU(device_links_srcu);
 
@@ -531,9 +539,13 @@ static void devlink_dev_release(struct device *dev)
 	 * It may take a while to complete this work because of the SRCU
 	 * synchronization in device_link_release_fn() and if the consumer or
 	 * supplier devices get deleted when it runs, so put it into the "long"
-	 * workqueue.
+	 * devlink workqueue (in case we could allocate one).
+	 *
 	 */
-	queue_work(system_long_wq, &link->rm_work);
+	if (devlink_release_queue)
+		queue_work(devlink_release_queue, &link->rm_work);
+	else
+		device_link_release_fn(&link->rm_work);
 }
 
 static struct class devlink_class = {
@@ -636,10 +648,22 @@ static int __init devlink_class_init(void)
 		return ret;
 
 	ret = class_interface_register(&devlink_class_intf);
-	if (ret)
+	if (ret) {
 		class_unregister(&devlink_class);
+		return ret;
+	}
 
-	return ret;
+	/*
+	 * Using a dedicated queue for devlinks since releasing a link happens
+	 * asynchronously but some code paths, like DT overlays, have some
+	 * expectations regarding the of_node when being removed (the refcount
+	 * must be 1). Given how devlinks are released that cannot be assured.
+	 * Hence, add a dedicated queue so that it's easy to sync against
+	 * devlinks removal.
+	 */
+	devlink_release_queue = alloc_workqueue("devlink_release", 0, 0);
+
+	return 0;
 }
 postcore_initcall(devlink_class_init);
 
diff --git a/include/linux/fwnode.h b/include/linux/fwnode.h
index 2a72f55d26eb..017b170e9903 100644
--- a/include/linux/fwnode.h
+++ b/include/linux/fwnode.h
@@ -213,5 +213,6 @@ extern bool fw_devlink_is_strict(void);
 int fwnode_link_add(struct fwnode_handle *con, struct fwnode_handle *sup);
 void fwnode_links_purge(struct fwnode_handle *fwnode);
 void fw_devlink_purge_absent_suppliers(struct fwnode_handle *fwnode);
+void fwnode_links_flush_queue(void);
 
 #endif

-- 
2.43.0

