From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 13 Feb 2024 00:30:15 +0800
Subject: [PATCH RFC] pinctrl: add support for HiSilicon HiSTB SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240213-pinctrl-v1-1-e71c8ead72f2@outlook.com>
X-B4-Tracking: v=1; b=H4sIAJZHymUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDIwMT3YLMvOSSohxd40RDI7PEFEsjC7NUJaDqgqLUtMwKsEnRSkFuzkq
 xtbUAFKa4UF4AAAA=
To: Tom Rini <trini@konsulko.com>
Cc: Jorge Ramirez-Ortiz <jorge.ramirez.ortiz@gmail.com>, 
 Igor Opaniuk <igor.opaniuk@foundries.io>, u-boot@lists.denx.de, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707755438; l=34662;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=UseY4dYwZjBOA/9vWMlTrlZQS+C3gZ2QX6N+ehU+YBg=;
 b=zpzNExKJ5k25YMfBMaMpMBEBrJOYXJOmlgcFB7hHHq2Y8jGDt7ZGJG+HWgqEhoEjw/Nes9EOx
 Bj1k082APDgAKBO7WfiX1ll7JiokdlbUcFdBlpY8wwXVi2Wo8ZJQo9N
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The first supported SoC is Hi3798MV200.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
This patchset adds support for HiSTB ioconfig module. The module is used
to set pins config(e.g. pull-up, pull-down, drive-strength etc..) and
pinmux.

The first supported chip is Hi3798MV200. Adding support for Hi3798CV200
should be also easy.

Below is an example of the dts node:

```dts
ioconfig: pinctrl@8a21000 {
	compatible = "hisilicon,hi3798mv200-ioconfig";
	reg = <0x8a21000 0x180>;
	#pinctrl-cells = <1>;

	emmc_default: emmc-default-state {
		cdata-pins {
			// CDATA0-7
			pins = "W20", "V20", "U20", "V19", "Y21", "W21", "V21", "U21";
			bias-pullup;
			slew-rate = <1>;

			drive-strength = <8>;
			function = "emmc_cdata";
		};

		cclk-pin {
			pins = "T18";

			bias-pullup;
			slew-rate = <1>;

			drive-strength = <8>;
			function = "emmc_cclk";
		};

		ccmd-pin {
			pins = "T20";

			bias-pullup;
			slew-rate = <1>;

			drive-strength = <6>;
			function = "emmc_ccmd";
		};

		reset-pin {
			pins = "R20";

			bias-disable;
			slew-rate = <1>;

			drive-strength = <1>;
			function = "emmc_rst";
		};

		datastrobe-pin {
			pins = "R21";

			bias-pullup;
			slew-rate;

			drive-strength = <1>;
			function = "emmc_datastrobe";
		};
	};
};
```
---
 drivers/pinctrl/Kconfig                        |   1 +
 drivers/pinctrl/Makefile                       |   1 +
 drivers/pinctrl/hisilicon/Kconfig              |  21 ++
 drivers/pinctrl/hisilicon/Makefile             |   6 +
 drivers/pinctrl/hisilicon/pinctrl-hi3798mv2x.c | 319 +++++++++++++++++++++++++
 drivers/pinctrl/hisilicon/pinctrl-histb.c      | 276 +++++++++++++++++++++
 drivers/pinctrl/hisilicon/pinctrl-histb.h      | 132 ++++++++++
 7 files changed, 756 insertions(+)

diff --git a/drivers/pinctrl/Kconfig b/drivers/pinctrl/Kconfig
index a1d53cfbdb..d600a30492 100644
--- a/drivers/pinctrl/Kconfig
+++ b/drivers/pinctrl/Kconfig
@@ -346,6 +346,7 @@ endif
 
 source "drivers/pinctrl/broadcom/Kconfig"
 source "drivers/pinctrl/exynos/Kconfig"
+source "drivers/pinctrl/hisilicon/Kconfig"
 source "drivers/pinctrl/intel/Kconfig"
 source "drivers/pinctrl/mediatek/Kconfig"
 source "drivers/pinctrl/meson/Kconfig"
diff --git a/drivers/pinctrl/Makefile b/drivers/pinctrl/Makefile
index 0e929d8ca0..79fb800faf 100644
--- a/drivers/pinctrl/Makefile
+++ b/drivers/pinctrl/Makefile
@@ -36,3 +36,4 @@ obj-$(CONFIG_$(SPL_)PINCTRL_STMFX)	+= pinctrl-stmfx.o
 obj-y				+= broadcom/
 obj-$(CONFIG_PINCTRL_ZYNQMP)	+= pinctrl-zynqmp.o
 obj-$(CONFIG_PINCTRL_STARFIVE)	+= starfive/
+obj-$(CONFIG_PINCTRL_HISILICON)	+= hisilicon/
diff --git a/drivers/pinctrl/hisilicon/Kconfig b/drivers/pinctrl/hisilicon/Kconfig
new file mode 100644
index 0000000000..33c3048940
--- /dev/null
+++ b/drivers/pinctrl/hisilicon/Kconfig
@@ -0,0 +1,21 @@
+config PINCTRL_HISILICON
+	bool
+
+config PINCTRL_HISTB
+	bool "HiSilicon HiSTB pinctrl framework"
+	depends on PINCTRL
+	select PINCTRL_HISILICON
+	imply PINCONF
+	help
+	  Support HiSTB SoCs IOCONFIG module
+
+menu "HiSTB pinctrl drivers"
+	depends on PINCTRL_HISTB
+
+config PINCTRL_HI3798MV2X
+	bool "HiSilicon Hi3798MV2X pinctrl driver"
+	depends on ARCH_HI3798MV2X
+	help
+	  Support IOCONFIG on Hi3798MV2X SoCs
+
+endmenu
diff --git a/drivers/pinctrl/hisilicon/Makefile b/drivers/pinctrl/hisilicon/Makefile
new file mode 100644
index 0000000000..5afb64d4b6
--- /dev/null
+++ b/drivers/pinctrl/hisilicon/Makefile
@@ -0,0 +1,6 @@
+# SPDX-License-Identifier: GPL-2.0-or-later
+#
+# Copyright 2024 (r) Yang Xiwen <forbidden405@foxmail.com>
+
+obj-$(CONFIG_PINCTRL_HISTB)		+= pinctrl-histb.o
+obj-$(CONFIG_PINCTRL_HI3798MV2X)	+= pinctrl-hi3798mv2x.o
diff --git a/drivers/pinctrl/hisilicon/pinctrl-hi3798mv2x.c b/drivers/pinctrl/hisilicon/pinctrl-hi3798mv2x.c
new file mode 100644
index 0000000000..1e0a89675a
--- /dev/null
+++ b/drivers/pinctrl/hisilicon/pinctrl-hi3798mv2x.c
@@ -0,0 +1,319 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * IOCONFIG driver for Hi3798MV2x SoCs
+ *
+ * Copyright 2024 (r) Yang Xiwen <forbidden405@outlook.com>
+ */
+
+#include <dm/device.h>
+
+#include "pinctrl-histb.h"
+
+// The sequence is important!
+enum hi3798mv2x_ioconfig_pins {
+	HI3798MV2X_Y19,
+	HI3798MV2X_W19,
+	HI3798MV2X_AA20,
+	HI3798MV2X_Y20,
+	HI3798MV2X_V19,
+	HI3798MV2X_Y21,
+	HI3798MV2X_W20,
+	HI3798MV2X_W21,
+	HI3798MV2X_V20,
+	HI3798MV2X_V21,
+	HI3798MV2X_U20,
+	HI3798MV2X_U21,
+	HI3798MV2X_T18,
+	HI3798MV2X_T19,
+	HI3798MV2X_T20,
+	HI3798MV2X_R20,
+	HI3798MV2X_R21,
+	HI3798MV2X_P20,
+	HI3798MV2X_R19,
+	HI3798MV2X_K18,
+	HI3798MV2X_J17,
+	HI3798MV2X_J18,
+	HI3798MV2X_H17,
+	HI3798MV2X_H18,
+	HI3798MV2X_K20,
+	HI3798MV2X_K19,
+	HI3798MV2X_J20,
+	HI3798MV2X_J19,
+	HI3798MV2X_H21,
+	HI3798MV2X_H20,
+	HI3798MV2X_H19,
+	HI3798MV2X_G20,
+	HI3798MV2X_G19,
+	HI3798MV2X_F21,
+	HI3798MV2X_F20,
+	HI3798MV2X_F19,
+	HI3798MV2X_E20,
+	HI3798MV2X_E19,
+	HI3798MV2X_D21,
+	HI3798MV2X_E18,
+	HI3798MV2X_C20,
+	HI3798MV2X_D19,
+	HI3798MV2X_B21,
+	HI3798MV2X_B18,
+	HI3798MV2X_C17,
+	HI3798MV2X_B17,
+	HI3798MV2X_A17,
+	HI3798MV2X_C16,
+	HI3798MV2X_B16,
+	HI3798MV2X_B4,
+	HI3798MV2X_C4,
+	HI3798MV2X_A3,
+	HI3798MV2X_B3,
+	HI3798MV2X_A2,
+	HI3798MV2X_B2,
+	HI3798MV2X_A6,
+	HI3798MV2X_C6,
+	HI3798MV2X_C5,
+	HI3798MV2X_C3,
+	HI3798MV2X_D4,
+	HI3798MV2X_D3,
+	HI3798MV2X_B1,
+	HI3798MV2X_C2,
+	HI3798MV2X_C1,
+	HI3798MV2X_A5,
+	HI3798MV2X_D5,
+};
+
+/* incomplete (yet) */
+static const struct histb_pin_function_desc hi3798mv2x_pin_funcs[] = {
+	HISTB_PIN_FUNC(0, "emmc_cdata", ((struct histb_pin_func_setup_entry[]){
+		       { HI3798MV2X_V19, 0x2 }, { HI3798MV2X_Y21, 0x2 }, { HI3798MV2X_W20, 0x2 },
+		       { HI3798MV2X_W21, 0x2 }, { HI3798MV2X_V20, 0x2 }, { HI3798MV2X_V21, 0x2 },
+		       { HI3798MV2X_U20, 0x2 }, { HI3798MV2X_U21, 0x2 }, })),
+	HISTB_PIN_FUNC(1, "emmc_cclk",
+		       ((struct histb_pin_func_setup_entry[]){ { HI3798MV2X_T18, 0x2 } })),
+	HISTB_PIN_FUNC(2, "emmc_ccmd",
+		       ((struct histb_pin_func_setup_entry[]){ { HI3798MV2X_T20, 0x2 } })),
+	HISTB_PIN_FUNC(3, "emmc_rst",
+		       ((struct histb_pin_func_setup_entry[]){ { HI3798MV2X_R20, 0x2 } })),
+	HISTB_PIN_FUNC(4, "emmc_datastrobe",
+		       ((struct histb_pin_func_setup_entry[]){ { HI3798MV2X_R21, 0x2 } })),
+};
+
+/* Frequentely used drive strength table */
+#define DRIVE_STRENGTH_TABLE_SAMPLE_A ((const u8[]){ 4, 3, 2, 1, 0 })
+#define DRIVE_STRENGTH_TABLE_SAMPLE_B ((const u8[]){ 18, 17, 16, 15, 13, 12, 11, 10, 9, 8, 7, 6, 4, 3, 2, 1, 0 })
+
+static const struct histb_pin_desc hi3798mv2x_pins[] = {
+	HISTB_PIN(HI3798MV2X_Y19, "Y19", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO0_0", 0x0 }, { "NF_RDY", 0x1 }, { } }),
+		  HISTB_PIN_FLAG_NOPD),
+	HISTB_PIN(HI3798MV2X_W19, "W19", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO0_1", 0x0 }, { "NF_CSN", 0x1 }, { } }),
+		  HISTB_PIN_FLAG_NOPD),
+	HISTB_PIN(HI3798MV2X_AA20, "AA20", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO0_2", 0x0 }, { "NF_DQSN", 0x1 }, { "BOOT_SEL2", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_Y20, "Y20", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[]){ { "NF_DQS", 0x1 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_V19, "V19", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO0_4", 0x0 }, { "NF_DQ7", 0x1 }, { "EMMC_CDATA3", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_Y21, "Y21", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO0_5", 0x0 }, { "NF_DQ6", 0x1 }, { "EMMC_CDATA4", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_W20, "W20", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO0_6", 0x0 }, { "NF_DQ5", 0x1 }, { "EMMC_CDATA0", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_W21, "W21", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO0_7", 0x0 }, { "NF_DQ4", 0x1 }, { "EMMC_CDATA5", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_V20, "V20", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO1_0", 0x0 }, { "NF_DQ3", 0x1 }, { "EMMC_CDATA1", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_V21, "V21", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO1_1", 0x0 }, { "NF_DQ2", 0x1 }, { "EMMC_CDATA6", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_U20, "U20", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO1_2", 0x0 }, { "NF_DQ1", 0x1 }, { "EMMC_CDATA2", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_U21, "U21", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO1_3", 0x0 }, { "NF_DQ0", 0x1 }, { "EMMC_CDATA7", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_T18, "T18", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO1_4", 0x0 }, { "NF_WEN", 0x1 }, { "EMMC_CCLK_OUT", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_T19, "T19", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO1_5", 0x0 }, { "NF_ALE", 0x1 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_T20, "T20", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO1_6", 0x0 }, { "NF_CLE", 0x1 }, { "EMMC_CCMD", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_R20, "R20", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO1_7", 0x0 }, { "NF_REC", 0x1 }, { "EMMC_RST", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_R21, "R21", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO2_0", 0x0 }, { "NF_REN", 0x1 }, { "EMMC_DATA_STROBE", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_P20, "P20", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "PMC_CORE0", 0x0 }, { "I2C0_SDA", 0x1 }, { "GPIO2_1", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_R19, "R19", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "PMC_GPU0", 0x0 }, { "I2C0_SCL", 0x1 }, { "GPIO2_2", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_K18, "K18", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]) { { "GPIO2_3", 0x0 }, { "SATA0_PWREN", 0x1 },
+		   { "UART3_CTSN", 0x2 }, { "TSI0_D7", 0x3 }, { "TSI3_CLK", 0x4 }, { "SIM1_DATA", 0x5 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_J17, "J17", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[])
+		   { { "GPIO2_4", 0x0 }, { "SATA0_LED_N", 0x1 }, { "UART3_RTSN", 0x2 }, { "TSI1_SYNC", 0x3 },
+		   { "TSI1_D1", 0x4 }, { "TSI0D6", 0x5 }, { "TSI3_VALID", 0x6 }, { "SIM1DET", 0x7 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_J18, "J18", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO2_5", 0x0 }, { "UART3_RXD", 0x1 },
+		   { "TSI1_D0", 0x2 }, { "TSIO_D5", 0x3 }, { "TSI3_D0", 0x4 }, { "SIM1_RST", 0x5 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_H17, "H17", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO2_6", 0x0 }, { "UART3_TXD", 0x1 },
+		   { "TSI1_CLK", 0x2 }, { "TSIO_D4", 0x3 }, { "TSI2_VALID", 0x4 }, { "SIM1_CLK", 0x5 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_H18, "H18", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO2_7", 0x0 }, { "I2C2_SDA", 0x1 },
+		   { "TSI1_VALID", 0x2 }, { "TSIO_D3", 0x3 }, { "TSI2_D0", 0x4 }, { "SIM1_PWREN", 0x5 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_K20, "K20", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "JTAG_TRSTN", 0x0 }, { "I2C2_SCL", 0x1 },
+		   { "SPI0_SD0", 0x2 }, { "SIM0_DATA", 0x3 }, { "GPIO3_0", 0x4 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_K19, "K19", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "JTAG_TDI", 0x0 }, { "SPIO_CSN", 0x1 },
+		   { "SIM0_DET", 0x2 }, { "GPIO3_1", 0x3 }, { "UART2_CTSN", 0x4 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_J20, "J20", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "JTAG_TMS", 0x0 }, { "I2S_RX_BCLK", 0x1 },
+		   { "SPI0_SCLK", 0x2 }, { "SIM0_RST", 0x3 }, { "GPIO3_2", 0x4 }, { "UART2_TXD", 0x5 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_J19, "J19", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "JTAG_TCK", 0x0 }, { "I2S_RX_WS", 0x1 },
+		   { "SPI0_SDI", 0x2 }, { "SIM0_CLK", 0x3 }, { "GPIO3_3", 0x4 }, { "UART2_RXD", 0x5 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_H21, "H21", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "JTAG_TDO", 0x0 }, { "I2S_RX_MCLK", 0x1 },
+		   { "I2S_DOUT3", 0x2 }, { "SIM0_PWREN", 0x3 }, { "GPIO3_4", 0x4 }, { "UART2_RTSN", 0x5 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_H20, "H20", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO3_5", 0x0 }, { "I2S_MCLK", 0x1 },
+		   { "I2S_DOUT2", 0x2 }, { "SF_WPN_IO2", 0x3 }, { "TSO0_SYNC", 0x4 }, { } }), HISTB_PIN_FLAG_NOPD),
+	HISTB_PIN(HI3798MV2X_H19, "H19", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO3_6", 0x0 }, { "I2S_WS", 0x1 },
+		   { "I2S_DOUT1", 0x2 }, { "TSI1_SYNC", 0x3 }, { "TSI1_D1", 0x4 }, { "SF_SDI_IO1", 0x5 },
+		   { "TSO0_VALID", 0x6 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_G20, "G20", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO3_7", 0x0 }, { "I2S_DOUT0", 0x1 },
+		   { "TSI1_D0", 0x3 }, { "SF_CSN", 0x5 }, { "TSO0_CLK", 0x6 }, { } }), HISTB_PIN_FLAG_NOPD),
+	HISTB_PIN(HI3798MV2X_G19, "G19", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO4_0", 0x0 }, { "I2S_BCLK", 0x1 },
+		   { "I2S_WS", 0x2 }, { "TSI1_CLK", 0x3 }, { "SF_HOLDN_IO3", 0x5 }, { "TSO0_D0", 0x6 }, { } }),
+		  HISTB_PIN_FLAG_NOPD),
+	HISTB_PIN(HI3798MV2X_F21, "F21", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO4_1", 0x0 }, { "I2S_DIN", 0x1 },
+		   { "I2S_BCLK", 0x2 }, { "TSI1_VALID", 0x3 }, { "SF_CLK", 0x5 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_F20, "F20", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO4_2", 0x0 }, { "SDIO1_CWPR", 0x1 },
+		   { "I2S_MCLK", 0x2 }, { "SF_SDO_IO0", 0x4 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_F19, "F19", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO4_3", 0x0 }, { "SDIO1_CARD_POWER_EN", 0x1 },
+		   { "I2C1_SCL", 0x3 }, { "I2S_RX_BCLK", 0x4 }, { "TSI0_D2", 0x5 }, { "TSI2_CLK", 0x6 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_E20, "E20", ((const u8[]){ 18, 16, 14, 12, 5, 4, 2, 1, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO4_4", 0x0 }, { "SDIO1_CDATA1", 0x1 },
+		   { "I2S_RX_WS", 0x4 }, { "TSI0_D1", 0x5 }, { "I2C1_SDA", 0x6 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_E19, "E19", ((const u8[]){ 18, 16, 14, 12, 5, 4, 2, 1, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO4_5", 0x0 }, { "SDIO1_CDATA0", 0x1 },
+		   { "TSI0_D1", 0x2 }, { "TSI0_SYNC", 0x3 }, { "I2S_RX_MCLK", 0x4 }, { "TSI0_DO", 0x5 },
+		   { "I2C1_SCL", 0x6 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_D21, "D21", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO4_6", 0x0 }, { "SDIO1_CCLK_OUT", 0x1 },
+		   { "TSI0_DO", 0x3 }, { "I2S_MCLK", 0x4 }, { "TSI0_CLK", 0x5 }, { "TSI1_VALID", 0x6 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_E18, "E18", ((const u8[]){ 18, 16, 14, 12, 5, 4, 2, 1, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO4_7", 0x0 }, { "SDIO1_CCMD", 0x1 },
+		   { "TSI0_CLK", 0x3 }, { "I2S_WS", 0x4 }, { "TSI0_VALID", 0x5 }, { "TSI1_D0", 0x6 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_C20, "C20", ((const u8[]){ 18, 16, 14, 12, 5, 4, 2, 1, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO6_0", 0x0 }, { "SDIO1_CDATA3", 0x1 },
+		   { "TSI1_CLK", 0x2 }, { "TSI0_VALID", 0x3 }, { "I2S_DOUT0", 0x4 }, { "I2C2_SCL", 0x5 },
+		   { "TSI0_VALID", 0x6 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_D19, "D19", ((const u8[]){ 18, 16, 14, 12, 5, 4, 2, 1, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO6_1", 0x0 }, { "SDIO1_CDATA2", 0x1 },
+		   { "I2C2_SCL", 0x3 }, { "I2S_BCLK", 0x4 }, { "I2C2_SDA", 0x5 }, { "TSI0_D0", 0x6 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_B21, "B21", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO6_2", 0x0 }, { "SDIO1_CARD_DETECT", 0x1 },
+		   { "I2C2_SDA", 0x3 }, { "I2S_DIN", 0x4 }, { "TSI0_CLK", 0x6 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_B18, "B18", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "JTAG_SEL", 0x0 }, { "GPIO6_3", 0x1 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_C17, "C17", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO6_4", 0x0 }, { "SPDIF_OUT", 0x1 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_B17, "B17", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "HDMITX_HOTPLUG", 0x1 }, { "GPIO6_5", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_A17, "A17", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "HDMITX_SDA", 0x1 }, { "GPIO6_6", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_C16, "C16", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "HDMITX_SCL", 0x1 }, { "GPIO6_7", 0x2 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_B16, "B16", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "HDMITX_CEC", 0x1 }, { "GPIO7_0", 0x2 }, { } }),
+		  HISTB_PIN_FLAG_NOPU | HISTB_PIN_FLAG_NOPD | HISTB_PIN_FLAG_NOSR),
+	HISTB_PIN(HI3798MV2X_B4, "B4", ((const u8[]){ 18, 16, 14, 12, 10, 8, 6, 4, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO7_4", 0x0 }, { "RGMII_RXCK", 0x1 },
+		   { "RMII_TXD1", 0x2 }, { "SDIOO_CDATA1", 0x3 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_C4, "C4", ((const u8[]){ 18, 16, 14, 12, 10, 8, 6, 4, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO7_5", 0x0 }, { "RGMII_RXDV", 0x1 },
+		   { "RMII_TXD0", 0x2 }, { "SDIO0_CDATA0", 0x3 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_A3, "A3", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO7_6", 0x0 }, { "RGMII_RXD0", 0x1 },
+		   { "RMII_TXEN", 0x2 }, { "SDIO0_CCLK_OUT", 0x3 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_B3, "B3", ((const u8[]){ 18, 16, 14, 12, 10, 8, 6, 4, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO7_7", 0x0 }, { "RGMII_RXD1", 0x1 },
+		   { "RMII_RXDV", 0x2 }, { "SDIO0_CCMD", 0x3 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_A2, "A2", ((const u8[]){ 18, 16, 14, 12, 10, 8, 6, 4, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO8_0", 0x0 }, { "RGMII_RXD2", 0x1 },
+		   { "RMII_RXD0", 0x2 }, { "SDIO0_CDATA3", 0x3 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_B2, "B2", ((const u8[]){ 18, 16, 14, 12, 10, 8, 6, 4, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO8_1", 0x0 }, { "RGMII_RXD3", 0x1 },
+		   { "RMII_RXD1", 0x2 }, { "SDIOO_CDATA2", 0x3 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_A6, "A6", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO7_1", 0x0 }, { "RGMII_RST", 0x1 },
+		   { "UART3_TXD", 0x2 }, { "FE_LED_ACT", 0x3 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_C6, "C6", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO7_2", 0x0 }, { "RGMII_MDIO", 0x1 },
+		   { "UART3_RXD", 0x2 }, { "FE_LED_BASE", 0x3 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_C5, "C5", DRIVE_STRENGTH_TABLE_SAMPLE_A,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO7_3", 0x0 }, { "RGMII_MDCK", 0x1 },
+		   { "RMII_RST", 0x2 }, { "SDIO0_CARD_DETECT", 0x3 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_C3, "C3", ((const u8[]){ 18, 16, 14, 12, 10, 8, 6, 4, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO8_2", 0x0 }, { "RGMII_TXEN", 0x1 },
+		   { "BOOT_SEL0", 0x2 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_D4, "D4", ((const u8[]){ 18, 16, 14, 12, 10, 8, 6, 4, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO8_3", 0x0 }, { "RGMII_TXCK", 0x1 },
+		   { "UART3_CTSN", 0x2 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_D3, "D3", ((const u8[]){ 18, 16, 14, 12, 10, 8, 6, 4, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO8_4", 0x0 }, { "RGMII_TXD3", 0x1 },
+		   { "UART3_RTSN", 0x2 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_B1, "B1", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO8_5", 0x0 }, { "RGMII_TXD2", 0x1 },
+		   { "RMII_MDCK", 0x2 }, { "BOOT_SEL1", 0x3 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_C2, "C2", ((const u8[]){ 18, 16, 14, 12, 10, 8, 6, 4, 0 }),
+		  ((const struct histb_pin_mux_desc[]){ { "RGMII_TXD1", 0x1 }, { "RMII_MDI0", 0x2 },
+		   { "SDIO0_CWPR", 0x3 }, { "GPIO8_6", 0x4 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_C1, "C1", DRIVE_STRENGTH_TABLE_SAMPLE_B,
+		  ((const struct histb_pin_mux_desc[]){ { "RGMII_TXDO", 0x1 }, { "RMII_REFCLK", 0x2 },
+		   { "SDIO0_CARD_POWER_EN", 0x3 }, { "GPIO8_7", 0x4 }, { } }), HISTB_PIN_FLAG_HAS_SCHMITT),
+	HISTB_PIN(HI3798MV2X_A5, "A5", ((const u8 *)NULL),
+		  ((const struct histb_pin_mux_desc[]){ { "GPIO9_0", 0x0 }, { "CLKOUT_25M", 0x1 }, { } }), 0),
+	HISTB_PIN(HI3798MV2X_D5, "D5", ((const u8 *)NULL),
+		  ((const struct histb_pin_mux_desc[]){ { "PMC_CPU0", 0x0 }, { "GPIO9_1", 0x1 }, { } }),
+		  HISTB_PIN_FLAG_NOPU | HISTB_PIN_FLAG_NOPD | HISTB_PIN_FLAG_NOSR),
+};
+
+static struct histb_pinctrl_priv hi3798mv2x_pinctrl_priv = {
+	.pins = hi3798mv2x_pins,
+	.funcs = hi3798mv2x_pin_funcs,
+	.pin_nums = ARRAY_SIZE(hi3798mv2x_pins),
+	.func_nums = ARRAY_SIZE(hi3798mv2x_pin_funcs),
+};
+
+static const struct udevice_id hi3798mv2x_pinctrl_match[] = {
+	{ .compatible = "hisilicon,hi3798mv200-ioconfig", .data = (ulong)&hi3798mv2x_pinctrl_priv },
+	{ },
+};
+
+U_BOOT_DRIVER(hi3798mv2x_pinctrl) = {
+	.name		= "hi3798mv2x_pinctrl",
+	.id		= UCLASS_PINCTRL,
+	.of_match	= hi3798mv2x_pinctrl_match,
+	.of_to_plat	= histb_pinctrl_of_to_plat,
+	.ops		= &histb_pinctrl_ops,
+};
diff --git a/drivers/pinctrl/hisilicon/pinctrl-histb.c b/drivers/pinctrl/hisilicon/pinctrl-histb.c
new file mode 100644
index 0000000000..d0521c3459
--- /dev/null
+++ b/drivers/pinctrl/hisilicon/pinctrl-histb.c
@@ -0,0 +1,276 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * IOCONFIG pinctrl driver for HiSTB SoCs
+ *
+ * Copyright 2024 (r) Yang Xiwen <forbidden405@outlook.com>
+ */
+
+#include <asm/io.h>
+#include <dm/device.h>
+#include <dm/device_compat.h>
+#include <dm/device-internal.h>
+#include <dm/pinctrl.h>
+#include <dm/read.h>
+#include <linux/bitfield.h>
+#include <linux/kernel.h>
+#include <linux/types.h>
+
+#include "pinctrl-histb.h"
+
+static int histb_pinctrl_get_pins_count(struct udevice *dev)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+
+	return priv->pin_nums;
+}
+
+static const char *histb_pinctrl_get_pin_name(struct udevice *dev, unsigned int selector)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+
+	return priv->pins[selector].name;
+}
+
+static int histb_pinctrl_get_functions_count(struct udevice *dev)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+
+	return priv->func_nums;
+}
+
+static const char *histb_pinctrl_get_function_name(struct udevice *dev, unsigned int selector)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+
+	return priv->funcs[selector].name;
+}
+
+static int histb_pinctrl_pinmux_set(struct udevice *dev, unsigned int pin_selector,
+				    unsigned int func_selector)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+	const struct histb_pin_function_desc *func = &priv->funcs[func_selector];
+	const struct histb_pin_func_setup_entry *func_setup_tbl = func->cfg_tbl;
+	int i;
+	u32 reg;
+	void __iomem *pin_reg = (u32 *)priv->base + priv->pins[pin_selector].number;
+	bool found = false;
+
+	for (i = 0; i < func->pins_num; i++) {
+		if (func_setup_tbl[i].pin_selector == pin_selector) {
+			reg = readl(pin_reg);
+			reg &= ~HISTB_PIN_FUNC_MASK;
+			reg |= func_setup_tbl[i].mask;
+			writel(reg, pin_reg);
+
+			found = true;
+			break;
+		}
+	}
+
+	if (!found) {
+		dev_err(dev, "Unable to set pin %d to the given function %d\n",
+			pin_selector, func_selector);
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+static const struct pinconf_param histb_pinctrl_pinconf_params[] = {
+	{ "bias-disable", PIN_CONFIG_BIAS_DISABLE, 0 },
+	{ "bias-pulldown", PIN_CONFIG_BIAS_PULL_DOWN, 0 },
+	{ "bias-pullup", PIN_CONFIG_BIAS_PULL_UP, 0 },
+	{ "input-schmitt-enable", PIN_CONFIG_INPUT_SCHMITT_ENABLE, 1 },
+	{ "input-schmitt-disable", PIN_CONFIG_INPUT_SCHMITT_ENABLE, 0 },
+	{ "drive-strength", PIN_CONFIG_DRIVE_STRENGTH, 1 },
+	{ "slew-rate", PIN_CONFIG_SLEW_RATE, 1 },
+};
+
+enum histb_pinctrl_bias_status {
+	BIAS_PULL_DOWN,
+	BIAS_PULL_UP,
+	BIAS_DISABLE,
+};
+
+static int histb_pinctrl_set_bias(struct udevice *dev, unsigned int selector,
+				  enum histb_pinctrl_bias_status status)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+	void __iomem *pin_reg = (u32 *)priv->base + priv->pins[selector].number;
+	u32 reg = readl(pin_reg);
+
+	reg &= ~(HISTB_PIN_PULLDOWN | HISTB_PIN_PULLUP);
+
+	switch (status) {
+	case BIAS_DISABLE:
+		break;
+	case BIAS_PULL_DOWN:
+		reg |= HISTB_PIN_PULLDOWN;
+		break;
+	case BIAS_PULL_UP:
+		reg |= HISTB_PIN_PULLUP;
+		break;
+	}
+
+	writel(reg, pin_reg);
+
+	return 0;
+}
+
+static int histb_pinctrl_set_slew_rate(struct udevice *dev, unsigned int pin_selector,
+				       unsigned int argument)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+	void __iomem *pin_reg = (u32 *)priv->base + priv->pins[pin_selector].number;
+	u32 reg = readl(pin_reg);
+
+	if (likely(argument == 1)) {
+		reg |= HISTB_PIN_SLEWRATE;
+	} else if (argument == 0) {
+		reg &= ~HISTB_PIN_SLEWRATE;
+	} else {
+		dev_err(dev, "slew rate argument can be only 0 or 1!\n");
+		return -EINVAL;
+	}
+
+	writel(reg, pin_reg);
+
+	return 0;
+}
+
+static int histb_pinctrl_set_schmitt(struct udevice *dev, unsigned int pin_selector,
+				     unsigned int argument)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+	void __iomem *pin_reg = (u32 *)priv->base + priv->pins[pin_selector].number;
+	u32 reg = readl(pin_reg);
+
+	if (likely(argument == 0)) {
+		reg &= ~HISTB_PIN_SCHMITT;
+	} else if (argument == 1) {
+		reg |= HISTB_PIN_SCHMITT;
+	} else {
+		dev_err(dev, "schmitt argument can be only 0 or 1!\n");
+		return -EINVAL;
+	}
+
+	writel(reg, pin_reg);
+
+	return 0;
+}
+
+static int histb_pinctrl_set_drive_strength(struct udevice *dev, unsigned int pin_selector,
+					    unsigned int argument)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+	const u8 *drv_tbl = priv->pins[pin_selector].drv_tbl;
+	void __iomem *pin_reg = (u32 *)priv->base + priv->pins[pin_selector].number;
+	u32 reg = readl(pin_reg);
+	int i = -1;
+
+	if (unlikely(argument == 0)) {
+		dev_err(dev, "the minimal drive strength is 1mA!\n");
+		return -EINVAL;
+	}
+
+	if (unlikely(!drv_tbl)) {
+		dev_err(dev, "pin %u does not support setting drive strength!\n", pin_selector);
+		return -ENOENT;
+	}
+
+	// calculate the largest drive-strength that does not exceeds the given value
+	// if the lowest value is still too large, use that anyway
+	// TODO: use bsearch()?
+	while (drv_tbl[++i] > argument)
+		;
+
+	if (!drv_tbl[i])
+		i--;
+
+	reg &= ~HISTB_PIN_DRV_MASK;
+	reg |= FIELD_PREP(HISTB_PIN_DRV_MASK, i);
+
+	debug("%s: setting drive strength of pin %s to %d\n", __func__, priv->pins[pin_selector].name, drv_tbl[i]);
+	writel(reg, pin_reg);
+
+	return 0;
+}
+
+static int histb_pinctrl_pinconf_set(struct udevice *dev, unsigned int pin_selector,
+				     unsigned int param, unsigned int argument)
+{
+	switch (param) {
+	case PIN_CONFIG_BIAS_DISABLE:
+		return histb_pinctrl_set_bias(dev, pin_selector, BIAS_DISABLE);
+	case PIN_CONFIG_BIAS_PULL_UP:
+		return histb_pinctrl_set_bias(dev, pin_selector, BIAS_PULL_UP);
+	case PIN_CONFIG_BIAS_PULL_DOWN:
+		return histb_pinctrl_set_bias(dev, pin_selector, BIAS_PULL_DOWN);
+	case PIN_CONFIG_SLEW_RATE:
+		return histb_pinctrl_set_slew_rate(dev, pin_selector, argument);
+	case PIN_CONFIG_INPUT_SCHMITT_ENABLE:
+		return histb_pinctrl_set_schmitt(dev, pin_selector, argument);
+	case PIN_CONFIG_DRIVE_STRENGTH:
+		return histb_pinctrl_set_drive_strength(dev, pin_selector, argument);
+	}
+
+	dev_err(dev, "can't handle given config %d\n", param);
+	return -EINVAL;
+}
+
+static int histb_pinctrl_get_pin_muxing(struct udevice *dev, unsigned int selector,
+					char *buf, int size)
+{
+	struct histb_pinctrl_priv *priv = dev_get_priv(dev);
+	const struct histb_pin_mux_desc *desc = priv->pins[selector].func_tbl;
+	u32 reg = readl((u32 *)priv->base + priv->pins[selector].number);
+	bool found = false;
+	int current;
+
+	current = FIELD_GET(HISTB_PIN_FUNC_MASK, reg);
+
+	while (desc->name) {
+		if (desc->bits == current) {
+			strlcpy(buf, desc->name, size);
+			found = true;
+			break;
+		}
+		desc++;
+	}
+
+	if (!found) {
+		dev_warn(dev, "unknown pinmux selected\n");
+		strcpy(buf, "UNKNOWN!");
+	}
+
+	return 0;
+}
+
+const struct pinctrl_ops histb_pinctrl_ops = {
+	.get_pins_count = histb_pinctrl_get_pins_count,
+	.get_pin_name = histb_pinctrl_get_pin_name,
+	.get_functions_count = histb_pinctrl_get_functions_count,
+	.get_function_name = histb_pinctrl_get_function_name,
+	.pinmux_set = histb_pinctrl_pinmux_set,
+	.pinconf_num_params = ARRAY_SIZE(histb_pinctrl_pinconf_params),
+	.pinconf_params = histb_pinctrl_pinconf_params,
+	.pinconf_set = histb_pinctrl_pinconf_set,
+	.set_state = pinctrl_generic_set_state,
+	.get_pin_muxing = histb_pinctrl_get_pin_muxing,
+};
+
+int histb_pinctrl_of_to_plat(struct udevice *dev)
+{
+	struct histb_pinctrl_priv *priv = (void *)dev_get_driver_data(dev);
+
+	priv->base = dev_remap_addr(dev);
+	if (!priv->base) {
+		dev_err(dev, "failed to remap addr\n");
+		return -EINVAL;
+	}
+
+	dev_set_priv(dev, priv);
+
+	return 0;
+}
diff --git a/drivers/pinctrl/hisilicon/pinctrl-histb.h b/drivers/pinctrl/hisilicon/pinctrl-histb.h
new file mode 100644
index 0000000000..6169534139
--- /dev/null
+++ b/drivers/pinctrl/hisilicon/pinctrl-histb.h
@@ -0,0 +1,132 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+
+#include <dm/pinctrl.h>
+#include <linux/bitops.h>
+
+/* per-register bit definition */
+#define HISTB_PIN_SCHMITT	BIT(14)
+#define HISTB_PIN_PULLDOWN	BIT(13)
+#define HISTB_PIN_PULLUP	BIT(12)
+#define HISTB_PIN_SLEWRATE	BIT(8)
+#define HISTB_PIN_DRV_MASK	GENMASK(7, 4)
+#define HISTB_PIN_FUNC_MASK	GENMASK(2, 0)
+
+/**
+ * @histb_pin_desc flags
+ *
+ * @HISTB_PIN_FLAG_NOPU: This pin does not support "bias-pullup"
+ * @HISTB_PIN_FLAG_NOPD: This pin does not support "bias-pulldown"
+ * @HISTB_PIN_FLAG_NOSR: This pin does not support "slew-rate"
+ * @HISTB_PIN_FLAG_HAS_SCHMITT: This pin supports setting schmitt
+ */
+#define HISTB_PIN_FLAG_NOPU	BIT(0)
+#define HISTB_PIN_FLAG_NOPD	BIT(1)
+#define HISTB_PIN_FLAG_NOSR	BIT(2)
+#define HISTB_PIN_FLAG_HAS_SCHMITT	BIT(3)
+
+/**
+ * histb_pin_mux_desc - a descriptor for one function of a pin.
+ *
+ * @name: the name of the function, in capital
+ * @bits: the bits pattern for this function
+ */
+struct histb_pin_mux_desc {
+	const char *name;
+	u32 bits;
+};
+
+/**
+ * histb_pin_desc - a descriptor for a pin
+ *
+ * @number: ID for this pin, also used as offset into device address space
+ * @name: pin name, e.g. "F17", refer to the datasheet for detail
+ * @drv_tbl: (Optional) drive strength table, end with 0. The index is used as bits pattern. fill
+ * NULL if setting drive strength is not supported.
+ * @func_tbl: pinmux function table, end with { }.
+ * @flags: pin flags (use HISTB_PIN_FLAG_* constants)
+ */
+struct histb_pin_desc {
+	unsigned int number;
+	const char *name;
+	const u8 *drv_tbl;
+	const struct histb_pin_mux_desc *func_tbl;
+	int flags;
+};
+
+/**
+ * HISTB_PIN() - a helper for initializing struct histb_pin_desc
+ */
+#define HISTB_PIN(_index, _name, _drv_tbl, _func_tbl, _flag) { \
+	.number = _index, \
+	.name = _name, \
+	.drv_tbl = _drv_tbl, \
+	.func_tbl = _func_tbl, \
+	.flags = _flag, \
+}
+
+/**
+ * histb_pin_func_setup_entry - an entry for setting up a function for a pin
+ *
+ * @pin_selector: pin ID
+ * @mask: function bit pattern
+ */
+struct histb_pin_func_setup_entry {
+	unsigned int pin_selector;
+	u8 mask;
+};
+
+/**
+ * histb_pin_function_desc - a descriptor for a function
+ *
+ * @func_selector: function selector
+ * @name: function name
+ * @pins_num: the number of pins engaged in this function
+ * @cfg_tbl: config table
+ */
+struct histb_pin_function_desc {
+	unsigned int func_selector;
+	const char *name;
+	unsigned int pins_num;
+	const struct histb_pin_func_setup_entry *cfg_tbl;
+};
+
+/**
+ * HISTB_PIN_FUNC - a helper macro to setup a function
+ */
+#define HISTB_PIN_FUNC(_id, _name, _cfg) { \
+	.func_selector = _id, \
+	.name = _name, \
+	.pins_num = ARRAY_SIZE(_cfg), \
+	.cfg_tbl = _cfg, \
+}
+
+/**
+ * histb_pinctrl_priv - private data for the driver
+ *
+ * @base: device base address
+ * @pins: descriptor array for all pins
+ * @funcs: descriptor array for all functions
+ * @pin_nums: array size of .pins
+ * @func_nums: array size of .funcs
+ */
+struct histb_pinctrl_priv {
+	void __iomem *base;
+	const struct histb_pin_desc *pins;
+	const struct histb_pin_function_desc *funcs;
+	unsigned int pin_nums;
+	unsigned int func_nums;
+};
+
+/**
+ * histb_pinctrl_of_to_plat - convert device tree node to private data
+ *
+ * use this function as .of_to_plat field in the driver
+ */
+int histb_pinctrl_of_to_plat(struct udevice *dev);
+
+/**
+ * histb_pinctrl_ops - HiSTB pinctrl ops
+ *
+ * use this struct as .ops field in the driver
+ */
+extern const struct pinctrl_ops histb_pinctrl_ops;

---
base-commit: 050a9b981d6a835133521b599be3ae189ce70f41
change-id: 20240204-pinctrl-3a126ad9286e

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

