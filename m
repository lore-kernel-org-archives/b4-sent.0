From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 25 Nov 2026 11:17:41 +0100
Subject: [PATCH 1/4] thermal/of: Add thermal_zone_get_zone_by_node() API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-glymur-thermal-fix-v1-1-b93a9feae156@oss.qualcomm.com>
References: <20261125-glymur-thermal-fix-v1-0-b93a9feae156@oss.qualcomm.com>
In-Reply-To: <20261125-glymur-thermal-fix-v1-0-b93a9feae156@oss.qualcomm.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2400;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=5k4BZ2Ul4s1/TwVfhXlkb5ymb3YEzOmcYly7NzusMwk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBrBrXN8u8ZRLWNBFP4jw+2gD9HawI4nmGTJbgqY
 CxNRmHYXOuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCawa1zQAKCRBVnxHm/pHO
 9WFCB/9mmUu/B7ciK+Msk45jcGrCF0JgSFpXipyfDaWN8v8q21uXAhXH8wqe6hRfLUcRgbp/TTP
 YEWv4vT+qRMs1A3TwV5hf7+h5UQ5L1F/E6zey9l9gsFE/Y/rox8MRkC6k+oDVqVajiNaewEQXkC
 5IrojZYtt5oa/ZN4BViWSe9uJcNKLIR/PKsR1lxd/m5eZTUJcQLJO8yH0wGOQkLuCMS2Jtj/hrt
 fe35TS0SMQYNus95gqsRdnJg05oEjjuTIpVp4oCz4CLPBRXt/Rbgu+UWPK6gbmbK3un73VpoYNZ
 TtMg1as8xc5Gspm/PAI+RovSpPsViwSp5ZxbwzZ+k/CkKXYS
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an API to allow the drivers to get a registered thermal zone from OF
node.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/thermal/thermal_of.c | 21 +++++++++++++++++++++
 include/linux/thermal.h      |  8 ++++++++
 2 files changed, 29 insertions(+)

diff --git a/drivers/thermal/thermal_of.c b/drivers/thermal/thermal_of.c
index 9e96fb1b033e..e38f67c19c8e 100644
--- a/drivers/thermal/thermal_of.c
+++ b/drivers/thermal/thermal_of.c
@@ -530,6 +530,27 @@ void devm_thermal_of_zone_unregister(struct device *dev, struct thermal_zone_dev
 }
 EXPORT_SYMBOL_GPL(devm_thermal_of_zone_unregister);
 
+/**
+ * thermal_zone_get_zone_by_node() - get a registered zone from its OF node
+ * @np: device tree node of the thermal zone
+ *
+ * Thermal zones described in the device tree are registered using the name
+ * of their device tree node, so resolve @np to its registered thermal zone
+ * by that name.
+ *
+ * Return: a valid thermal zone on success, an ERR_PTR otherwise (-EINVAL for
+ * an invalid argument, -ENODEV if no zone matches @np and -EEXIST if the name
+ * is not unique).
+ */
+struct thermal_zone_device *thermal_zone_get_zone_by_node(struct device_node *np)
+{
+	if (!np)
+		return ERR_PTR(-EINVAL);
+
+	return thermal_zone_get_zone_by_name(np->name);
+}
+EXPORT_SYMBOL_GPL(thermal_zone_get_zone_by_node);
+
 /**
  * thermal_of_cooling_device_register() - register an OF thermal cooling device
  * @np:		a pointer to a device tree node.
diff --git a/include/linux/thermal.h b/include/linux/thermal.h
index 306ad17aed89..c5278d1ff0ef 100644
--- a/include/linux/thermal.h
+++ b/include/linux/thermal.h
@@ -216,6 +216,8 @@ devm_thermal_of_child_cooling_device_register(struct device *dev,
 					      struct device_node *np,
 					      const char *type, void *devdata,
 					      const struct thermal_cooling_device_ops *ops);
+
+struct thermal_zone_device *thermal_zone_get_zone_by_node(struct device_node *np);
 #else
 
 static inline
@@ -254,6 +256,12 @@ devm_thermal_of_child_cooling_device_register(struct device *dev,
 {
 	return ERR_PTR(-ENODEV);
 }
+
+static inline struct thermal_zone_device *
+thermal_zone_get_zone_by_node(struct device_node *np)
+{
+	return ERR_PTR(-ENODEV);
+}
 #endif
 
 int for_each_thermal_trip(struct thermal_zone_device *tz,

-- 
2.43.0

