From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 16 Oct 2026 21:55:06 +0200
Subject: [PATCH] pinctrl: qcom: implement get_pin_muxing for 'pinmux
 status'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-b4-msm-pinmux-getter-v1-1-586760fcf01b@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBG4avIrDvgBEmhVyld1PirU0gqmVgE8
 e5N6/JbvLeTISuMbs1OGR81facKuTQU5meawDpUk2udl1Y89x1Hi7xoiuvGE0pB5tHhOkjnJAR
 PNV0yRt3+2/vjtK39C6H8XnQcX+Wv0jx4AAAA
X-Change-ID: 20261016-b4-msm-pinmux-getter-f2e7d1421cc6
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 David Heidelberg <david@ixit.cz>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792180518; l=2751;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=EnIZcxXLwtPjMWjmTK3tdxGThpLrYGDGwylS3p7h6E0=;
 b=ED/de8ZT0F+CRwDNl2QGun5fVH0/S5DTPiLIRw39XvYF11JiZ63KBz5u7hA5omWsTJNxdLK42
 VyhPBeYEvCRCnT9Syxp8U+LRj5isWr7HWLoinaw7DlIsCFxWwFHCwlu
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the get_pin_muxing op so that 'pinmux status' can show which
function each pin is currently muxed to.

Reserved pins are reported as "reserved" without touching the register
as some of them are TZ-owned and a non-secure read traps.

Special pins are reported as "special".

For any other pin the FUNC_SEL field is matched against the SoC's
function table, falling back to "func N" if no entry matches.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
When bringing up a new Qualcomm board it is hard to tell which function
the bootloader or firmware left a pin in and 'pinmux status' prints
nothing useful for these SoCs. Being able to read that back makes pin
mux problems much quicker to track down.
---
 drivers/pinctrl/qcom/pinctrl-qcom.c | 34 ++++++++++++++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/drivers/pinctrl/qcom/pinctrl-qcom.c b/drivers/pinctrl/qcom/pinctrl-qcom.c
index c95db56bc47..014082bec8e 100644
--- a/drivers/pinctrl/qcom/pinctrl-qcom.c
+++ b/drivers/pinctrl/qcom/pinctrl-qcom.c
@@ -18,6 +18,7 @@
 #include <linux/bitmap.h>
 #include <linux/bug.h>
 #include <mach/gpio.h>
+#include <vsprintf.h>
 
 #include "pinctrl-qcom.h"
 
@@ -232,6 +233,38 @@ static int msm_pinconf_set(struct udevice *dev, unsigned int pin_selector,
 	return 0;
 }
 
+static int msm_get_pin_muxing(struct udevice *dev, unsigned int selector,
+			      char *buf, int size)
+{
+	struct msm_pinctrl_priv *priv = dev_get_priv(dev);
+	u32 val;
+	int func, i;
+
+	if (msm_pinctrl_is_reserved(dev, selector)) {
+		snprintf(buf, size, "reserved");
+		return 0;
+	}
+
+	if (qcom_is_special_pin(&priv->data->pin_data, selector)) {
+		snprintf(buf, size, "special");
+		return 0;
+	}
+
+	val = readl(priv->base + GPIO_CONFIG_REG(priv, selector));
+	func = (val & TLMM_FUNC_SEL_MASK) >> 2;
+
+	for (i = 0; i < priv->data->functions_count; i++) {
+		if (priv->data->get_function_mux(selector, i) == func) {
+			snprintf(buf, size, "%s",
+				 priv->data->get_function_name(dev, i));
+			return 0;
+		}
+	}
+
+	snprintf(buf, size, "func %d", func);
+	return 0;
+}
+
 struct pinctrl_ops msm_pinctrl_ops = {
 	.get_pins_count = msm_get_pins_count,
 	.get_pin_name = msm_get_pin_name,
@@ -242,6 +275,7 @@ struct pinctrl_ops msm_pinctrl_ops = {
 	.pinconf_set = msm_pinconf_set,
 	.get_functions_count = msm_get_functions_count,
 	.get_function_name = msm_get_function_name,
+	.get_pin_muxing = msm_get_pin_muxing,
 };
 
 int msm_pinctrl_bind(struct udevice *dev)

---
base-commit: 71433ebf2aed1be5fbd2b1d497eae670ab9b9962
change-id: 20261016-b4-msm-pinmux-getter-f2e7d1421cc6

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

