From: Amit Sunil Dhamne <amitsd@google.com>
Date: Wed, 01 Jul 2026 00:34:18 +0000
Subject: [PATCH v4 1/2] power: supply: Add helpers to get and put arrays of
 power supply handles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260701-batt-status-v4-1-a31d97b1ae57@google.com>
References: <20260701-batt-status-v4-0-a31d97b1ae57@google.com>
In-Reply-To: <20260701-batt-status-v4-0-a31d97b1ae57@google.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Hans de Goede <hansg@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>, 
 Purism Kernel Team <kernel@puri.sm>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>, RD Babiera <rdbabiera@google.com>, 
 Kyle Tso <kyletso@google.com>, Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782866074; l=6221;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=gvdYw83SlBQnEVfW0ZcpDG4WOMw9avUKEx52LOGumVc=;
 b=H32nRc+fa+3ucffN0tuPR0ZsFUV7cTi3WBdtCNh9Mp3KrR/s58OiTkRIUWhYuJa3veQCU6K2/
 aDCyp/1jsJQCR3xNq9VKS9cXClcrX5tclQjG4mj81u0Tn7FEi/NnJcE
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power_supply_get_system_batteries() to allow drivers to obtain
a list of registered battery type power supply references in the
system. Also add power_supply_put_system_batteries() to perform
cleanup after the former function is called.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 drivers/power/supply/power_supply_core.c | 153 +++++++++++++++++++++++++++++++
 include/linux/power_supply.h             |  15 +++
 2 files changed, 168 insertions(+)

diff --git a/drivers/power/supply/power_supply_core.c b/drivers/power/supply/power_supply_core.c
index 2532e221b2e1..70f35f64cc72 100644
--- a/drivers/power/supply/power_supply_core.c
+++ b/drivers/power/supply/power_supply_core.c
@@ -477,6 +477,159 @@ struct power_supply *power_supply_get_by_name(const char *name)
 }
 EXPORT_SYMBOL_GPL(power_supply_get_by_name);
 
+static bool power_supply_is_system_battery(struct power_supply *psy)
+{
+	union power_supply_propval val;
+
+	if (psy->desc->type != POWER_SUPPLY_TYPE_BATTERY)
+		return false;
+
+	if (!power_supply_get_property_direct(psy, POWER_SUPPLY_PROP_SCOPE,
+					      &val))
+		if (val.intval == POWER_SUPPLY_SCOPE_DEVICE)
+			return false;
+
+	return true;
+}
+
+static int __power_supply_get_num_system_batteries(struct power_supply *epsy,
+						   void *data)
+{
+	int *count = data;
+
+	if (power_supply_is_system_battery(epsy))
+		(*count)++;
+
+	return 0;
+}
+
+static int power_supply_get_num_system_batteries(struct device *dev)
+{
+	int ret, count = 0;
+
+	ret = power_supply_for_each_psy(&count,
+					__power_supply_get_num_system_batteries);
+
+	dev_dbg(dev, "%s: count: %d ret %d\n", __func__, count, ret);
+
+	if (ret)
+		return ret;
+
+	return count;
+}
+
+struct psy_get_supplies_data {
+	int cnt;
+	int size;
+	struct power_supply **psys;
+};
+
+static int
+__power_supply_populate_system_batteries_array(struct power_supply *epsy,
+					       void *_data)
+{
+	struct psy_get_supplies_data *data = _data;
+
+	if (power_supply_is_system_battery(epsy)) {
+		if (data->size <= data->cnt)
+			return -EOVERFLOW;
+
+		get_device(&epsy->dev);
+		data->psys[data->cnt] = epsy;
+		atomic_inc(&epsy->use_cnt);
+		data->cnt++;
+	}
+
+	return 0;
+}
+
+static int
+power_supply_populate_system_batteries_array(struct device *dev, int size,
+					     struct power_supply **batteries)
+{
+	int ret;
+
+	struct psy_get_supplies_data data = {
+		.cnt = 0,
+		.size = size,
+		.psys = batteries,
+	};
+
+	ret = power_supply_for_each_psy(&data,
+					__power_supply_populate_system_batteries_array);
+
+	dev_dbg(dev, "%s Found %d batteries with array size %d ret %d\n",
+		__func__, data.cnt, data.size, ret);
+
+	if (ret < 0 || !data.cnt) {
+		power_supply_put_system_batteries(batteries, data.cnt);
+		return ret;
+	}
+
+	return data.cnt;
+}
+
+/**
+ * power_supply_get_system_batteries() - Fetches references to battery type
+ *                                       power supplies in the system.
+ * @dev: Pointer to device requesting the power supply refs.
+ * @psys: Pointer to an array of power supply refs.
+ *
+ * Helper function to get handles to battery type power supplies in the system.
+ * If acquiring a ref to a power supply fails, then the search for battery type
+ * power supplies will abort and the acquired power supply references will be
+ * released.
+ *
+ * Return: Indicates the number of battery type power supplies returned on
+ * success or a negative error code on failure.
+ *
+ * Call power_supply_put_system_batteries() after use to cleanup resources.
+ */
+int __must_check power_supply_get_system_batteries(struct device *dev,
+						   struct power_supply ***psys)
+{
+	int ret;
+
+	if (!psys)
+		return -EINVAL;
+
+	ret = power_supply_get_num_system_batteries(dev);
+	if (ret <= 0) {
+		*psys = NULL;
+		return ret;
+	}
+
+	*psys = kzalloc_objs(**psys, ret);
+	if (!*psys)
+		return -ENOMEM;
+
+	ret = power_supply_populate_system_batteries_array(dev, ret, *psys);
+	if (ret <= 0)
+		*psys = NULL;
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(power_supply_get_system_batteries);
+
+/**
+ * power_supply_put_system_batteries() - Cleanup resources allocated by
+ *                                       power_supply_get_system_batteries()
+ * @psys: Array of power supply references to release and free.
+ * @count: Number of elements in the array.
+ */
+void power_supply_put_system_batteries(struct power_supply **psys, int count)
+{
+	int i;
+
+	for (i = 0; i < count; i++) {
+		if (psys[i])
+			power_supply_put(psys[i]);
+	}
+
+	kfree(psys);
+}
+EXPORT_SYMBOL_GPL(power_supply_put_system_batteries);
+
 /**
  * power_supply_put() - Drop reference obtained with power_supply_get_by_name
  * @psy: Reference to put
diff --git a/include/linux/power_supply.h b/include/linux/power_supply.h
index 7a5e4c3242a0..9167a33d074b 100644
--- a/include/linux/power_supply.h
+++ b/include/linux/power_supply.h
@@ -806,11 +806,26 @@ extern int power_supply_reg_notifier(struct notifier_block *nb);
 extern void power_supply_unreg_notifier(struct notifier_block *nb);
 #if IS_ENABLED(CONFIG_POWER_SUPPLY)
 extern struct power_supply *power_supply_get_by_name(const char *name);
+extern int __must_check power_supply_get_system_batteries(struct device *dev,
+							  struct power_supply ***psys);
+extern void power_supply_put_system_batteries(struct power_supply **psys, int count);
 extern void power_supply_put(struct power_supply *psy);
 #else
 static inline void power_supply_put(struct power_supply *psy) {}
 static inline struct power_supply *power_supply_get_by_name(const char *name)
 { return NULL; }
+static inline int __must_check power_supply_get_system_batteries(struct device *dev,
+								 struct power_supply ***psys)
+{
+	if (psys)
+		*psys = NULL;
+	return 0;
+}
+
+static inline void power_supply_put_system_batteries(struct power_supply **psys,
+						     int count)
+{
+}
 #endif
 extern struct power_supply *power_supply_get_by_reference(struct fwnode_handle *fwnode,
 							  const char *property);

-- 
2.55.0.rc0.799.gd6f94ed593-goog

