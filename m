From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 10 Jan 2026 12:26:21 +0530
Subject: [PATCH v3 03/14] software node: Implement device_get_match_data
 fwnode callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260110-pci-m2-e-v3-3-4faee7d0d5ae@oss.qualcomm.com>
References: <20260110-pci-m2-e-v3-0-4faee7d0d5ae@oss.qualcomm.com>
In-Reply-To: <20260110-pci-m2-e-v3-0-4faee7d0d5ae@oss.qualcomm.com>
To: Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Mark Pearson <mpearson-lenovo@squebb.ca>, 
 "Derek J. Clark" <derekjohn.clark@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-acpi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Sui Jingfeng <sui.jingfeng@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2751;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=F4x+figNtDXQ6BLWQUSdqEh/6YP1l/9oLa5mqDRbEME=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpYfg92szPUWg0M5Z43p+tA6xqrl3Xl+TIDuuuW
 XT09vq7oMyJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWH4PQAKCRBVnxHm/pHO
 9Ra+B/9a2vNsci/y7Vpukgq08GScntUk3yAHclypYGi2q/5MqocsLJbX2OW+UJ7m09cC9mwWHW9
 AjiVY6ee45aGahT2qvrBUDo8pfqzMgj+XDXR58kY0HeUsdYN2VxhlgdgSbPt8dwbIJRKt01iSbg
 6D8jlu6wA6SRpswVZrY+8QCxMfOiylv388qf0ymdwhNz3UDkdbMDKfrHhHOPwXYyf2CMW/2RTCt
 eVEDd1fcPULjtiOFhKCS0TH9F2L7Fb+nr+ID2XL+RS5IhX773uIyZ+tcRsibmv/iazQy41ImfM1
 SUX0ODTN1m2oiueF2rjUeQgUgz8KGWouTV7w9qbBynZj1YKu
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sui Jingfeng <sui.jingfeng@linux.dev>

Because the software node backend of the fwnode API framework lacks an
implementation for the .device_get_match_data function callback. This
makes it difficult to use(and/or test) a few drivers that originates
from DT world on the non-DT platform.

Implement the .device_get_match_data fwnode callback, which helps to keep
the three backends of the fwnode API aligned as much as possible. This is
also a fundamental step to make a few drivers OF-independent truely
possible.

Device drivers or platform setup codes are expected to provide a software
node string property, named as "compatible". At this moment, the value of
this string property is being used to match against the compatible entries
in the of_device_id table. It can be extended in the future though.

Signed-off-by: Sui Jingfeng <sui.jingfeng@linux.dev>
[mani: removed fixes tag]
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/base/swnode.c | 29 +++++++++++++++++++++++++++++
 1 file changed, 29 insertions(+)

diff --git a/drivers/base/swnode.c b/drivers/base/swnode.c
index 16a8301c25d6..cd722712b8e9 100644
--- a/drivers/base/swnode.c
+++ b/drivers/base/swnode.c
@@ -15,6 +15,7 @@
 #include <linux/kobject.h>
 #include <linux/kstrtox.h>
 #include <linux/list.h>
+#include <linux/mod_devicetable.h>
 #include <linux/property.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
@@ -390,6 +391,33 @@ static void software_node_put(struct fwnode_handle *fwnode)
 	kobject_put(&swnode->kobj);
 }
 
+static const void *
+software_node_get_match_data(const struct fwnode_handle *fwnode,
+			     const struct device *dev)
+{
+	struct swnode *swnode = to_swnode(fwnode);
+	const struct of_device_id *matches = dev->driver->of_match_table;
+	const char *val = NULL;
+	int ret;
+
+	ret = property_entry_read_string_array(swnode->node->properties,
+					       "compatible", &val, 1);
+	if (ret < 0 || !val)
+		return NULL;
+
+	if (!matches)
+		return NULL;
+
+	while (matches->compatible[0]) {
+		if (!strcmp(matches->compatible, val))
+			return matches->data;
+
+		++matches;
+	}
+
+	return NULL;
+}
+
 static bool software_node_property_present(const struct fwnode_handle *fwnode,
 					   const char *propname)
 {
@@ -694,6 +722,7 @@ software_node_graph_parse_endpoint(const struct fwnode_handle *fwnode,
 static const struct fwnode_operations software_node_ops = {
 	.get = software_node_get,
 	.put = software_node_put,
+	.device_get_match_data = software_node_get_match_data,
 	.property_present = software_node_property_present,
 	.property_read_bool = software_node_property_present,
 	.property_read_int_array = software_node_read_int_array,

-- 
2.48.1

