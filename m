From: Amit Sunil Dhamne <amitsd@google.com>
Date: Wed, 07 May 2025 18:00:23 -0700
Subject: [PATCH v2 2/5] power: supply: core: add helper to get power supply
 given a fwnode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250507-batt_ops-v2-2-8d06130bffe6@google.com>
References: <20250507-batt_ops-v2-0-8d06130bffe6@google.com>
In-Reply-To: <20250507-batt_ops-v2-0-8d06130bffe6@google.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Sebastian Reichel <sre@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <len.brown@intel.com>, 
 Pavel Machek <pavel@kernel.org>
Cc: Kyle Tso <kyletso@google.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-pm@vger.kernel.org, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746666154; l=2859;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=n/LuhXwbMG+uq2FAx4zj5314rxmEnmyuEdKNHG3ZivU=;
 b=dTaz7OkB3YkPjDneIrBZe+0QEC+/53CmHhzD87wh4fYYWZ7UQ5H7LlQRrclRrlPHTp6tsTyXR
 iV8Z2mcwUyhCP0cZivtxXycLG8L081x/tLWCnn4Bz17G/s19koXnENJ
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a helper function power_supply_get_by_fwnode() to retrieve
power_supply given a valid fwnode reference.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 drivers/power/supply/power_supply_core.c | 30 ++++++++++++++++++++++++++++++
 include/linux/power_supply.h             |  3 +++
 2 files changed, 33 insertions(+)

diff --git a/drivers/power/supply/power_supply_core.c b/drivers/power/supply/power_supply_core.c
index 76c340b38015af0a67a0d91305e6242a8646bf53..ef6ba22b837b0b9463f9a3065425e2720f40b9eb 100644
--- a/drivers/power/supply/power_supply_core.c
+++ b/drivers/power/supply/power_supply_core.c
@@ -496,6 +496,36 @@ struct power_supply *power_supply_get_by_name(const char *name)
 }
 EXPORT_SYMBOL_GPL(power_supply_get_by_name);
 
+static int power_supply_match_device_by_fwnode(struct device *dev, const void *data)
+{
+	return dev->parent && dev_fwnode(dev->parent) == data;
+}
+
+/**
+ * power_supply_get_by_fwnode() - Search for power supply given a fwnode ref.
+ * @fwnode: fwnode reference
+ *
+ * If power supply was found, it increases reference count for the internal
+ * power supply's device. The user should power_supply_put() after use.
+ *
+ * Return: Reference to power_supply node matching the fwnode on success or
+ * NULL on failure.
+ */
+struct power_supply *power_supply_get_by_fwnode(struct fwnode_handle *fwnode)
+{
+	struct power_supply *psy = NULL;
+	struct device *dev = class_find_device(&power_supply_class, NULL, fwnode,
+					       power_supply_match_device_by_fwnode);
+
+	if (dev) {
+		psy = dev_get_drvdata(dev);
+		atomic_inc(&psy->use_cnt);
+	}
+
+	return psy;
+}
+EXPORT_SYMBOL_GPL(power_supply_get_by_fwnode);
+
 /**
  * power_supply_put() - Drop reference obtained with power_supply_get_by_name
  * @psy: Reference to put
diff --git a/include/linux/power_supply.h b/include/linux/power_supply.h
index 6ed53b292162469d7b357734d5589bff18a201d0..a35b08bd368e9305554e1a608dc8e526983cfa12 100644
--- a/include/linux/power_supply.h
+++ b/include/linux/power_supply.h
@@ -801,10 +801,13 @@ extern void power_supply_unreg_notifier(struct notifier_block *nb);
 #if IS_ENABLED(CONFIG_POWER_SUPPLY)
 extern struct power_supply *power_supply_get_by_name(const char *name);
 extern void power_supply_put(struct power_supply *psy);
+extern struct power_supply *power_supply_get_by_fwnode(struct fwnode_handle *fwnode);
 #else
 static inline void power_supply_put(struct power_supply *psy) {}
 static inline struct power_supply *power_supply_get_by_name(const char *name)
 { return NULL; }
+static inline struct power_supply *power_supply_get_by_fwnode(struct fwnode_handle *fwnode)
+{ return NULL; }
 #endif
 #ifdef CONFIG_OF
 extern struct power_supply *power_supply_get_by_phandle(struct device_node *np,

-- 
2.49.0.987.g0cc8ee98dc-goog

