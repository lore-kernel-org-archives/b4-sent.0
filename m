From: Ben Grisdale <bengris32@protonmail.ch>
Date: Tue, 17 Nov 2026 21:00:42 +0000
Subject: [PATCH 2/2] pinctrl: mediatek: Add support for MT8163 pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-mt8163-pinctrl-v1-2-2cfd12206b17@protonmail.ch>
References: <20261117-mt8163-pinctrl-v1-0-2cfd12206b17@protonmail.ch>
In-Reply-To: <20261117-mt8163-pinctrl-v1-0-2cfd12206b17@protonmail.ch>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794949947; l=63078;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=ixaMKCowrdTxZlJyBSToER+pcAY0QWpuHfTKMZJZfOk=;
 b=Ao5wgKKdR5pTlfYKy4P6TentRaOKgbxl/6QXyFQAnN6Q0KmQ+2PC4OpyeAhrpdUXi39FmLr68
 hJsCHCl9YnDBzVN0UdjBSN2nz3ZeBJ/41FvwcgZJg0dDpPJHEcTMqh/
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the pin controller on the MediaTek MT8163 SoC.

The MT8163 has 155 GPIOs and 169 EINTs. Every GPIO is wired to an EINT
except GPIO44 and GPIO45: although these pins are named EINT12 and
EINT13, the EINTs they would be associated with are instead connected
to the USB IDDIG and VBUSVALID signals. EINT155 to EINT168 are
undocumented and not mapped to any pin.

To keep EINT12 and EINT13 usable without misrepresenting the hardware
routing, they are added as virtual GPIOs 155 and 156. GPIO44 and
GPIO45 are then marked as having no EINT.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 drivers/pinctrl/mediatek/Kconfig              |   12 +
 drivers/pinctrl/mediatek/Makefile             |    1 +
 drivers/pinctrl/mediatek/pinctrl-mt8163.c     |  478 +++++++++
 drivers/pinctrl/mediatek/pinctrl-mtk-mt8163.h | 1299 +++++++++++++++++++++++++
 4 files changed, 1790 insertions(+)

diff --git a/drivers/pinctrl/mediatek/Kconfig b/drivers/pinctrl/mediatek/Kconfig
index 912d782fb6a5..12f41835eeb3 100644
--- a/drivers/pinctrl/mediatek/Kconfig
+++ b/drivers/pinctrl/mediatek/Kconfig
@@ -231,6 +231,18 @@ config PINCTRL_MT7988
 	default ARM64 && ARCH_MEDIATEK
 	select PINCTRL_MTK_MOORE
 
+config PINCTRL_MT8163
+	tristate "MediaTek MT8163 pin control"
+	depends on OF
+	depends on ARM64 || COMPILE_TEST
+	default ARM64 && ARCH_MEDIATEK
+	select PINCTRL_MTK_PARIS
+	help
+	  Say yes here to enable support for the pin controller on the
+	  MediaTek MT8163 SoC, which provides pin multiplexing, pin
+	  configuration, GPIO and external interrupt support.
+	  This driver can also be built as a module.
+
 config PINCTRL_MT8167
 	tristate "MediaTek MT8167 pin control"
 	depends on OF
diff --git a/drivers/pinctrl/mediatek/Makefile b/drivers/pinctrl/mediatek/Makefile
index 9982866359af..112287e31583 100644
--- a/drivers/pinctrl/mediatek/Makefile
+++ b/drivers/pinctrl/mediatek/Makefile
@@ -32,6 +32,7 @@ obj-$(CONFIG_PINCTRL_MT7629)		+= pinctrl-mt7629.o
 obj-$(CONFIG_PINCTRL_MT7981)		+= pinctrl-mt7981.o
 obj-$(CONFIG_PINCTRL_MT7986)		+= pinctrl-mt7986.o
 obj-$(CONFIG_PINCTRL_MT7988)		+= pinctrl-mt7988.o
+obj-$(CONFIG_PINCTRL_MT8163)		+= pinctrl-mt8163.o
 obj-$(CONFIG_PINCTRL_MT8167)		+= pinctrl-mt8167.o
 obj-$(CONFIG_PINCTRL_MT8173)		+= pinctrl-mt8173.o
 obj-$(CONFIG_PINCTRL_MT8183)		+= pinctrl-mt8183.o
diff --git a/drivers/pinctrl/mediatek/pinctrl-mt8163.c b/drivers/pinctrl/mediatek/pinctrl-mt8163.c
new file mode 100644
index 000000000000..e7a085ab1bb8
--- /dev/null
+++ b/drivers/pinctrl/mediatek/pinctrl-mt8163.c
@@ -0,0 +1,478 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2026 Ben Grisdale <bengris32@protonmail.ch>
+ */
+
+#include "pinctrl-mtk-mt8163.h"
+#include "pinctrl-paris.h"
+
+#define PIN_FIELD15(_s_pin, _e_pin, _s_addr, _x_addrs, _s_bit, _x_bits)	\
+	PIN_FIELD_CALC(_s_pin, _e_pin, 0, _s_addr, _x_addrs, _s_bit,	\
+		       _x_bits, 15, 0)
+
+#define PIN_FIELD16(_s_pin, _e_pin, _s_addr, _x_addrs, _s_bit, _x_bits)	\
+	PIN_FIELD_CALC(_s_pin, _e_pin, 0, _s_addr, _x_addrs, _s_bit,	\
+		       _x_bits, 16, 0)
+
+#define PINS_FIELD16(_s_pin, _e_pin, _s_addr, _x_addrs, _s_bit, _x_bits)\
+	PIN_FIELD_CALC(_s_pin, _e_pin, 0, _s_addr, _x_addrs, _s_bit,	\
+		       _x_bits, 16, 1)
+
+static const struct mtk_pin_field_calc mt8163_pin_mode_range[] = {
+	PIN_FIELD15(0, 154, 0x600, 0x10, 0, 3),
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_dir_range[] = {
+	PIN_FIELD16(0, 154, 0x0, 0x10, 0, 1),
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_di_range[] = {
+	PIN_FIELD16(0, 154, 0x500, 0x10, 0, 1),
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_do_range[] = {
+	PIN_FIELD16(0, 154, 0x400, 0x10, 0, 1),
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_sr_range[] = {
+	PINS_FIELD16(0, 6, 0xb00, 0x10, 3, 1),		/* PWRAP_SPI0_MI - PWRAP_SPI0_CSN2 */
+	PINS_FIELD16(7, 9, 0xb00, 0x10, 15, 1),		/* AUD_CLK_MOSI - AUD_DAT_MOSI */
+	PINS_FIELD16(10, 13, 0xb00, 0x10, 11, 1),	/* RTC32K_CK - SRCLKENAI */
+	PINS_FIELD16(14, 17, 0xb10, 0x10, 7, 1),	/* URXD2 - UTXD3 */
+	PINS_FIELD16(18, 21, 0xb10, 0x10, 11, 1),	/* PCM_CLK - PCM_TX */
+	PINS_FIELD16(22, 26, 0xb20, 0x10, 3, 1),	/* EINT0 - EINT4 */
+	PINS_FIELD16(27, 32, 0xb20, 0x10, 7, 1),	/* EINT5 - EINT10 */
+	PINS_FIELD16(33, 33, 0xb30, 0x10, 7, 1),	/* KPROW0 */
+	PINS_FIELD16(34, 38, 0xb30, 0x10, 11, 1),	/* KPROW1 - KPCOL2 */
+	PINS_FIELD16(39, 42, 0xb30, 0x10, 15, 1),	/* JTMS - JTDO */
+	PINS_FIELD16(43, 45, 0xb40, 0x10, 15, 1),	/* EINT11 - EINT13 */
+	PINS_FIELD16(46, 49, 0xb50, 0x10, 3, 1),	/* EINT14 - EINT17 */
+	PINS_FIELD16(50, 52, 0xb70, 0x10, 3, 1),	/* EINT18 - EINT20 */
+	PINS_FIELD16(53, 56, 0xb50, 0x10, 15, 1),	/* SPI_CS - SPI_MO */
+	PINS_FIELD16(59, 59, 0xb40, 0x10, 7, 1),	/* DISP_PWM */
+	PINS_FIELD16(60, 62, 0xb40, 0x10, 3, 1),	/* WB_RSTB - F2W_CLK */
+	PINS_FIELD16(63, 65, 0xb40, 0x10, 7, 1),	/* WB_SCLK - WB_SEN */
+	PINS_FIELD16(66, 71, 0xb40, 0x10, 11, 1),	/* WB_CRTL0 - WB_CRTL5 */
+	PINS_FIELD16(72, 74, 0xb50, 0x10, 7, 1),	/* I2S_DATA_IN - I2S_BCK */
+	PINS_FIELD16(79, 84, 0xb50, 0x10, 11, 1),	/* URXD0 - DSI_TE */
+	PINS_FIELD16(85, 85, 0xce0, 0x10, 3, 1),	/* MSDC2_CMD */
+	PINS_FIELD16(86, 86, 0xcd0, 0x10, 3, 1),	/* MSDC2_CLK */
+	PINS_FIELD16(87, 90, 0xcf0, 0x10, 3, 1),	/* MSDC2_DAT0 - MSDC2_DAT3 */
+	PINS_FIELD16(117, 120, 0xb60, 0x10, 15, 1),	/* CMDAT0 - CMPCLK */
+	PINS_FIELD16(121, 121, 0xc80, 0x10, 3, 1),	/* MSDC1_CMD */
+	PINS_FIELD16(122, 122, 0xc70, 0x10, 3, 1),	/* MSDC1_CLK */
+	PINS_FIELD16(123, 126, 0xc90, 0x10, 3, 1),	/* MSDC1_DAT0 - MSDC1_DAT3 */
+	PINS_FIELD16(127, 131, 0xc20, 0x10, 3, 1),	/* MSDC0_DAT7 - MSDC0_RSTB */
+	PINS_FIELD16(132, 132, 0xc10, 0x10, 3, 1),	/* MSDC0_CMD */
+	PINS_FIELD16(133, 133, 0xc00, 0x10, 3, 1),	/* MSDC0_CLK */
+	PINS_FIELD16(134, 137, 0xc20, 0x10, 3, 1),	/* MSDC0_DAT3 - MSDC0_DAT0 */
+	PINS_FIELD16(142, 142, 0xb50, 0x10, 3, 1),	/* EINT21 */
+	PINS_FIELD16(143, 147, 0xf20, 0x10, 3, 1),	/* MSDC3_DAT7 - MSDC3_RSTB */
+	PINS_FIELD16(148, 148, 0xf10, 0x10, 3, 1),	/* MSDC3_CMD */
+	PINS_FIELD16(149, 149, 0xf00, 0x10, 3, 1),	/* MSDC3_CLK */
+	PINS_FIELD16(150, 154, 0xf20, 0x10, 3, 1),	/* MSDC3_DAT3 - MSDC3_DSL */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_smt_range[] = {
+	PINS_FIELD16(0, 9, 0x920, 0x10, 0, 1),		/* PWRAP_SPI0_MI - AUD_DAT_MOSI */
+	PINS_FIELD16(10, 13, 0x920, 0x10, 1, 1),	/* RTC32K_CK - SRCLKENAI */
+	PINS_FIELD16(14, 28, 0x920, 0x10, 2, 1),	/* URXD2 - EINT6 */
+	PINS_FIELD16(29, 32, 0x920, 0x10, 3, 1),	/* EINT7 - EINT10 */
+	PINS_FIELD16(33, 33, 0x930, 0x10, 11, 1),	/* KPROW0 */
+	PINS_FIELD16(34, 38, 0x920, 0x10, 10, 1),	/* KPROW1 - KPCOL2 */
+	PINS_FIELD16(39, 42, 0x920, 0x10, 11, 1),	/* JTMS - JTDO */
+	PINS_FIELD16(43, 45, 0x920, 0x10, 12, 1),	/* EINT11 - EINT13 */
+	PINS_FIELD16(46, 49, 0x920, 0x10, 13, 1),	/* EINT14 - EINT17 */
+	PINS_FIELD16(50, 52, 0x930, 0x10, 10, 1),	/* EINT18 - EINT20 */
+	PINS_FIELD16(53, 56, 0x920, 0x10, 14, 1),	/* SPI_CS - SPI_MO */
+	PINS_FIELD16(57, 58, 0x930, 0x10, 0, 1),	/* SDA1 - SCL1 */
+	PINS_FIELD16(59, 65, 0x930, 0x10, 2, 1),	/* DISP_PWM - WB_SEN */
+	PINS_FIELD16(66, 71, 0x930, 0x10, 3, 1),	/* WB_CRTL0 - WB_CRTL5 */
+	PINS_FIELD16(72, 74, 0x930, 0x10, 4, 1),	/* I2S_DATA_IN - I2S_BCK */
+	PINS_FIELD16(75, 76, 0x920, 0x10, 15, 1),	/* SDA0 - SCL0 */
+	PINS_FIELD16(77, 78, 0x930, 0x10, 1, 1),	/* SDA2 - SCL2 */
+	PINS_FIELD16(79, 82, 0x930, 0x10, 5, 1),	/* URXD0 - UTXD1 */
+	PINS_FIELD16(83, 84, 0x930, 0x10, 6, 1),	/* LCM_RST - DSI_TE */
+	PINS_FIELD16(85, 85, 0xce0, 0x10, 11, 1),	/* MSDC2_CMD */
+	PINS_FIELD16(86, 86, 0xcd0, 0x10, 11, 1),	/* MSDC2_CLK */
+	PINS_FIELD16(87, 87, 0xd00, 0x10, 3, 1),	/* MSDC2_DAT0 */
+	PINS_FIELD16(88, 88, 0xd00, 0x10, 7, 1),	/* MSDC2_DAT1 */
+	PINS_FIELD16(89, 89, 0xd00, 0x10, 11, 1),	/* MSDC2_DAT2 */
+	PINS_FIELD16(90, 90, 0xd00, 0x10, 15, 1),	/* MSDC2_DAT3 */
+	PINS_FIELD16(117, 120, 0x930, 0x10, 7, 1),	/* CMDAT0 - CMPCLK */
+	PINS_FIELD16(121, 121, 0xc80, 0x10, 11, 1),	/* MSDC1_CMD */
+	PINS_FIELD16(122, 122, 0xc70, 0x10, 11, 1),	/* MSDC1_CLK */
+	PINS_FIELD16(123, 123, 0xca0, 0x10, 3, 1),	/* MSDC1_DAT0 */
+	PINS_FIELD16(124, 124, 0xca0, 0x10, 7, 1),	/* MSDC1_DAT1 */
+	PINS_FIELD16(125, 125, 0xca0, 0x10, 11, 1),	/* MSDC1_DAT2 */
+	PINS_FIELD16(126, 126, 0xca0, 0x10, 15, 1),	/* MSDC1_DAT3 */
+	PINS_FIELD16(127, 127, 0xc40, 0x10, 15, 1),	/* MSDC0_DAT7 */
+	PINS_FIELD16(128, 128, 0xc40, 0x10, 11, 1),	/* MSDC0_DAT6 */
+	PINS_FIELD16(129, 129, 0xc40, 0x10, 7, 1),	/* MSDC0_DAT5 */
+	PINS_FIELD16(130, 130, 0xc40, 0x10, 3, 1),	/* MSDC0_DAT4 */
+	PINS_FIELD16(131, 131, 0xc50, 0x10, 3, 1),	/* MSDC0_RSTB */
+	PINS_FIELD16(132, 132, 0xc10, 0x10, 11, 1),	/* MSDC0_CMD */
+	PINS_FIELD16(133, 133, 0xc00, 0x10, 11, 1),	/* MSDC0_CLK */
+	PINS_FIELD16(134, 134, 0xc30, 0x10, 15, 1),	/* MSDC0_DAT3 */
+	PINS_FIELD16(135, 135, 0xc30, 0x10, 11, 1),	/* MSDC0_DAT2 */
+	PINS_FIELD16(136, 136, 0xc30, 0x10, 7, 1),	/* MSDC0_DAT1 */
+	PINS_FIELD16(137, 137, 0xc30, 0x10, 3, 1),	/* MSDC0_DAT0 */
+	PINS_FIELD16(138, 141, 0x930, 0x10, 9, 1),	/* CEC - HDMISD */
+	PINS_FIELD16(142, 142, 0x920, 0x10, 13, 1),	/* EINT21 */
+	PINS_FIELD16(143, 143, 0xf40, 0x10, 15, 1),	/* MSDC3_DAT7 */
+	PINS_FIELD16(144, 144, 0xf40, 0x10, 11, 1),	/* MSDC3_DAT6 */
+	PINS_FIELD16(145, 145, 0xf40, 0x10, 7, 1),	/* MSDC3_DAT5 */
+	PINS_FIELD16(146, 146, 0xf40, 0x10, 3, 1),	/* MSDC3_DAT4 */
+	PINS_FIELD16(147, 147, 0xf50, 0x10, 3, 1),	/* MSDC3_RSTB */
+	PINS_FIELD16(148, 148, 0xf10, 0x10, 11, 1),	/* MSDC3_CMD */
+	PINS_FIELD16(149, 149, 0xf00, 0x10, 11, 1),	/* MSDC3_CLK */
+	PINS_FIELD16(150, 150, 0xf30, 0x10, 15, 1),	/* MSDC3_DAT3 */
+	PINS_FIELD16(151, 151, 0xf30, 0x10, 11, 1),	/* MSDC3_DAT2 */
+	PINS_FIELD16(152, 152, 0xf30, 0x10, 7, 1),	/* MSDC3_DAT1 */
+	PINS_FIELD16(153, 153, 0xf30, 0x10, 3, 1),	/* MSDC3_DAT0 */
+	PINS_FIELD16(154, 154, 0xf50, 0x10, 7, 1),	/* MSDC3_DSL */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_pullen_range[] = {
+	PIN_FIELD16(0, 32, 0x100, 0x10, 0, 1),		/* PWRAP_SPI0_MI - EINT10 */
+	PIN_FIELD16(39, 45, 0x120, 0x10, 7, 1),		/* JTMS - EINT13 */
+	PIN_FIELD16(50, 84, 0x130, 0x10, 2, 1),		/* EINT18 - DSI_TE */
+	PIN_FIELD16(117, 120, 0x170, 0x10, 5, 1),	/* CMDAT0 - CMPCLK */
+	PIN_FIELD16(138, 141, 0x180, 0x10, 10, 1),	/* CEC - HDMISD */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_pullsel_range[] = {
+	PIN_FIELD16(0, 32, 0x200, 0x10, 0, 1),		/* PWRAP_SPI0_MI - EINT10 */
+	PIN_FIELD16(39, 45, 0x220, 0x10, 7, 1),		/* JTMS - EINT13 */
+	PIN_FIELD16(50, 84, 0x230, 0x10, 2, 1),		/* EINT18 - DSI_TE */
+	PIN_FIELD16(117, 120, 0x270, 0x10, 5, 1),	/* CMDAT0 - CMPCLK */
+	PIN_FIELD16(138, 141, 0x280, 0x10, 10, 1),	/* CEC - HDMISD */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_drv_range[] = {
+	PINS_FIELD16(0, 6, 0xb00, 0x10, 1, 2),		/* PWRAP_SPI0_MI - PWRAP_SPI0_CSN2 */
+	PINS_FIELD16(7, 9, 0xb00, 0x10, 13, 2),		/* AUD_CLK_MOSI - AUD_DAT_MOSI */
+	PINS_FIELD16(10, 13, 0xb00, 0x10, 9, 2),	/* RTC32K_CK - SRCLKENAI */
+	PINS_FIELD16(14, 17, 0xb10, 0x10, 5, 2),	/* URXD2 - UTXD3 */
+	PINS_FIELD16(18, 21, 0xb10, 0x10, 9, 2),	/* PCM_CLK - PCM_TX */
+	PINS_FIELD16(22, 26, 0xb20, 0x10, 1, 2),	/* EINT0 - EINT4 */
+	PINS_FIELD16(27, 32, 0xb20, 0x10, 5, 2),	/* EINT5 - EINT10 */
+	PINS_FIELD16(33, 33, 0xb30, 0x10, 5, 2),	/* KPROW0 */
+	PINS_FIELD16(34, 38, 0xb30, 0x10, 9, 2),	/* KPROW1 - KPCOL2 */
+	PINS_FIELD16(39, 42, 0xb30, 0x10, 13, 2),	/* JTMS - JTDO */
+	PINS_FIELD16(43, 45, 0xb40, 0x10, 13, 2),	/* EINT11 - EINT13 */
+	PINS_FIELD16(46, 49, 0xb50, 0x10, 0, 3),	/* EINT14 - EINT17 */
+	PINS_FIELD16(50, 52, 0xb70, 0x10, 1, 2),	/* EINT18 - EINT20 */
+	PINS_FIELD16(53, 56, 0xb50, 0x10, 13, 2),	/* SPI_CS - SPI_MO */
+	PINS_FIELD16(59, 59, 0xb40, 0x10, 5, 2),	/* DISP_PWM */
+	PINS_FIELD16(60, 62, 0xb40, 0x10, 1, 2),	/* WB_RSTB - F2W_CLK */
+	PINS_FIELD16(63, 65, 0xb40, 0x10, 5, 2),	/* WB_SCLK - WB_SEN */
+	PINS_FIELD16(66, 71, 0xb40, 0x10, 9, 2),	/* WB_CRTL0 - WB_CRTL5 */
+	PINS_FIELD16(72, 74, 0xb50, 0x10, 5, 2),	/* I2S_DATA_IN - I2S_BCK */
+	PINS_FIELD16(79, 84, 0xb50, 0x10, 9, 2),	/* URXD0 - DSI_TE */
+	PINS_FIELD16(85, 85, 0xce0, 0x10, 0, 3),	/* MSDC2_CMD */
+	PINS_FIELD16(86, 86, 0xcd0, 0x10, 0, 3),	/* MSDC2_CLK */
+	PINS_FIELD16(87, 90, 0xcf0, 0x10, 0, 3),	/* MSDC2_DAT0 - MSDC2_DAT3 */
+	PINS_FIELD16(117, 120, 0xb60, 0x10, 13, 2),	/* CMDAT0 - CMPCLK */
+	PINS_FIELD16(121, 121, 0xc80, 0x10, 0, 3),	/* MSDC1_CMD */
+	PINS_FIELD16(122, 122, 0xc70, 0x10, 0, 3),	/* MSDC1_CLK */
+	PINS_FIELD16(123, 126, 0xc90, 0x10, 0, 3),	/* MSDC1_DAT0 - MSDC1_DAT3 */
+	PINS_FIELD16(127, 131, 0xc20, 0x10, 0, 3),	/* MSDC0_DAT7 - MSDC0_RSTB */
+	PINS_FIELD16(132, 132, 0xc10, 0x10, 0, 3),	/* MSDC0_CMD */
+	PINS_FIELD16(133, 133, 0xc00, 0x10, 0, 3),	/* MSDC0_CLK */
+	PINS_FIELD16(134, 137, 0xc20, 0x10, 0, 3),	/* MSDC0_DAT3 - MSDC0_DAT0 */
+	PINS_FIELD16(142, 142, 0xb50, 0x10, 0, 3),	/* EINT21 */
+	PINS_FIELD16(143, 147, 0xf20, 0x10, 0, 3),	/* MSDC3_DAT7 - MSDC3_RSTB */
+	PINS_FIELD16(148, 148, 0xf10, 0x10, 0, 3),	/* MSDC3_CMD */
+	PINS_FIELD16(149, 149, 0xf00, 0x10, 0, 3),	/* MSDC3_CLK */
+	PINS_FIELD16(150, 154, 0xf20, 0x10, 0, 3),	/* MSDC3_DAT3 - MSDC3_DSL */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_pupd_range[] = {
+	PIN_FIELD16(33, 33, 0xd90, 0x10, 2, 1),		/* KPROW0 */
+	PIN_FIELD16(34, 34, 0xd90, 0x10, 6, 1),		/* KPROW1 */
+	PIN_FIELD16(35, 35, 0xd90, 0x10, 10, 1),	/* KPROW2 */
+	PIN_FIELD16(36, 36, 0xda0, 0x10, 2, 1),		/* KPCOL0 */
+	PIN_FIELD16(37, 37, 0xda0, 0x10, 6, 1),		/* KPCOL1 */
+	PIN_FIELD16(38, 38, 0xda0, 0x10, 10, 1),	/* KPCOL2 */
+	PIN_FIELD16(46, 46, 0xdb0, 0x10, 2, 1),		/* EINT14 */
+	PIN_FIELD16(47, 47, 0xdb0, 0x10, 6, 1),		/* EINT15 */
+	PIN_FIELD16(48, 48, 0xdb0, 0x10, 10, 1),	/* EINT16 */
+	PIN_FIELD16(49, 49, 0xdb0, 0x10, 14, 1),	/* EINT17 */
+	PIN_FIELD16(85, 85, 0xce0, 0x10, 8, 1),		/* MSDC2_CMD */
+	PIN_FIELD16(86, 86, 0xcd0, 0x10, 8, 1),		/* MSDC2_CLK */
+	PIN_FIELD16(87, 87, 0xd00, 0x10, 0, 1),		/* MSDC2_DAT0 */
+	PIN_FIELD16(88, 88, 0xd00, 0x10, 4, 1),		/* MSDC2_DAT1 */
+	PIN_FIELD16(89, 89, 0xd00, 0x10, 8, 1),		/* MSDC2_DAT2 */
+	PIN_FIELD16(90, 90, 0xd00, 0x10, 12, 1),	/* MSDC2_DAT3 */
+	PIN_FIELD16(121, 121, 0xc80, 0x10, 8, 1),	/* MSDC1_CMD */
+	PIN_FIELD16(122, 122, 0xc70, 0x10, 8, 1),	/* MSDC1_CLK */
+	PIN_FIELD16(123, 123, 0xca0, 0x10, 0, 1),	/* MSDC1_DAT0 */
+	PIN_FIELD16(124, 124, 0xca0, 0x10, 4, 1),	/* MSDC1_DAT1 */
+	PIN_FIELD16(125, 125, 0xca0, 0x10, 8, 1),	/* MSDC1_DAT2 */
+	PIN_FIELD16(126, 126, 0xca0, 0x10, 12, 1),	/* MSDC1_DAT3 */
+	PIN_FIELD16(127, 127, 0xc40, 0x10, 12, 1),	/* MSDC0_DAT7 */
+	PIN_FIELD16(128, 128, 0xc40, 0x10, 8, 1),	/* MSDC0_DAT6 */
+	PIN_FIELD16(129, 129, 0xc40, 0x10, 4, 1),	/* MSDC0_DAT5 */
+	PIN_FIELD16(130, 130, 0xc40, 0x10, 0, 1),	/* MSDC0_DAT4 */
+	PIN_FIELD16(131, 131, 0xc50, 0x10, 0, 1),	/* MSDC0_RSTB */
+	PIN_FIELD16(132, 132, 0xc10, 0x10, 8, 1),	/* MSDC0_CMD */
+	PIN_FIELD16(133, 133, 0xc00, 0x10, 8, 1),	/* MSDC0_CLK */
+	PIN_FIELD16(134, 134, 0xc30, 0x10, 12, 1),	/* MSDC0_DAT3 */
+	PIN_FIELD16(135, 135, 0xc30, 0x10, 8, 1),	/* MSDC0_DAT2 */
+	PIN_FIELD16(136, 136, 0xc30, 0x10, 4, 1),	/* MSDC0_DAT1 */
+	PIN_FIELD16(137, 137, 0xc30, 0x10, 0, 1),	/* MSDC0_DAT0 */
+	PIN_FIELD16(142, 142, 0xdc0, 0x10, 2, 1),	/* EINT21 */
+	PIN_FIELD16(143, 143, 0xf40, 0x10, 12, 1),	/* MSDC3_DAT7 */
+	PIN_FIELD16(144, 144, 0xf40, 0x10, 8, 1),	/* MSDC3_DAT6 */
+	PIN_FIELD16(145, 145, 0xf40, 0x10, 4, 1),	/* MSDC3_DAT5 */
+	PIN_FIELD16(146, 146, 0xf40, 0x10, 0, 1),	/* MSDC3_DAT4 */
+	PIN_FIELD16(147, 147, 0xf50, 0x10, 0, 1),	/* MSDC3_RSTB */
+	PIN_FIELD16(148, 148, 0xf10, 0x10, 8, 1),	/* MSDC3_CMD */
+	PIN_FIELD16(149, 149, 0xf00, 0x10, 8, 1),	/* MSDC3_CLK */
+	PIN_FIELD16(150, 150, 0xf30, 0x10, 12, 1),	/* MSDC3_DAT3 */
+	PIN_FIELD16(151, 151, 0xf30, 0x10, 8, 1),	/* MSDC3_DAT2 */
+	PIN_FIELD16(152, 152, 0xf30, 0x10, 4, 1),	/* MSDC3_DAT1 */
+	PIN_FIELD16(153, 153, 0xf30, 0x10, 0, 1),	/* MSDC3_DAT0 */
+	PIN_FIELD16(154, 154, 0xf50, 0x10, 4, 1),	/* MSDC3_DSL */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_r0_range[] = {
+	PIN_FIELD16(33, 33, 0xd90, 0x10, 0, 1),		/* KPROW0 */
+	PIN_FIELD16(34, 34, 0xd90, 0x10, 4, 1),		/* KPROW1 */
+	PIN_FIELD16(35, 35, 0xd90, 0x10, 8, 1),		/* KPROW2 */
+	PIN_FIELD16(36, 36, 0xda0, 0x10, 0, 1),		/* KPCOL0 */
+	PIN_FIELD16(37, 37, 0xda0, 0x10, 4, 1),		/* KPCOL1 */
+	PIN_FIELD16(38, 38, 0xda0, 0x10, 8, 1),		/* KPCOL2 */
+	PIN_FIELD16(46, 46, 0xdb0, 0x10, 0, 1),		/* EINT14 */
+	PIN_FIELD16(47, 47, 0xdb0, 0x10, 4, 1),		/* EINT15 */
+	PIN_FIELD16(48, 48, 0xdb0, 0x10, 8, 1),		/* EINT16 */
+	PIN_FIELD16(49, 49, 0xdb0, 0x10, 12, 1),	/* EINT17 */
+	PIN_FIELD16(85, 85, 0xce0, 0x10, 10, 1),	/* MSDC2_CMD */
+	PIN_FIELD16(86, 86, 0xcd0, 0x10, 10, 1),	/* MSDC2_CLK */
+	PIN_FIELD16(87, 87, 0xd00, 0x10, 2, 1),		/* MSDC2_DAT0 */
+	PIN_FIELD16(88, 88, 0xd00, 0x10, 6, 1),		/* MSDC2_DAT1 */
+	PIN_FIELD16(89, 89, 0xd00, 0x10, 10, 1),	/* MSDC2_DAT2 */
+	PIN_FIELD16(90, 90, 0xd00, 0x10, 14, 1),	/* MSDC2_DAT3 */
+	PIN_FIELD16(121, 121, 0xc80, 0x10, 10, 1),	/* MSDC1_CMD */
+	PIN_FIELD16(122, 122, 0xc70, 0x10, 10, 1),	/* MSDC1_CLK */
+	PIN_FIELD16(123, 123, 0xca0, 0x10, 2, 1),	/* MSDC1_DAT0 */
+	PIN_FIELD16(124, 124, 0xca0, 0x10, 6, 1),	/* MSDC1_DAT1 */
+	PIN_FIELD16(125, 125, 0xca0, 0x10, 10, 1),	/* MSDC1_DAT2 */
+	PIN_FIELD16(126, 126, 0xca0, 0x10, 14, 1),	/* MSDC1_DAT3 */
+	PIN_FIELD16(127, 127, 0xc40, 0x10, 14, 1),	/* MSDC0_DAT7 */
+	PIN_FIELD16(128, 128, 0xc40, 0x10, 10, 1),	/* MSDC0_DAT6 */
+	PIN_FIELD16(129, 129, 0xc40, 0x10, 6, 1),	/* MSDC0_DAT5 */
+	PIN_FIELD16(130, 130, 0xc40, 0x10, 2, 1),	/* MSDC0_DAT4 */
+	PIN_FIELD16(131, 131, 0xc50, 0x10, 2, 1),	/* MSDC0_RSTB */
+	PIN_FIELD16(132, 132, 0xc10, 0x10, 10, 1),	/* MSDC0_CMD */
+	PIN_FIELD16(133, 133, 0xc00, 0x10, 10, 1),	/* MSDC0_CLK */
+	PIN_FIELD16(134, 134, 0xc30, 0x10, 14, 1),	/* MSDC0_DAT3 */
+	PIN_FIELD16(135, 135, 0xc30, 0x10, 10, 1),	/* MSDC0_DAT2 */
+	PIN_FIELD16(136, 136, 0xc30, 0x10, 6, 1),	/* MSDC0_DAT1 */
+	PIN_FIELD16(137, 137, 0xc30, 0x10, 2, 1),	/* MSDC0_DAT0 */
+	PIN_FIELD16(142, 142, 0xdc0, 0x10, 0, 1),	/* EINT21 */
+	PIN_FIELD16(143, 143, 0xf40, 0x10, 14, 1),	/* MSDC3_DAT7 */
+	PIN_FIELD16(144, 144, 0xf40, 0x10, 10, 1),	/* MSDC3_DAT6 */
+	PIN_FIELD16(145, 145, 0xf40, 0x10, 6, 1),	/* MSDC3_DAT5 */
+	PIN_FIELD16(146, 146, 0xf40, 0x10, 2, 1),	/* MSDC3_DAT4 */
+	PIN_FIELD16(147, 147, 0xf50, 0x10, 2, 1),	/* MSDC3_RSTB */
+	PIN_FIELD16(148, 148, 0xf10, 0x10, 10, 1),	/* MSDC3_CMD */
+	PIN_FIELD16(149, 149, 0xf00, 0x10, 10, 1),	/* MSDC3_CLK */
+	PIN_FIELD16(150, 150, 0xf30, 0x10, 14, 1),	/* MSDC3_DAT3 */
+	PIN_FIELD16(151, 151, 0xf30, 0x10, 10, 1),	/* MSDC3_DAT2 */
+	PIN_FIELD16(152, 152, 0xf30, 0x10, 6, 1),	/* MSDC3_DAT1 */
+	PIN_FIELD16(153, 153, 0xf30, 0x10, 2, 1),	/* MSDC3_DAT0 */
+	PIN_FIELD16(154, 154, 0xf50, 0x10, 6, 1),	/* MSDC3_DSL */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_r1_range[] = {
+	PIN_FIELD16(33, 33, 0xd90, 0x10, 1, 1),		/* KPROW0 */
+	PIN_FIELD16(34, 34, 0xd90, 0x10, 5, 1),		/* KPROW1 */
+	PIN_FIELD16(35, 35, 0xd90, 0x10, 9, 1),		/* KPROW2 */
+	PIN_FIELD16(36, 36, 0xda0, 0x10, 1, 1),		/* KPCOL0 */
+	PIN_FIELD16(37, 37, 0xda0, 0x10, 5, 1),		/* KPCOL1 */
+	PIN_FIELD16(38, 38, 0xda0, 0x10, 9, 1),		/* KPCOL2 */
+	PIN_FIELD16(46, 46, 0xdb0, 0x10, 1, 1),		/* EINT14 */
+	PIN_FIELD16(47, 47, 0xdb0, 0x10, 5, 1),		/* EINT15 */
+	PIN_FIELD16(48, 48, 0xdb0, 0x10, 9, 1),		/* EINT16 */
+	PIN_FIELD16(49, 49, 0xdb0, 0x10, 13, 1),	/* EINT17 */
+	PIN_FIELD16(85, 85, 0xce0, 0x10, 9, 1),		/* MSDC2_CMD */
+	PIN_FIELD16(86, 86, 0xcd0, 0x10, 9, 1),		/* MSDC2_CLK */
+	PIN_FIELD16(87, 87, 0xd00, 0x10, 1, 1),		/* MSDC2_DAT0 */
+	PIN_FIELD16(88, 88, 0xd00, 0x10, 5, 1),		/* MSDC2_DAT1 */
+	PIN_FIELD16(89, 89, 0xd00, 0x10, 9, 1),		/* MSDC2_DAT2 */
+	PIN_FIELD16(90, 90, 0xd00, 0x10, 13, 1),	/* MSDC2_DAT3 */
+	PIN_FIELD16(121, 121, 0xc80, 0x10, 9, 1),	/* MSDC1_CMD */
+	PIN_FIELD16(122, 122, 0xc70, 0x10, 9, 1),	/* MSDC1_CLK */
+	PIN_FIELD16(123, 123, 0xca0, 0x10, 1, 1),	/* MSDC1_DAT0 */
+	PIN_FIELD16(124, 124, 0xca0, 0x10, 5, 1),	/* MSDC1_DAT1 */
+	PIN_FIELD16(125, 125, 0xca0, 0x10, 9, 1),	/* MSDC1_DAT2 */
+	PIN_FIELD16(126, 126, 0xca0, 0x10, 13, 1),	/* MSDC1_DAT3 */
+	PIN_FIELD16(127, 127, 0xc40, 0x10, 13, 1),	/* MSDC0_DAT7 */
+	PIN_FIELD16(128, 128, 0xc40, 0x10, 9, 1),	/* MSDC0_DAT6 */
+	PIN_FIELD16(129, 129, 0xc40, 0x10, 5, 1),	/* MSDC0_DAT5 */
+	PIN_FIELD16(130, 130, 0xc40, 0x10, 1, 1),	/* MSDC0_DAT4 */
+	PIN_FIELD16(131, 131, 0xc50, 0x10, 1, 1),	/* MSDC0_RSTB */
+	PIN_FIELD16(132, 132, 0xc10, 0x10, 9, 1),	/* MSDC0_CMD */
+	PIN_FIELD16(133, 133, 0xc00, 0x10, 9, 1),	/* MSDC0_CLK */
+	PIN_FIELD16(134, 134, 0xc30, 0x10, 13, 1),	/* MSDC0_DAT3 */
+	PIN_FIELD16(135, 135, 0xc30, 0x10, 9, 1),	/* MSDC0_DAT2 */
+	PIN_FIELD16(136, 136, 0xc30, 0x10, 5, 1),	/* MSDC0_DAT1 */
+	PIN_FIELD16(137, 137, 0xc30, 0x10, 1, 1),	/* MSDC0_DAT0 */
+	PIN_FIELD16(142, 142, 0xdc0, 0x10, 1, 1),	/* EINT21 */
+	PIN_FIELD16(143, 143, 0xf40, 0x10, 13, 1),	/* MSDC3_DAT7 */
+	PIN_FIELD16(144, 144, 0xf40, 0x10, 9, 1),	/* MSDC3_DAT6 */
+	PIN_FIELD16(145, 145, 0xf40, 0x10, 5, 1),	/* MSDC3_DAT5 */
+	PIN_FIELD16(146, 146, 0xf40, 0x10, 1, 1),	/* MSDC3_DAT4 */
+	PIN_FIELD16(147, 147, 0xf50, 0x10, 1, 1),	/* MSDC3_RSTB */
+	PIN_FIELD16(148, 148, 0xf10, 0x10, 9, 1),	/* MSDC3_CMD */
+	PIN_FIELD16(149, 149, 0xf00, 0x10, 9, 1),	/* MSDC3_CLK */
+	PIN_FIELD16(150, 150, 0xf30, 0x10, 13, 1),	/* MSDC3_DAT3 */
+	PIN_FIELD16(151, 151, 0xf30, 0x10, 9, 1),	/* MSDC3_DAT2 */
+	PIN_FIELD16(152, 152, 0xf30, 0x10, 5, 1),	/* MSDC3_DAT1 */
+	PIN_FIELD16(153, 153, 0xf30, 0x10, 1, 1),	/* MSDC3_DAT0 */
+	PIN_FIELD16(154, 154, 0xf50, 0x10, 5, 1),	/* MSDC3_DSL */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_ies_range[] = {
+	PINS_FIELD16(0, 9, 0x900, 0x10, 0, 1),		/* PWRAP_SPI0_MI - AUD_DAT_MOSI */
+	PINS_FIELD16(10, 13, 0x900, 0x10, 1, 1),	/* RTC32K_CK - SRCLKENAI */
+	PINS_FIELD16(14, 28, 0x900, 0x10, 2, 1),	/* URXD2 - EINT6 */
+	PINS_FIELD16(29, 32, 0x900, 0x10, 3, 1),	/* EINT7 - EINT10 */
+	PINS_FIELD16(33, 33, 0x910, 0x10, 11, 1),	/* KPROW0 */
+	PINS_FIELD16(34, 38, 0x900, 0x10, 10, 1),	/* KPROW1 - KPCOL2 */
+	PINS_FIELD16(39, 42, 0x900, 0x10, 11, 1),	/* JTMS - JTDO */
+	PINS_FIELD16(43, 45, 0x900, 0x10, 12, 1),	/* EINT11 - EINT13 */
+	PINS_FIELD16(46, 49, 0x900, 0x10, 13, 1),	/* EINT14 - EINT17 */
+	PINS_FIELD16(50, 52, 0x910, 0x10, 10, 1),	/* EINT18 - EINT20 */
+	PINS_FIELD16(53, 56, 0x900, 0x10, 14, 1),	/* SPI_CS - SPI_MO */
+	PINS_FIELD16(57, 58, 0x910, 0x10, 0, 1),	/* SDA1 - SCL1 */
+	PINS_FIELD16(59, 65, 0x910, 0x10, 2, 1),	/* DISP_PWM - WB_SEN */
+	PINS_FIELD16(66, 71, 0x910, 0x10, 3, 1),	/* WB_CRTL0 - WB_CRTL5 */
+	PINS_FIELD16(72, 74, 0x910, 0x10, 4, 1),	/* I2S_DATA_IN - I2S_BCK */
+	PINS_FIELD16(75, 76, 0x900, 0x10, 15, 1),	/* SDA0 - SCL0 */
+	PINS_FIELD16(77, 78, 0x910, 0x10, 1, 1),	/* SDA2 - SCL2 */
+	PINS_FIELD16(79, 82, 0x910, 0x10, 5, 1),	/* URXD0 - UTXD1 */
+	PINS_FIELD16(83, 84, 0x910, 0x10, 6, 1),	/* LCM_RST - DSI_TE */
+	PINS_FIELD16(85, 85, 0xce0, 0x10, 4, 1),	/* MSDC2_CMD */
+	PINS_FIELD16(86, 86, 0xcd0, 0x10, 4, 1),	/* MSDC2_CLK */
+	PINS_FIELD16(87, 90, 0xcf0, 0x10, 4, 1),	/* MSDC2_DAT0 - MSDC2_DAT3 */
+	PINS_FIELD16(117, 120, 0x910, 0x10, 7, 1),	/* CMDAT0 - CMPCLK */
+	PINS_FIELD16(121, 121, 0xc80, 0x10, 4, 1),	/* MSDC1_CMD */
+	PINS_FIELD16(122, 122, 0xc70, 0x10, 4, 1),	/* MSDC1_CLK */
+	PINS_FIELD16(123, 126, 0xc90, 0x10, 4, 1),	/* MSDC1_DAT0 - MSDC1_DAT3 */
+	PINS_FIELD16(127, 131, 0xc20, 0x10, 4, 1),	/* MSDC0_DAT7 - MSDC0_RSTB */
+	PINS_FIELD16(132, 132, 0xc10, 0x10, 4, 1),	/* MSDC0_CMD */
+	PINS_FIELD16(133, 133, 0xc00, 0x10, 4, 1),	/* MSDC0_CLK */
+	PINS_FIELD16(134, 137, 0xc20, 0x10, 4, 1),	/* MSDC0_DAT3 - MSDC0_DAT0 */
+	PINS_FIELD16(138, 141, 0x910, 0x10, 9, 1),	/* CEC - HDMISD */
+	PINS_FIELD16(142, 142, 0x900, 0x10, 13, 1),	/* EINT21 */
+	PINS_FIELD16(143, 147, 0xf20, 0x10, 4, 1),	/* MSDC3_DAT7 - MSDC3_RSTB */
+	PINS_FIELD16(148, 148, 0xf10, 0x10, 4, 1),	/* MSDC3_CMD */
+	PINS_FIELD16(149, 149, 0xf00, 0x10, 4, 1),	/* MSDC3_CLK */
+	PINS_FIELD16(150, 154, 0xf20, 0x10, 4, 1),	/* MSDC3_DAT3 - MSDC3_DSL */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_tdsel_range[] = {
+	PINS_FIELD16(14, 32, 0xd50, 0x10, 0, 4),	/* URXD2 - EINT10 */
+	PINS_FIELD16(43, 45, 0xd60, 0x10, 0, 4),	/* EINT11 - EINT13 */
+	PINS_FIELD16(46, 49, 0xd70, 0x10, 0, 4),	/* EINT14 - EINT17 */
+	PINS_FIELD16(85, 90, 0xd20, 0x10, 0, 4),	/* MSDC2_CMD - MSDC2_DAT3 */
+	PINS_FIELD16(121, 126, 0xcc0, 0x10, 0, 4),	/* MSDC1_CMD - MSDC1_DAT3 */
+	PINS_FIELD16(127, 137, 0xc60, 0x10, 0, 4),	/* MSDC0_DAT7 - MSDC0_DAT0 */
+	PINS_FIELD16(142, 142, 0xd70, 0x10, 0, 4),	/* EINT21 */
+	PINS_FIELD16(143, 154, 0xf60, 0x10, 0, 4),	/* MSDC3_DAT7 - MSDC3_DSL */
+};
+
+static const struct mtk_pin_field_calc mt8163_pin_rdsel_range[] = {
+	PINS_FIELD16(14, 32, 0xd50, 0x10, 4, 6),	/* URXD2 - EINT10 */
+	PINS_FIELD16(43, 45, 0xd60, 0x10, 4, 6),	/* EINT11 - EINT13 */
+	PINS_FIELD16(46, 49, 0xd70, 0x10, 4, 6),	/* EINT14 - EINT17 */
+	PINS_FIELD16(85, 90, 0xd20, 0x10, 4, 6),	/* MSDC2_CMD - MSDC2_DAT3 */
+	PINS_FIELD16(121, 126, 0xcc0, 0x10, 4, 6),	/* MSDC1_CMD - MSDC1_DAT3 */
+	PINS_FIELD16(127, 137, 0xc60, 0x10, 4, 6),	/* MSDC0_DAT7 - MSDC0_DAT0 */
+	PINS_FIELD16(142, 142, 0xd70, 0x10, 4, 6),	/* EINT21 */
+	PINS_FIELD16(143, 154, 0xf60, 0x10, 4, 6),	/* MSDC3_DAT7 - MSDC3_DSL */
+};
+
+static const unsigned int mt8163_pull_type[] = {
+	[0 ... 32] = MTK_PULL_PULLSEL_TYPE,		/* PWRAP_SPI0_MI - EINT10 */
+	[33 ... 38] = MTK_PULL_PUPD_R1R0_TYPE,		/* KPROW0 - KPCOL2 */
+	[39 ... 45] = MTK_PULL_PULLSEL_TYPE,		/* JTMS - EINT13 */
+	[46 ... 49] = MTK_PULL_PUPD_R1R0_TYPE,		/* EINT14 - EINT17 */
+	[50 ... 84] = MTK_PULL_PULLSEL_TYPE,		/* EINT18 - DSI_TE */
+	[85 ... 90] = MTK_PULL_PUPD_R1R0_TYPE,		/* MSDC2_CMD - MSDC2_DAT3 */
+	/* MIPI pins have no pull control in the GPIO block */
+	[91 ... 100] = 0,				/* TDN3 - TDP0 */
+	[101 ... 116] = 0,				/* RDN0 - RDP0_A */
+	[117 ... 120] = MTK_PULL_PULLSEL_TYPE,		/* CMDAT0 - CMPCLK */
+	[121 ... 137] = MTK_PULL_PUPD_R1R0_TYPE,	/* MSDC1_CMD - MSDC0_DAT0 */
+	[138 ... 141] = MTK_PULL_PULLSEL_TYPE,		/* CEC - HDMISD */
+	[142 ... 154] = MTK_PULL_PUPD_R1R0_TYPE,	/* EINT21 - MSDC3_DSL */
+	/* No pull resistors for virtual EINT pins */
+	[155 ... 156] = 0,				/* IDDIG, VBUSVALID */
+};
+
+static const struct mtk_pin_reg_calc mt8163_reg_cals[PINCTRL_PIN_REG_MAX] = {
+	[PINCTRL_PIN_REG_MODE] = MTK_RANGE(mt8163_pin_mode_range),
+	[PINCTRL_PIN_REG_DIR] = MTK_RANGE(mt8163_pin_dir_range),
+	[PINCTRL_PIN_REG_DI] = MTK_RANGE(mt8163_pin_di_range),
+	[PINCTRL_PIN_REG_DO] = MTK_RANGE(mt8163_pin_do_range),
+	[PINCTRL_PIN_REG_SR] = MTK_RANGE(mt8163_pin_sr_range),
+	[PINCTRL_PIN_REG_SMT] = MTK_RANGE(mt8163_pin_smt_range),
+	[PINCTRL_PIN_REG_PULLEN] = MTK_RANGE(mt8163_pin_pullen_range),
+	[PINCTRL_PIN_REG_PULLSEL] = MTK_RANGE(mt8163_pin_pullsel_range),
+	[PINCTRL_PIN_REG_DRV] = MTK_RANGE(mt8163_pin_drv_range),
+	[PINCTRL_PIN_REG_PUPD] = MTK_RANGE(mt8163_pin_pupd_range),
+	[PINCTRL_PIN_REG_R0] = MTK_RANGE(mt8163_pin_r0_range),
+	[PINCTRL_PIN_REG_R1] = MTK_RANGE(mt8163_pin_r1_range),
+	[PINCTRL_PIN_REG_IES] = MTK_RANGE(mt8163_pin_ies_range),
+	[PINCTRL_PIN_REG_TDSEL] = MTK_RANGE(mt8163_pin_tdsel_range),
+	[PINCTRL_PIN_REG_RDSEL] = MTK_RANGE(mt8163_pin_rdsel_range),
+};
+
+static const struct mtk_eint_hw mt8163_eint_hw = {
+	.port_mask = 7,
+	.ports     = 6,
+	.ap_num    = 169,
+	.db_cnt    = 64,
+	.db_time   = debounce_time_mt6795,
+};
+
+static const struct mtk_pin_soc mt8163_data = {
+	.reg_cal = mt8163_reg_cals,
+	.pins = mtk_pins_mt8163,
+	.npins = ARRAY_SIZE(mtk_pins_mt8163),
+	.ngrps = ARRAY_SIZE(mtk_pins_mt8163),
+	.nfuncs = 8,
+	.eint_hw = &mt8163_eint_hw,
+	.gpio_m = 0,
+	.base_names = mtk_default_register_base_names,
+	.nbase_names = ARRAY_SIZE(mtk_default_register_base_names),
+	.pull_type = mt8163_pull_type,
+	.bias_set_combo = mtk_pinconf_bias_set_combo,
+	.bias_get_combo = mtk_pinconf_bias_get_combo,
+	.drive_set = mtk_pinconf_drive_set_rev1,
+	.drive_get = mtk_pinconf_drive_get_rev1,
+};
+
+static const struct of_device_id mt8163_pinctrl_match[] = {
+	{ .compatible = "mediatek,mt8163-pinctrl", .data = &mt8163_data },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, mt8163_pinctrl_match);
+
+static struct platform_driver mt8163_pinctrl_driver = {
+	.probe = mtk_paris_pinctrl_probe,
+	.driver = {
+		.name = "mt8163-pinctrl",
+		.of_match_table = mt8163_pinctrl_match,
+		.pm = pm_sleep_ptr(&mtk_paris_pinctrl_pm_ops),
+	},
+};
+module_platform_driver(mt8163_pinctrl_driver);
+
+MODULE_AUTHOR("Ben Grisdale <bengris32@protonmail.ch>");
+MODULE_DESCRIPTION("MediaTek MT8163 pinctrl driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/pinctrl/mediatek/pinctrl-mtk-mt8163.h b/drivers/pinctrl/mediatek/pinctrl-mtk-mt8163.h
new file mode 100644
index 000000000000..025e8fe086f5
--- /dev/null
+++ b/drivers/pinctrl/mediatek/pinctrl-mtk-mt8163.h
@@ -0,0 +1,1299 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/*
+ * Copyright (c) 2026 Ben Grisdale <bengris32@protonmail.ch>
+ */
+
+#ifndef __PINCTRL_MTK_MT8163_H
+#define __PINCTRL_MTK_MT8163_H
+
+#include "pinctrl-paris.h"
+
+static const struct mtk_pin_desc mtk_pins_mt8163[] = {
+	MTK_PIN(0, "GPIO0",
+		MTK_EINT_FUNCTION(0, 22),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO0"),
+		MTK_FUNCTION(1, "PWRAP_SPI0_MO"),
+		MTK_FUNCTION(2, "PWRAP_SPI0_MI")
+	),
+	MTK_PIN(1, "GPIO1",
+		MTK_EINT_FUNCTION(0, 23),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO1"),
+		MTK_FUNCTION(1, "PWRAP_SPI0_MI"),
+		MTK_FUNCTION(2, "PWRAP_SPI0_MO")
+	),
+	MTK_PIN(2, "GPIO2",
+		MTK_EINT_FUNCTION(0, 24),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO2"),
+		MTK_FUNCTION(1, "I2S0_MCK"),
+		MTK_FUNCTION(4, "I2S1_MCK"),
+		MTK_FUNCTION(5, "I2S2_MCK"),
+		MTK_FUNCTION(6, "I2S3_MCK")
+	),
+	MTK_PIN(3, "GPIO3",
+		MTK_EINT_FUNCTION(0, 25),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO3"),
+		MTK_FUNCTION(1, "PWRAP_SPI0_CK")
+	),
+	MTK_PIN(4, "GPIO4",
+		MTK_EINT_FUNCTION(0, 26),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO4"),
+		MTK_FUNCTION(1, "PWRAP_SPI0_CSN")
+	),
+	MTK_PIN(5, "GPIO5",
+		MTK_EINT_FUNCTION(0, 27),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO5"),
+		MTK_FUNCTION(1, "I2S0_MCK"),
+		MTK_FUNCTION(2, "ANT_SEL1"),
+		MTK_FUNCTION(3, "VDEC_TEST_CK"),
+		MTK_FUNCTION(4, "I2S1_MCK"),
+		MTK_FUNCTION(5, "I2S2_MCK"),
+		MTK_FUNCTION(6, "I2S3_MCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[0]")
+	),
+	MTK_PIN(6, "GPIO6",
+		MTK_EINT_FUNCTION(0, 28),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO6"),
+		MTK_FUNCTION(1, "I2S0_MCK"),
+		MTK_FUNCTION(2, "ANT_SEL0"),
+		MTK_FUNCTION(3, "MM_TEST_CK"),
+		MTK_FUNCTION(4, "I2S1_MCK"),
+		MTK_FUNCTION(5, "I2S2_MCK"),
+		MTK_FUNCTION(6, "I2S3_MCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[1]")
+	),
+	MTK_PIN(7, "GPIO7",
+		MTK_EINT_FUNCTION(0, 29),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO7"),
+		MTK_FUNCTION(1, "AUD_CLK_MOSI"),
+		MTK_FUNCTION(2, "I2S2_BCK")
+	),
+	MTK_PIN(8, "GPIO8",
+		MTK_EINT_FUNCTION(0, 30),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO8"),
+		MTK_FUNCTION(1, "AUD_DAT_MISO"),
+		MTK_FUNCTION(2, "I2S2_DI"),
+		MTK_FUNCTION(3, "AUD_DAT_MOSI")
+	),
+	MTK_PIN(9, "GPIO9",
+		MTK_EINT_FUNCTION(0, 31),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO9"),
+		MTK_FUNCTION(1, "AUD_DAT_MOSI"),
+		MTK_FUNCTION(2, "I2S2_LRCK"),
+		MTK_FUNCTION(3, "AUD_DAT_MISO")
+	),
+	MTK_PIN(10, "GPIO10",
+		MTK_EINT_FUNCTION(0, 32),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO10"),
+		MTK_FUNCTION(1, "RTC32K_CK")
+	),
+	MTK_PIN(11, "GPIO11",
+		MTK_EINT_FUNCTION(0, 33),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO11"),
+		MTK_FUNCTION(1, "WATCHDOG")
+	),
+	MTK_PIN(12, "GPIO12",
+		MTK_EINT_FUNCTION(0, 34),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO12"),
+		MTK_FUNCTION(1, "SRCLKENA0")
+	),
+	MTK_PIN(13, "GPIO13",
+		MTK_EINT_FUNCTION(0, 35),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO13"),
+		MTK_FUNCTION(1, "SRCLKENAI")
+	),
+	MTK_PIN(14, "GPIO14",
+		MTK_EINT_FUNCTION(0, 36),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO14"),
+		MTK_FUNCTION(1, "URXD2"),
+		MTK_FUNCTION(2, "DPI_D5"),
+		MTK_FUNCTION(3, "UTXD2"),
+		MTK_FUNCTION(4, "DBG_SCL"),
+		MTK_FUNCTION(5, "SRCCLKENAI2"),
+		MTK_FUNCTION(6, "I2S0_MCK")
+	),
+	MTK_PIN(15, "GPIO15",
+		MTK_EINT_FUNCTION(0, 37),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO15"),
+		MTK_FUNCTION(1, "UTXD2"),
+		MTK_FUNCTION(2, "DPI_HSYNC"),
+		MTK_FUNCTION(3, "URXD2"),
+		MTK_FUNCTION(4, "DBG_SDA"),
+		MTK_FUNCTION(6, "I2S1_MCK")
+	),
+	MTK_PIN(16, "GPIO16",
+		MTK_EINT_FUNCTION(0, 38),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO16"),
+		MTK_FUNCTION(1, "URXD3"),
+		MTK_FUNCTION(2, "DPI_DE"),
+		MTK_FUNCTION(3, "UTXD3"),
+		MTK_FUNCTION(4, "UCTS2"),
+		MTK_FUNCTION(5, "PWM_A"),
+		MTK_FUNCTION(6, "I2S2_MCK"),
+		MTK_FUNCTION(7, "TP_URXD3_AO")
+	),
+	MTK_PIN(17, "GPIO17",
+		MTK_EINT_FUNCTION(0, 39),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO17"),
+		MTK_FUNCTION(1, "UTXD3"),
+		MTK_FUNCTION(2, "DPI_VSYNC"),
+		MTK_FUNCTION(3, "URXD3"),
+		MTK_FUNCTION(4, "URTS2"),
+		MTK_FUNCTION(5, "PWM_B"),
+		MTK_FUNCTION(6, "I2S3_MCK"),
+		MTK_FUNCTION(7, "TP_UTXD3_AO")
+	),
+	MTK_PIN(18, "GPIO18",
+		MTK_EINT_FUNCTION(0, 40),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO18"),
+		MTK_FUNCTION(1, "PCM0_CLK"),
+		MTK_FUNCTION(2, "DPI_D4"),
+		MTK_FUNCTION(3, "I2S0_BCK0"),
+		MTK_FUNCTION(4, "I2S3_BCK"),
+		MTK_FUNCTION(5, "CONN_DSP_JCK"),
+		MTK_FUNCTION(6, "IR"),
+		MTK_FUNCTION(7, "DBG_MON_A[0]")
+	),
+	MTK_PIN(19, "GPIO19",
+		MTK_EINT_FUNCTION(0, 41),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO19"),
+		MTK_FUNCTION(1, "PCM0_SYNC"),
+		MTK_FUNCTION(2, "DPI_D3"),
+		MTK_FUNCTION(3, "I2S0_LRCK"),
+		MTK_FUNCTION(4, "I2S3_LRCK"),
+		MTK_FUNCTION(5, "CONN_DSP_JINTP"),
+		MTK_FUNCTION(6, "EXT_COL"),
+		MTK_FUNCTION(7, "DBG_MON_A[1]")
+	),
+	MTK_PIN(20, "GPIO20",
+		MTK_EINT_FUNCTION(0, 42),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO20"),
+		MTK_FUNCTION(1, "PCM0_DI"),
+		MTK_FUNCTION(2, "DPI_D1"),
+		MTK_FUNCTION(3, "I2S0_DI"),
+		MTK_FUNCTION(4, "PCM0_DO"),
+		MTK_FUNCTION(5, "CONN_DSP_JDI"),
+		MTK_FUNCTION(6, "EXT_MDIO"),
+		MTK_FUNCTION(7, "DBG_MON_A[2]")
+	),
+	MTK_PIN(21, "GPIO21",
+		MTK_EINT_FUNCTION(0, 43),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO21"),
+		MTK_FUNCTION(1, "PCM0_DO"),
+		MTK_FUNCTION(2, "DPI_D2"),
+		MTK_FUNCTION(3, "I2S3_DO"),
+		MTK_FUNCTION(4, "PCM0_DI"),
+		MTK_FUNCTION(5, "CONN_DSP_JMS"),
+		MTK_FUNCTION(6, "EXT_MDC"),
+		MTK_FUNCTION(7, "DBG_MON_A[3]")
+	),
+	MTK_PIN(22, "GPIO22",
+		MTK_EINT_FUNCTION(0, 0),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO22"),
+		MTK_FUNCTION(1, "PWM_B"),
+		MTK_FUNCTION(2, "DPI_CK"),
+		MTK_FUNCTION(4, "EXT_TXD0"),
+		MTK_FUNCTION(5, "CONN_DSP_JDO"),
+		MTK_FUNCTION(7, "DBG_MON_A[4]")
+	),
+	MTK_PIN(23, "GPIO23",
+		MTK_EINT_FUNCTION(0, 1),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO23"),
+		MTK_FUNCTION(1, "PWM_C"),
+		MTK_FUNCTION(2, "DPI_D12"),
+		MTK_FUNCTION(4, "EXT_TXD1"),
+		MTK_FUNCTION(5, "CONN_MCU_TDO"),
+		MTK_FUNCTION(7, "DBG_MON_A[5]")
+	),
+	MTK_PIN(24, "GPIO24",
+		MTK_EINT_FUNCTION(0, 2),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO24"),
+		MTK_FUNCTION(1, "CLKM0"),
+		MTK_FUNCTION(2, "DPI_D13"),
+		MTK_FUNCTION(4, "EXT_TXD2"),
+		MTK_FUNCTION(5, "CONN_MCU_DBGACK_N"),
+		MTK_FUNCTION(7, "DBG_MON_A[6]")
+	),
+	MTK_PIN(25, "GPIO25",
+		MTK_EINT_FUNCTION(0, 3),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO25"),
+		MTK_FUNCTION(1, "CLKM1"),
+		MTK_FUNCTION(2, "DPI_D14"),
+		MTK_FUNCTION(3, "SPI_MI"),
+		MTK_FUNCTION(4, "EXT_TXD3"),
+		MTK_FUNCTION(5, "CONN_MCU_DBGI_N"),
+		MTK_FUNCTION(7, "DBG_MON_A[7]")
+	),
+	MTK_PIN(26, "GPIO26",
+		MTK_EINT_FUNCTION(0, 4),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO26"),
+		MTK_FUNCTION(1, "CLKM2"),
+		MTK_FUNCTION(2, "DPI_D15"),
+		MTK_FUNCTION(3, "SPI_MO"),
+		MTK_FUNCTION(4, "EXT_TXC"),
+		MTK_FUNCTION(5, "CONN_MCU_TCK0"),
+		MTK_FUNCTION(6, "CONN_MCU_AICE_JCKC"),
+		MTK_FUNCTION(7, "DBG_MON_A[8]")
+	),
+	MTK_PIN(27, "GPIO27",
+		MTK_EINT_FUNCTION(0, 5),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO27"),
+		MTK_FUNCTION(1, "UCTS2"),
+		MTK_FUNCTION(2, "DPI_D16"),
+		MTK_FUNCTION(3, "SPI_CSB"),
+		MTK_FUNCTION(4, "EXT_RXER"),
+		MTK_FUNCTION(5, "CONN_MCU_TDI"),
+		MTK_FUNCTION(7, "DBG_MON_A[9]")
+	),
+	MTK_PIN(28, "GPIO28",
+		MTK_EINT_FUNCTION(0, 6),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO28"),
+		MTK_FUNCTION(1, "URTS2"),
+		MTK_FUNCTION(2, "DPI_D17"),
+		MTK_FUNCTION(3, "SPI_CLK"),
+		MTK_FUNCTION(4, "EXT_RXC"),
+		MTK_FUNCTION(5, "CONN_MCU_TRST_B"),
+		MTK_FUNCTION(7, "DBG_MON_A[10]")
+	),
+	MTK_PIN(29, "GPIO29",
+		MTK_EINT_FUNCTION(0, 7),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO29"),
+		MTK_FUNCTION(1, "UCTS3"),
+		MTK_FUNCTION(2, "DPI_D6"),
+		MTK_FUNCTION(3, "SDA1_0"),
+		MTK_FUNCTION(4, "EXT_RXDV"),
+		MTK_FUNCTION(5, "CONN_MCU_TMS"),
+		MTK_FUNCTION(6, "CONN_MCU_AICE_JMSC"),
+		MTK_FUNCTION(7, "DBG_MON_A[11]")
+	),
+	MTK_PIN(30, "GPIO30",
+		MTK_EINT_FUNCTION(0, 8),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO30"),
+		MTK_FUNCTION(1, "URTS3"),
+		MTK_FUNCTION(2, "CLKM3"),
+		MTK_FUNCTION(3, "SCL1_0"),
+		MTK_FUNCTION(4, "EXT_RXD0"),
+		MTK_FUNCTION(5, "ANT_SEL0"),
+		MTK_FUNCTION(6, "DPI_D7"),
+		MTK_FUNCTION(7, "DBG_MON_B[2]")
+	),
+	MTK_PIN(31, "GPIO31",
+		MTK_EINT_FUNCTION(0, 9),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO31"),
+		MTK_FUNCTION(1, "CLKM4"),
+		MTK_FUNCTION(2, "SDA2_0"),
+		MTK_FUNCTION(3, "EXT_FRAME_SYNC"),
+		MTK_FUNCTION(4, "EXT_RXD1"),
+		MTK_FUNCTION(5, "ANT_SEL1"),
+		MTK_FUNCTION(6, "DPI_D8"),
+		MTK_FUNCTION(7, "DBG_MON_B[3]")
+	),
+	MTK_PIN(32, "GPIO32",
+		MTK_EINT_FUNCTION(0, 10),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO32"),
+		MTK_FUNCTION(1, "CLKM5"),
+		MTK_FUNCTION(2, "SCL2_0"),
+		MTK_FUNCTION(3, "EXT_FRAME_SYNC"),
+		MTK_FUNCTION(4, "EXT_RXD2"),
+		MTK_FUNCTION(5, "ANT_SEL2"),
+		MTK_FUNCTION(6, "DPI_D9"),
+		MTK_FUNCTION(7, "DBG_MON_B[4]")
+	),
+	MTK_PIN(33, "GPIO33",
+		MTK_EINT_FUNCTION(0, 44),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO33"),
+		MTK_FUNCTION(1, "KPROW0"),
+		MTK_FUNCTION(4, "IMG_TEST_CK"),
+		MTK_FUNCTION(7, "DBG_MON_A[12]")
+	),
+	MTK_PIN(34, "GPIO34",
+		MTK_EINT_FUNCTION(0, 45),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO34"),
+		MTK_FUNCTION(1, "KPROW1"),
+		MTK_FUNCTION(2, "IDDIG"),
+		MTK_FUNCTION(3, "EXT_FRAME_SYNC"),
+		MTK_FUNCTION(4, "MFG_TEST_CK"),
+		MTK_FUNCTION(7, "DBG_MON_B[5]")
+	),
+	MTK_PIN(35, "GPIO35",
+		MTK_EINT_FUNCTION(0, 46),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO35"),
+		MTK_FUNCTION(1, "KPROW2"),
+		MTK_FUNCTION(2, "USB_DRVVBUS"),
+		MTK_FUNCTION(3, "EXT_FRAME_SYNC"),
+		MTK_FUNCTION(4, "CONN_TEST_CK"),
+		MTK_FUNCTION(7, "DBG_MON_B[6]")
+	),
+	MTK_PIN(36, "GPIO36",
+		MTK_EINT_FUNCTION(0, 47),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO36"),
+		MTK_FUNCTION(1, "KPCOL0"),
+		MTK_FUNCTION(7, "DBG_MON_A[13]")
+	),
+	MTK_PIN(37, "GPIO37",
+		MTK_EINT_FUNCTION(0, 48),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO37"),
+		MTK_FUNCTION(1, "KPCOL1"),
+		MTK_FUNCTION(4, "MD32_JTAG_TRST"),
+		MTK_FUNCTION(7, "DBG_MON_B[7]")
+	),
+	MTK_PIN(38, "GPIO38",
+		MTK_EINT_FUNCTION(0, 49),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO38"),
+		MTK_FUNCTION(1, "KPCOL2"),
+		MTK_FUNCTION(2, "IDDIG"),
+		MTK_FUNCTION(3, "EXT_FRAME_SYNC"),
+		MTK_FUNCTION(7, "DBG_MON_B[8]")
+	),
+	MTK_PIN(39, "GPIO39",
+		MTK_EINT_FUNCTION(0, 50),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO39"),
+		MTK_FUNCTION(1, "JTMS"),
+		MTK_FUNCTION(2, "CONN_MCU_TMS"),
+		MTK_FUNCTION(3, "CONN_MCU_AICE_JMSC"),
+		MTK_FUNCTION(4, "MD32_JTAG_TMS"),
+		MTK_FUNCTION(5, "DFD_TMS_XI")
+	),
+	MTK_PIN(40, "GPIO40",
+		MTK_EINT_FUNCTION(0, 51),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO40"),
+		MTK_FUNCTION(1, "JTCK"),
+		MTK_FUNCTION(2, "CONN_MCU_TCK1"),
+		MTK_FUNCTION(3, "CONN_MCU_AICE_JCKC"),
+		MTK_FUNCTION(4, "MD32_JTAG_TCK"),
+		MTK_FUNCTION(5, "DFD_TCK_XI")
+	),
+	MTK_PIN(41, "GPIO41",
+		MTK_EINT_FUNCTION(0, 52),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO41"),
+		MTK_FUNCTION(1, "JTDI"),
+		MTK_FUNCTION(2, "CONN_MCU_TDI"),
+		MTK_FUNCTION(4, "MD32_JTAG_TDI"),
+		MTK_FUNCTION(5, "DFD_TDI_XI")
+	),
+	MTK_PIN(42, "GPIO42",
+		MTK_EINT_FUNCTION(0, 53),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO42"),
+		MTK_FUNCTION(1, "JTDO"),
+		MTK_FUNCTION(2, "CONN_MCU_TDO"),
+		MTK_FUNCTION(4, "MD32_JTAG_TDO"),
+		MTK_FUNCTION(5, "DFD_TDO")
+	),
+	MTK_PIN(43, "GPIO43",
+		MTK_EINT_FUNCTION(0, 11),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO43"),
+		MTK_FUNCTION(1, "CLKM4"),
+		MTK_FUNCTION(2, "PWM_C"),
+		MTK_FUNCTION(4, "ANT_SEL3"),
+		MTK_FUNCTION(5, "DPI_D10"),
+		MTK_FUNCTION(6, "EXT_RXD3"),
+		MTK_FUNCTION(7, "DBG_MON_B[9]")
+	),
+	MTK_PIN(44, "GPIO44",
+		MTK_EINT_FUNCTION(NO_EINT_SUPPORT, NO_EINT_SUPPORT),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO44"),
+		MTK_FUNCTION(1, "CLKM5"),
+		MTK_FUNCTION(2, "PWM_A"),
+		MTK_FUNCTION(4, "ANT_SEL4"),
+		MTK_FUNCTION(5, "DPI_D11"),
+		MTK_FUNCTION(6, "EXT_TXEN"),
+		MTK_FUNCTION(7, "DBG_MON_B[10]")
+	),
+	MTK_PIN(45, "GPIO45",
+		MTK_EINT_FUNCTION(NO_EINT_SUPPORT, NO_EINT_SUPPORT),
+		DRV_GRP0,
+		MTK_FUNCTION(0, "GPIO45"),
+		MTK_FUNCTION(3, "SFCS0"),
+		MTK_FUNCTION(4, "ANT_SEL5"),
+		MTK_FUNCTION(5, "DPI_D0"),
+		MTK_FUNCTION(6, "SPDIF"),
+		MTK_FUNCTION(7, "DBG_MON_B[11]")
+	),
+	MTK_PIN(46, "GPIO46",
+		MTK_EINT_FUNCTION(0, 14),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO46"),
+		MTK_FUNCTION(1, "TP_GPIO0_AO"),
+		MTK_FUNCTION(2, "I2S1_DO"),
+		MTK_FUNCTION(3, "SFWP_B"),
+		MTK_FUNCTION(4, "ANT_SEL1"),
+		MTK_FUNCTION(5, "CONN_MCU_DBGACK_N"),
+		MTK_FUNCTION(6, "NCLE"),
+		MTK_FUNCTION(7, "DBG_MON_A[14]")
+	),
+	MTK_PIN(47, "GPIO47",
+		MTK_EINT_FUNCTION(0, 15),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO47"),
+		MTK_FUNCTION(1, "TP_GPIO1_AO"),
+		MTK_FUNCTION(2, "I2S1_LRCK"),
+		MTK_FUNCTION(3, "SFOUT"),
+		MTK_FUNCTION(4, "ANT_SEL2"),
+		MTK_FUNCTION(5, "CONN_MCU_DBGI_N"),
+		MTK_FUNCTION(6, "NCEB1"),
+		MTK_FUNCTION(7, "DBG_MON_A[15]")
+	),
+	MTK_PIN(48, "GPIO48",
+		MTK_EINT_FUNCTION(0, 16),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO48"),
+		MTK_FUNCTION(2, "I2S1_BCK"),
+		MTK_FUNCTION(3, "SFHOLD"),
+		MTK_FUNCTION(4, "ANT_SEL3"),
+		MTK_FUNCTION(5, "CONN_MCU_TRST_B"),
+		MTK_FUNCTION(6, "NCEB0"),
+		MTK_FUNCTION(7, "DBG_MON_A[16]")
+	),
+	MTK_PIN(49, "GPIO49",
+		MTK_EINT_FUNCTION(0, 17),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO49"),
+		MTK_FUNCTION(1, "UCTS0"),
+		MTK_FUNCTION(2, "SFIN"),
+		MTK_FUNCTION(3, "CLKM0"),
+		MTK_FUNCTION(4, "IDDIG"),
+		MTK_FUNCTION(5, "ANT_SEL4"),
+		MTK_FUNCTION(6, "NREB"),
+		MTK_FUNCTION(7, "DBG_MON_A[17]")
+	),
+	MTK_PIN(50, "GPIO50",
+		MTK_EINT_FUNCTION(0, 18),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO50"),
+		MTK_FUNCTION(1, "URTS0"),
+		MTK_FUNCTION(2, "CLKM3"),
+		MTK_FUNCTION(3, "I2S3_LRCK"),
+		MTK_FUNCTION(4, "USB_DRVVBUS"),
+		MTK_FUNCTION(5, "ANT_SEL3"),
+		MTK_FUNCTION(6, "I2S2_BCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[12]")
+	),
+	MTK_PIN(51, "GPIO51",
+		MTK_EINT_FUNCTION(0, 19),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO51"),
+		MTK_FUNCTION(1, "UCTS1"),
+		MTK_FUNCTION(3, "I2S3_BCK"),
+		MTK_FUNCTION(4, "CLKM1"),
+		MTK_FUNCTION(5, "ANT_SEL4"),
+		MTK_FUNCTION(6, "I2S2_DI"),
+		MTK_FUNCTION(7, "DBG_MON_B[13]")
+	),
+	MTK_PIN(52, "GPIO52",
+		MTK_EINT_FUNCTION(0, 20),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO52"),
+		MTK_FUNCTION(1, "URTS1"),
+		MTK_FUNCTION(2, "PCM1_DO"),
+		MTK_FUNCTION(3, "I2S3_DO"),
+		MTK_FUNCTION(4, "CLKM2"),
+		MTK_FUNCTION(5, "ANT_SEL5"),
+		MTK_FUNCTION(6, "I2S2_LRCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[14]")
+	),
+	MTK_PIN(53, "GPIO53",
+		MTK_EINT_FUNCTION(0, 54),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO53"),
+		MTK_FUNCTION(1, "SPI_CSB"),
+		MTK_FUNCTION(3, "I2S0_DI"),
+		MTK_FUNCTION(4, "I2S2_BCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[15]")
+	),
+	MTK_PIN(54, "GPIO54",
+		MTK_EINT_FUNCTION(0, 55),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO54"),
+		MTK_FUNCTION(1, "SPI_CLK"),
+		MTK_FUNCTION(3, "I2S0_LRCK"),
+		MTK_FUNCTION(4, "I2S2_DI"),
+		MTK_FUNCTION(7, "DBG_MON_B[16]")
+	),
+	MTK_PIN(55, "GPIO55",
+		MTK_EINT_FUNCTION(0, 56),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO55"),
+		MTK_FUNCTION(1, "SPI_MI"),
+		MTK_FUNCTION(2, "SPI_MO"),
+		MTK_FUNCTION(3, "I2S0_BCK1"),
+		MTK_FUNCTION(4, "I2S2_LRCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[17]")
+	),
+	MTK_PIN(56, "GPIO56",
+		MTK_EINT_FUNCTION(0, 57),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO56"),
+		MTK_FUNCTION(1, "SPI_MO"),
+		MTK_FUNCTION(2, "SPI_MI"),
+		MTK_FUNCTION(3, "I2S0_MCK"),
+		MTK_FUNCTION(4, "I2S2_MCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[18]")
+	),
+	MTK_PIN(57, "GPIO57",
+		MTK_EINT_FUNCTION(0, 58),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO57"),
+		MTK_FUNCTION(1, "SDA1_0")
+	),
+	MTK_PIN(58, "GPIO58",
+		MTK_EINT_FUNCTION(0, 59),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO58"),
+		MTK_FUNCTION(1, "SCL1_0")
+	),
+	MTK_PIN(59, "GPIO59",
+		MTK_EINT_FUNCTION(0, 60),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO59"),
+		MTK_FUNCTION(1, "DISP_PWM"),
+		MTK_FUNCTION(2, "PWM_B"),
+		MTK_FUNCTION(7, "DBG_MON_A[18]")
+	),
+	MTK_PIN(60, "GPIO60",
+		MTK_EINT_FUNCTION(0, 61),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO60"),
+		MTK_FUNCTION(1, "WB_RSTB"),
+		MTK_FUNCTION(7, "DBG_MON_A[19]")
+	),
+	MTK_PIN(61, "GPIO61",
+		MTK_EINT_FUNCTION(0, 62),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO61"),
+		MTK_FUNCTION(1, "F2W_DATA"),
+		MTK_FUNCTION(2, "MRG_CLK"),
+		MTK_FUNCTION(7, "DBG_MON_A[20]")
+	),
+	MTK_PIN(62, "GPIO62",
+		MTK_EINT_FUNCTION(0, 63),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO62"),
+		MTK_FUNCTION(1, "F2W_CK"),
+		MTK_FUNCTION(2, "MRG_DI"),
+		MTK_FUNCTION(7, "DBG_MON_A[21]")
+	),
+	MTK_PIN(63, "GPIO63",
+		MTK_EINT_FUNCTION(0, 64),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO63"),
+		MTK_FUNCTION(1, "WB_SCLK"),
+		MTK_FUNCTION(2, "MRG_DO"),
+		MTK_FUNCTION(7, "DBG_MON_A[22]")
+	),
+	MTK_PIN(64, "GPIO64",
+		MTK_EINT_FUNCTION(0, 65),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO64"),
+		MTK_FUNCTION(1, "WB_SDATA"),
+		MTK_FUNCTION(2, "MRG_SYNC"),
+		MTK_FUNCTION(7, "DBG_MON_A[23]")
+	),
+	MTK_PIN(65, "GPIO65",
+		MTK_EINT_FUNCTION(0, 66),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO65"),
+		MTK_FUNCTION(1, "WB_SEN"),
+		MTK_FUNCTION(7, "DBG_MON_A[24]")
+	),
+	MTK_PIN(66, "GPIO66",
+		MTK_EINT_FUNCTION(0, 67),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO66"),
+		MTK_FUNCTION(1, "WB_CRTL0"),
+		MTK_FUNCTION(2, "DFD_NTRST_XI"),
+		MTK_FUNCTION(7, "DBG_MON_A[25]")
+	),
+	MTK_PIN(67, "GPIO67",
+		MTK_EINT_FUNCTION(0, 68),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO67"),
+		MTK_FUNCTION(1, "WB_CRTL1"),
+		MTK_FUNCTION(2, "DFD_TMS_XI"),
+		MTK_FUNCTION(7, "DBG_MON_A[26]")
+	),
+	MTK_PIN(68, "GPIO68",
+		MTK_EINT_FUNCTION(0, 69),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO68"),
+		MTK_FUNCTION(1, "WB_CRTL2"),
+		MTK_FUNCTION(2, "DFD_TCK_XI"),
+		MTK_FUNCTION(7, "DBG_MON_A[27]")
+	),
+	MTK_PIN(69, "GPIO69",
+		MTK_EINT_FUNCTION(0, 70),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO69"),
+		MTK_FUNCTION(1, "WB_CRTL3"),
+		MTK_FUNCTION(2, "DFD_TDI_XI"),
+		MTK_FUNCTION(7, "DBG_MON_A[28]")
+	),
+	MTK_PIN(70, "GPIO70",
+		MTK_EINT_FUNCTION(0, 71),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO70"),
+		MTK_FUNCTION(1, "WB_CRTL4"),
+		MTK_FUNCTION(2, "DFD_TDO"),
+		MTK_FUNCTION(7, "DBG_MON_A[29]")
+	),
+	MTK_PIN(71, "GPIO71",
+		MTK_EINT_FUNCTION(0, 72),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO71"),
+		MTK_FUNCTION(1, "WB_CRTL5"),
+		MTK_FUNCTION(7, "DBG_MON_A[30]")
+	),
+	MTK_PIN(72, "GPIO72",
+		MTK_EINT_FUNCTION(0, 73),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO72"),
+		MTK_FUNCTION(1, "I2S0_DI"),
+		MTK_FUNCTION(2, "PCM1_DI"),
+		MTK_FUNCTION(3, "I2S3_DO"),
+		MTK_FUNCTION(4, "I2S1_DO"),
+		MTK_FUNCTION(5, "PWM_A"),
+		MTK_FUNCTION(6, "I2S2_BCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[19]")
+	),
+	MTK_PIN(73, "GPIO73",
+		MTK_EINT_FUNCTION(0, 74),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO73"),
+		MTK_FUNCTION(1, "I2S0_LRCK"),
+		MTK_FUNCTION(2, "PCM1_SYNC"),
+		MTK_FUNCTION(3, "I2S3_LRCK"),
+		MTK_FUNCTION(4, "I2S1_LRCK"),
+		MTK_FUNCTION(5, "PWM_B"),
+		MTK_FUNCTION(6, "I2S2_DI"),
+		MTK_FUNCTION(7, "DBG_MON_B[20]")
+	),
+	MTK_PIN(74, "GPIO74",
+		MTK_EINT_FUNCTION(0, 75),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO74"),
+		MTK_FUNCTION(1, "I2S0_BCK2"),
+		MTK_FUNCTION(2, "PCM1_CLK"),
+		MTK_FUNCTION(3, "I2S3_BCK"),
+		MTK_FUNCTION(4, "I2S1_BCK"),
+		MTK_FUNCTION(5, "PWM_C"),
+		MTK_FUNCTION(6, "I2S2_LRCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[21]")
+	),
+	MTK_PIN(75, "GPIO75",
+		MTK_EINT_FUNCTION(0, 76),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO75"),
+		MTK_FUNCTION(1, "SDA0_0")
+	),
+	MTK_PIN(76, "GPIO76",
+		MTK_EINT_FUNCTION(0, 77),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO76"),
+		MTK_FUNCTION(1, "SCL0_0")
+	),
+	MTK_PIN(77, "GPIO77",
+		MTK_EINT_FUNCTION(0, 78),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO77"),
+		MTK_FUNCTION(1, "SDA2_0"),
+		MTK_FUNCTION(2, "PWM_B")
+	),
+	MTK_PIN(78, "GPIO78",
+		MTK_EINT_FUNCTION(0, 79),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO78"),
+		MTK_FUNCTION(1, "SCL2_0"),
+		MTK_FUNCTION(2, "PWM_C")
+	),
+	MTK_PIN(79, "GPIO79",
+		MTK_EINT_FUNCTION(0, 80),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO79"),
+		MTK_FUNCTION(1, "URXD0"),
+		MTK_FUNCTION(2, "UTXD0")
+	),
+	MTK_PIN(80, "GPIO80",
+		MTK_EINT_FUNCTION(0, 81),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO80"),
+		MTK_FUNCTION(1, "UTXD0"),
+		MTK_FUNCTION(2, "URXD0")
+	),
+	MTK_PIN(81, "GPIO81",
+		MTK_EINT_FUNCTION(0, 82),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO81"),
+		MTK_FUNCTION(1, "URXD1"),
+		MTK_FUNCTION(2, "UTXD1")
+	),
+	MTK_PIN(82, "GPIO82",
+		MTK_EINT_FUNCTION(0, 83),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO82"),
+		MTK_FUNCTION(1, "UTXD1"),
+		MTK_FUNCTION(2, "URXD1")
+	),
+	MTK_PIN(83, "GPIO83",
+		MTK_EINT_FUNCTION(0, 84),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO83"),
+		MTK_FUNCTION(1, "LCM_RST"),
+		MTK_FUNCTION(2, "VDAC_CK_XI"),
+		MTK_FUNCTION(7, "DBG_MON_A[31]")
+	),
+	MTK_PIN(84, "GPIO84",
+		MTK_EINT_FUNCTION(0, 85),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO84"),
+		MTK_FUNCTION(1, "DSI_TE"),
+		MTK_FUNCTION(7, "DBG_MON_A[32]")
+	),
+	MTK_PIN(85, "GPIO85",
+		MTK_EINT_FUNCTION(0, 86),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO85"),
+		MTK_FUNCTION(1, "MSDC2_CMD"),
+		MTK_FUNCTION(2, "ANT_SEL0"),
+		MTK_FUNCTION(3, "SDA1_0"),
+		MTK_FUNCTION(6, "I2S3_BCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[22]")
+	),
+	MTK_PIN(86, "GPIO86",
+		MTK_EINT_FUNCTION(0, 87),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO86"),
+		MTK_FUNCTION(1, "MSDC2_CLK"),
+		MTK_FUNCTION(2, "ANT_SEL1"),
+		MTK_FUNCTION(3, "SCL1_0"),
+		MTK_FUNCTION(6, "I2S3_LRCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[23]")
+	),
+	MTK_PIN(87, "GPIO87",
+		MTK_EINT_FUNCTION(0, 88),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO87"),
+		MTK_FUNCTION(1, "MSDC2_DAT0"),
+		MTK_FUNCTION(2, "ANT_SEL2"),
+		MTK_FUNCTION(5, "UTXD0"),
+		MTK_FUNCTION(6, "I2S3_DO"),
+		MTK_FUNCTION(7, "DBG_MON_B[24]")
+	),
+	MTK_PIN(88, "GPIO88",
+		MTK_EINT_FUNCTION(0, 89),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO88"),
+		MTK_FUNCTION(1, "MSDC2_DAT1"),
+		MTK_FUNCTION(2, "ANT_SEL3"),
+		MTK_FUNCTION(3, "PWM_A"),
+		MTK_FUNCTION(4, "I2S3_MCK"),
+		MTK_FUNCTION(5, "URXD0"),
+		MTK_FUNCTION(6, "PWM_B"),
+		MTK_FUNCTION(7, "DBG_MON_B[25]")
+	),
+	MTK_PIN(89, "GPIO89",
+		MTK_EINT_FUNCTION(0, 90),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO89"),
+		MTK_FUNCTION(1, "MSDC2_DAT2"),
+		MTK_FUNCTION(2, "ANT_SEL4"),
+		MTK_FUNCTION(3, "SDA2_0"),
+		MTK_FUNCTION(5, "UTXD1"),
+		MTK_FUNCTION(6, "PWM_C"),
+		MTK_FUNCTION(7, "DBG_MON_B[26]")
+	),
+	MTK_PIN(90, "GPIO90",
+		MTK_EINT_FUNCTION(0, 91),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO90"),
+		MTK_FUNCTION(1, "MSDC2_DAT3"),
+		MTK_FUNCTION(2, "ANT_SEL5"),
+		MTK_FUNCTION(3, "SCL2_0"),
+		MTK_FUNCTION(4, "EXT_FRAME_SYNC"),
+		MTK_FUNCTION(5, "URXD1"),
+		MTK_FUNCTION(6, "PWM_A"),
+		MTK_FUNCTION(7, "DBG_MON_B[27]")
+	),
+	MTK_PIN(91, "GPIO91",
+		MTK_EINT_FUNCTION(0, 92),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI91"),
+		MTK_FUNCTION(1, "TDN3")
+	),
+	MTK_PIN(92, "GPIO92",
+		MTK_EINT_FUNCTION(0, 93),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI92"),
+		MTK_FUNCTION(1, "TDP3")
+	),
+	MTK_PIN(93, "GPIO93",
+		MTK_EINT_FUNCTION(0, 94),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI93"),
+		MTK_FUNCTION(1, "TDN2")
+	),
+	MTK_PIN(94, "GPIO94",
+		MTK_EINT_FUNCTION(0, 95),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI94"),
+		MTK_FUNCTION(1, "TDP2")
+	),
+	MTK_PIN(95, "GPIO95",
+		MTK_EINT_FUNCTION(0, 96),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI95"),
+		MTK_FUNCTION(1, "TCN")
+	),
+	MTK_PIN(96, "GPIO96",
+		MTK_EINT_FUNCTION(0, 97),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI96"),
+		MTK_FUNCTION(1, "TCP")
+	),
+	MTK_PIN(97, "GPIO97",
+		MTK_EINT_FUNCTION(0, 98),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI97"),
+		MTK_FUNCTION(1, "TDN1")
+	),
+	MTK_PIN(98, "GPIO98",
+		MTK_EINT_FUNCTION(0, 99),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI98"),
+		MTK_FUNCTION(1, "TDP1")
+	),
+	MTK_PIN(99, "GPIO99",
+		MTK_EINT_FUNCTION(0, 100),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI99"),
+		MTK_FUNCTION(1, "TDN0")
+	),
+	MTK_PIN(100, "GPIO100",
+		MTK_EINT_FUNCTION(0, 101),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI100"),
+		MTK_FUNCTION(1, "TDP0")
+	),
+	MTK_PIN(101, "GPIO101",
+		MTK_EINT_FUNCTION(0, 102),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI101"),
+		MTK_FUNCTION(1, "RDN0")
+	),
+	MTK_PIN(102, "GPIO102",
+		MTK_EINT_FUNCTION(0, 103),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI102"),
+		MTK_FUNCTION(1, "RDP0")
+	),
+	MTK_PIN(103, "GPIO103",
+		MTK_EINT_FUNCTION(0, 104),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI103"),
+		MTK_FUNCTION(1, "RDN1")
+	),
+	MTK_PIN(104, "GPIO104",
+		MTK_EINT_FUNCTION(0, 105),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI104"),
+		MTK_FUNCTION(1, "RDP1")
+	),
+	MTK_PIN(105, "GPIO105",
+		MTK_EINT_FUNCTION(0, 106),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI105"),
+		MTK_FUNCTION(1, "RCN")
+	),
+	MTK_PIN(106, "GPIO106",
+		MTK_EINT_FUNCTION(0, 107),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI106"),
+		MTK_FUNCTION(1, "RCP")
+	),
+	MTK_PIN(107, "GPIO107",
+		MTK_EINT_FUNCTION(0, 108),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI107"),
+		MTK_FUNCTION(1, "RDN2"),
+		MTK_FUNCTION(2, "CMDAT8")
+	),
+	MTK_PIN(108, "GPIO108",
+		MTK_EINT_FUNCTION(0, 109),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI108"),
+		MTK_FUNCTION(1, "RDP2"),
+		MTK_FUNCTION(2, "CMDAT9")
+	),
+	MTK_PIN(109, "GPIO109",
+		MTK_EINT_FUNCTION(0, 110),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI109"),
+		MTK_FUNCTION(1, "RDN3"),
+		MTK_FUNCTION(2, "CMDAT4")
+	),
+	MTK_PIN(110, "GPIO110",
+		MTK_EINT_FUNCTION(0, 111),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI110"),
+		MTK_FUNCTION(1, "RDP3"),
+		MTK_FUNCTION(2, "CMDAT5")
+	),
+	MTK_PIN(111, "GPIO111",
+		MTK_EINT_FUNCTION(0, 112),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI111"),
+		MTK_FUNCTION(1, "RCN_A"),
+		MTK_FUNCTION(2, "CMDAT6")
+	),
+	MTK_PIN(112, "GPIO112",
+		MTK_EINT_FUNCTION(0, 113),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI112"),
+		MTK_FUNCTION(1, "RCP_A"),
+		MTK_FUNCTION(2, "CMDAT7")
+	),
+	MTK_PIN(113, "GPIO113",
+		MTK_EINT_FUNCTION(0, 114),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI113"),
+		MTK_FUNCTION(1, "RDN1_A"),
+		MTK_FUNCTION(2, "CMDAT2"),
+		MTK_FUNCTION(3, "CMCSD2")
+	),
+	MTK_PIN(114, "GPIO114",
+		MTK_EINT_FUNCTION(0, 115),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI114"),
+		MTK_FUNCTION(1, "RDP1_A"),
+		MTK_FUNCTION(2, "CMDAT3"),
+		MTK_FUNCTION(3, "CMCSD3")
+	),
+	MTK_PIN(115, "GPIO115",
+		MTK_EINT_FUNCTION(0, 116),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI115"),
+		MTK_FUNCTION(1, "RDN0_A"),
+		MTK_FUNCTION(2, "CMHSYNC")
+	),
+	MTK_PIN(116, "GPIO116",
+		MTK_EINT_FUNCTION(0, 117),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPI116"),
+		MTK_FUNCTION(1, "RDP0_A"),
+		MTK_FUNCTION(2, "CMVSYNC")
+	),
+	MTK_PIN(117, "GPIO117",
+		MTK_EINT_FUNCTION(0, 118),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO117"),
+		MTK_FUNCTION(1, "CMDAT0"),
+		MTK_FUNCTION(2, "CMCSD0"),
+		MTK_FUNCTION(3, "ANT_SEL2"),
+		MTK_FUNCTION(7, "DBG_MON_B[28]")
+	),
+	MTK_PIN(118, "GPIO118",
+		MTK_EINT_FUNCTION(0, 119),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO118"),
+		MTK_FUNCTION(1, "CMDAT1"),
+		MTK_FUNCTION(2, "CMCSD1"),
+		MTK_FUNCTION(3, "ANT_SEL3"),
+		MTK_FUNCTION(4, "CMFLASH"),
+		MTK_FUNCTION(7, "DBG_MON_B[29]")
+	),
+	MTK_PIN(119, "GPIO119",
+		MTK_EINT_FUNCTION(0, 120),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO119"),
+		MTK_FUNCTION(1, "CMMCLK"),
+		MTK_FUNCTION(3, "ANT_SEL4"),
+		MTK_FUNCTION(7, "DBG_MON_B[30]")
+	),
+	MTK_PIN(120, "GPIO120",
+		MTK_EINT_FUNCTION(0, 121),
+		DRV_GRP2,
+		MTK_FUNCTION(0, "GPIO120"),
+		MTK_FUNCTION(1, "CMPCLK"),
+		MTK_FUNCTION(2, "CMCSK"),
+		MTK_FUNCTION(3, "ANT_SEL5"),
+		MTK_FUNCTION(7, "DBG_MON_B[31]")
+	),
+	MTK_PIN(121, "GPIO121",
+		MTK_EINT_FUNCTION(0, 122),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO121"),
+		MTK_FUNCTION(1, "MSDC1_CMD")
+	),
+	MTK_PIN(122, "GPIO122",
+		MTK_EINT_FUNCTION(0, 123),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO122"),
+		MTK_FUNCTION(1, "MSDC1_CLK"),
+		MTK_FUNCTION(2, "MD32_JTAG_TCK")
+	),
+	MTK_PIN(123, "GPIO123",
+		MTK_EINT_FUNCTION(0, 124),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO123"),
+		MTK_FUNCTION(1, "MSDC1_DAT0"),
+		MTK_FUNCTION(2, "MD32_JTAG_TMS")
+	),
+	MTK_PIN(124, "GPIO124",
+		MTK_EINT_FUNCTION(0, 125),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO124"),
+		MTK_FUNCTION(1, "MSDC1_DAT1"),
+		MTK_FUNCTION(2, "MD32_JTAG_TDI")
+	),
+	MTK_PIN(125, "GPIO125",
+		MTK_EINT_FUNCTION(0, 126),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO125"),
+		MTK_FUNCTION(1, "MSDC1_DAT2"),
+		MTK_FUNCTION(2, "MD32_JTAG_TDO")
+	),
+	MTK_PIN(126, "GPIO126",
+		MTK_EINT_FUNCTION(0, 127),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO126"),
+		MTK_FUNCTION(1, "MSDC1_DAT3"),
+		MTK_FUNCTION(2, "MD32_JTAG_TRST")
+	),
+	MTK_PIN(127, "GPIO127",
+		MTK_EINT_FUNCTION(0, 128),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO127"),
+		MTK_FUNCTION(1, "MSDC0_DAT7"),
+		MTK_FUNCTION(4, "NLD7")
+	),
+	MTK_PIN(128, "GPIO128",
+		MTK_EINT_FUNCTION(0, 129),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO128"),
+		MTK_FUNCTION(1, "MSDC0_DAT6"),
+		MTK_FUNCTION(4, "NLD6")
+	),
+	MTK_PIN(129, "GPIO129",
+		MTK_EINT_FUNCTION(0, 130),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO129"),
+		MTK_FUNCTION(1, "MSDC0_DAT5"),
+		MTK_FUNCTION(4, "NLD4")
+	),
+	MTK_PIN(130, "GPIO130",
+		MTK_EINT_FUNCTION(0, 131),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO130"),
+		MTK_FUNCTION(1, "MSDC0_DAT4"),
+		MTK_FUNCTION(4, "NLD3")
+	),
+	MTK_PIN(131, "GPIO131",
+		MTK_EINT_FUNCTION(0, 132),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO131"),
+		MTK_FUNCTION(1, "MSDC0_RSTB"),
+		MTK_FUNCTION(4, "NLD0")
+	),
+	MTK_PIN(132, "GPIO132",
+		MTK_EINT_FUNCTION(0, 133),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO132"),
+		MTK_FUNCTION(1, "MSDC0_CMD"),
+		MTK_FUNCTION(4, "NALE")
+	),
+	MTK_PIN(133, "GPIO133",
+		MTK_EINT_FUNCTION(0, 134),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO133"),
+		MTK_FUNCTION(1, "MSDC0_CLK"),
+		MTK_FUNCTION(4, "NWEB")
+	),
+	MTK_PIN(134, "GPIO134",
+		MTK_EINT_FUNCTION(0, 135),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO134"),
+		MTK_FUNCTION(1, "MSDC0_DAT3"),
+		MTK_FUNCTION(4, "NLD1")
+	),
+	MTK_PIN(135, "GPIO135",
+		MTK_EINT_FUNCTION(0, 136),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO135"),
+		MTK_FUNCTION(1, "MSDC0_DAT2"),
+		MTK_FUNCTION(4, "NLD5")
+	),
+	MTK_PIN(136, "GPIO136",
+		MTK_EINT_FUNCTION(0, 137),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO136"),
+		MTK_FUNCTION(1, "MSDC0_DAT1"),
+		MTK_FUNCTION(4, "NLD8")
+	),
+	MTK_PIN(137, "GPIO137",
+		MTK_EINT_FUNCTION(0, 138),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO137"),
+		MTK_FUNCTION(1, "MSDC0_DAT0"),
+		MTK_FUNCTION(4, "WATCHDOG"),
+		MTK_FUNCTION(5, "NLD2")
+	),
+	MTK_PIN(138, "GPIO138",
+		MTK_EINT_FUNCTION(0, 139),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO138"),
+		MTK_FUNCTION(1, "CEC")
+	),
+	MTK_PIN(139, "GPIO139",
+		MTK_EINT_FUNCTION(0, 140),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO139"),
+		MTK_FUNCTION(1, "HTPLG")
+	),
+	MTK_PIN(140, "GPIO140",
+		MTK_EINT_FUNCTION(0, 141),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO140"),
+		MTK_FUNCTION(1, "HDMISCK")
+	),
+	MTK_PIN(141, "GPIO141",
+		MTK_EINT_FUNCTION(0, 142),
+		DRV_FIXED,
+		MTK_FUNCTION(0, "GPIO141"),
+		MTK_FUNCTION(1, "HDMISD")
+	),
+	MTK_PIN(142, "GPIO142",
+		MTK_EINT_FUNCTION(0, 21),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO142"),
+		MTK_FUNCTION(1, "NRNB"),
+		MTK_FUNCTION(2, "ANT_SEL0"),
+		MTK_FUNCTION(3, "SFCK"),
+		MTK_FUNCTION(7, "DBG_MON_B[32]")
+	),
+	MTK_PIN(143, "GPIO143",
+		MTK_EINT_FUNCTION(0, 143),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO143"),
+		MTK_FUNCTION(1, "MSDC3_DAT7")
+	),
+	MTK_PIN(144, "GPIO144",
+		MTK_EINT_FUNCTION(0, 144),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO144"),
+		MTK_FUNCTION(1, "MSDC3_DAT6")
+	),
+	MTK_PIN(145, "GPIO145",
+		MTK_EINT_FUNCTION(0, 145),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO145"),
+		MTK_FUNCTION(1, "MSDC3_DAT5")
+	),
+	MTK_PIN(146, "GPIO146",
+		MTK_EINT_FUNCTION(0, 146),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO146"),
+		MTK_FUNCTION(1, "MSDC3_DAT4")
+	),
+	MTK_PIN(147, "GPIO147",
+		MTK_EINT_FUNCTION(0, 147),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO147"),
+		MTK_FUNCTION(1, "MSDC3_RSTB")
+	),
+	MTK_PIN(148, "GPIO148",
+		MTK_EINT_FUNCTION(0, 148),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO148"),
+		MTK_FUNCTION(1, "MSDC3_CMD")
+	),
+	MTK_PIN(149, "GPIO149",
+		MTK_EINT_FUNCTION(0, 149),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO149"),
+		MTK_FUNCTION(1, "MSDC3_CLK")
+	),
+	MTK_PIN(150, "GPIO150",
+		MTK_EINT_FUNCTION(0, 150),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO150"),
+		MTK_FUNCTION(1, "MSDC3_DAT3")
+	),
+	MTK_PIN(151, "GPIO151",
+		MTK_EINT_FUNCTION(0, 151),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO151"),
+		MTK_FUNCTION(1, "MSDC3_DAT2")
+	),
+	MTK_PIN(152, "GPIO152",
+		MTK_EINT_FUNCTION(0, 152),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO152"),
+		MTK_FUNCTION(1, "MSDC3_DAT1")
+	),
+	MTK_PIN(153, "GPIO153",
+		MTK_EINT_FUNCTION(0, 153),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO153"),
+		MTK_FUNCTION(1, "MSDC3_DAT0")
+	),
+	MTK_PIN(154, "GPIO154",
+		MTK_EINT_FUNCTION(0, 154),
+		DRV_GRP4,
+		MTK_FUNCTION(0, "GPIO154"),
+		MTK_FUNCTION(1, "MSDC3_DSL")
+	),
+	MTK_PIN(155, "GPIO155",
+		MTK_EINT_FUNCTION(0, 12),
+		DRV_FIXED,
+		MTK_FUNCTION(0, NULL)
+	),
+	MTK_PIN(156, "GPIO156",
+		MTK_EINT_FUNCTION(0, 13),
+		DRV_FIXED,
+		MTK_FUNCTION(0, NULL)
+	),
+};
+
+#endif /* __PINCTRL_MTK_MT8163_H */

-- 
2.56.0

