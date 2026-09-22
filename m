From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 20:54:00 -0400
Subject: [PATCH] firmware: xilinx: zynqmp: serialise and publish the
 feature check cache
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-zynqmp-fw-v1-1-1b7f9773df46@vt.edu>
X-B4-Tracking: v=1; b=H4sIAKfRsWoC/yXMzQ6CMBAE4Fche3ZNKYjRVzEe+rPImlBxK6AS3
 t0Wj99kZhaIJEwRzsUCQhNHfoSEcleA60y4EbJPBq10o066xN7i9xOe/YDtjMrWlTroxhtvIE0
 GoZbf293l+ncc7Z3cK3/khjWR0IoJrsvRxum4r1BcDev6A+kiiJ+QAAAA
X-Change-ID: 20260921-mb-zynqmp-fw-0b430526dada
To: Michal Simek <michal.simek@amd.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790038443; l=10397;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=ld144bmnJCTHlODiihZvEWWLWKVWTqPEqRizGBX4ouo=;
 b=gDekVjwALg8OAzkZTix3rqQ6vJnBuSRB6bhgsQAHlbptwQJ4BFkw8/PCNVboPQa3CJyY4bfVr
 OKT+kZ8Uts7Adje9rM5grdhcXAp8ucVxkqK9q/MVowqPbaVGn6TpFOX
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Every firmware call reaches do_feature_check_call() through
zynqmp_pm_invoke_fn() and zynqmp_pm_feature(). It caches the firmware's
answers in pm_api_features_map and extends that hash table on a miss
with hash_add(), taking no lock. Clock, pinctrl, reset, power domain and
GPIO operations all reach it, from any CPU, concurrently.

Two CPUs that miss on the same bucket both call hlist_add_head() on it
and corrupt the list. hash_add() is also a plain store of the node
pointer, so a CPU walking the bucket can see the node before pm_api_id
and feature_status are visible and return an answer meant for a
different API. The IOCTL and QUERY masks are copied into ioctl_features
and query_features after the entry is published, so
zynqmp_pm_is_function_supported() can find the entry and read an all
zero mask, reporting every IOCTL as unsupported.

Serialise insertions with a spinlock, recheck the bucket under it and
publish with hash_add_rcu(). Look up under rcu_read_lock() with
hash_for_each_possible_rcu(). Move the IOCTL and QUERY masks into the
entry so that they are published with it, and free entries with
kfree_rcu().

The lock is taken with interrupts disabled because firmware calls are
made from atomic context, for example under the clock enable lock.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/firmware/xilinx/zynqmp.c | 108 +++++++++++++++++++++++++++++----------
 1 file changed, 80 insertions(+), 28 deletions(-)

diff --git a/drivers/firmware/xilinx/zynqmp.c b/drivers/firmware/xilinx/zynqmp.c
index fe650747a..3d395d5a4 100644
--- a/drivers/firmware/xilinx/zynqmp.c
+++ b/drivers/firmware/xilinx/zynqmp.c
@@ -25,6 +25,8 @@
 #include <linux/slab.h>
 #include <linux/uaccess.h>
 #include <linux/hashtable.h>
+#include <linux/rcupdate.h>
+#include <linux/spinlock.h>
 
 #include <linux/firmware/xlnx-zynqmp.h>
 #include <linux/firmware/xlnx-event-manager.h>
@@ -45,8 +47,8 @@
 
 static bool feature_check_enabled;
 static DEFINE_HASHTABLE(pm_api_features_map, PM_API_FEATURE_CHECK_MAX_ORDER);
-static u32 ioctl_features[FEATURE_PAYLOAD_SIZE];
-static u32 query_features[FEATURE_PAYLOAD_SIZE];
+/* Serialises insertions into pm_api_features_map; lookups run under RCU. */
+static DEFINE_SPINLOCK(pm_api_features_lock);
 
 static u32 sip_svc_version;
 static struct platform_device *em_dev;
@@ -65,12 +67,16 @@ struct zynqmp_devinfo {
  * struct pm_api_feature_data - PM API Feature data
  * @pm_api_id:		PM API Id, used as key to index into hashmap
  * @feature_status:	status of PM API feature: valid, invalid
+ * @features:		supported IOCTL/QUERY IDs mask reported by the firmware
  * @hentry:		hlist_node that hooks this entry into hashtable
+ * @rcu:		used to free the entry after a grace period
  */
 struct pm_api_feature_data {
 	u32 pm_api_id;
 	int feature_status;
+	u32 features[FEATURE_PAYLOAD_SIZE];
 	struct hlist_node hentry;
+	struct rcu_head rcu;
 };
 
 struct platform_fw_data {
@@ -257,18 +263,46 @@ static int __do_feature_check_call(const u32 api_id, u32 *ret_payload)
 	return ret_payload[1];
 }
 
-static int do_feature_check_call(const u32 api_id)
+/*
+ * Look up the cached firmware answer for @api_id. Called under
+ * rcu_read_lock() or with pm_api_features_lock held.
+ */
+static struct pm_api_feature_data *pm_api_feature_lookup(const u32 api_id)
+{
+	struct pm_api_feature_data *feature_data;
+
+	hash_for_each_possible_rcu(pm_api_features_map, feature_data, hentry,
+				   api_id, lockdep_is_held(&pm_api_features_lock)) {
+		if (feature_data->pm_api_id == api_id)
+			return feature_data;
+	}
+
+	return NULL;
+}
+
+/*
+ * Return the feature status of @api_id, asking the firmware on the first
+ * call. When @features is not NULL, the IOCTL/QUERY ID mask the firmware
+ * reported for @api_id is copied into it.
+ */
+static int do_feature_check_call(const u32 api_id, u32 *features)
 {
 	int ret;
 	u32 ret_payload[PAYLOAD_ARG_CNT];
-	struct pm_api_feature_data *feature_data;
+	struct pm_api_feature_data *feature_data, *found;
+	unsigned long flags;
 
 	/* Check for existing entry in hash table for given api */
-	hash_for_each_possible(pm_api_features_map, feature_data, hentry,
-			       api_id) {
-		if (feature_data->pm_api_id == api_id)
-			return feature_data->feature_status;
+	rcu_read_lock();
+	found = pm_api_feature_lookup(api_id);
+	if (found) {
+		ret = found->feature_status;
+		if (features)
+			memcpy(features, found->features, sizeof(found->features));
+		rcu_read_unlock();
+		return ret;
 	}
+	rcu_read_unlock();
 
 	/* Add new entry if not present */
 	feature_data = kmalloc_obj(*feature_data, GFP_ATOMIC);
@@ -277,16 +311,33 @@ static int do_feature_check_call(const u32 api_id)
 
 	feature_data->pm_api_id = api_id;
 	ret = __do_feature_check_call(api_id, ret_payload);
-
 	feature_data->feature_status = ret;
-	hash_add(pm_api_features_map, &feature_data->hentry, api_id);
+	/* Supported IOCTL/QUERY IDs mask, meaningful for PM_IOCTL and PM_QUERY_DATA */
+	memcpy(feature_data->features, &ret_payload[2], sizeof(feature_data->features));
+
+	/*
+	 * Firmware calls are made from any CPU without a common lock, so a
+	 * concurrent caller may have added an entry for the same API while the
+	 * firmware was being asked. Insert under pm_api_features_lock and
+	 * recheck. hash_add_rcu() publishes the entry with release semantics,
+	 * which pairs with the rcu_dereference() in the lockless lookup above,
+	 * so a reader never sees the entry before its fields.
+	 */
+	spin_lock_irqsave(&pm_api_features_lock, flags);
+	found = pm_api_feature_lookup(api_id);
+	if (found) {
+		ret = found->feature_status;
+		if (features)
+			memcpy(features, found->features, sizeof(found->features));
+		spin_unlock_irqrestore(&pm_api_features_lock, flags);
+		kfree(feature_data);
+		return ret;
+	}
+	hash_add_rcu(pm_api_features_map, &feature_data->hentry, api_id);
+	spin_unlock_irqrestore(&pm_api_features_lock, flags);
 
-	if (api_id == PM_IOCTL)
-		/* Store supported IOCTL IDs mask */
-		memcpy(ioctl_features, &ret_payload[2], FEATURE_PAYLOAD_SIZE * 4);
-	else if (api_id == PM_QUERY_DATA)
-		/* Store supported QUERY IDs mask */
-		memcpy(query_features, &ret_payload[2], FEATURE_PAYLOAD_SIZE * 4);
+	if (features)
+		memcpy(features, &ret_payload[2], sizeof(feature_data->features));
 
 	return ret;
 }
@@ -305,7 +356,7 @@ int zynqmp_pm_feature(const u32 api_id)
 	if (!feature_check_enabled)
 		return 0;
 
-	ret = do_feature_check_call(api_id);
+	ret = do_feature_check_call(api_id, NULL);
 
 	return ret;
 }
@@ -322,14 +373,14 @@ EXPORT_SYMBOL_GPL(zynqmp_pm_feature);
 int zynqmp_pm_is_function_supported(const u32 api_id, const u32 id)
 {
 	int ret;
-	u32 *bit_mask;
+	u32 bit_mask[FEATURE_PAYLOAD_SIZE];
 
 	/* Input arguments validation */
 	if (id >= 64 || (api_id != PM_IOCTL && api_id != PM_QUERY_DATA))
 		return -EINVAL;
 
 	/* Check feature check API version */
-	ret = do_feature_check_call(PM_FEATURE_CHECK);
+	ret = do_feature_check_call(PM_FEATURE_CHECK, NULL);
 	if (ret < 0)
 		return ret;
 
@@ -339,12 +390,10 @@ int zynqmp_pm_is_function_supported(const u32 api_id, const u32 id)
 		 * Call feature check for IOCTL/QUERY API to get IOCTL ID or
 		 * QUERY ID feature status.
 		 */
-		ret = do_feature_check_call(api_id);
+		ret = do_feature_check_call(api_id, bit_mask);
 		if (ret < 0)
 			return ret;
 
-		bit_mask = (api_id == PM_IOCTL) ? ioctl_features : query_features;
-
 		if ((bit_mask[(id / 32)] & BIT((id % 32))) == 0U)
 			return -EOPNOTSUPP;
 	} else {
@@ -2184,7 +2233,7 @@ static int zynqmp_clear_pm_state(struct device *dev)
 	if (pm_family_code == PM_VERSAL_FAMILY_CODE ||
 	    pm_family_code == PM_VERSAL_NET_FAMILY_CODE) {
 		/* Check if EL3 firmware supports TF_A_CLEAR_PM_STATE */
-		ret = do_feature_check_call(TF_A_CLEAR_PM_STATE);
+		ret = do_feature_check_call(TF_A_CLEAR_PM_STATE, NULL);
 		if (ret >= 0 && ((ret & FIRMWARE_VERSION_MASK) >= PM_API_VERSION_1)) {
 			/* Clear PM specific data in EL3 firmware */
 			ret = zynqmp_pm_invoke_fn(TF_A_CLEAR_PM_STATE, NULL, 0);
@@ -2197,7 +2246,7 @@ static int zynqmp_clear_pm_state(struct device *dev)
 		}
 
 		/* Check if the firmware supports the PM_DEV_ALL_PERIPH node ID */
-		ret = do_feature_check_call(PM_RELEASE_NODE);
+		ret = do_feature_check_call(PM_RELEASE_NODE, NULL);
 		if (ret >= 0 && ((ret & FIRMWARE_VERSION_MASK) >= PM_API_VERSION_3)) {
 			/* Attempt to release all peripheral devices via firmware */
 			ret = zynqmp_pm_release_node(PM_DEV_ALL_PERIPH);
@@ -2210,7 +2259,7 @@ static int zynqmp_clear_pm_state(struct device *dev)
 		}
 
 		/* Check if the firmware supports the PM_ALL_NOTIFIERS node ID */
-		ret = do_feature_check_call(PM_REGISTER_NOTIFIER);
+		ret = do_feature_check_call(PM_REGISTER_NOTIFIER, NULL);
 		if (ret >= 0 && ((ret & FIRMWARE_VERSION_MASK) >= PM_API_VERSION_3)) {
 			/* Attempt to unregister all notifier callbacks via firmware */
 			ret = zynqmp_pm_register_notifier(PM_ALL_NOTIFIERS, 0, 0, 0);
@@ -2248,7 +2297,7 @@ static int zynqmp_firmware_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	ret = do_feature_check_call(PM_FEATURE_CHECK);
+	ret = do_feature_check_call(PM_FEATURE_CHECK, NULL);
 	if (ret >= 0 && ((ret & FIRMWARE_VERSION_MASK) >= PM_API_VERSION_1))
 		feature_check_enabled = true;
 
@@ -2325,15 +2374,18 @@ static void zynqmp_firmware_remove(struct platform_device *pdev)
 {
 	struct pm_api_feature_data *feature_data;
 	struct hlist_node *tmp;
+	unsigned long flags;
 	int i;
 
 	mfd_remove_devices(&pdev->dev);
 	zynqmp_pm_api_debugfs_exit();
 
+	spin_lock_irqsave(&pm_api_features_lock, flags);
 	hash_for_each_safe(pm_api_features_map, i, tmp, feature_data, hentry) {
-		hash_del(&feature_data->hentry);
-		kfree(feature_data);
+		hash_del_rcu(&feature_data->hentry);
+		kfree_rcu(feature_data, rcu);
 	}
+	spin_unlock_irqrestore(&pm_api_features_lock, flags);
 
 	platform_device_unregister(em_dev);
 }

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-zynqmp-fw-0b430526dada

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

