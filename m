From: Demeter Barna <me@fromdisposition.org>
Date: Sat, 14 Nov 2026 02:21:56 +0000
Subject: [PATCH 2/9] pinctrl: qcom: Add SM8350 pinctrl driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-sm8350-support-v1-2-414271f59474@fromdisposition.org>
References: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
In-Reply-To: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Lukasz Majewski <lukma@nabladev.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Biswapriyo Nath <nathbappai@gmail.com>, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Erikas Bitovtas <xerikasxx@gmail.com>, Johan Jonker <jbx6244@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Michael Srba <Michael.Srba@seznam.cz>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Demeter Barna <me@fromdisposition.org>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794622936; l=4747;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=2EcApNXV/eG/Pm7CCvLKbtl+vUubNR3+bLBbP8YfanQ=;
 b=5QxEqws3YtxsBbD77gO5cvrVd+5L3ukxS+juDgfmCStMBuw5PvdbmqguWMX7QoZV4G4k9nQGN
 PwXHG3Lc1DoDuWqG2q+EtGmC9q42Cadz37YIG75DWk0skeonQ0CKYhC
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the SM8350 TLMM: 203 GPIOs, the UFS reset and SDC2
special pins, and the debug UART function.

The data are those of Linux's pinctrl-sm8350 driver (tag v7.4-rc1).

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/pinctrl/qcom/Kconfig          |   8 +++
 drivers/pinctrl/qcom/Makefile         |   1 +
 drivers/pinctrl/qcom/pinctrl-sm8350.c | 101 ++++++++++++++++++++++++++++++++++
 3 files changed, 110 insertions(+)

diff --git a/drivers/pinctrl/qcom/Kconfig b/drivers/pinctrl/qcom/Kconfig
index fa0385f159..00ce340b69 100644
--- a/drivers/pinctrl/qcom/Kconfig
+++ b/drivers/pinctrl/qcom/Kconfig
@@ -187,6 +187,14 @@ config PINCTRL_QCOM_SM8250
 	  Say Y here to enable support for pinctrl on the Snapdragon SM8250 SoC,
 	  as well as the associated GPIO driver.
 
+config PINCTRL_QCOM_SM8350
+	bool "Qualcomm SM8350 Pinctrl"
+	default y if PINCTRL_QCOM_GENERIC
+	select PINCTRL_QCOM
+	help
+	  Say Y here to enable support for pinctrl on the Snapdragon SM8350 SoC,
+	  as well as the associated GPIO driver.
+
 config PINCTRL_QCOM_SM8550
 	bool "Qualcomm SM8550 Pinctrl"
 	default y if PINCTRL_QCOM_GENERIC
diff --git a/drivers/pinctrl/qcom/Makefile b/drivers/pinctrl/qcom/Makefile
index 97d59f5eac..8e49e8085a 100644
--- a/drivers/pinctrl/qcom/Makefile
+++ b/drivers/pinctrl/qcom/Makefile
@@ -25,6 +25,7 @@ obj-$(CONFIG_PINCTRL_QCOM_SM6350) += pinctrl-sm6350.o
 obj-$(CONFIG_PINCTRL_QCOM_SM7150) += pinctrl-sm7150.o
 obj-$(CONFIG_PINCTRL_QCOM_SM8150) += pinctrl-sm8150.o
 obj-$(CONFIG_PINCTRL_QCOM_SM8250) += pinctrl-sm8250.o
+obj-$(CONFIG_PINCTRL_QCOM_SM8350) += pinctrl-sm8350.o
 obj-$(CONFIG_PINCTRL_QCOM_SM8550) += pinctrl-sm8550.o
 obj-$(CONFIG_PINCTRL_QCOM_SM8650) += pinctrl-sm8650.o
 obj-$(CONFIG_PINCTRL_QCOM_X1E80100) += pinctrl-x1e80100.o
diff --git a/drivers/pinctrl/qcom/pinctrl-sm8350.c b/drivers/pinctrl/qcom/pinctrl-sm8350.c
new file mode 100644
index 0000000000..0365887d20
--- /dev/null
+++ b/drivers/pinctrl/qcom/pinctrl-sm8350.c
@@ -0,0 +1,101 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Qualcomm sm8350 pinctrl
+ *
+ * (C) Copyright 2024 Linaro Ltd.
+ * (C) Copyright 2026 Demeter Barna <me@fromdisposition.org>
+ *
+ * Based on Linux Kernel driver
+ */
+
+#include <dm.h>
+
+#include "pinctrl-qcom.h"
+
+#define MAX_PIN_NAME_LEN 32
+static char pin_name[MAX_PIN_NAME_LEN] __section(".data");
+
+static const struct pinctrl_function msm_pinctrl_functions[] = {
+	{"gpio", 0},
+	{"qup3", 1},
+};
+
+#define SDC_QDSD_PINGROUP(pg_name, ctl, pull, drv)	\
+	{					        \
+		.name = pg_name,			\
+		.ctl_reg = ctl,				\
+		.io_reg = 0,				\
+		.pull_bit = pull,			\
+		.drv_bit = drv,				\
+		.oe_bit = -1,				\
+		.in_bit = -1,				\
+		.out_bit = -1,				\
+	}
+
+#define UFS_RESET(pg_name, ctl, io)			\
+	{					        \
+		.name = pg_name,			\
+		.ctl_reg = ctl,				\
+		.io_reg = io,				\
+		.pull_bit = 3,				\
+		.drv_bit = 0,				\
+		.oe_bit = -1,				\
+		.in_bit = -1,				\
+		.out_bit = 0,				\
+	}
+
+static const struct msm_special_pin_data msm_special_pins_data[] = {
+	[0] = UFS_RESET("ufs_reset", 0xd8000, 0xd8004),
+	[1] = SDC_QDSD_PINGROUP("sdc2_clk", 0xcf000, 14, 6),
+	[2] = SDC_QDSD_PINGROUP("sdc2_cmd", 0xcf000, 11, 3),
+	[3] = SDC_QDSD_PINGROUP("sdc2_data", 0xcf000, 9, 0),
+};
+
+static const char *sm8350_get_function_name(struct udevice *dev,
+					    unsigned int selector)
+{
+	return msm_pinctrl_functions[selector].name;
+}
+
+static const char *sm8350_get_pin_name(struct udevice *dev,
+				       unsigned int selector)
+{
+	if (selector >= 203 && selector <= 206)
+		snprintf(pin_name, MAX_PIN_NAME_LEN,
+			 msm_special_pins_data[selector - 203].name);
+	else
+		snprintf(pin_name, MAX_PIN_NAME_LEN, "gpio%u", selector);
+
+	return pin_name;
+}
+
+static int sm8350_get_function_mux(__maybe_unused unsigned int pin,
+				   unsigned int selector)
+{
+	return msm_pinctrl_functions[selector].val;
+}
+
+static struct msm_pinctrl_data sm8350_data = {
+	.pin_data = {
+		.pin_count = 207,
+		.special_pins_start = 203,
+		.special_pins_data = msm_special_pins_data,
+	},
+	.functions_count = ARRAY_SIZE(msm_pinctrl_functions),
+	.get_function_name = sm8350_get_function_name,
+	.get_function_mux = sm8350_get_function_mux,
+	.get_pin_name = sm8350_get_pin_name,
+};
+
+static const struct udevice_id msm_pinctrl_ids[] = {
+	{ .compatible = "qcom,sm8350-tlmm", .data = (ulong)&sm8350_data },
+	{ /* Sentinel */ }
+};
+
+U_BOOT_DRIVER(pinctrl_sm8350) = {
+	.name		= "pinctrl_sm8350",
+	.id		= UCLASS_NOP,
+	.of_match	= msm_pinctrl_ids,
+	.ops		= &msm_pinctrl_ops,
+	.bind		= msm_pinctrl_bind,
+};

-- 
2.53.0

