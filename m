From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 12 Nov 2025 20:15:14 +0530
Subject: [PATCH 2/9] serdev: Add serdev device based driver match support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251112-pci-m2-e-v1-2-97413d6bf824@oss.qualcomm.com>
References: <20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com>
In-Reply-To: <20251112-pci-m2-e-v1-0-97413d6bf824@oss.qualcomm.com>
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
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-serial@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-pm@vger.kernel.org, Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4197;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=nlTsT1KuaCByFt+CSA6xTACxTdskiJ12kycskYPPccs=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYsgUmdv29OlUg/BV3A+d6k4uKeJU0Hk27zpng/n/ip/3/
 Vty267EdDIaszAwcjHIiimypC911mr0OH1jSYT6dJhBrEwgUxi4OAVgIsYWHAyzO1dLnLyaOKXp
 A3PP/5YuY9l5uw+I39568paoWoWXylnba4G8J5u09Hf1mD/5Wv5ZoKXx+b0NeuI3s77mPOJKqbw
 y5xzvLcllfYWSfBufmlzZpGxYf2vuDcvXGSZHMpSbJHy2nrCX5jA+cHjb+hkr2Gs+nA3iizfKeJ
 xiVKd6ybKOqflv/CO2k6tfOFTXn67QVlWJeHBGhycqYHqligOr+Z9rgl7h3vLSmku5a249UC/nf
 eaowjspJmFllWdoxnfX5TVitodChToPruS8co3zgG9+TJNdhtyE0Gkdekkf7OpZLVKN5ynomOsn
 TrZWV/yeHCai/lXuJYvK9asH9rS3rZrb8MbzoujRvlkFAA==
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support to match serdev devices with serdev drivers based on the serdev
ID table defined in serdev_device_driver::id_table.

The matching function, serdev_driver_match_device() uses the serdev device
name to match against the entries in serdev_device_driver::id_table.

If there is no serdev id_table for the driver, then serdev_device_match()
will fallback to ACPI and DT based matching.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/tty/serdev/core.c         | 23 ++++++++++++++++++++++-
 include/linux/mod_devicetable.h   |  7 +++++++
 include/linux/serdev.h            |  4 ++++
 scripts/mod/devicetable-offsets.c |  3 +++
 4 files changed, 36 insertions(+), 1 deletion(-)

diff --git a/drivers/tty/serdev/core.c b/drivers/tty/serdev/core.c
index b33e708cb2455fc144a9fd4ac40ce9118e1a8faa..2b5582cd5063a87c9a6c99f83a8ab071637eae57 100644
--- a/drivers/tty/serdev/core.c
+++ b/drivers/tty/serdev/core.c
@@ -85,12 +85,33 @@ static const struct device_type serdev_ctrl_type = {
 	.release	= serdev_ctrl_release,
 };
 
+static int serdev_driver_match_device(struct device *dev, const struct device_driver *drv)
+{
+	const struct serdev_device_driver *serdev_drv = to_serdev_device_driver(drv);
+	struct serdev_device *serdev = to_serdev_device(dev);
+	const struct serdev_device_id *id;
+
+	if (!serdev_drv->id_table)
+		return 0;
+
+	for (id = serdev_drv->id_table; id->name[0]; id++) {
+		if (!strcmp(dev_name(dev), id->name)) {
+			serdev->id = id;
+			return 1;
+		}
+	}
+
+	return 0;
+}
+
 static int serdev_device_match(struct device *dev, const struct device_driver *drv)
 {
 	if (!is_serdev_device(dev))
 		return 0;
 
-	/* TODO: platform matching */
+	if (serdev_driver_match_device(dev, drv))
+		return 1;
+
 	if (acpi_driver_match_device(dev, drv))
 		return 1;
 
diff --git a/include/linux/mod_devicetable.h b/include/linux/mod_devicetable.h
index 6077972e8b45de3d07881c0226459d815dd1f83d..70c54c4bedba2fcb8f5eb37c2d9ede05d5d91188 100644
--- a/include/linux/mod_devicetable.h
+++ b/include/linux/mod_devicetable.h
@@ -976,4 +976,11 @@ struct coreboot_device_id {
 	kernel_ulong_t driver_data;
 };
 
+#define SERDEV_NAME_SIZE 32
+
+struct serdev_device_id {
+	const char name[SERDEV_NAME_SIZE];
+	kernel_ulong_t driver_data;
+};
+
 #endif /* LINUX_MOD_DEVICETABLE_H */
diff --git a/include/linux/serdev.h b/include/linux/serdev.h
index ab185cac556380dfa3cdf94b7af6ee168b677587..ee42e293445d928a311bd3c120e609214f89a5dd 100644
--- a/include/linux/serdev.h
+++ b/include/linux/serdev.h
@@ -39,6 +39,7 @@ struct serdev_device_ops {
  * @ops:	Device operations.
  * @write_comp	Completion used by serdev_device_write() internally
  * @write_lock	Lock to serialize access when writing data
+ * @id:		serdev device ID entry
  */
 struct serdev_device {
 	struct device dev;
@@ -47,6 +48,7 @@ struct serdev_device {
 	const struct serdev_device_ops *ops;
 	struct completion write_comp;
 	struct mutex write_lock;
+	const struct serdev_device_id *id;
 };
 
 #define to_serdev_device(d) container_of(d, struct serdev_device, dev)
@@ -55,11 +57,13 @@ struct serdev_device {
  * struct serdev_device_driver - serdev slave device driver
  * @driver:	serdev device drivers should initialize name field of this
  *		structure.
+ * @id_table:	serdev device ID table
  * @probe:	binds this driver to a serdev device.
  * @remove:	unbinds this driver from the serdev device.
  */
 struct serdev_device_driver {
 	struct device_driver driver;
+	const struct serdev_device_id *id_table;
 	int	(*probe)(struct serdev_device *);
 	void	(*remove)(struct serdev_device *);
 };
diff --git a/scripts/mod/devicetable-offsets.c b/scripts/mod/devicetable-offsets.c
index d3d00e85edf73553ba3d9b5f9fccf1ff61c99026..c1bfa8eddc4d638c55db54cfd9b6407f47594b4c 100644
--- a/scripts/mod/devicetable-offsets.c
+++ b/scripts/mod/devicetable-offsets.c
@@ -280,5 +280,8 @@ int main(void)
 	DEVID(coreboot_device_id);
 	DEVID_FIELD(coreboot_device_id, tag);
 
+	DEVID(serdev_device_id);
+	DEVID_FIELD(serdev_device_id, name);
+
 	return 0;
 }

-- 
2.48.1

