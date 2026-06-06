From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 18:47:35 +1000
Subject: [PATCH 04/11] drivers: misc: pm8916_pon: support setting reboot
 type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-pm8916-pon-v1-4-170c9cbe5099@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=3673;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=76dKyOtGeFtRvYlmOuCos7kO0xYFBzb4257ZABhZoV8=;
 b=s1kdfA2vUHbKNW7rDLKY7D/l3exg/+pr4n11Y2aWmLsIsKeFfSprzNRsKxaiHEJszAOhRsWNW
 why9C8FUti2Dj3w62iZepT5W4VA+WGapPwW55Fnbgn6pIpBhRRtcb81
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is to be used in conjunction with PSHOLD sysreset driver.

This code manages the RST_CTL register block, which PM8916 uses to
decide what action to take when PS_HOLD is de-asserted.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/misc/pm8916_pon.c | 82 +++++++++++++++++++++++++++++++++++++++++++++++
 include/pm8916_pon.h      | 18 +++++++++++
 2 files changed, 100 insertions(+)

diff --git a/drivers/misc/pm8916_pon.c b/drivers/misc/pm8916_pon.c
index d65a7cab459..4cd8921a08a 100644
--- a/drivers/misc/pm8916_pon.c
+++ b/drivers/misc/pm8916_pon.c
@@ -10,16 +10,98 @@
 #include <dm/lists.h>
 #include <dm/device_compat.h>
 #include <power/pmic.h>
+#include <linux/delay.h>
+#include <sysreset.h>
 #include "button/qcom-pmic.h"
+#include "pm8916_pon.h"
 
 #define PON_REV2 0x01
 
+#define PON_PS_HOLD_RST_CTL 0x5a
+#define PON_PS_HOLD_RST_CTL2 0x5b
+
+#define PON_PS_HOLD_ENABLE BIT(7)
+
+#define PON_PS_HOLD_TYPE_MASK GENMASK(3, 0)
+#define PON_PS_HOLD_TYPE_WARM_RESET 1
+#define PON_PS_HOLD_TYPE_SHUTDOWN 4
+#define PON_PS_HOLD_TYPE_HARD_RESET 7
+
 struct pm8916_pon_priv {
 	struct udevice *pmic;
 	phys_addr_t base;
 	u32 revision;
 };
 
+int pm8916_pon_set_reboot_type(enum sysreset_t reset_type)
+{
+	struct udevice *dev;
+	struct pm8916_pon_priv *priv;
+	int ret;
+	uint pmic_reset_type;
+	uint enable_reg;
+
+	ret = uclass_get_device_by_driver(UCLASS_MISC,
+					  DM_DRIVER_GET(pm8916_pon), &dev);
+	if (ret) {
+		pr_warn("couldn't find pm8916_pon device: %d\n", ret);
+		return ret;
+	}
+	if (!dev) {
+		dev_warn(dev, "couldn't find pm8916_pon device\n");
+		return -ENODEV;
+	}
+
+	priv = dev_get_priv(dev);
+
+	/* PMICs with revision 0 have the enable bit in same register as ctrl */
+	if (priv->revision == 0)
+		enable_reg = PON_PS_HOLD_RST_CTL;
+	else
+		enable_reg = PON_PS_HOLD_RST_CTL2;
+
+	switch (reset_type) {
+	case SYSRESET_POWER_OFF:
+		pmic_reset_type = PON_PS_HOLD_TYPE_SHUTDOWN;
+		break;
+	case SYSRESET_COLD:
+	case SYSRESET_POWER:
+		pmic_reset_type = PON_PS_HOLD_TYPE_HARD_RESET;
+		break;
+	default:
+		pmic_reset_type = PON_PS_HOLD_TYPE_WARM_RESET;
+	}
+
+	dev_dbg(dev, "Setting PON reboot type: %x\n", pmic_reset_type);
+
+	ret = pmic_clrsetbits(priv->pmic, priv->base + enable_reg,
+			      PON_PS_HOLD_ENABLE, 0);
+	if (ret) {
+		dev_warn(dev, "clear PON_PS_HOLD_ENABLE failed: %d\n", ret);
+		return ret;
+	}
+
+	/* Delay needed for disable to kick in. */
+	/* Kernel uses usleep_range(100, 1000), lk2nd waits 300usec */
+	udelay(300);
+
+	ret = pmic_clrsetbits(priv->pmic, priv->base + PON_PS_HOLD_RST_CTL,
+			      PON_PS_HOLD_TYPE_MASK, pmic_reset_type);
+	if (ret) {
+		dev_warn(dev, "RST_CTL set failed: %d\n", ret);
+		return ret;
+	}
+
+	ret = pmic_clrsetbits(priv->pmic, priv->base + enable_reg, 0,
+			      PON_PS_HOLD_ENABLE);
+	if (ret) {
+		dev_warn(dev, "PON_PS_HOLD_ENABLE failed: %d\n", ret);
+		return ret;
+	}
+
+	return 0;
+}
+
 static int pm8916_pon_probe(struct udevice *dev)
 {
 	int ret;
diff --git a/include/pm8916_pon.h b/include/pm8916_pon.h
new file mode 100644
index 00000000000..cc553d43713
--- /dev/null
+++ b/include/pm8916_pon.h
@@ -0,0 +1,18 @@
+/* SPDX-License-Identifier: GPL-2.0+ */
+
+#ifndef __PM8916_PON_H__
+#define __PM8916_PON_H__
+
+#include <linux/errno.h>
+#include <sysreset.h>
+
+#if CONFIG_IS_ENABLED(PM8916_PON)
+int pm8916_pon_set_reboot_type(enum sysreset_t reset_type);
+#else
+static inline int pm8916_pon_set_reboot_type(enum sysreset_t reset_type)
+{
+	return -ENOSYS;
+}
+#endif
+
+#endif /* __PM8916_PON_H__ */

-- 
2.54.0

