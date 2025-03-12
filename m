From: Amit Sunil Dhamne <amitsd@google.com>
Date: Wed, 12 Mar 2025 16:42:02 -0700
Subject: [PATCH 2/5] power: supply: core: add function to get supplies from
 fwnode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250312-batt_ops-v1-2-88e0bb3129fd@google.com>
References: <20250312-batt_ops-v1-0-88e0bb3129fd@google.com>
In-Reply-To: <20250312-batt_ops-v1-0-88e0bb3129fd@google.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Sebastian Reichel <sre@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <len.brown@intel.com>, 
 Pavel Machek <pavel@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-pm@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741822998; l=3979;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=UN1YhzvNxvK3QvtdEdK0hrzY0vn7uaEFCUiBkNIHAs8=;
 b=vD3Kw+ItD4Ub6LxGFQKj8W+L2dzxAs/jw3tiolbJe66WFIJz1ITx3ICBYCUKUzGOp1cnQM0wA
 xAFZbNBc2R6D7+1VJpksNLvRTIjDkIk4A1W88LLk1cwXy0dNouaFMDO
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new helper function power_supply_get_by_fwnode_reference_array()
to retrieve a list of power_supplies associated with the fwnode's
property. The property can contain multiple nodes where each node is
associated with a power_supply. The list of power_supply objects will be
stored in an array supplied by the caller and the return value will
indicate the size of the resulting array.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 drivers/power/supply/power_supply_core.c | 60 ++++++++++++++++++++++++++++++++
 include/linux/power_supply.h             |  5 +++
 2 files changed, 65 insertions(+)

diff --git a/drivers/power/supply/power_supply_core.c b/drivers/power/supply/power_supply_core.c
index 76c340b38015af0a67a0d91305e6242a8646bf53..df1a52f85125748c4fdcb10687aa7ed2f626ded1 100644
--- a/drivers/power/supply/power_supply_core.c
+++ b/drivers/power/supply/power_supply_core.c
@@ -593,6 +593,66 @@ struct power_supply *devm_power_supply_get_by_phandle(struct device *dev,
 EXPORT_SYMBOL_GPL(devm_power_supply_get_by_phandle);
 #endif /* CONFIG_OF */
 
+static int power_supply_match_fwnode(struct device *dev, const void *data)
+{
+	return dev && dev->parent && dev->parent->fwnode == data;
+}
+
+/**
+ * power_supply_get_by_fwnode_reference_array() - Returns an array of power
+ * supply objects associated with each fwnode reference present in the property
+ * @fwnode: Pointer to fwnode to lookup property
+ * @property: Name of property holding references
+ * @psy: Resulting array of power_supply pointers. To be provided by the caller.
+ * @size: size of power_supply pointer array.
+ *
+ * If power supply was found, it increases reference count for the
+ * internal power supply's device. The user should power_supply_put()
+ * after usage.
+ *
+ * Return: On success returns the number of power supply objects filled
+ * in the @psy array.
+ * -EOVERFLOW when size of @psy array is not suffice.
+ * -EINVAL when @psy is NULL or @size is 0.
+ * -ENODATA when fwnode does not contain the given property
+ */
+int power_supply_get_by_fwnode_reference_array(struct fwnode_handle *fwnode,
+					       const char *property,
+					       struct power_supply **psy,
+					       ssize_t size)
+{
+	int ret, index, count = 0;
+	struct fwnode_reference_args args;
+	struct device *dev;
+
+	if (!psy || !size)
+		return -EINVAL;
+
+	for (index = 0; index < size &&
+	     !(ret = fwnode_property_get_reference_args(fwnode, property, NULL,
+							0, index, &args));
+	     ++index) {
+		dev = class_find_device(&power_supply_class, NULL, args.fwnode,
+					power_supply_match_fwnode);
+		fwnode_handle_put(args.fwnode);
+		if (!dev)
+			continue;
+
+		if (count > size)
+			return -EOVERFLOW;
+
+		psy[count] = dev_get_drvdata(dev);
+		atomic_inc(&psy[count]->use_cnt);
+		++count;
+	}
+
+	if (ret != -ENOENT)
+		return ret;
+
+	return index ? count : -ENODATA;
+}
+EXPORT_SYMBOL_GPL(power_supply_get_by_fwnode_reference_array);
+
 int power_supply_get_battery_info(struct power_supply *psy,
 				  struct power_supply_battery_info **info_out)
 {
diff --git a/include/linux/power_supply.h b/include/linux/power_supply.h
index 6ed53b292162469d7b357734d5589bff18a201d0..3f062607e5cd7c7f04384e34128ae0953e25d981 100644
--- a/include/linux/power_supply.h
+++ b/include/linux/power_supply.h
@@ -820,6 +820,11 @@ devm_power_supply_get_by_phandle(struct device *dev, const char *property)
 { return NULL; }
 #endif /* CONFIG_OF */
 
+extern int
+power_supply_get_by_fwnode_reference_array(struct fwnode_handle *fwnode,
+					   const char *property,
+					   struct power_supply **psy,
+					   ssize_t size);
 extern const enum power_supply_property power_supply_battery_info_properties[];
 extern const size_t power_supply_battery_info_properties_size;
 extern int power_supply_get_battery_info(struct power_supply *psy,

-- 
2.49.0.rc0.332.g42c0ae87b1-goog

