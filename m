From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 20:55:17 -0400
Subject: [PATCH] soc: xilinx: xlnx_event_manager: protect the registration
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-xlnx-event-v1-1-e0a62b9bd785@vt.edu>
X-B4-Tracking: v=1; b=H4sIAPTRsWoC/yXMwQ6CMBAE0F8he3ZNKUTBXzEeunWVNbqaFpsmh
 H+3xeObzMwCkYNwhFOzQOAkUd5a0O4a8JPTO6Nci8EaezCjbfFFmJ+akRPrjANb6qkbDNEIZfM
 JfJO8/Z0vf8cvPdjP9aQ2yEVGCk79VKON6bjvMPge1vUHdVu0hpEAAAA=
X-Change-ID: 20260921-mb-xlnx-event-8e2b4b380bb9
To: Michal Simek <michal.simek@amd.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790038519; l=14636;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=2FhiPy8TQSKIt73xgcEyqVI5ArjGi5istvRlySD3F0U=;
 b=ozXzmMi6Fimy9dqeMTRjpCzApeRg6eQeLf1V4QQRWyWhukrragqq6x54lLZ1vyj3kc13JG88s
 UwQG45/OwXIC+Cee6Z9EFsvZ/Ja6rkaF5CXTUBad5JhL1d5zUrfT7N1
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xlnx_register_event() and xlnx_unregister_event() modify reg_driver_map
and the per-event callback lists with hash_add(), list_add(), hash_del()
and list_del(), taking no lock. xlnx_event_handler() walks the same
table and lists from the SGI, on whichever CPU the firmware raised it,
also without a lock, and calls the registered callbacks.

Once the first event is registered with the firmware the SGI can arrive
at any time, including while versal_edac or zynqmp_power registers
further events. hlist_add_head() and list_add() are plain stores, so the
handler can see a node before its key, flags, list head or callback
pointer are visible, and call through a pointer it reads as NULL. Two
registrations hashing to the same bucket corrupt it outright.

Serialise the writers with a spinlock and walk the table and the lists
under RCU in the handler. hash_add_rcu() and list_add_rcu() publish the
entries, removed entries are freed with kfree_rcu(), and the allocations
move in front of the critical section so that they keep using
GFP_KERNEL. The lock is taken with interrupts disabled because the
handler removes entries when re-registration with the firmware fails.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/soc/xilinx/xlnx_event_manager.c | 183 ++++++++++++++++++++------------
 1 file changed, 116 insertions(+), 67 deletions(-)

diff --git a/drivers/soc/xilinx/xlnx_event_manager.c b/drivers/soc/xilinx/xlnx_event_manager.c
index f733dc42b..157051e45 100644
--- a/drivers/soc/xilinx/xlnx_event_manager.c
+++ b/drivers/soc/xilinx/xlnx_event_manager.c
@@ -18,7 +18,9 @@
 #include <linux/module.h>
 #include <linux/of_irq.h>
 #include <linux/platform_device.h>
+#include <linux/rcupdate.h>
 #include <linux/slab.h>
+#include <linux/spinlock.h>
 
 static DEFINE_PER_CPU_READ_MOSTLY(int, dummy_cpu_number);
 
@@ -39,6 +41,11 @@ static int event_manager_availability = -EACCES;
 #define REGISTER_NOTIFIER_FIRMWARE_VERSION	(2U)
 
 static DEFINE_HASHTABLE(reg_driver_map, REGISTERED_DRIVER_MAX_ORDER);
+/*
+ * Serialises insertions into and removals from reg_driver_map and the
+ * per-event callback lists. The SGI handler walks both under RCU.
+ */
+static DEFINE_SPINLOCK(reg_driver_map_lock);
 static int sgi_num = XLNX_EVENT_SGI_NUM;
 
 static bool is_need_to_unregister;
@@ -48,11 +55,13 @@ static bool is_need_to_unregister;
  * @agent_data:		Data passed back to handler function.
  * @eve_cb:		Function pointer to store the callback function.
  * @list:		member to create list.
+ * @rcu:		used to free the callback after a grace period.
  */
 struct agent_cb {
 	void *agent_data;
 	event_cb_func_t eve_cb;
 	struct list_head list;
+	struct rcu_head rcu;
 };
 
 /**
@@ -66,6 +75,7 @@ struct agent_cb {
  * @cb_list_head:	Head of call back data list which contain the information
  *			about registered handler and private data.
  * @hentry:		hlist_node that hooks this entry into hashtable.
+ * @rcu:		used to free the entry after a grace period.
  */
 struct registered_event_data {
 	u64 key;
@@ -73,6 +83,7 @@ struct registered_event_data {
 	bool wake;
 	struct list_head cb_list_head;
 	struct hlist_node hentry;
+	struct rcu_head rcu;
 };
 
 static bool xlnx_is_error_event(const u32 node_id)
@@ -104,14 +115,27 @@ static bool xlnx_is_error_event(const u32 node_id)
 static int xlnx_add_cb_for_notify_event(const u32 node_id, const u32 event, const bool wake,
 					event_cb_func_t cb_fun,	void *data)
 {
-	u64 key = 0;
+	u64 key = ((u64)node_id << 32U) | (u64)event;
 	bool present_in_hash = false;
-	struct registered_event_data *eve_data;
+	struct registered_event_data *eve_data, *new_eve_data;
 	struct agent_cb *cb_data;
 	struct agent_cb *cb_pos;
-	struct agent_cb *cb_next;
+	unsigned long flags;
+
+	/* Allocate up front: the hash table is updated under a spinlock */
+	new_eve_data = kmalloc_obj(*new_eve_data);
+	if (!new_eve_data)
+		return -ENOMEM;
+
+	cb_data = kmalloc_obj(*cb_data);
+	if (!cb_data) {
+		kfree(new_eve_data);
+		return -ENOMEM;
+	}
+	cb_data->eve_cb = cb_fun;
+	cb_data->agent_data = data;
 
-	key = ((u64)node_id << 32U) | (u64)event;
+	spin_lock_irqsave(&reg_driver_map_lock, flags);
 	/* Check for existing entry in hash table for given key id */
 	hash_for_each_possible(reg_driver_map, eve_data, hentry, key) {
 		if (eve_data->key == key) {
@@ -122,85 +146,94 @@ static int xlnx_add_cb_for_notify_event(const u32 node_id, const u32 event, cons
 
 	if (!present_in_hash) {
 		/* Add new entry if not present in HASH table */
-		eve_data = kmalloc_obj(*eve_data);
-		if (!eve_data)
-			return -ENOMEM;
+		eve_data = new_eve_data;
+		new_eve_data = NULL;
 		eve_data->key = key;
 		eve_data->cb_type = PM_NOTIFY_CB;
 		eve_data->wake = wake;
 		INIT_LIST_HEAD(&eve_data->cb_list_head);
 
-		cb_data = kmalloc_obj(*cb_data);
-		if (!cb_data) {
-			kfree(eve_data);
-			return -ENOMEM;
-		}
-		cb_data->eve_cb = cb_fun;
-		cb_data->agent_data = data;
-
 		/* Add into callback list */
-		list_add(&cb_data->list, &eve_data->cb_list_head);
-
-		/* Add into HASH table */
-		hash_add(reg_driver_map, &eve_data->hentry, key);
+		list_add_rcu(&cb_data->list, &eve_data->cb_list_head);
+		cb_data = NULL;
+
+		/*
+		 * Add into HASH table. hash_add_rcu() publishes the entry with
+		 * release semantics, so the SGI handler, which walks the table
+		 * without the lock, sees the key, the flags and the callback
+		 * list only once they have been written.
+		 */
+		hash_add_rcu(reg_driver_map, &eve_data->hentry, key);
 	} else {
 		/* Search for callback function and private data in list */
-		list_for_each_entry_safe(cb_pos, cb_next, &eve_data->cb_list_head, list) {
+		list_for_each_entry(cb_pos, &eve_data->cb_list_head, list) {
 			if (cb_pos->eve_cb == cb_fun &&
-			    cb_pos->agent_data == data) {
-				return 0;
-			}
+			    cb_pos->agent_data == data)
+				goto out;
 		}
 
 		/* Add multiple handler and private data in list */
-		cb_data = kmalloc_obj(*cb_data);
-		if (!cb_data)
-			return -ENOMEM;
-		cb_data->eve_cb = cb_fun;
-		cb_data->agent_data = data;
-
-		list_add(&cb_data->list, &eve_data->cb_list_head);
+		list_add_rcu(&cb_data->list, &eve_data->cb_list_head);
+		cb_data = NULL;
 	}
 
+out:
+	spin_unlock_irqrestore(&reg_driver_map_lock, flags);
+	kfree(new_eve_data);
+	kfree(cb_data);
+
 	return 0;
 }
 
 static int xlnx_add_cb_for_suspend(event_cb_func_t cb_fun, void *data)
 {
-	struct registered_event_data *eve_data;
+	struct registered_event_data *eve_data, *new_eve_data;
 	struct agent_cb *cb_data;
+	unsigned long flags;
+	int ret = 0;
 
+	/* Allocate up front: the hash table is updated under a spinlock */
+	new_eve_data = kmalloc_obj(*new_eve_data);
+	if (!new_eve_data)
+		return -ENOMEM;
+
+	cb_data = kmalloc_obj(*cb_data);
+	if (!cb_data) {
+		kfree(new_eve_data);
+		return -ENOMEM;
+	}
+	cb_data->eve_cb = cb_fun;
+	cb_data->agent_data = data;
+
+	spin_lock_irqsave(&reg_driver_map_lock, flags);
 	/* Check for existing entry in hash table for given cb_type */
 	hash_for_each_possible(reg_driver_map, eve_data, hentry, PM_INIT_SUSPEND_CB) {
 		if (eve_data->cb_type == PM_INIT_SUSPEND_CB) {
 			pr_err("Found as already registered\n");
-			return -EINVAL;
+			ret = -EINVAL;
+			goto out;
 		}
 	}
 
 	/* Add new entry if not present */
-	eve_data = kmalloc_obj(*eve_data);
-	if (!eve_data)
-		return -ENOMEM;
-
+	eve_data = new_eve_data;
+	new_eve_data = NULL;
 	eve_data->key = 0;
 	eve_data->cb_type = PM_INIT_SUSPEND_CB;
 	INIT_LIST_HEAD(&eve_data->cb_list_head);
 
-	cb_data = kmalloc_obj(*cb_data);
-	if (!cb_data) {
-		kfree(eve_data);
-		return -ENOMEM;
-	}
-	cb_data->eve_cb = cb_fun;
-	cb_data->agent_data = data;
-
 	/* Add into callback list */
-	list_add(&cb_data->list, &eve_data->cb_list_head);
+	list_add_rcu(&cb_data->list, &eve_data->cb_list_head);
+	cb_data = NULL;
 
-	hash_add(reg_driver_map, &eve_data->hentry, PM_INIT_SUSPEND_CB);
+	hash_add_rcu(reg_driver_map, &eve_data->hentry, PM_INIT_SUSPEND_CB);
 
-	return 0;
+out:
+	spin_unlock_irqrestore(&reg_driver_map_lock, flags);
+	kfree(new_eve_data);
+	kfree(cb_data);
+
+	return ret;
 }
 
 static int xlnx_remove_cb_for_suspend(event_cb_func_t cb_fun)
@@ -210,9 +243,11 @@ static int xlnx_remove_cb_for_suspend(event_cb_func_t cb_fun)
 	struct agent_cb *cb_pos;
 	struct agent_cb *cb_next;
 	struct hlist_node *tmp;
+	unsigned long flags;
 
 	is_need_to_unregister = false;
 
+	spin_lock_irqsave(&reg_driver_map_lock, flags);
 	/* Check for existing entry in hash table for given cb_type */
 	hash_for_each_possible_safe(reg_driver_map, eve_data, tmp, hentry, PM_INIT_SUSPEND_CB) {
 		if (eve_data->cb_type == PM_INIT_SUSPEND_CB) {
@@ -220,16 +255,17 @@ static int xlnx_remove_cb_for_suspend(event_cb_func_t cb_fun)
 			list_for_each_entry_safe(cb_pos, cb_next, &eve_data->cb_list_head, list) {
 				if (cb_pos->eve_cb == cb_fun) {
 					is_callback_found = true;
-					list_del_init(&cb_pos->list);
-					kfree(cb_pos);
+					list_del_rcu(&cb_pos->list);
+					kfree_rcu(cb_pos, rcu);
 				}
 			}
 			/* remove an object from a hashtable */
-			hash_del(&eve_data->hentry);
-			kfree(eve_data);
+			hash_del_rcu(&eve_data->hentry);
+			kfree_rcu(eve_data, rcu);
 			is_need_to_unregister = true;
 		}
 	}
+	spin_unlock_irqrestore(&reg_driver_map_lock, flags);
 	if (!is_callback_found) {
 		pr_warn("Didn't find any registered callback for suspend event\n");
 		return -EINVAL;
@@ -247,9 +283,11 @@ static int xlnx_remove_cb_for_notify_event(const u32 node_id, const u32 event,
 	struct agent_cb *cb_pos;
 	struct agent_cb *cb_next;
 	struct hlist_node *tmp;
+	unsigned long flags;
 
 	is_need_to_unregister = false;
 
+	spin_lock_irqsave(&reg_driver_map_lock, flags);
 	/* Check for existing entry in hash table for given key id */
 	hash_for_each_possible_safe(reg_driver_map, eve_data, tmp, hentry, key) {
 		if (eve_data->key == key) {
@@ -258,20 +296,21 @@ static int xlnx_remove_cb_for_notify_event(const u32 node_id, const u32 event,
 				if (cb_pos->eve_cb == cb_fun &&
 				    cb_pos->agent_data == data) {
 					is_callback_found = true;
-					list_del_init(&cb_pos->list);
-					kfree(cb_pos);
+					list_del_rcu(&cb_pos->list);
+					kfree_rcu(cb_pos, rcu);
 				}
 			}
 
 			/* Remove HASH table if callback list is empty */
 			if (list_empty(&eve_data->cb_list_head)) {
 				/* remove an object from a HASH table */
-				hash_del(&eve_data->hentry);
-				kfree(eve_data);
+				hash_del_rcu(&eve_data->hentry);
+				kfree_rcu(eve_data, rcu);
 				is_need_to_unregister = true;
 			}
 		}
 	}
+	spin_unlock_irqrestore(&reg_driver_map_lock, flags);
 	if (!is_callback_found) {
 		pr_warn("Didn't find any registered callback for 0x%x 0x%x\n",
 			node_id, event);
@@ -445,17 +484,18 @@ static void xlnx_call_suspend_cb_handler(const u32 *payload)
 	struct registered_event_data *eve_data;
 	u32 cb_type = payload[0];
 	struct agent_cb *cb_pos;
-	struct agent_cb *cb_next;
 
 	/* Check for existing entry in hash table for given cb_type */
-	hash_for_each_possible(reg_driver_map, eve_data, hentry, cb_type) {
+	rcu_read_lock();
+	hash_for_each_possible_rcu(reg_driver_map, eve_data, hentry, cb_type) {
 		if (eve_data->cb_type == cb_type) {
-			list_for_each_entry_safe(cb_pos, cb_next, &eve_data->cb_list_head, list) {
+			list_for_each_entry_rcu(cb_pos, &eve_data->cb_list_head, list) {
 				cb_pos->eve_cb(&payload[0], cb_pos->agent_data);
 				is_callback_found = true;
 			}
 		}
 	}
+	rcu_read_unlock();
 	if (!is_callback_found)
 		pr_warn("Didn't find any registered callback for suspend event\n");
 }
@@ -467,12 +507,18 @@ static void xlnx_call_notify_cb_handler(const u32 *payload)
 	u64 key = ((u64)payload[1] << 32U) | (u64)payload[2];
 	int ret;
 	struct agent_cb *cb_pos;
-	struct agent_cb *cb_next;
 
+	/*
+	 * Registration may run on another CPU while this SGI is handled. The
+	 * table and the callback lists are walked under RCU; the writers
+	 * publish entries with hash_add_rcu()/list_add_rcu() and free them
+	 * after a grace period, so an entry is never seen before its fields.
+	 */
+	rcu_read_lock();
 	/* Check for existing entry in hash table for given key id */
-	hash_for_each_possible(reg_driver_map, eve_data, hentry, key) {
+	hash_for_each_possible_rcu(reg_driver_map, eve_data, hentry, key) {
 		if (eve_data->key == key) {
-			list_for_each_entry_safe(cb_pos, cb_next, &eve_data->cb_list_head, list) {
+			list_for_each_entry_rcu(cb_pos, &eve_data->cb_list_head, list) {
 				cb_pos->eve_cb(&payload[0], cb_pos->agent_data);
 				is_callback_found = true;
 			}
@@ -483,8 +529,7 @@ static void xlnx_call_notify_cb_handler(const u32 *payload)
 			if (ret) {
 				pr_err("%s() failed for 0x%x and 0x%x: %d\r\n", __func__,
 				       payload[1], payload[2], ret);
-				list_for_each_entry_safe(cb_pos, cb_next, &eve_data->cb_list_head,
-							 list) {
+				list_for_each_entry_rcu(cb_pos, &eve_data->cb_list_head, list) {
 					/* Remove already registered event from hash table */
 					xlnx_remove_cb_for_notify_event(payload[1], payload[2],
 									cb_pos->eve_cb,
@@ -493,6 +538,7 @@ static void xlnx_call_notify_cb_handler(const u32 *payload)
 			}
 		}
 	}
+	rcu_read_unlock();
 	if (!is_callback_found)
 		pr_warn("Unhandled SGI node 0x%x event 0x%x. Expected with Xen hypervisor\n",
 			payload[1], payload[2]);
@@ -690,15 +736,18 @@ static void xlnx_event_manager_remove(struct platform_device *pdev)
 	int ret;
 	struct agent_cb *cb_pos;
 	struct agent_cb *cb_next;
+	unsigned long flags;
 
+	spin_lock_irqsave(&reg_driver_map_lock, flags);
 	hash_for_each_safe(reg_driver_map, i, tmp, eve_data, hentry) {
 		list_for_each_entry_safe(cb_pos, cb_next, &eve_data->cb_list_head, list) {
-			list_del_init(&cb_pos->list);
-			kfree(cb_pos);
+			list_del_rcu(&cb_pos->list);
+			kfree_rcu(cb_pos, rcu);
 		}
-		hash_del(&eve_data->hentry);
-		kfree(eve_data);
+		hash_del_rcu(&eve_data->hentry);
+		kfree_rcu(eve_data, rcu);
 	}
+	spin_unlock_irqrestore(&reg_driver_map_lock, flags);
 
 	ret = zynqmp_pm_register_sgi(0, 1);
 	if (ret)

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-xlnx-event-8e2b4b380bb9

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

