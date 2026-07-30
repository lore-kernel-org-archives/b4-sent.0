From: Mayank Rungta <mrungta@google.com>
Date: Thu, 30 Jul 2026 14:32:47 -0700
Subject: [PATCH 1/3] watchdog: pretimeout: Protect governor access with RCU
 for NMI safety
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-qcom-wdt-nmi-series-v1-1-3aa86d162914@google.com>
References: <20260730-qcom-wdt-nmi-series-v1-0-3aa86d162914@google.com>
In-Reply-To: <20260730-qcom-wdt-nmi-series-v1-0-3aa86d162914@google.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Thomas Gleixner <tglx@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, "Kirill A. Shutemov" <kas@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Mayank Rungta <mrungta@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785447181; l=5501;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=t15zeyq+anv1jyLmU9IhJu5FkHd+UAFnOQxcFThkG6g=;
 b=4P0XcbDQ2Y3bMFQNv+aooTAQ5h4ldPDHwhU+VAyjvFit6G/6Ju8Op0YQv+iwd1O/Wb74hSZh7
 DBZxfhl2hIVBE5U4ZLMnOuwAGztELa20bJzTr+100A9mIUGEg3kCBys
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, watchdog_notify_pretimeout() acquires pretimeout_lock using
spin_lock_irqsave() to safely dereference wdd->gov before invoking the
pretimeout callback.

On architectures supporting pseudo-NMIs (ARM64 GICv3), watchdog drivers
may register their pretimeout warning interrupt (bark) as an NMI.
Because spin_lock_irqsave() disables regular interrupts but leaves NMIs
unmasked, if a pretimeout NMI fires while pretimeout_lock is already
held by normal process context, attempting to re-acquire pretimeout_lock
triggers an unrecoverable deadlock.

To make pretimeout notifications completely safe to execute from NMI,
convert read access to wdd->gov inside watchdog_notify_pretimeout() from
a spinlock to lockless RCU. Use rcu_assign_pointer() when modifying
wdd->gov and invoke synchronize_rcu() during governor unregister and
pretimeout unregister routines.

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
 drivers/watchdog/watchdog_pretimeout.c | 47 +++++++++++++++++++---------------
 include/linux/watchdog.h               |  2 +-
 2 files changed, 27 insertions(+), 22 deletions(-)

diff --git a/drivers/watchdog/watchdog_pretimeout.c b/drivers/watchdog/watchdog_pretimeout.c
index 02e09b9e396d..3793d4cb60f8 100644
--- a/drivers/watchdog/watchdog_pretimeout.c
+++ b/drivers/watchdog/watchdog_pretimeout.c
@@ -4,6 +4,7 @@
  */
 
 #include <linux/list.h>
+#include <linux/rcupdate.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
 #include <linux/string.h>
@@ -17,7 +18,7 @@
 /* Default watchdog pretimeout governor */
 static struct watchdog_governor *default_gov;
 
-/* The spinlock protects default_gov, wdd->gov and pretimeout_list */
+/* The spinlock protects default_gov and pretimeout_list */
 static DEFINE_SPINLOCK(pretimeout_lock);
 
 /* List of watchdog devices, which can generate a pretimeout event */
@@ -67,12 +68,14 @@ int watchdog_pretimeout_available_governors_get(char *buf)
 
 int watchdog_pretimeout_governor_get(struct watchdog_device *wdd, char *buf)
 {
+	struct watchdog_governor *gov;
 	int count = 0;
 
-	spin_lock_irq(&pretimeout_lock);
-	if (wdd->gov)
-		count = sysfs_emit(buf, "%s\n", wdd->gov->name);
-	spin_unlock_irq(&pretimeout_lock);
+	rcu_read_lock();
+	gov = rcu_dereference(wdd->gov);
+	if (gov)
+		count = sysfs_emit(buf, "%s\n", gov->name);
+	rcu_read_unlock();
 
 	return count;
 }
@@ -91,7 +94,7 @@ int watchdog_pretimeout_governor_set(struct watchdog_device *wdd,
 	}
 
 	spin_lock_irq(&pretimeout_lock);
-	wdd->gov = priv->gov;
+	rcu_assign_pointer(wdd->gov, priv->gov);
 	spin_unlock_irq(&pretimeout_lock);
 
 	mutex_unlock(&governor_lock);
@@ -101,16 +104,13 @@ int watchdog_pretimeout_governor_set(struct watchdog_device *wdd,
 
 void watchdog_notify_pretimeout(struct watchdog_device *wdd)
 {
-	unsigned long flags;
+	struct watchdog_governor *gov;
 
-	spin_lock_irqsave(&pretimeout_lock, flags);
-	if (!wdd->gov) {
-		spin_unlock_irqrestore(&pretimeout_lock, flags);
-		return;
-	}
-
-	wdd->gov->pretimeout(wdd);
-	spin_unlock_irqrestore(&pretimeout_lock, flags);
+	rcu_read_lock();
+	gov = rcu_dereference(wdd->gov);
+	if (gov)
+		gov->pretimeout(wdd);
+	rcu_read_unlock();
 }
 EXPORT_SYMBOL_GPL(watchdog_notify_pretimeout);
 
@@ -140,8 +140,8 @@ int watchdog_register_governor(struct watchdog_governor *gov)
 		default_gov = gov;
 
 		list_for_each_entry(p, &pretimeout_list, entry)
-			if (!p->wdd->gov)
-				p->wdd->gov = default_gov;
+			if (!rcu_access_pointer(p->wdd->gov))
+				rcu_assign_pointer(p->wdd->gov, default_gov);
 		spin_unlock_irq(&pretimeout_lock);
 	}
 
@@ -170,11 +170,14 @@ void watchdog_unregister_governor(struct watchdog_governor *gov)
 	if (default_gov == gov)
 		default_gov = NULL;
 	list_for_each_entry(p, &pretimeout_list, entry)
-		if (p->wdd->gov == gov)
-			p->wdd->gov = default_gov;
+		if (rcu_dereference_protected(p->wdd->gov,
+					      lockdep_is_held(&pretimeout_lock)) == gov)
+			rcu_assign_pointer(p->wdd->gov, default_gov);
 	spin_unlock_irq(&pretimeout_lock);
 
 	mutex_unlock(&governor_lock);
+
+	synchronize_rcu();
 }
 EXPORT_SYMBOL(watchdog_unregister_governor);
 
@@ -192,7 +195,7 @@ int watchdog_register_pretimeout(struct watchdog_device *wdd)
 	spin_lock_irq(&pretimeout_lock);
 	list_add(&p->entry, &pretimeout_list);
 	p->wdd = wdd;
-	wdd->gov = default_gov;
+	rcu_assign_pointer(wdd->gov, default_gov);
 	spin_unlock_irq(&pretimeout_lock);
 
 	return 0;
@@ -206,7 +209,7 @@ void watchdog_unregister_pretimeout(struct watchdog_device *wdd)
 		return;
 
 	spin_lock_irq(&pretimeout_lock);
-	wdd->gov = NULL;
+	rcu_assign_pointer(wdd->gov, NULL);
 
 	list_for_each_entry_safe(p, t, &pretimeout_list, entry) {
 		if (p->wdd == wdd) {
@@ -216,4 +219,6 @@ void watchdog_unregister_pretimeout(struct watchdog_device *wdd)
 		}
 	}
 	spin_unlock_irq(&pretimeout_lock);
+
+	synchronize_rcu();
 }
diff --git a/include/linux/watchdog.h b/include/linux/watchdog.h
index 29cd03686154..5a3c35968cc8 100644
--- a/include/linux/watchdog.h
+++ b/include/linux/watchdog.h
@@ -105,7 +105,7 @@ struct watchdog_device {
 	const struct attribute_group **groups;
 	const struct watchdog_info *info;
 	const struct watchdog_ops *ops;
-	const struct watchdog_governor *gov;
+	const struct watchdog_governor __rcu *gov;
 	unsigned int bootstatus;
 	unsigned int timeout;
 	unsigned int pretimeout;

-- 
2.55.0.508.g3f0d502094-goog

