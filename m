From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 10 Jan 2026 12:26:24 +0530
Subject: [PATCH v3 06/14] software node: Add
 software_node_device_modalias() API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260110-pci-m2-e-v3-6-4faee7d0d5ae@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1735;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=hP/S8Z4ct7CcIRG39KVjpY1137sEbkCLhENN+ADZYvc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpYfg9uwIlLNwsjiWJEiqmMui2S6mjeDAmocoYD
 B3oBp/UHmOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWH4PQAKCRBVnxHm/pHO
 9ca0B/9SLAMwWT9XvwylsIVN2bRjxI8FjRSwSkLnEt/XBOa61mhgkOFI/IrWMtdGPHN3qdU6Uhm
 FyudWgJPzcddwKwp3xY5Nf0NTofUzSrcI13Orctcjxc20nKl9mguMlbNmn3Q6kVicCWRFv6ujzY
 qWvrG1yNtQxEuY4/utH4HWxT2Ex/n1vQ6yYlLmWLPgWTgMoEVju6T4Mckan2+45Wlth/ZbnwMHg
 DyGfsZhr4dHiuKxmfEqtoy2KGbu+GL396UG2zue95hQuTFv1Mz56313B+GZxCeK5U3LAylTQTkI
 TqfqNO5gRmqg4kvrK5cEFRJqaM2dQIESVnyvUOaEEvKdqkNz
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add software_node_device_modalias() API to return the MODALIAS string for
swnode based on the swnode's compatible property.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/base/swnode.c    | 13 +++++++++++++
 include/linux/property.h |  1 +
 2 files changed, 14 insertions(+)

diff --git a/drivers/base/swnode.c b/drivers/base/swnode.c
index c33e09300e5f..a9fa19a27dc6 100644
--- a/drivers/base/swnode.c
+++ b/drivers/base/swnode.c
@@ -401,6 +401,19 @@ int software_node_device_uevent(const struct device *dev, struct kobj_uevent_env
 }
 EXPORT_SYMBOL_GPL(software_node_device_uevent);
 
+ssize_t software_node_device_modalias(struct device *dev, char *str, ssize_t len)
+{
+	const char *compatible;
+	int ret;
+
+	ret = device_property_read_string(dev, "compatible", &compatible);
+	if (ret)
+		return ret;
+
+	return sysfs_emit(str, "%s\n", compatible);
+}
+EXPORT_SYMBOL_GPL(software_node_device_modalias);
+
 /* -------------------------------------------------------------------------- */
 /* fwnode operations */
 
diff --git a/include/linux/property.h b/include/linux/property.h
index 14f85fd66bfc..94ea02ae1675 100644
--- a/include/linux/property.h
+++ b/include/linux/property.h
@@ -600,6 +600,7 @@ void software_node_unregister(const struct software_node *node);
 
 bool software_node_match_device(struct device *dev, const struct device_driver *drv);
 int software_node_device_uevent(const struct device *dev, struct kobj_uevent_env *env);
+ssize_t software_node_device_modalias(struct device *dev, char *str, ssize_t len);
 
 struct fwnode_handle *
 fwnode_create_software_node(const struct property_entry *properties,

-- 
2.48.1

