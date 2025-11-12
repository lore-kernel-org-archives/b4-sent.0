From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 12 Nov 2025 20:15:17 +0530
Subject: [PATCH 5/9] serdev: Add modalias support for serdev client devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251112-pci-m2-e-v1-5-97413d6bf824@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3104;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=d3crWSGCGUGn4wtoYTdDJMgOBARJSAYtgVh6kQhItYQ=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpFJ2HLBj0atRdQkoYoEtIlsRq/2nfEpNLLTmK8
 0Ee8SHCPp2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaRSdhwAKCRBVnxHm/pHO
 9ccoB/9JulXVNBQpte5g04Zu3cGVEtybP7nbcJRotlJ106/5GvyjbUjrShqI832UjbWtjgtNtc3
 myVXAVbBbIRPoaVWY356o/T3owMpyRDkiLZk1NFJ0RVInasTwuDM+GXTT3URoLQkCYbusx7nlfn
 pP+eHsk+ZjcXWswcI+pRcm1d63s65LwpVHyeZlcxQv8r/cg/MbUp/PMEZiSHw/e4Ka3pprDytt7
 2Osv6Mynw2x9nJ5M+sb3n1u0NRLnqeM/D5s/sPFAwyMHsCHy2VVabnJSwo7BsY/opFJ4jUa1c/k
 ryGpgpPFOpTHT7cFdpd8gXslxG4YoRjCn7kZZjis3WqdlDMM
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add modlias support to serdev so that the serdev client driver can be
autoloaded by udev when the serdev client device gets created.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/tty/serdev/core.c       | 15 +++++++++++----
 include/linux/mod_devicetable.h |  1 +
 scripts/mod/file2alias.c        |  8 ++++++++
 3 files changed, 20 insertions(+), 4 deletions(-)

diff --git a/drivers/tty/serdev/core.c b/drivers/tty/serdev/core.c
index f90095cb778f2374303f98809d1639a000e0d9e0..8c2a40a537d93f4b9353a2f128cdf51b521929b1 100644
--- a/drivers/tty/serdev/core.c
+++ b/drivers/tty/serdev/core.c
@@ -34,7 +34,11 @@ static ssize_t modalias_show(struct device *dev,
 	if (len != -ENODEV)
 		return len;
 
-	return of_device_modalias(dev, buf, PAGE_SIZE);
+	len = of_device_modalias(dev, buf, PAGE_SIZE);
+	if (len != -ENODEV)
+		return len;
+
+	return sysfs_emit(buf, SERDEV_DEVICE_MODALIAS_FMT "\n", dev_name(dev));
 }
 static DEVICE_ATTR_RO(modalias);
 
@@ -48,13 +52,16 @@ static int serdev_device_uevent(const struct device *dev, struct kobj_uevent_env
 {
 	int rc;
 
-	/* TODO: platform modalias */
-
 	rc = acpi_device_uevent_modalias(dev, env);
 	if (rc != -ENODEV)
 		return rc;
 
-	return of_device_uevent_modalias(dev, env);
+	rc = of_device_uevent_modalias(dev, env);
+	if (rc != -ENODEV)
+		return rc;
+
+	return add_uevent_var(env, "MODALIAS=" SERDEV_DEVICE_MODALIAS_FMT,
+					dev_name(dev));
 }
 
 static void serdev_device_release(struct device *dev)
diff --git a/include/linux/mod_devicetable.h b/include/linux/mod_devicetable.h
index 70c54c4bedba2fcb8f5eb37c2d9ede05d5d91188..dad9637cf28552c3423affc4eb249efa6ba05514 100644
--- a/include/linux/mod_devicetable.h
+++ b/include/linux/mod_devicetable.h
@@ -976,6 +976,7 @@ struct coreboot_device_id {
 	kernel_ulong_t driver_data;
 };
 
+#define SERDEV_DEVICE_MODALIAS_FMT "serdev:%s"
 #define SERDEV_NAME_SIZE 32
 
 struct serdev_device_id {
diff --git a/scripts/mod/file2alias.c b/scripts/mod/file2alias.c
index b3333560b95ee998fbe5bdc9ed380847962d1bd1..27e9f7c718c4d48ca5dbd5538490529119df9509 100644
--- a/scripts/mod/file2alias.c
+++ b/scripts/mod/file2alias.c
@@ -1371,6 +1371,13 @@ static void do_coreboot_entry(struct module *mod, void *symval)
 	module_alias_printf(mod, false, "coreboot:t%08X", tag);
 }
 
+/* Looks like: serdev:S */
+static void do_serdev_entry(struct module *mod, void *symval)
+{
+	DEF_FIELD_ADDR(symval, serdev_device_id, name);
+	module_alias_printf(mod, false, SERDEV_DEVICE_MODALIAS_FMT, *name);
+}
+
 /* Does namelen bytes of name exactly match the symbol? */
 static bool sym_is(const char *name, unsigned namelen, const char *symbol)
 {
@@ -1467,6 +1474,7 @@ static const struct devtable devtable[] = {
 	{"usb", SIZE_usb_device_id, do_usb_entry_multi},
 	{"pnp", SIZE_pnp_device_id, do_pnp_device_entry},
 	{"pnp_card", SIZE_pnp_card_device_id, do_pnp_card_entry},
+	{"serdev", SIZE_serdev_device_id, do_serdev_entry},
 };
 
 /* Create MODULE_ALIAS() statements.

-- 
2.48.1

