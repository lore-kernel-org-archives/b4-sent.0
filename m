From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:52 +1000
Subject: [PATCH RESEND 11/16] pinctrl: qcom: introduce MSM8960 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-11-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=6209;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=xDD2p3z3mdqk9kHEZI4iBzCE48rjVFGfMvUtRYCXN98=;
 b=0jHuOZn9tXkCytiuLN918RAiZLnaW70WeBQBbtAoqE34Uxotf9MKWDHUXkkbCuAJ4o62e/i9J
 qkKoVi8WoHJDUNQJTTc0P2dq06/ujH8Zr+1Ki5ypVkikUPrf9qG+yDp
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This flavour of TLMM has a different layout to the existing versions
already supported in U-Boot. The GPIOs are offset by 0x1000 and have a
stride of 0x10. We prepared the generic pinctrl-qcom infra for that in
the previous commit. Otherwise, this driver quacks like the others.

Signed-off-by: Sam Day <me@samcday.com>
---
 configs/qcom_armv7_defconfig           |   1 +
 drivers/pinctrl/qcom/Kconfig           |   9 +++
 drivers/pinctrl/qcom/Makefile          |   1 +
 drivers/pinctrl/qcom/pinctrl-msm8960.c | 135 +++++++++++++++++++++++++++++++++
 4 files changed, 146 insertions(+)

diff --git a/configs/qcom_armv7_defconfig b/configs/qcom_armv7_defconfig
index 7d64ee68ecd..aef8838c8a8 100644
--- a/configs/qcom_armv7_defconfig
+++ b/configs/qcom_armv7_defconfig
@@ -43,6 +43,7 @@ CONFIG_MSM_GPIO=y
 CONFIG_DM_KEYBOARD=y
 CONFIG_BUTTON_KEYBOARD=y
 CONFIG_PINCTRL=y
+CONFIG_PINCTRL_QCOM_MSM8960=y
 CONFIG_MSM_SERIAL=y
 CONFIG_SYSRESET_QCOM_PSHOLD=y
 CONFIG_TIMER=y
diff --git a/drivers/pinctrl/qcom/Kconfig b/drivers/pinctrl/qcom/Kconfig
index 11e6763b5f3..04d888535fa 100644
--- a/drivers/pinctrl/qcom/Kconfig
+++ b/drivers/pinctrl/qcom/Kconfig
@@ -30,6 +30,15 @@ config PINCTRL_QCOM_APQ8096
 	  Say Y here to enable support for pinctrl on the MSM8996 / APQ8096
 	  Snapdragon 820 SoC, as well as the associated GPIO driver.
 
+config PINCTRL_QCOM_MSM8960
+	bool "Qualcomm MSM8960 Pinctrl"
+	default y if PINCTRL_QCOM_GENERIC
+	select PINCTRL_QCOM
+	help
+	  Say Y here to enable TLMM support on the MSM8960 family, including
+	  MSM8930. This provides pinctrl/GPIO support as well as the PS_HOLD
+	  sysreset child exposed by TLMM.
+
 config PINCTRL_QCOM_IPQ4019
 	bool "Qualcomm IPQ4019 Pinctrl"
 	default y if PINCTRL_QCOM_GENERIC
diff --git a/drivers/pinctrl/qcom/Makefile b/drivers/pinctrl/qcom/Makefile
index 4096c1aa491..d518f488db2 100644
--- a/drivers/pinctrl/qcom/Makefile
+++ b/drivers/pinctrl/qcom/Makefile
@@ -8,6 +8,7 @@ obj-$(CONFIG_PINCTRL_QCOM_IPQ4019) += pinctrl-ipq4019.o
 obj-$(CONFIG_PINCTRL_QCOM_IPQ5424) += pinctrl-ipq5424.o
 obj-$(CONFIG_PINCTRL_QCOM_IPQ9574) += pinctrl-ipq9574.o
 obj-$(CONFIG_PINCTRL_QCOM_APQ8096) += pinctrl-apq8096.o
+obj-$(CONFIG_PINCTRL_QCOM_MSM8960) += pinctrl-msm8960.o
 obj-$(CONFIG_PINCTRL_QCOM_MILOS) += pinctrl-milos.o
 obj-$(CONFIG_PINCTRL_QCOM_QCM2290) += pinctrl-qcm2290.o
 obj-$(CONFIG_PINCTRL_QCOM_QCS404) += pinctrl-qcs404.o
diff --git a/drivers/pinctrl/qcom/pinctrl-msm8960.c b/drivers/pinctrl/qcom/pinctrl-msm8960.c
new file mode 100644
index 00000000000..32a474c89bc
--- /dev/null
+++ b/drivers/pinctrl/qcom/pinctrl-msm8960.c
@@ -0,0 +1,135 @@
+// SPDX-License-Identifier: GPL-2.0+
+#include <dm.h>
+#include <dm/device-internal.h>
+#include <dm/lists.h>
+#include <errno.h>
+
+#include "pinctrl-qcom.h"
+#include "dm/device_compat.h"
+
+#define MSM8960_PS_HOLD_OFFSET 0x820
+
+#define MAX_PIN_NAME_LEN   32
+#define MSM8960_NUM_GPIO   152
+#define MSM8960_NUM_PINS   158
+#define MSM8960_GPIO_BASE  0x1000
+#define MSM8960_GPIO_STRIDE 0x10
+
+static char pin_name[MAX_PIN_NAME_LEN] __section(".data");
+
+static const struct pinctrl_function msm8960_functions[] = {
+	{ "gpio", 0 },
+	{ "gsbi1", 1 },
+	{ "gsbi2", 1 },
+	{ "gsbi3", 1 },
+	{ "gsbi4", 1 },
+	{ "gsbi5", 1 },
+	{ "gsbi6", 1 },
+	{ "gsbi7", 1 },
+	{ "gsbi8", 1 },
+	{ "gsbi9", 1 },
+	{ "gsbi10", 1 },
+	{ "gsbi11", 1 },
+	{ "gsbi12", 1 },
+};
+
+#define SDC_PINGROUP(pg_name, ctl, pull, drv) \
+	{ \
+		.name = pg_name, \
+		.ctl_reg = ctl, \
+		.io_reg = 0, \
+		.pull_bit = pull, \
+		.drv_bit = drv, \
+		.oe_bit = -1, \
+		.in_bit = -1, \
+		.out_bit = -1, \
+	}
+
+static const struct msm_special_pin_data msm8960_special_pins_data[] = {
+	SDC_PINGROUP("sdc1_clk", 0x20a0, 13, 6),
+	SDC_PINGROUP("sdc1_cmd", 0x20a0, 11, 3),
+	SDC_PINGROUP("sdc1_data", 0x20a0, 9, 0),
+	SDC_PINGROUP("sdc3_clk", 0x20a4, 14, 6),
+	SDC_PINGROUP("sdc3_cmd", 0x20a4, 11, 3),
+	SDC_PINGROUP("sdc3_data", 0x20a4, 9, 0),
+};
+
+static const char *msm8960_get_function_name(struct udevice *dev,
+					     unsigned int selector)
+{
+	return msm8960_functions[selector].name;
+}
+
+static int msm8960_get_function_mux(__maybe_unused unsigned int pin,
+				    unsigned int selector)
+{
+	if (selector >= ARRAY_SIZE(msm8960_functions))
+		return -EINVAL;
+
+	return msm8960_functions[selector].val;
+}
+
+static const char *msm8960_get_pin_name(struct udevice *dev,
+					unsigned int selector)
+{
+	if (selector < MSM8960_NUM_GPIO)
+		snprintf(pin_name, MAX_PIN_NAME_LEN, "gpio%u", selector);
+	else
+		snprintf(pin_name, MAX_PIN_NAME_LEN, "%s",
+			 msm8960_special_pins_data[selector -
+						   MSM8960_NUM_GPIO].name);
+
+	return pin_name;
+}
+
+static const struct msm_pinctrl_data msm8960_data = {
+	.pin_data = {
+		.pin_count = MSM8960_NUM_PINS,
+		.gpio_base = MSM8960_GPIO_BASE,
+		.gpio_stride = MSM8960_GPIO_STRIDE,
+		.special_pins_start = MSM8960_NUM_GPIO,
+		.special_pins_data = msm8960_special_pins_data,
+	},
+	.functions_count = ARRAY_SIZE(msm8960_functions),
+	.get_function_name = msm8960_get_function_name,
+	.get_function_mux = msm8960_get_function_mux,
+	.get_pin_name = msm8960_get_pin_name,
+};
+
+static int msm8960_bind_pshold(struct udevice *dev)
+{
+	struct driver *drv;
+
+	drv = lists_driver_lookup_name("qcom_pshold");
+	if (!drv)
+		return -ENOENT;
+
+	return device_bind_with_driver_data(dev, drv, "msm8960-pshold",
+					    MSM8960_PS_HOLD_OFFSET,
+					    dev_ofnode(dev), NULL);
+}
+
+static int msm8960_pinctrl_bind(struct udevice *dev)
+{
+	int ret;
+
+	if (IS_ENABLED(CONFIG_SYSRESET_QCOM_PSHOLD)) {
+		ret = msm8960_bind_pshold(dev);
+		if (ret)
+			dev_err(dev, "Failed to bind pshold: %d\n", ret);
+	}
+
+	return msm_pinctrl_bind(dev);
+}
+
+static const struct udevice_id msm8960_pinctrl_ids[] = {
+	{ .compatible = "qcom,msm8960-pinctrl", .data = (ulong)&msm8960_data },
+	{ }
+};
+
+U_BOOT_DRIVER(pinctrl_msm8960) = {
+	.name = "pinctrl_msm8960",
+	.id = UCLASS_NOP,
+	.of_match = msm8960_pinctrl_ids,
+	.bind = msm8960_pinctrl_bind,
+};

-- 
2.54.0

