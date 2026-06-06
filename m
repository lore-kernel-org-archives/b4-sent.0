From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 18:47:38 +1000
Subject: [PATCH 07/11] reboot-mode: pm8916-pon: add new driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-pm8916-pon-v1-7-170c9cbe5099@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=4020;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=UukCK74H00/SmwCVzmAYKjrf2eCisaqySlvcxfvl8O8=;
 b=yJhtI6cw2EJqSD6nsebAnfZ5sQpHLNZhF0zXkQAQmt33aeDUWuj+Gv1YUhpKUX6wKLy4yHp5b
 AX4mJe6mNqyAJzmE8GLJ52vej5VKHa/KjvNDvYWsA21DQ6Ze3XSCwhD
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PM8916 provides a PON_SOFT_RB_SPARE register that survives across
reboots.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/misc/pm8916_pon.c                    |  7 +++
 drivers/reboot-mode/Makefile                 |  1 +
 drivers/reboot-mode/reboot-mode-pm8916-pon.c | 88 ++++++++++++++++++++++++++++
 3 files changed, 96 insertions(+)

diff --git a/drivers/misc/pm8916_pon.c b/drivers/misc/pm8916_pon.c
index 4cd8921a08a..c889d2d4e6e 100644
--- a/drivers/misc/pm8916_pon.c
+++ b/drivers/misc/pm8916_pon.c
@@ -142,6 +142,13 @@ static int pm8916_pon_bind(struct udevice *dev)
 			dev_warn(dev, "failed to bind qcom_pwrkey: %d\n", ret);
 	}
 
+	if (CONFIG_IS_ENABLED(DM_REBOOT_MODE)) {
+		ret = device_bind_driver_to_node(dev, "pm8916_pon_reboot_mode",
+						 "reboot_mode", dev_ofnode(dev), NULL);
+		if (ret)
+			dev_warn(dev, "failed to bind reboot_mode: %d\n", ret);
+	}
+
 	return 0;
 }
 
diff --git a/drivers/reboot-mode/Makefile b/drivers/reboot-mode/Makefile
index 48c8ab7fe71..467334d010e 100644
--- a/drivers/reboot-mode/Makefile
+++ b/drivers/reboot-mode/Makefile
@@ -8,3 +8,4 @@ obj-$(CONFIG_DM_REBOOT_MODE) += reboot-mode-uclass.o
 obj-$(CONFIG_DM_REBOOT_MODE_GPIO) += reboot-mode-gpio.o
 obj-$(CONFIG_DM_REBOOT_MODE_RTC) += reboot-mode-rtc.o
 obj-$(CONFIG_REBOOT_MODE_NVMEM) += reboot-mode-nvmem.o
+obj-$(CONFIG_PM8916_PON) += reboot-mode-pm8916-pon.o
diff --git a/drivers/reboot-mode/reboot-mode-pm8916-pon.c b/drivers/reboot-mode/reboot-mode-pm8916-pon.c
new file mode 100644
index 00000000000..fa8d0ecaa77
--- /dev/null
+++ b/drivers/reboot-mode/reboot-mode-pm8916-pon.c
@@ -0,0 +1,88 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+#include <dm.h>
+#include <dm/device_compat.h>
+#include <dm/read.h>
+#include <fdtdec.h>
+#include <power/pmic.h>
+#include <reboot-mode/reboot-mode.h>
+
+#define PON_SOFT_RB_SPARE 0x8f
+
+#define GEN1_REASON_SHIFT 2
+
+struct pm8916_pon_reboot_mode_priv {
+	struct udevice *pmic;
+	phys_addr_t base;
+};
+
+static int pm8916_pon_reboot_mode_get(struct udevice *dev, u32 *rebootmode)
+{
+	struct pm8916_pon_reboot_mode_priv *priv = dev_get_priv(dev);
+	int reg;
+	uint mask = GENMASK(7, GEN1_REASON_SHIFT);
+
+	reg = pmic_reg_read(priv->pmic, priv->base + PON_SOFT_RB_SPARE);
+	if (reg < 0) {
+		dev_warn(dev, "Failed to read PON_SOFT_RB_SPARE: %d\n", reg);
+		return reg;
+	}
+
+	*rebootmode = (reg & mask) >> GEN1_REASON_SHIFT;
+
+	return 0;
+}
+
+static int pm8916_pon_reboot_mode_set(struct udevice *dev, u32 rebootmode)
+{
+	struct pm8916_pon_reboot_mode_priv *priv = dev_get_priv(dev);
+	uint mask = GENMASK(7, GEN1_REASON_SHIFT);
+	int ret;
+
+	ret = pmic_clrsetbits(priv->pmic, priv->base + PON_SOFT_RB_SPARE, mask,
+			      rebootmode << GEN1_REASON_SHIFT);
+	if (ret) {
+		dev_warn(dev, "Failed to write PON_SOFT_RB_SPARE: %d\n", ret);
+		return ret;
+	}
+	return 0;
+}
+
+static const struct reboot_mode_ops pm8916_pon_reboot_mode_ops = {
+	.get = pm8916_pon_reboot_mode_get,
+	.set = pm8916_pon_reboot_mode_set,
+};
+
+static int pm8916_pon_reboot_mode_probe(struct udevice *dev)
+{
+	struct pm8916_pon_reboot_mode_priv *priv = dev_get_priv(dev);
+	struct udevice *pon = dev_get_parent(dev);
+	fdt_addr_t base;
+
+	/* this driver only works as a child of pm8916_pon */
+	if (!pon || !pon->driver || strcmp(pon->driver->name, "pm8916_pon"))
+		return -EINVAL;
+
+	priv->pmic = dev_get_parent(pon);
+	if (!priv->pmic) {
+		dev_err(dev, "PMIC driver not found\n");
+		return -EINVAL;
+	}
+
+	base = dev_read_addr(pon);
+	if (base == FDT_ADDR_T_NONE) {
+		dev_err(dev, "missing PON reg base\n");
+		return -EINVAL;
+	}
+	priv->base = base;
+
+	return 0;
+}
+
+U_BOOT_DRIVER(pm8916_pon_reboot_mode) = {
+	.name = "pm8916_pon_reboot_mode",
+	.id = UCLASS_REBOOT_MODE,
+	.probe = pm8916_pon_reboot_mode_probe,
+	.ops = &pm8916_pon_reboot_mode_ops,
+	.priv_auto = sizeof(struct pm8916_pon_reboot_mode_priv),
+};

-- 
2.54.0

