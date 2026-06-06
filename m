From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 18:47:33 +1000
Subject: [PATCH 02/11] drivers: misc: pm8916_pon: add glue driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-pm8916-pon-v1-2-170c9cbe5099@samcday.com>
References: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
In-Reply-To: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Leo Yu-Chi Liang <ycliang@andestech.com>, Anshul Dalal <anshuld@ti.com>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Justin Klaassen <justin@tidylabs.net>, 
 Jamie Gibbons <jamie.gibbons@microchip.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Mateus Lima Alves <mateuslima.ti@gmail.com>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Ariel D'Alessandro <ariel.dalessandro@collabora.com>, 
 Dmitrii Merkurev <dimorinny@google.com>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=4101;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=idTb+rb5Z5SO31dkHf8uRTI/b9zHBWgdmGShzp78poc=;
 b=MOxyNsCf3MPg5DtE3hDAY1OuyhbqwYBqSwWYWEF3fYxW5lPDhQWxM0wKOeh8pjK36e2XbcCpx
 ii9AXhJtyc4DmA2GChOr4ZzpHYKZ9bC4ZJAMIWs6XSqiWFwWYumGiC4
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Initially, this driver binds the existing qcom_pwrkey driver to continue
supporting pwrkey/resin buttons. In follow-up commits it will be further
extended to bind a reboot-mode driver.

The "qcom,pm8916-pon" compatible is removed from qcom_pwrkey, since
pm8916_pon owns it and handles binding qcom_pwrkey.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/button/button-qcom-pmic.c |  1 -
 drivers/misc/Kconfig              |  7 ++++
 drivers/misc/Makefile             |  1 +
 drivers/misc/pm8916_pon.c         | 78 +++++++++++++++++++++++++++++++++++++++
 4 files changed, 86 insertions(+), 1 deletion(-)

diff --git a/drivers/button/button-qcom-pmic.c b/drivers/button/button-qcom-pmic.c
index d9ac6a51df5..caa47cd9373 100644
--- a/drivers/button/button-qcom-pmic.c
+++ b/drivers/button/button-qcom-pmic.c
@@ -216,7 +216,6 @@ static const struct button_ops button_qcom_pmic_ops = {
 };
 
 static const struct udevice_id qcom_pwrkey_ids[] = {
-	{ .compatible = "qcom,pm8916-pon" },
 	{ .compatible = "qcom,pm8941-pon" },
 	{ .compatible = "qcom,pm8998-pon" },
 	{ .compatible = "qcom,pmk8350-pon" },
diff --git a/drivers/misc/Kconfig b/drivers/misc/Kconfig
index ea785793d18..d2e9b833ff7 100644
--- a/drivers/misc/Kconfig
+++ b/drivers/misc/Kconfig
@@ -439,6 +439,13 @@ config SPL_PWRSEQ
 	  device. When the device is started up, its power sequence can be
 	  initiated.
 
+config PM8916_PON
+	bool "Enable PM8916 PON driver"
+	depends on PMIC_QCOM && MISC
+	help
+	  The PM8916 PMIC is a multifunction device that handles pwr/resin buttons,
+	  reboot type (soft/hard/poweroff) and reboot mode (recovery/bootloader).
+
 config STM32MP_FUSE
 	bool "Enable STM32MP fuse wrapper providing the fuse API"
 	depends on ARCH_STM32MP && MISC
diff --git a/drivers/misc/Makefile b/drivers/misc/Makefile
index e2170212e5a..6b979ba4289 100644
--- a/drivers/misc/Makefile
+++ b/drivers/misc/Makefile
@@ -92,3 +92,4 @@ obj-$(CONFIG_K3_BIST) += k3_bist.o
 obj-$(CONFIG_ESM_PMIC) += esm_pmic.o
 obj-$(CONFIG_SL28CPLD) += sl28cpld.o
 obj-$(CONFIG_SPL_SOCFPGA_DT_REG) += socfpga_dtreg.o
+obj-$(CONFIG_PM8916_PON) += pm8916_pon.o
diff --git a/drivers/misc/pm8916_pon.c b/drivers/misc/pm8916_pon.c
new file mode 100644
index 00000000000..d65a7cab459
--- /dev/null
+++ b/drivers/misc/pm8916_pon.c
@@ -0,0 +1,78 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Qualcomm PM8916 PON glue driver
+ *
+ * The PON device handles pwrkey/resin buttons, as well as setting reboot
+ * type and reboot mode. This glue driver binds the respective drivers.
+ */
+
+#include <dm.h>
+#include <dm/lists.h>
+#include <dm/device_compat.h>
+#include <power/pmic.h>
+#include "button/qcom-pmic.h"
+
+#define PON_REV2 0x01
+
+struct pm8916_pon_priv {
+	struct udevice *pmic;
+	phys_addr_t base;
+	u32 revision;
+};
+
+static int pm8916_pon_probe(struct udevice *dev)
+{
+	int ret;
+	struct pm8916_pon_priv *priv = dev_get_priv(dev);
+
+	priv->pmic = dev->parent;
+	if (!priv->pmic) {
+		dev_err(dev, "PMIC driver not found\n");
+		return -EINVAL;
+	}
+
+	priv->base = dev_read_addr(dev);
+
+	if (!priv->base) {
+		dev_err(dev, "missing reg base\n");
+		return -EINVAL;
+	}
+
+	ret = pmic_reg_read(priv->pmic, priv->base + PON_REV2);
+	if (ret < 0) {
+		dev_err(dev, "failed to determine PON rev: %d\n", ret);
+		return ret;
+	}
+
+	priv->revision = ret;
+	dev_dbg(dev, "PON rev: %d\n", priv->revision);
+
+	return 0;
+}
+
+static int pm8916_pon_bind(struct udevice *dev)
+{
+	int ret;
+
+	if (CONFIG_IS_ENABLED(BUTTON_QCOM_PMIC)) {
+		ret = button_qcom_pmic_setup(dev);
+		if (ret)
+			dev_warn(dev, "failed to bind qcom_pwrkey: %d\n", ret);
+	}
+
+	return 0;
+}
+
+static const struct udevice_id pm8916_pon_ids[] = {
+	{ .compatible = "qcom,pm8916-pon" },
+	{},
+};
+
+U_BOOT_DRIVER(pm8916_pon) = {
+	.name = "pm8916_pon",
+	.id = UCLASS_MISC,
+	.of_match = pm8916_pon_ids,
+	.bind = pm8916_pon_bind,
+	.probe = pm8916_pon_probe,
+	.priv_auto = sizeof(struct pm8916_pon_priv),
+};

-- 
2.54.0

