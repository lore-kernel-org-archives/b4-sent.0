From: Amit Sunil Dhamne <amitsd@google.com>
Date: Wed, 27 May 2026 00:02:25 +0000
Subject: [PATCH v2 1/2] power: supply: Add helpers to get and put arrays of
 power supply handles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-batt-status-v2-1-4282985165f3@google.com>
References: <20260527-batt-status-v2-0-4282985165f3@google.com>
In-Reply-To: <20260527-batt-status-v2-0-4282985165f3@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779840151; l=5925;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=ijjk2ySMN0dL36fe0OTjSfQADrJgWHjO1SJEZMi/CKY=;
 b=z2ksABg47kx5ufLiDUjWcv7ibc5t+tO8aEyiWgsPEbXTrAe1ZcTVjXv+QJwGgTDnf0x5u8Bvg
 TPjdPmmxmblBfo0/4sFYAQ1IW2FA2K+gqs9oE7zUtTsH5emfOlMK55B
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power_supply_get_battery_all() to allow drivers to obtain a list of
registered battery type power supply references in the system. Also add
power_supply_put_array() to release references to the power supplies
when no longer needed.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 drivers/power/supply/power_supply_core.c | 137 +++++++++++++++++++++++++++++++
 include/linux/power_supply.h             |  12 +++
 2 files changed, 149 insertions(+)

diff --git a/drivers/power/supply/power_supply_core.c b/drivers/power/supply/power_supply_core.c
index a446d3d086fc..04e5c1083e8f 100644
--- a/drivers/power/supply/power_supply_core.c
+++ b/drivers/power/supply/power_supply_core.c
@@ -482,6 +482,127 @@ struct power_supply *power_supply_get_by_name(const char *name)
 }
 EXPORT_SYMBOL_GPL(power_supply_get_by_name);
 
+static int __power_supply_get_num_battery(struct power_supply *epsy, void *data)
+{
+	int *count = data;
+
+	if (epsy->desc->type == POWER_SUPPLY_TYPE_BATTERY)
+		(*count)++;
+
+	return 0;
+}
+
+static int power_supply_get_num_battery(struct device *dev)
+{
+	int ret, count = 0;
+
+	ret = power_supply_for_each_psy(&count, __power_supply_get_num_battery);
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
+static int __power_supply_populate_battery_array(struct power_supply *epsy,
+						 void *_data)
+{
+	struct psy_get_supplies_data *data = _data;
+
+	if (epsy->desc->type == POWER_SUPPLY_TYPE_BATTERY) {
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
+static int power_supply_populate_battery_array(struct device *dev, int size,
+					       struct power_supply **batteries)
+{
+	int ret;
+
+	struct psy_get_supplies_data data = {
+		.cnt = 0,
+		.size = size,
+		.psys = batteries,
+	};
+
+	ret = power_supply_for_each_psy(&data, __power_supply_populate_battery_array);
+
+	dev_dbg(dev, "%s Found %d batteries with array size %d ret %d\n",
+		__func__, data.cnt, data.size, ret);
+
+	if (ret < 0) {
+		power_supply_put_array(batteries, data.cnt);
+		return ret;
+	}
+
+	return data.cnt;
+}
+
+/**
+ * power_supply_get_battery_all() - Fetches references to all battery type power
+ *                                  supplies.
+ * @dev: Pointer to device requesting the power supply refs.
+ * @psys: Pointer to an array of power supply refs.
+ *
+ * Helper function to get handles to all battery type power supplies.
+ * If acquiring a ref to a power supply fails, then the search for battery
+ * type power supplies will abort and the acquired power supply references will
+ * be released.
+ *
+ * Return: Indicates the number of battery type power supplies returned on
+ * success or a negative error code on failure.
+ *
+ * The caller should invoke power_supply_put_array() on the returned array
+ * of psy refs and free the array returned by this function using kfree()
+ * after use.
+ */
+int __must_check power_supply_get_battery_all(struct device *dev,
+					      struct power_supply ***psys)
+{
+	int ret;
+
+	if (!psys)
+		return -EINVAL;
+
+	ret = power_supply_get_num_battery(dev);
+	if (ret < 0)
+		return ret;
+
+	if (!ret) {
+		*psys = NULL;
+		return 0;
+	}
+
+	*psys = kzalloc_objs(**psys, ret);
+	if (!*psys)
+		return -ENOMEM;
+
+	ret = power_supply_populate_battery_array(dev, ret, *psys);
+	if (ret <= 0) {
+		kfree(*psys);
+		*psys = NULL;
+	}
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(power_supply_get_battery_all);
+
 /**
  * power_supply_put() - Drop reference obtained with power_supply_get_by_name
  * @psy: Reference to put
@@ -496,6 +617,22 @@ void power_supply_put(struct power_supply *psy)
 }
 EXPORT_SYMBOL_GPL(power_supply_put);
 
+/**
+ * power_supply_put_array() - Drop references to an array of power supplies.
+ * @psys: Array of power supply references to put.
+ * @count: Number of elements in the array.
+ */
+void power_supply_put_array(struct power_supply **psys, int count)
+{
+	int i;
+
+	for (i = 0; i < count; i++) {
+		if (psys[i])
+			power_supply_put(psys[i]);
+	}
+}
+EXPORT_SYMBOL_GPL(power_supply_put_array);
+
 static int power_supply_match_device_fwnode(struct device *dev, const void *data)
 {
 	return dev->parent && dev_fwnode(dev->parent) == data;
diff --git a/include/linux/power_supply.h b/include/linux/power_supply.h
index 7a5e4c3242a0..026412164a88 100644
--- a/include/linux/power_supply.h
+++ b/include/linux/power_supply.h
@@ -806,11 +806,23 @@ extern int power_supply_reg_notifier(struct notifier_block *nb);
 extern void power_supply_unreg_notifier(struct notifier_block *nb);
 #if IS_ENABLED(CONFIG_POWER_SUPPLY)
 extern struct power_supply *power_supply_get_by_name(const char *name);
+extern int __must_check power_supply_get_battery_all(struct device *dev,
+						     struct power_supply ***psys);
+extern void power_supply_put_array(struct power_supply **psys, int count);
 extern void power_supply_put(struct power_supply *psy);
 #else
 static inline void power_supply_put(struct power_supply *psy) {}
 static inline struct power_supply *power_supply_get_by_name(const char *name)
 { return NULL; }
+static inline int __must_check power_supply_get_battery_all(struct device *dev,
+							    struct power_supply ***psys)
+{
+	if (psys)
+		*psys = NULL;
+	return 0;
+}
+
+static inline void power_supply_put_array(struct power_supply **psys, int count) {}
 #endif
 extern struct power_supply *power_supply_get_by_reference(struct fwnode_handle *fwnode,
 							  const char *property);

-- 
2.54.0.746.g67dd491aae-goog

