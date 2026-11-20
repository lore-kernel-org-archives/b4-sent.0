From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Fri, 20 Nov 2026 21:22:29 +0530
Subject: [PATCH v3 2/2] pinctrl: qcom: Add Molokai TLMM driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-molokai-tlmm-v3-2-e5fc37e37011@yahoo.com>
References: <20261120-molokai-tlmm-v3-0-e5fc37e37011@yahoo.com>
In-Reply-To: <20261120-molokai-tlmm-v3-0-e5fc37e37011@yahoo.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795189947; l=58688;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=CyOiGDCQci/wT2nDUEAIza7PTMNFmSEVSMMSMLkNfkI=;
 b=I4kFkOBPO0n7oZW/sJELAX5UFYcW5iI/F4uFTB7cgcyy7JC860UG5s1ko6INxuaLs6/N1Ag9+
 DGusGtmPpxBCDny4iv3h7fgklKfLwVPdM1kQW/mgzU7vBEjK9Ba+Lfc
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the pin controller driver for the TLMM block of the Qualcomm Molokai
(SM8845) SoC.

The register layout is the one of Kaanapali, but the pin functions and
the GPIO to PDC wakeup interrupt map are different on every pin, so the
Kaanapali driver cannot be reused: with its tables, a wake-capable GPIO
interrupt on Molokai is routed to the wrong PDC input and never fires.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 drivers/pinctrl/qcom/Kconfig.msm       |   10 +
 drivers/pinctrl/qcom/Makefile          |    1 +
 drivers/pinctrl/qcom/pinctrl-molokai.c | 1681 ++++++++++++++++++++++++++++++++
 3 files changed, 1692 insertions(+)

diff --git a/drivers/pinctrl/qcom/Kconfig.msm b/drivers/pinctrl/qcom/Kconfig.msm
index e45c701db627..ca5f776c60cb 100644
--- a/drivers/pinctrl/qcom/Kconfig.msm
+++ b/drivers/pinctrl/qcom/Kconfig.msm
@@ -174,6 +174,16 @@ config PINCTRL_MAILI
 	  Say Y here to compile statically, or M here to compile it as a module.
 	  If unsure, say N.
 
+config PINCTRL_MOLOKAI
+	tristate "Qualcomm Technologies Inc Molokai pin controller driver"
+	depends on ARM64 || COMPILE_TEST
+	default ARCH_QCOM
+	help
+	  This is the pinctrl, pinmux, pinconf and gpiolib driver for the
+	  Qualcomm Technologies Inc TLMM block found on the Qualcomm
+	  Technologies Inc Molokai (SM8845) platform. Say Y or M here if
+	  you have a device with this SoC.
+
 config PINCTRL_MSM8226
 	tristate "Qualcomm 8226 pin controller driver"
 	depends on ARM || COMPILE_TEST
diff --git a/drivers/pinctrl/qcom/Makefile b/drivers/pinctrl/qcom/Makefile
index a3daca77a448..8e83e38894e4 100644
--- a/drivers/pinctrl/qcom/Makefile
+++ b/drivers/pinctrl/qcom/Makefile
@@ -42,6 +42,7 @@ obj-$(CONFIG_PINCTRL_MDM9607)	+= pinctrl-mdm9607.o
 obj-$(CONFIG_PINCTRL_MDM9615)	+= pinctrl-mdm9615.o
 obj-$(CONFIG_PINCTRL_MILOS) += pinctrl-milos.o
 obj-$(CONFIG_PINCTRL_MILOS_LPASS_LPI) += pinctrl-milos-lpass-lpi.o
+obj-$(CONFIG_PINCTRL_MOLOKAI)	+= pinctrl-molokai.o
 obj-$(CONFIG_PINCTRL_NORD)	+= pinctrl-nord.o
 obj-$(CONFIG_PINCTRL_QCOM_SPMI_PMIC) += pinctrl-spmi-gpio.o
 obj-$(CONFIG_PINCTRL_QCOM_SPMI_PMIC) += pinctrl-spmi-mpp.o
diff --git a/drivers/pinctrl/qcom/pinctrl-molokai.c b/drivers/pinctrl/qcom/pinctrl-molokai.c
new file mode 100644
index 000000000000..ac59db2a9eb3
--- /dev/null
+++ b/drivers/pinctrl/qcom/pinctrl-molokai.c
@@ -0,0 +1,1681 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
+ * Copyright (c) 2026 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+ */
+
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+
+#include "pinctrl-msm.h"
+
+#define REG_SIZE 0x1000
+#define PINGROUP(id, f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11)	\
+	{					        \
+		.grp = PINCTRL_PINGROUP("gpio" #id,	\
+			gpio##id##_pins,		\
+			ARRAY_SIZE(gpio##id##_pins)),	\
+		.funcs = (int[]){			\
+			msm_mux_gpio, /* gpio mode */	\
+			msm_mux_##f1,			\
+			msm_mux_##f2,			\
+			msm_mux_##f3,			\
+			msm_mux_##f4,			\
+			msm_mux_##f5,			\
+			msm_mux_##f6,			\
+			msm_mux_##f7,			\
+			msm_mux_##f8,			\
+			msm_mux_##f9,			\
+			msm_mux_##f10,			\
+			msm_mux_##f11 /* egpio mode */	\
+		},					\
+		.nfuncs = 12,				\
+		.ctl_reg = REG_SIZE * id,		\
+		.io_reg = 0x4 + REG_SIZE * id,		\
+		.intr_cfg_reg = 0x8 + REG_SIZE * id,	\
+		.intr_status_reg = 0xc + REG_SIZE * id,	\
+		.mux_bit = 2,			\
+		.pull_bit = 0,			\
+		.drv_bit = 6,			\
+		.i2c_pull_bit = 13,		\
+		.egpio_enable = 12,		\
+		.egpio_present = 11,		\
+		.oe_bit = 9,			\
+		.in_bit = 0,			\
+		.out_bit = 1,			\
+		.intr_enable_bit = 0,		\
+		.intr_status_bit = 0,		\
+		.intr_wakeup_present_bit = 6,	\
+		.intr_wakeup_enable_bit = 7,	\
+		.intr_target_bit = 8,		\
+		.intr_target_kpss_val = 3,	\
+		.intr_raw_status_bit = 4,	\
+		.intr_polarity_bit = 1,		\
+		.intr_detection_bit = 2,	\
+		.intr_detection_width = 2,	\
+	}
+
+#define UFS_RESET(pg_name, ctl, io)			\
+	{					        \
+		.grp = PINCTRL_PINGROUP(#pg_name,	\
+			pg_name##_pins,			\
+			ARRAY_SIZE(pg_name##_pins)),    \
+		.ctl_reg = ctl,				\
+		.io_reg = io,				\
+		.intr_cfg_reg = 0,			\
+		.intr_status_reg = 0,			\
+		.mux_bit = -1,				\
+		.pull_bit = 3,				\
+		.drv_bit = 0,				\
+		.oe_bit = -1,				\
+		.in_bit = -1,				\
+		.out_bit = 0,				\
+		.intr_enable_bit = -1,			\
+		.intr_status_bit = -1,			\
+		.intr_target_bit = -1,			\
+		.intr_raw_status_bit = -1,		\
+		.intr_polarity_bit = -1,		\
+		.intr_detection_bit = -1,		\
+		.intr_detection_width = -1,		\
+	}
+
+static const struct pinctrl_pin_desc molokai_pins[] = {
+	PINCTRL_PIN(0, "GPIO_0"),
+	PINCTRL_PIN(1, "GPIO_1"),
+	PINCTRL_PIN(2, "GPIO_2"),
+	PINCTRL_PIN(3, "GPIO_3"),
+	PINCTRL_PIN(4, "GPIO_4"),
+	PINCTRL_PIN(5, "GPIO_5"),
+	PINCTRL_PIN(6, "GPIO_6"),
+	PINCTRL_PIN(7, "GPIO_7"),
+	PINCTRL_PIN(8, "GPIO_8"),
+	PINCTRL_PIN(9, "GPIO_9"),
+	PINCTRL_PIN(10, "GPIO_10"),
+	PINCTRL_PIN(11, "GPIO_11"),
+	PINCTRL_PIN(12, "GPIO_12"),
+	PINCTRL_PIN(13, "GPIO_13"),
+	PINCTRL_PIN(14, "GPIO_14"),
+	PINCTRL_PIN(15, "GPIO_15"),
+	PINCTRL_PIN(16, "GPIO_16"),
+	PINCTRL_PIN(17, "GPIO_17"),
+	PINCTRL_PIN(18, "GPIO_18"),
+	PINCTRL_PIN(19, "GPIO_19"),
+	PINCTRL_PIN(20, "GPIO_20"),
+	PINCTRL_PIN(21, "GPIO_21"),
+	PINCTRL_PIN(22, "GPIO_22"),
+	PINCTRL_PIN(23, "GPIO_23"),
+	PINCTRL_PIN(24, "GPIO_24"),
+	PINCTRL_PIN(25, "GPIO_25"),
+	PINCTRL_PIN(26, "GPIO_26"),
+	PINCTRL_PIN(27, "GPIO_27"),
+	PINCTRL_PIN(28, "GPIO_28"),
+	PINCTRL_PIN(29, "GPIO_29"),
+	PINCTRL_PIN(30, "GPIO_30"),
+	PINCTRL_PIN(31, "GPIO_31"),
+	PINCTRL_PIN(32, "GPIO_32"),
+	PINCTRL_PIN(33, "GPIO_33"),
+	PINCTRL_PIN(34, "GPIO_34"),
+	PINCTRL_PIN(35, "GPIO_35"),
+	PINCTRL_PIN(36, "GPIO_36"),
+	PINCTRL_PIN(37, "GPIO_37"),
+	PINCTRL_PIN(38, "GPIO_38"),
+	PINCTRL_PIN(39, "GPIO_39"),
+	PINCTRL_PIN(40, "GPIO_40"),
+	PINCTRL_PIN(41, "GPIO_41"),
+	PINCTRL_PIN(42, "GPIO_42"),
+	PINCTRL_PIN(43, "GPIO_43"),
+	PINCTRL_PIN(44, "GPIO_44"),
+	PINCTRL_PIN(45, "GPIO_45"),
+	PINCTRL_PIN(46, "GPIO_46"),
+	PINCTRL_PIN(47, "GPIO_47"),
+	PINCTRL_PIN(48, "GPIO_48"),
+	PINCTRL_PIN(49, "GPIO_49"),
+	PINCTRL_PIN(50, "GPIO_50"),
+	PINCTRL_PIN(51, "GPIO_51"),
+	PINCTRL_PIN(52, "GPIO_52"),
+	PINCTRL_PIN(53, "GPIO_53"),
+	PINCTRL_PIN(54, "GPIO_54"),
+	PINCTRL_PIN(55, "GPIO_55"),
+	PINCTRL_PIN(56, "GPIO_56"),
+	PINCTRL_PIN(57, "GPIO_57"),
+	PINCTRL_PIN(58, "GPIO_58"),
+	PINCTRL_PIN(59, "GPIO_59"),
+	PINCTRL_PIN(60, "GPIO_60"),
+	PINCTRL_PIN(61, "GPIO_61"),
+	PINCTRL_PIN(62, "GPIO_62"),
+	PINCTRL_PIN(63, "GPIO_63"),
+	PINCTRL_PIN(64, "GPIO_64"),
+	PINCTRL_PIN(65, "GPIO_65"),
+	PINCTRL_PIN(66, "GPIO_66"),
+	PINCTRL_PIN(67, "GPIO_67"),
+	PINCTRL_PIN(68, "GPIO_68"),
+	PINCTRL_PIN(69, "GPIO_69"),
+	PINCTRL_PIN(70, "GPIO_70"),
+	PINCTRL_PIN(71, "GPIO_71"),
+	PINCTRL_PIN(72, "GPIO_72"),
+	PINCTRL_PIN(73, "GPIO_73"),
+	PINCTRL_PIN(74, "GPIO_74"),
+	PINCTRL_PIN(75, "GPIO_75"),
+	PINCTRL_PIN(76, "GPIO_76"),
+	PINCTRL_PIN(77, "GPIO_77"),
+	PINCTRL_PIN(78, "GPIO_78"),
+	PINCTRL_PIN(79, "GPIO_79"),
+	PINCTRL_PIN(80, "GPIO_80"),
+	PINCTRL_PIN(81, "GPIO_81"),
+	PINCTRL_PIN(82, "GPIO_82"),
+	PINCTRL_PIN(83, "GPIO_83"),
+	PINCTRL_PIN(84, "GPIO_84"),
+	PINCTRL_PIN(85, "GPIO_85"),
+	PINCTRL_PIN(86, "GPIO_86"),
+	PINCTRL_PIN(87, "GPIO_87"),
+	PINCTRL_PIN(88, "GPIO_88"),
+	PINCTRL_PIN(89, "GPIO_89"),
+	PINCTRL_PIN(90, "GPIO_90"),
+	PINCTRL_PIN(91, "GPIO_91"),
+	PINCTRL_PIN(92, "GPIO_92"),
+	PINCTRL_PIN(93, "GPIO_93"),
+	PINCTRL_PIN(94, "GPIO_94"),
+	PINCTRL_PIN(95, "GPIO_95"),
+	PINCTRL_PIN(96, "GPIO_96"),
+	PINCTRL_PIN(97, "GPIO_97"),
+	PINCTRL_PIN(98, "GPIO_98"),
+	PINCTRL_PIN(99, "GPIO_99"),
+	PINCTRL_PIN(100, "GPIO_100"),
+	PINCTRL_PIN(101, "GPIO_101"),
+	PINCTRL_PIN(102, "GPIO_102"),
+	PINCTRL_PIN(103, "GPIO_103"),
+	PINCTRL_PIN(104, "GPIO_104"),
+	PINCTRL_PIN(105, "GPIO_105"),
+	PINCTRL_PIN(106, "GPIO_106"),
+	PINCTRL_PIN(107, "GPIO_107"),
+	PINCTRL_PIN(108, "GPIO_108"),
+	PINCTRL_PIN(109, "GPIO_109"),
+	PINCTRL_PIN(110, "GPIO_110"),
+	PINCTRL_PIN(111, "GPIO_111"),
+	PINCTRL_PIN(112, "GPIO_112"),
+	PINCTRL_PIN(113, "GPIO_113"),
+	PINCTRL_PIN(114, "GPIO_114"),
+	PINCTRL_PIN(115, "GPIO_115"),
+	PINCTRL_PIN(116, "GPIO_116"),
+	PINCTRL_PIN(117, "GPIO_117"),
+	PINCTRL_PIN(118, "GPIO_118"),
+	PINCTRL_PIN(119, "GPIO_119"),
+	PINCTRL_PIN(120, "GPIO_120"),
+	PINCTRL_PIN(121, "GPIO_121"),
+	PINCTRL_PIN(122, "GPIO_122"),
+	PINCTRL_PIN(123, "GPIO_123"),
+	PINCTRL_PIN(124, "GPIO_124"),
+	PINCTRL_PIN(125, "GPIO_125"),
+	PINCTRL_PIN(126, "GPIO_126"),
+	PINCTRL_PIN(127, "GPIO_127"),
+	PINCTRL_PIN(128, "GPIO_128"),
+	PINCTRL_PIN(129, "GPIO_129"),
+	PINCTRL_PIN(130, "GPIO_130"),
+	PINCTRL_PIN(131, "GPIO_131"),
+	PINCTRL_PIN(132, "GPIO_132"),
+	PINCTRL_PIN(133, "GPIO_133"),
+	PINCTRL_PIN(134, "GPIO_134"),
+	PINCTRL_PIN(135, "GPIO_135"),
+	PINCTRL_PIN(136, "GPIO_136"),
+	PINCTRL_PIN(137, "GPIO_137"),
+	PINCTRL_PIN(138, "GPIO_138"),
+	PINCTRL_PIN(139, "GPIO_139"),
+	PINCTRL_PIN(140, "GPIO_140"),
+	PINCTRL_PIN(141, "GPIO_141"),
+	PINCTRL_PIN(142, "GPIO_142"),
+	PINCTRL_PIN(143, "GPIO_143"),
+	PINCTRL_PIN(144, "GPIO_144"),
+	PINCTRL_PIN(145, "GPIO_145"),
+	PINCTRL_PIN(146, "GPIO_146"),
+	PINCTRL_PIN(147, "GPIO_147"),
+	PINCTRL_PIN(148, "GPIO_148"),
+	PINCTRL_PIN(149, "GPIO_149"),
+	PINCTRL_PIN(150, "GPIO_150"),
+	PINCTRL_PIN(151, "GPIO_151"),
+	PINCTRL_PIN(152, "GPIO_152"),
+	PINCTRL_PIN(153, "GPIO_153"),
+	PINCTRL_PIN(154, "GPIO_154"),
+	PINCTRL_PIN(155, "GPIO_155"),
+	PINCTRL_PIN(156, "GPIO_156"),
+	PINCTRL_PIN(157, "GPIO_157"),
+	PINCTRL_PIN(158, "GPIO_158"),
+	PINCTRL_PIN(159, "GPIO_159"),
+	PINCTRL_PIN(160, "GPIO_160"),
+	PINCTRL_PIN(161, "GPIO_161"),
+	PINCTRL_PIN(162, "GPIO_162"),
+	PINCTRL_PIN(163, "GPIO_163"),
+	PINCTRL_PIN(164, "GPIO_164"),
+	PINCTRL_PIN(165, "GPIO_165"),
+	PINCTRL_PIN(166, "GPIO_166"),
+	PINCTRL_PIN(167, "GPIO_167"),
+	PINCTRL_PIN(168, "GPIO_168"),
+	PINCTRL_PIN(169, "GPIO_169"),
+	PINCTRL_PIN(170, "GPIO_170"),
+	PINCTRL_PIN(171, "GPIO_171"),
+	PINCTRL_PIN(172, "GPIO_172"),
+	PINCTRL_PIN(173, "GPIO_173"),
+	PINCTRL_PIN(174, "GPIO_174"),
+	PINCTRL_PIN(175, "GPIO_175"),
+	PINCTRL_PIN(176, "GPIO_176"),
+	PINCTRL_PIN(177, "GPIO_177"),
+	PINCTRL_PIN(178, "GPIO_178"),
+	PINCTRL_PIN(179, "GPIO_179"),
+	PINCTRL_PIN(180, "GPIO_180"),
+	PINCTRL_PIN(181, "GPIO_181"),
+	PINCTRL_PIN(182, "GPIO_182"),
+	PINCTRL_PIN(183, "GPIO_183"),
+	PINCTRL_PIN(184, "GPIO_184"),
+	PINCTRL_PIN(185, "GPIO_185"),
+	PINCTRL_PIN(186, "GPIO_186"),
+	PINCTRL_PIN(187, "GPIO_187"),
+	PINCTRL_PIN(188, "GPIO_188"),
+	PINCTRL_PIN(189, "GPIO_189"),
+	PINCTRL_PIN(190, "GPIO_190"),
+	PINCTRL_PIN(191, "GPIO_191"),
+	PINCTRL_PIN(192, "GPIO_192"),
+	PINCTRL_PIN(193, "GPIO_193"),
+	PINCTRL_PIN(194, "GPIO_194"),
+	PINCTRL_PIN(195, "GPIO_195"),
+	PINCTRL_PIN(196, "GPIO_196"),
+	PINCTRL_PIN(197, "GPIO_197"),
+	PINCTRL_PIN(198, "GPIO_198"),
+	PINCTRL_PIN(199, "GPIO_199"),
+	PINCTRL_PIN(200, "GPIO_200"),
+	PINCTRL_PIN(201, "GPIO_201"),
+	PINCTRL_PIN(202, "GPIO_202"),
+	PINCTRL_PIN(203, "GPIO_203"),
+	PINCTRL_PIN(204, "GPIO_204"),
+	PINCTRL_PIN(205, "UFS_RESET"),
+};
+
+#define DECLARE_MSM_GPIO_PINS(pin) \
+	static const unsigned int gpio##pin##_pins[] = { pin }
+DECLARE_MSM_GPIO_PINS(0);
+DECLARE_MSM_GPIO_PINS(1);
+DECLARE_MSM_GPIO_PINS(2);
+DECLARE_MSM_GPIO_PINS(3);
+DECLARE_MSM_GPIO_PINS(4);
+DECLARE_MSM_GPIO_PINS(5);
+DECLARE_MSM_GPIO_PINS(6);
+DECLARE_MSM_GPIO_PINS(7);
+DECLARE_MSM_GPIO_PINS(8);
+DECLARE_MSM_GPIO_PINS(9);
+DECLARE_MSM_GPIO_PINS(10);
+DECLARE_MSM_GPIO_PINS(11);
+DECLARE_MSM_GPIO_PINS(12);
+DECLARE_MSM_GPIO_PINS(13);
+DECLARE_MSM_GPIO_PINS(14);
+DECLARE_MSM_GPIO_PINS(15);
+DECLARE_MSM_GPIO_PINS(16);
+DECLARE_MSM_GPIO_PINS(17);
+DECLARE_MSM_GPIO_PINS(18);
+DECLARE_MSM_GPIO_PINS(19);
+DECLARE_MSM_GPIO_PINS(20);
+DECLARE_MSM_GPIO_PINS(21);
+DECLARE_MSM_GPIO_PINS(22);
+DECLARE_MSM_GPIO_PINS(23);
+DECLARE_MSM_GPIO_PINS(24);
+DECLARE_MSM_GPIO_PINS(25);
+DECLARE_MSM_GPIO_PINS(26);
+DECLARE_MSM_GPIO_PINS(27);
+DECLARE_MSM_GPIO_PINS(28);
+DECLARE_MSM_GPIO_PINS(29);
+DECLARE_MSM_GPIO_PINS(30);
+DECLARE_MSM_GPIO_PINS(31);
+DECLARE_MSM_GPIO_PINS(32);
+DECLARE_MSM_GPIO_PINS(33);
+DECLARE_MSM_GPIO_PINS(34);
+DECLARE_MSM_GPIO_PINS(35);
+DECLARE_MSM_GPIO_PINS(36);
+DECLARE_MSM_GPIO_PINS(37);
+DECLARE_MSM_GPIO_PINS(38);
+DECLARE_MSM_GPIO_PINS(39);
+DECLARE_MSM_GPIO_PINS(40);
+DECLARE_MSM_GPIO_PINS(41);
+DECLARE_MSM_GPIO_PINS(42);
+DECLARE_MSM_GPIO_PINS(43);
+DECLARE_MSM_GPIO_PINS(44);
+DECLARE_MSM_GPIO_PINS(45);
+DECLARE_MSM_GPIO_PINS(46);
+DECLARE_MSM_GPIO_PINS(47);
+DECLARE_MSM_GPIO_PINS(48);
+DECLARE_MSM_GPIO_PINS(49);
+DECLARE_MSM_GPIO_PINS(50);
+DECLARE_MSM_GPIO_PINS(51);
+DECLARE_MSM_GPIO_PINS(52);
+DECLARE_MSM_GPIO_PINS(53);
+DECLARE_MSM_GPIO_PINS(54);
+DECLARE_MSM_GPIO_PINS(55);
+DECLARE_MSM_GPIO_PINS(56);
+DECLARE_MSM_GPIO_PINS(57);
+DECLARE_MSM_GPIO_PINS(58);
+DECLARE_MSM_GPIO_PINS(59);
+DECLARE_MSM_GPIO_PINS(60);
+DECLARE_MSM_GPIO_PINS(61);
+DECLARE_MSM_GPIO_PINS(62);
+DECLARE_MSM_GPIO_PINS(63);
+DECLARE_MSM_GPIO_PINS(64);
+DECLARE_MSM_GPIO_PINS(65);
+DECLARE_MSM_GPIO_PINS(66);
+DECLARE_MSM_GPIO_PINS(67);
+DECLARE_MSM_GPIO_PINS(68);
+DECLARE_MSM_GPIO_PINS(69);
+DECLARE_MSM_GPIO_PINS(70);
+DECLARE_MSM_GPIO_PINS(71);
+DECLARE_MSM_GPIO_PINS(72);
+DECLARE_MSM_GPIO_PINS(73);
+DECLARE_MSM_GPIO_PINS(74);
+DECLARE_MSM_GPIO_PINS(75);
+DECLARE_MSM_GPIO_PINS(76);
+DECLARE_MSM_GPIO_PINS(77);
+DECLARE_MSM_GPIO_PINS(78);
+DECLARE_MSM_GPIO_PINS(79);
+DECLARE_MSM_GPIO_PINS(80);
+DECLARE_MSM_GPIO_PINS(81);
+DECLARE_MSM_GPIO_PINS(82);
+DECLARE_MSM_GPIO_PINS(83);
+DECLARE_MSM_GPIO_PINS(84);
+DECLARE_MSM_GPIO_PINS(85);
+DECLARE_MSM_GPIO_PINS(86);
+DECLARE_MSM_GPIO_PINS(87);
+DECLARE_MSM_GPIO_PINS(88);
+DECLARE_MSM_GPIO_PINS(89);
+DECLARE_MSM_GPIO_PINS(90);
+DECLARE_MSM_GPIO_PINS(91);
+DECLARE_MSM_GPIO_PINS(92);
+DECLARE_MSM_GPIO_PINS(93);
+DECLARE_MSM_GPIO_PINS(94);
+DECLARE_MSM_GPIO_PINS(95);
+DECLARE_MSM_GPIO_PINS(96);
+DECLARE_MSM_GPIO_PINS(97);
+DECLARE_MSM_GPIO_PINS(98);
+DECLARE_MSM_GPIO_PINS(99);
+DECLARE_MSM_GPIO_PINS(100);
+DECLARE_MSM_GPIO_PINS(101);
+DECLARE_MSM_GPIO_PINS(102);
+DECLARE_MSM_GPIO_PINS(103);
+DECLARE_MSM_GPIO_PINS(104);
+DECLARE_MSM_GPIO_PINS(105);
+DECLARE_MSM_GPIO_PINS(106);
+DECLARE_MSM_GPIO_PINS(107);
+DECLARE_MSM_GPIO_PINS(108);
+DECLARE_MSM_GPIO_PINS(109);
+DECLARE_MSM_GPIO_PINS(110);
+DECLARE_MSM_GPIO_PINS(111);
+DECLARE_MSM_GPIO_PINS(112);
+DECLARE_MSM_GPIO_PINS(113);
+DECLARE_MSM_GPIO_PINS(114);
+DECLARE_MSM_GPIO_PINS(115);
+DECLARE_MSM_GPIO_PINS(116);
+DECLARE_MSM_GPIO_PINS(117);
+DECLARE_MSM_GPIO_PINS(118);
+DECLARE_MSM_GPIO_PINS(119);
+DECLARE_MSM_GPIO_PINS(120);
+DECLARE_MSM_GPIO_PINS(121);
+DECLARE_MSM_GPIO_PINS(122);
+DECLARE_MSM_GPIO_PINS(123);
+DECLARE_MSM_GPIO_PINS(124);
+DECLARE_MSM_GPIO_PINS(125);
+DECLARE_MSM_GPIO_PINS(126);
+DECLARE_MSM_GPIO_PINS(127);
+DECLARE_MSM_GPIO_PINS(128);
+DECLARE_MSM_GPIO_PINS(129);
+DECLARE_MSM_GPIO_PINS(130);
+DECLARE_MSM_GPIO_PINS(131);
+DECLARE_MSM_GPIO_PINS(132);
+DECLARE_MSM_GPIO_PINS(133);
+DECLARE_MSM_GPIO_PINS(134);
+DECLARE_MSM_GPIO_PINS(135);
+DECLARE_MSM_GPIO_PINS(136);
+DECLARE_MSM_GPIO_PINS(137);
+DECLARE_MSM_GPIO_PINS(138);
+DECLARE_MSM_GPIO_PINS(139);
+DECLARE_MSM_GPIO_PINS(140);
+DECLARE_MSM_GPIO_PINS(141);
+DECLARE_MSM_GPIO_PINS(142);
+DECLARE_MSM_GPIO_PINS(143);
+DECLARE_MSM_GPIO_PINS(144);
+DECLARE_MSM_GPIO_PINS(145);
+DECLARE_MSM_GPIO_PINS(146);
+DECLARE_MSM_GPIO_PINS(147);
+DECLARE_MSM_GPIO_PINS(148);
+DECLARE_MSM_GPIO_PINS(149);
+DECLARE_MSM_GPIO_PINS(150);
+DECLARE_MSM_GPIO_PINS(151);
+DECLARE_MSM_GPIO_PINS(152);
+DECLARE_MSM_GPIO_PINS(153);
+DECLARE_MSM_GPIO_PINS(154);
+DECLARE_MSM_GPIO_PINS(155);
+DECLARE_MSM_GPIO_PINS(156);
+DECLARE_MSM_GPIO_PINS(157);
+DECLARE_MSM_GPIO_PINS(158);
+DECLARE_MSM_GPIO_PINS(159);
+DECLARE_MSM_GPIO_PINS(160);
+DECLARE_MSM_GPIO_PINS(161);
+DECLARE_MSM_GPIO_PINS(162);
+DECLARE_MSM_GPIO_PINS(163);
+DECLARE_MSM_GPIO_PINS(164);
+DECLARE_MSM_GPIO_PINS(165);
+DECLARE_MSM_GPIO_PINS(166);
+DECLARE_MSM_GPIO_PINS(167);
+DECLARE_MSM_GPIO_PINS(168);
+DECLARE_MSM_GPIO_PINS(169);
+DECLARE_MSM_GPIO_PINS(170);
+DECLARE_MSM_GPIO_PINS(171);
+DECLARE_MSM_GPIO_PINS(172);
+DECLARE_MSM_GPIO_PINS(173);
+DECLARE_MSM_GPIO_PINS(174);
+DECLARE_MSM_GPIO_PINS(175);
+DECLARE_MSM_GPIO_PINS(176);
+DECLARE_MSM_GPIO_PINS(177);
+DECLARE_MSM_GPIO_PINS(178);
+DECLARE_MSM_GPIO_PINS(179);
+DECLARE_MSM_GPIO_PINS(180);
+DECLARE_MSM_GPIO_PINS(181);
+DECLARE_MSM_GPIO_PINS(182);
+DECLARE_MSM_GPIO_PINS(183);
+DECLARE_MSM_GPIO_PINS(184);
+DECLARE_MSM_GPIO_PINS(185);
+DECLARE_MSM_GPIO_PINS(186);
+DECLARE_MSM_GPIO_PINS(187);
+DECLARE_MSM_GPIO_PINS(188);
+DECLARE_MSM_GPIO_PINS(189);
+DECLARE_MSM_GPIO_PINS(190);
+DECLARE_MSM_GPIO_PINS(191);
+DECLARE_MSM_GPIO_PINS(192);
+DECLARE_MSM_GPIO_PINS(193);
+DECLARE_MSM_GPIO_PINS(194);
+DECLARE_MSM_GPIO_PINS(195);
+DECLARE_MSM_GPIO_PINS(196);
+DECLARE_MSM_GPIO_PINS(197);
+DECLARE_MSM_GPIO_PINS(198);
+DECLARE_MSM_GPIO_PINS(199);
+DECLARE_MSM_GPIO_PINS(200);
+DECLARE_MSM_GPIO_PINS(201);
+DECLARE_MSM_GPIO_PINS(202);
+DECLARE_MSM_GPIO_PINS(203);
+DECLARE_MSM_GPIO_PINS(204);
+
+static const unsigned int ufs_reset_pins[] = { 205 };
+
+enum molokai_functions {
+	msm_mux_gpio,
+	msm_mux_aoss_cti,
+	msm_mux_atest_char,
+	msm_mux_atest_usb,
+	msm_mux_audio_ext_mclk0,
+	msm_mux_audio_ext_mclk1,
+	msm_mux_audio_ref_clk,
+	msm_mux_cam_asc_mclk4,
+	msm_mux_cam_mclk,
+	msm_mux_cci_async_in,
+	msm_mux_cci_i2c_scl,
+	msm_mux_cci_i2c_sda,
+	msm_mux_cci_timer,
+	msm_mux_coex_uart1_rx,
+	msm_mux_coex_uart1_tx,
+	msm_mux_coex_uart2_rx,
+	msm_mux_coex_uart2_tx,
+	msm_mux_dbg_out_clk,
+	msm_mux_ddr_bist_complete,
+	msm_mux_ddr_bist_fail,
+	msm_mux_ddr_bist_start,
+	msm_mux_ddr_bist_stop,
+	msm_mux_ddr_pxi0,
+	msm_mux_ddr_pxi1,
+	msm_mux_ddr_pxi2,
+	msm_mux_ddr_pxi3,
+	msm_mux_dp_hot,
+	msm_mux_egpio,
+	msm_mux_gcc_gp1,
+	msm_mux_gcc_gp2,
+	msm_mux_gcc_gp3,
+	msm_mux_gnss_adc0,
+	msm_mux_gnss_adc1,
+	msm_mux_host2wlan_sol,
+	msm_mux_i2s0_data0,
+	msm_mux_i2s0_data1,
+	msm_mux_i2s0_sck,
+	msm_mux_i2s0_ws,
+	msm_mux_i2s1_data0,
+	msm_mux_i2s1_data1,
+	msm_mux_i2s1_sck,
+	msm_mux_i2s1_ws,
+	msm_mux_ibi_i3c,
+	msm_mux_jitter_bist,
+	msm_mux_mdp_esync0_out,
+	msm_mux_mdp_esync1_out,
+	msm_mux_mdp_vsync,
+	msm_mux_mdp_vsync0_out,
+	msm_mux_mdp_vsync1_out,
+	msm_mux_mdp_vsync2_out,
+	msm_mux_mdp_vsync3_out,
+	msm_mux_mdp_vsync5_out,
+	msm_mux_mdp_vsync_e,
+	msm_mux_nav_gpio0,
+	msm_mux_nav_gpio1,
+	msm_mux_nav_gpio2,
+	msm_mux_nav_gpio3,
+	msm_mux_pcie0_clk_req_n,
+	msm_mux_phase_flag,
+	msm_mux_pll_bist_sync,
+	msm_mux_pll_clk_aux,
+	msm_mux_prng_rosc0,
+	msm_mux_prng_rosc1,
+	msm_mux_prng_rosc2,
+	msm_mux_prng_rosc3,
+	msm_mux_qdss_cti,
+	msm_mux_qdss_gpio_traceclk,
+	msm_mux_qdss_gpio_tracectl,
+	msm_mux_qdss_gpio_tracedata,
+	msm_mux_qlink_big_enable,
+	msm_mux_qlink_big_request,
+	msm_mux_qlink_little_enable,
+	msm_mux_qlink_little_request,
+	msm_mux_qlink_wmss,
+	msm_mux_qspi0,
+	msm_mux_qspi1,
+	msm_mux_qspi2,
+	msm_mux_qspi3,
+	msm_mux_qspi_clk,
+	msm_mux_qspi_cs,
+	msm_mux_qup1_se0,
+	msm_mux_qup1_se1,
+	msm_mux_qup1_se2,
+	msm_mux_qup1_se3,
+	msm_mux_qup1_se4,
+	msm_mux_qup1_se5_mira,
+	msm_mux_qup1_se5_mirb,
+	msm_mux_qup1_se6,
+	msm_mux_qup1_se7,
+	msm_mux_qup2_se0,
+	msm_mux_qup2_se1,
+	msm_mux_qup2_se2,
+	msm_mux_qup2_se3,
+	msm_mux_qup2_se4_mira,
+	msm_mux_qup2_se4_mirb,
+	msm_mux_qup2_se5,
+	msm_mux_qup2_se6,
+	msm_mux_qup2_se7,
+	msm_mux_qup3_se0,
+	msm_mux_qup3_se1,
+	msm_mux_qup3_se2,
+	msm_mux_qup3_se3,
+	msm_mux_qup3_se4,
+	msm_mux_resout_gpio_n,
+	msm_mux_sd_write_protect,
+	msm_mux_sdc2_clk,
+	msm_mux_sdc2_cmd,
+	msm_mux_sdc2_data,
+	msm_mux_sdc2_fb_clk,
+	msm_mux_sys_throttle,
+	msm_mux_tb_trig_sdc2,
+	msm_mux_tmess_prng0,
+	msm_mux_tmess_prng1,
+	msm_mux_tmess_prng2,
+	msm_mux_tmess_prng3,
+	msm_mux_tsense_pwm1,
+	msm_mux_tsense_pwm2,
+	msm_mux_tsense_pwm3,
+	msm_mux_tsense_pwm4,
+	msm_mux_tsense_pwm5,
+	msm_mux_tsense_pwm6,
+	msm_mux_tsense_pwm7,
+	msm_mux_uim0_clk,
+	msm_mux_uim0_data,
+	msm_mux_uim0_present,
+	msm_mux_uim0_reset,
+	msm_mux_uim1_clk,
+	msm_mux_uim1_data,
+	msm_mux_uim1_present,
+	msm_mux_uim1_reset,
+	msm_mux_usb1_hs,
+	msm_mux_usb_phy,
+	msm_mux_vfr_0,
+	msm_mux_vfr_1,
+	msm_mux_vsense_trigger_mirnat,
+	msm_mux_wcn_sw,
+	msm_mux_wcn_sw_ctrl,
+	msm_mux__,
+};
+
+static const char *const gpio_groups[] = {
+	"gpio0", "gpio1", "gpio2", "gpio3", "gpio4", "gpio5",
+	"gpio6", "gpio7", "gpio8", "gpio9", "gpio10", "gpio11",
+	"gpio12", "gpio13", "gpio14", "gpio15", "gpio16", "gpio17",
+	"gpio18", "gpio19", "gpio20", "gpio21", "gpio22", "gpio23",
+	"gpio24", "gpio25", "gpio26", "gpio27", "gpio28", "gpio29",
+	"gpio30", "gpio31", "gpio32", "gpio33", "gpio34", "gpio35",
+	"gpio36", "gpio37", "gpio38", "gpio39", "gpio40", "gpio41",
+	"gpio42", "gpio43", "gpio44", "gpio45", "gpio46", "gpio47",
+	"gpio48", "gpio49", "gpio50", "gpio51", "gpio52", "gpio53",
+	"gpio54", "gpio55", "gpio56", "gpio57", "gpio58", "gpio59",
+	"gpio60", "gpio61", "gpio62", "gpio63", "gpio64", "gpio65",
+	"gpio66", "gpio67", "gpio68", "gpio69", "gpio70", "gpio71",
+	"gpio72", "gpio73", "gpio74", "gpio75", "gpio76", "gpio77",
+	"gpio78", "gpio79", "gpio80", "gpio81", "gpio82", "gpio83",
+	"gpio84", "gpio85", "gpio86", "gpio87", "gpio88", "gpio89",
+	"gpio90", "gpio91", "gpio92", "gpio93", "gpio94", "gpio95",
+	"gpio96", "gpio97", "gpio98", "gpio99", "gpio100", "gpio101",
+	"gpio102", "gpio103", "gpio104", "gpio105", "gpio106", "gpio107",
+	"gpio108", "gpio109", "gpio110", "gpio111", "gpio112", "gpio113",
+	"gpio114", "gpio115", "gpio116", "gpio117", "gpio118", "gpio119",
+	"gpio120", "gpio121", "gpio122", "gpio123", "gpio124", "gpio125",
+	"gpio126", "gpio127", "gpio128", "gpio129", "gpio130", "gpio131",
+	"gpio132", "gpio133", "gpio134", "gpio135", "gpio136", "gpio137",
+	"gpio138", "gpio139", "gpio140", "gpio141", "gpio142", "gpio143",
+	"gpio144", "gpio145", "gpio146", "gpio147", "gpio148", "gpio149",
+	"gpio150", "gpio151", "gpio152", "gpio153", "gpio154", "gpio155",
+	"gpio156", "gpio157", "gpio158", "gpio159", "gpio160", "gpio161",
+	"gpio162", "gpio163", "gpio164", "gpio165", "gpio166", "gpio167",
+	"gpio168", "gpio169", "gpio170", "gpio171", "gpio172", "gpio173",
+	"gpio174", "gpio175", "gpio176", "gpio177", "gpio178", "gpio179",
+	"gpio180", "gpio181", "gpio182", "gpio183", "gpio184", "gpio185",
+	"gpio186", "gpio187", "gpio188", "gpio189", "gpio190", "gpio191",
+	"gpio192", "gpio193", "gpio194", "gpio195", "gpio196", "gpio197",
+	"gpio198", "gpio199", "gpio200", "gpio201", "gpio202", "gpio203",
+	"gpio204",
+};
+
+static const char *const aoss_cti_groups[] = {
+	"gpio50", "gpio51", "gpio60", "gpio61",
+};
+
+static const char *const atest_char_groups[] = {
+	"gpio113", "gpio114", "gpio115", "gpio117", "gpio118",
+};
+
+static const char *const atest_usb_groups[] = {
+	"gpio63", "gpio72", "gpio73", "gpio86", "gpio125",
+};
+
+static const char *const audio_ext_mclk0_groups[] = {
+	"gpio125",
+};
+
+static const char *const audio_ext_mclk1_groups[] = {
+	"gpio124",
+};
+
+static const char *const audio_ref_clk_groups[] = {
+	"gpio125",
+};
+
+static const char *const cam_asc_mclk4_groups[] = {
+	"gpio93",
+};
+
+static const char *const cam_mclk_groups[] = {
+	"gpio89", "gpio90", "gpio91", "gpio92", "gpio94",
+};
+
+static const char *const cci_async_in_groups[] = {
+	"gpio10", "gpio11", "gpio15",
+};
+
+static const char *const cci_i2c_scl_groups[] = {
+	"gpio7", "gpio114", "gpio116", "gpio118",
+};
+
+static const char *const cci_i2c_sda_groups[] = {
+	"gpio111", "gpio113", "gpio115", "gpio117",
+};
+
+static const char *const cci_timer_groups[] = {
+	"gpio109", "gpio110", "gpio111", "gpio163", "gpio164",
+};
+
+static const char *const coex_uart1_rx_groups[] = {
+	"gpio148",
+};
+
+static const char *const coex_uart1_tx_groups[] = {
+	"gpio149",
+};
+
+static const char *const coex_uart2_rx_groups[] = {
+	"gpio150",
+};
+
+static const char *const coex_uart2_tx_groups[] = {
+	"gpio151",
+};
+
+static const char *const dbg_out_clk_groups[] = {
+	"gpio90",
+};
+
+static const char *const ddr_bist_complete_groups[] = {
+	"gpio44",
+};
+
+static const char *const ddr_bist_fail_groups[] = {
+	"gpio40",
+};
+
+static const char *const ddr_bist_start_groups[] = {
+	"gpio41",
+};
+
+static const char *const ddr_bist_stop_groups[] = {
+	"gpio45",
+};
+
+static const char *const ddr_pxi0_groups[] = {
+	"gpio10", "gpio51",
+};
+
+static const char *const ddr_pxi1_groups[] = {
+	"gpio92", "gpio93",
+};
+
+static const char *const ddr_pxi2_groups[] = {
+	"gpio43", "gpio127",
+};
+
+static const char *const ddr_pxi3_groups[] = {
+	"gpio94", "gpio128",
+};
+
+static const char *const dp_hot_groups[] = {
+	"gpio22",
+};
+
+static const char *const egpio_groups[] = {
+	"gpio0", "gpio1", "gpio2", "gpio3", "gpio4", "gpio5",
+	"gpio8", "gpio9", "gpio20", "gpio21", "gpio22", "gpio23",
+	"gpio48", "gpio49", "gpio50", "gpio51", "gpio76", "gpio77",
+	"gpio105", "gpio106", "gpio107", "gpio108", "gpio112", "gpio119",
+	"gpio120", "gpio153", "gpio165", "gpio166", "gpio167", "gpio168",
+	"gpio169", "gpio170", "gpio171", "gpio172", "gpio173", "gpio174",
+	"gpio175", "gpio176", "gpio177", "gpio178", "gpio179", "gpio180",
+	"gpio181", "gpio182", "gpio183", "gpio184", "gpio185", "gpio186",
+	"gpio187", "gpio188", "gpio189", "gpio190", "gpio191", "gpio192",
+	"gpio193", "gpio194", "gpio195", "gpio196", "gpio197", "gpio198",
+	"gpio199", "gpio200", "gpio201", "gpio202", "gpio203", "gpio204",
+};
+
+static const char *const gcc_gp1_groups[] = {
+	"gpio48", "gpio76",
+};
+
+static const char *const gcc_gp2_groups[] = {
+	"gpio49", "gpio77",
+};
+
+static const char *const gcc_gp3_groups[] = {
+	"gpio125", "gpio136",
+};
+
+static const char *const gnss_adc0_groups[] = {
+	"gpio90", "gpio91",
+};
+
+static const char *const gnss_adc1_groups[] = {
+	"gpio60", "gpio87",
+};
+
+static const char *const host2wlan_sol_groups[] = {
+	"gpio95",
+};
+
+static const char *const i2s0_data0_groups[] = {
+	"gpio127",
+};
+
+static const char *const i2s0_data1_groups[] = {
+	"gpio128",
+};
+
+static const char *const i2s0_sck_groups[] = {
+	"gpio126",
+};
+
+static const char *const i2s0_ws_groups[] = {
+	"gpio129",
+};
+
+static const char *const i2s1_data0_groups[] = {
+	"gpio122",
+};
+
+static const char *const i2s1_data1_groups[] = {
+	"gpio124",
+};
+
+static const char *const i2s1_sck_groups[] = {
+	"gpio121",
+};
+
+static const char *const i2s1_ws_groups[] = {
+	"gpio123",
+};
+
+static const char *const ibi_i3c_groups[] = {
+	"gpio0", "gpio1", "gpio4", "gpio5", "gpio8", "gpio9",
+	"gpio12", "gpio13", "gpio24", "gpio25", "gpio28", "gpio29",
+	"gpio32", "gpio33", "gpio36", "gpio37", "gpio48", "gpio49",
+	"gpio52", "gpio53", "gpio64", "gpio65", "gpio68", "gpio69",
+};
+
+static const char *const jitter_bist_groups[] = {
+	"gpio73",
+};
+
+static const char *const mdp_esync0_out_groups[] = {
+	"gpio88",
+};
+
+static const char *const mdp_esync1_out_groups[] = {
+	"gpio100",
+};
+
+static const char *const mdp_vsync_groups[] = {
+	"gpio55", "gpio86", "gpio87", "gpio97",
+};
+
+static const char *const mdp_vsync0_out_groups[] = {
+	"gpio86",
+};
+
+static const char *const mdp_vsync1_out_groups[] = {
+	"gpio86",
+};
+
+static const char *const mdp_vsync2_out_groups[] = {
+	"gpio87",
+};
+
+static const char *const mdp_vsync3_out_groups[] = {
+	"gpio87",
+};
+
+static const char *const mdp_vsync5_out_groups[] = {
+	"gpio87",
+};
+
+static const char *const mdp_vsync_e_groups[] = {
+	"gpio88",
+};
+
+static const char *const nav_gpio0_groups[] = {
+	"gpio154",
+};
+
+static const char *const nav_gpio1_groups[] = {
+	"gpio155",
+};
+
+static const char *const nav_gpio2_groups[] = {
+	"gpio152",
+};
+
+static const char *const nav_gpio3_groups[] = {
+	"gpio154",
+};
+
+static const char *const pcie0_clk_req_n_groups[] = {
+	"gpio103",
+};
+
+static const char *const phase_flag_groups[] = {
+	"gpio6", "gpio7", "gpio11", "gpio14", "gpio15", "gpio16",
+	"gpio17", "gpio18", "gpio19", "gpio26", "gpio27", "gpio31",
+	"gpio34", "gpio42", "gpio44", "gpio45", "gpio46", "gpio47",
+	"gpio62", "gpio88", "gpio100", "gpio102", "gpio103", "gpio104",
+	"gpio109", "gpio110", "gpio113", "gpio114", "gpio117", "gpio118",
+	"gpio129", "gpio163",
+};
+
+static const char *const pll_bist_sync_groups[] = {
+	"gpio104",
+};
+
+static const char *const pll_clk_aux_groups[] = {
+	"gpio111",
+};
+
+static const char *const prng_rosc0_groups[] = {
+	"gpio163",
+};
+
+static const char *const prng_rosc1_groups[] = {
+	"gpio6",
+};
+
+static const char *const prng_rosc2_groups[] = {
+	"gpio7",
+};
+
+static const char *const prng_rosc3_groups[] = {
+	"gpio113",
+};
+
+static const char *const qdss_cti_groups[] = {
+	"gpio2", "gpio20", "gpio21", "gpio31", "gpio105", "gpio108",
+	"gpio112", "gpio119",
+};
+
+static const char *const qdss_gpio_traceclk_groups[] = {
+	"gpio92",
+};
+
+static const char *const qdss_gpio_tracectl_groups[] = {
+	"gpio93",
+};
+
+static const char *const qdss_gpio_tracedata_groups[] = {
+	"gpio3", "gpio26", "gpio27", "gpio89", "gpio90", "gpio91",
+	"gpio94", "gpio109", "gpio110", "gpio111", "gpio113", "gpio114",
+	"gpio116", "gpio117", "gpio118", "gpio164",
+};
+
+static const char *const qlink_big_enable_groups[] = {
+	"gpio160",
+};
+
+static const char *const qlink_big_request_groups[] = {
+	"gpio159",
+};
+
+static const char *const qlink_little_enable_groups[] = {
+	"gpio78",
+};
+
+static const char *const qlink_little_request_groups[] = {
+	"gpio156",
+};
+
+static const char *const qlink_wmss_groups[] = {
+	"gpio158",
+};
+
+static const char *const qspi0_groups[] = {
+	"gpio80",
+};
+
+static const char *const qspi1_groups[] = {
+	"gpio147",
+};
+
+static const char *const qspi2_groups[] = {
+	"gpio81",
+};
+
+static const char *const qspi3_groups[] = {
+	"gpio82",
+};
+
+static const char *const qspi_clk_groups[] = {
+	"gpio83",
+};
+
+static const char *const qspi_cs_groups[] = {
+	"gpio55", "gpio146",
+};
+
+static const char *const qup1_se0_groups[] = {
+	"gpio32", "gpio33", "gpio34", "gpio35",
+};
+
+static const char *const qup1_se1_groups[] = {
+	"gpio36", "gpio37", "gpio38", "gpio39",
+};
+
+static const char *const qup1_se2_groups[] = {
+	"gpio40", "gpio41", "gpio42", "gpio43", "gpio60", "gpio61",
+	"gpio62",
+};
+
+static const char *const qup1_se3_groups[] = {
+	"gpio44", "gpio45", "gpio46", "gpio47",
+};
+
+static const char *const qup1_se4_groups[] = {
+	"gpio48", "gpio49", "gpio50", "gpio51",
+};
+
+static const char *const qup1_se5_mira_groups[] = {
+	"gpio72", "gpio73", "gpio74", "gpio75",
+};
+
+static const char *const qup1_se5_mirb_groups[] = {
+	"gpio202", "gpio203",
+};
+
+static const char *const qup1_se6_groups[] = {
+	"gpio56", "gpio57", "gpio58", "gpio59",
+};
+
+static const char *const qup1_se7_groups[] = {
+	"gpio60", "gpio61", "gpio62", "gpio63",
+};
+
+static const char *const qup2_se0_groups[] = {
+	"gpio0", "gpio1", "gpio2", "gpio3",
+};
+
+static const char *const qup2_se1_groups[] = {
+	"gpio4", "gpio5", "gpio6", "gpio7",
+};
+
+static const char *const qup2_se2_groups[] = {
+	"gpio8", "gpio9", "gpio10", "gpio11", "gpio12", "gpio13",
+	"gpio15",
+};
+
+static const char *const qup2_se3_groups[] = {
+	"gpio12", "gpio13", "gpio14", "gpio15",
+};
+
+static const char *const qup2_se4_mira_groups[] = {
+	"gpio16", "gpio17", "gpio18", "gpio19",
+};
+
+static const char *const qup2_se4_mirb_groups[] = {
+	"gpio109", "gpio117", "gpio118", "gpio164",
+};
+
+static const char *const qup2_se5_groups[] = {
+	"gpio16", "gpio17", "gpio102", "gpio104",
+};
+
+static const char *const qup2_se6_groups[] = {
+	"gpio24", "gpio25", "gpio26", "gpio27",
+};
+
+static const char *const qup2_se7_groups[] = {
+	"gpio28", "gpio29", "gpio30", "gpio31",
+};
+
+static const char *const qup3_se0_groups[] = {
+	"gpio64", "gpio65", "gpio66", "gpio67",
+};
+
+static const char *const qup3_se1_groups[] = {
+	"gpio68", "gpio69", "gpio70", "gpio71",
+};
+
+static const char *const qup3_se2_groups[] = {
+	"gpio80", "gpio81", "gpio82", "gpio83",
+};
+
+static const char *const qup3_se3_groups[] = {
+	"gpio76", "gpio77", "gpio146", "gpio147",
+};
+
+static const char *const qup3_se4_groups[] = {
+	"gpio52", "gpio53", "gpio54", "gpio55",
+};
+
+static const char *const resout_gpio_n_groups[] = {
+	"gpio97",
+};
+
+static const char *const sd_write_protect_groups[] = {
+	"gpio125",
+};
+
+static const char *const sdc2_clk_groups[] = {
+	"gpio98",
+};
+
+static const char *const sdc2_cmd_groups[] = {
+	"gpio162",
+};
+
+static const char *const sdc2_data_groups[] = {
+	"gpio121", "gpio122", "gpio123", "gpio124",
+};
+
+static const char *const sdc2_fb_clk_groups[] = {
+	"gpio96",
+};
+
+static const char *const sys_throttle_groups[] = {
+	"gpio99",
+};
+
+static const char *const tb_trig_sdc2_groups[] = {
+	"gpio87",
+};
+
+static const char *const tmess_prng0_groups[] = {
+	"gpio163",
+};
+
+static const char *const tmess_prng1_groups[] = {
+	"gpio6",
+};
+
+static const char *const tmess_prng2_groups[] = {
+	"gpio7",
+};
+
+static const char *const tmess_prng3_groups[] = {
+	"gpio113",
+};
+
+static const char *const tsense_pwm1_groups[] = {
+	"gpio95",
+};
+
+static const char *const tsense_pwm2_groups[] = {
+	"gpio96",
+};
+
+static const char *const tsense_pwm3_groups[] = {
+	"gpio98",
+};
+
+static const char *const tsense_pwm4_groups[] = {
+	"gpio121",
+};
+
+static const char *const tsense_pwm5_groups[] = {
+	"gpio122",
+};
+
+static const char *const tsense_pwm6_groups[] = {
+	"gpio123",
+};
+
+static const char *const tsense_pwm7_groups[] = {
+	"gpio162",
+};
+
+static const char *const uim0_clk_groups[] = {
+	"gpio131",
+};
+
+static const char *const uim0_data_groups[] = {
+	"gpio130",
+};
+
+static const char *const uim0_present_groups[] = {
+	"gpio133",
+};
+
+static const char *const uim0_reset_groups[] = {
+	"gpio132",
+};
+
+static const char *const uim1_clk_groups[] = {
+	"gpio31", "gpio55", "gpio71", "gpio135",
+};
+
+static const char *const uim1_data_groups[] = {
+	"gpio30", "gpio54", "gpio70", "gpio134",
+};
+
+static const char *const uim1_present_groups[] = {
+	"gpio137",
+};
+
+static const char *const uim1_reset_groups[] = {
+	"gpio29", "gpio53", "gpio67", "gpio136",
+};
+
+static const char *const usb1_hs_groups[] = {
+	"gpio56",
+};
+
+static const char *const usb_phy_groups[] = {
+	"gpio59", "gpio60",
+};
+
+static const char *const vfr_0_groups[] = {
+	"gpio150",
+};
+
+static const char *const vfr_1_groups[] = {
+	"gpio155",
+};
+
+static const char *const vsense_trigger_mirnat_groups[] = {
+	"gpio59",
+};
+
+static const char *const wcn_sw_groups[] = {
+	"gpio19",
+};
+
+static const char *const wcn_sw_ctrl_groups[] = {
+	"gpio18",
+};
+
+static const struct pinfunction molokai_functions[] = {
+	MSM_GPIO_PIN_FUNCTION(gpio),
+	MSM_PIN_FUNCTION(aoss_cti),
+	MSM_PIN_FUNCTION(atest_char),
+	MSM_PIN_FUNCTION(atest_usb),
+	MSM_PIN_FUNCTION(audio_ext_mclk0),
+	MSM_PIN_FUNCTION(audio_ext_mclk1),
+	MSM_PIN_FUNCTION(audio_ref_clk),
+	MSM_PIN_FUNCTION(cam_asc_mclk4),
+	MSM_PIN_FUNCTION(cam_mclk),
+	MSM_PIN_FUNCTION(cci_async_in),
+	MSM_PIN_FUNCTION(cci_i2c_scl),
+	MSM_PIN_FUNCTION(cci_i2c_sda),
+	MSM_PIN_FUNCTION(cci_timer),
+	MSM_PIN_FUNCTION(coex_uart1_rx),
+	MSM_PIN_FUNCTION(coex_uart1_tx),
+	MSM_PIN_FUNCTION(coex_uart2_rx),
+	MSM_PIN_FUNCTION(coex_uart2_tx),
+	MSM_PIN_FUNCTION(dbg_out_clk),
+	MSM_PIN_FUNCTION(ddr_bist_complete),
+	MSM_PIN_FUNCTION(ddr_bist_fail),
+	MSM_PIN_FUNCTION(ddr_bist_start),
+	MSM_PIN_FUNCTION(ddr_bist_stop),
+	MSM_PIN_FUNCTION(ddr_pxi0),
+	MSM_PIN_FUNCTION(ddr_pxi1),
+	MSM_PIN_FUNCTION(ddr_pxi2),
+	MSM_PIN_FUNCTION(ddr_pxi3),
+	MSM_PIN_FUNCTION(dp_hot),
+	MSM_GPIO_PIN_FUNCTION(egpio),
+	MSM_PIN_FUNCTION(gcc_gp1),
+	MSM_PIN_FUNCTION(gcc_gp2),
+	MSM_PIN_FUNCTION(gcc_gp3),
+	MSM_PIN_FUNCTION(gnss_adc0),
+	MSM_PIN_FUNCTION(gnss_adc1),
+	MSM_PIN_FUNCTION(host2wlan_sol),
+	MSM_PIN_FUNCTION(i2s0_data0),
+	MSM_PIN_FUNCTION(i2s0_data1),
+	MSM_PIN_FUNCTION(i2s0_sck),
+	MSM_PIN_FUNCTION(i2s0_ws),
+	MSM_PIN_FUNCTION(i2s1_data0),
+	MSM_PIN_FUNCTION(i2s1_data1),
+	MSM_PIN_FUNCTION(i2s1_sck),
+	MSM_PIN_FUNCTION(i2s1_ws),
+	MSM_PIN_FUNCTION(ibi_i3c),
+	MSM_PIN_FUNCTION(jitter_bist),
+	MSM_PIN_FUNCTION(mdp_esync0_out),
+	MSM_PIN_FUNCTION(mdp_esync1_out),
+	MSM_PIN_FUNCTION(mdp_vsync),
+	MSM_PIN_FUNCTION(mdp_vsync0_out),
+	MSM_PIN_FUNCTION(mdp_vsync1_out),
+	MSM_PIN_FUNCTION(mdp_vsync2_out),
+	MSM_PIN_FUNCTION(mdp_vsync3_out),
+	MSM_PIN_FUNCTION(mdp_vsync5_out),
+	MSM_PIN_FUNCTION(mdp_vsync_e),
+	MSM_PIN_FUNCTION(nav_gpio0),
+	MSM_PIN_FUNCTION(nav_gpio1),
+	MSM_PIN_FUNCTION(nav_gpio2),
+	MSM_PIN_FUNCTION(nav_gpio3),
+	MSM_PIN_FUNCTION(pcie0_clk_req_n),
+	MSM_PIN_FUNCTION(phase_flag),
+	MSM_PIN_FUNCTION(pll_bist_sync),
+	MSM_PIN_FUNCTION(pll_clk_aux),
+	MSM_PIN_FUNCTION(prng_rosc0),
+	MSM_PIN_FUNCTION(prng_rosc1),
+	MSM_PIN_FUNCTION(prng_rosc2),
+	MSM_PIN_FUNCTION(prng_rosc3),
+	MSM_PIN_FUNCTION(qdss_cti),
+	MSM_PIN_FUNCTION(qdss_gpio_traceclk),
+	MSM_PIN_FUNCTION(qdss_gpio_tracectl),
+	MSM_PIN_FUNCTION(qdss_gpio_tracedata),
+	MSM_PIN_FUNCTION(qlink_big_enable),
+	MSM_PIN_FUNCTION(qlink_big_request),
+	MSM_PIN_FUNCTION(qlink_little_enable),
+	MSM_PIN_FUNCTION(qlink_little_request),
+	MSM_PIN_FUNCTION(qlink_wmss),
+	MSM_PIN_FUNCTION(qspi0),
+	MSM_PIN_FUNCTION(qspi1),
+	MSM_PIN_FUNCTION(qspi2),
+	MSM_PIN_FUNCTION(qspi3),
+	MSM_PIN_FUNCTION(qspi_clk),
+	MSM_PIN_FUNCTION(qspi_cs),
+	MSM_PIN_FUNCTION(qup1_se0),
+	MSM_PIN_FUNCTION(qup1_se1),
+	MSM_PIN_FUNCTION(qup1_se2),
+	MSM_PIN_FUNCTION(qup1_se3),
+	MSM_PIN_FUNCTION(qup1_se4),
+	MSM_PIN_FUNCTION(qup1_se5_mira),
+	MSM_PIN_FUNCTION(qup1_se5_mirb),
+	MSM_PIN_FUNCTION(qup1_se6),
+	MSM_PIN_FUNCTION(qup1_se7),
+	MSM_PIN_FUNCTION(qup2_se0),
+	MSM_PIN_FUNCTION(qup2_se1),
+	MSM_PIN_FUNCTION(qup2_se2),
+	MSM_PIN_FUNCTION(qup2_se3),
+	MSM_PIN_FUNCTION(qup2_se4_mira),
+	MSM_PIN_FUNCTION(qup2_se4_mirb),
+	MSM_PIN_FUNCTION(qup2_se5),
+	MSM_PIN_FUNCTION(qup2_se6),
+	MSM_PIN_FUNCTION(qup2_se7),
+	MSM_PIN_FUNCTION(qup3_se0),
+	MSM_PIN_FUNCTION(qup3_se1),
+	MSM_PIN_FUNCTION(qup3_se2),
+	MSM_PIN_FUNCTION(qup3_se3),
+	MSM_PIN_FUNCTION(qup3_se4),
+	MSM_PIN_FUNCTION(resout_gpio_n),
+	MSM_PIN_FUNCTION(sd_write_protect),
+	MSM_PIN_FUNCTION(sdc2_clk),
+	MSM_PIN_FUNCTION(sdc2_cmd),
+	MSM_PIN_FUNCTION(sdc2_data),
+	MSM_PIN_FUNCTION(sdc2_fb_clk),
+	MSM_PIN_FUNCTION(sys_throttle),
+	MSM_PIN_FUNCTION(tb_trig_sdc2),
+	MSM_PIN_FUNCTION(tmess_prng0),
+	MSM_PIN_FUNCTION(tmess_prng1),
+	MSM_PIN_FUNCTION(tmess_prng2),
+	MSM_PIN_FUNCTION(tmess_prng3),
+	MSM_PIN_FUNCTION(tsense_pwm1),
+	MSM_PIN_FUNCTION(tsense_pwm2),
+	MSM_PIN_FUNCTION(tsense_pwm3),
+	MSM_PIN_FUNCTION(tsense_pwm4),
+	MSM_PIN_FUNCTION(tsense_pwm5),
+	MSM_PIN_FUNCTION(tsense_pwm6),
+	MSM_PIN_FUNCTION(tsense_pwm7),
+	MSM_PIN_FUNCTION(uim0_clk),
+	MSM_PIN_FUNCTION(uim0_data),
+	MSM_PIN_FUNCTION(uim0_present),
+	MSM_PIN_FUNCTION(uim0_reset),
+	MSM_PIN_FUNCTION(uim1_clk),
+	MSM_PIN_FUNCTION(uim1_data),
+	MSM_PIN_FUNCTION(uim1_present),
+	MSM_PIN_FUNCTION(uim1_reset),
+	MSM_PIN_FUNCTION(usb1_hs),
+	MSM_PIN_FUNCTION(usb_phy),
+	MSM_PIN_FUNCTION(vfr_0),
+	MSM_PIN_FUNCTION(vfr_1),
+	MSM_PIN_FUNCTION(vsense_trigger_mirnat),
+	MSM_PIN_FUNCTION(wcn_sw),
+	MSM_PIN_FUNCTION(wcn_sw_ctrl),
+};
+
+/* Every pin is maintained as a single group, and missing or non-existing pin
+ * would be maintained as dummy group to synchronize pin group index with
+ * pin descriptor registered with pinctrl core.
+ * Clients would not be able to request these dummy pin groups.
+ */
+static const struct msm_pingroup molokai_groups[] = {
+	[0] = PINGROUP(0, qup2_se0, ibi_i3c, _, _, _, _, _, _, _, _, egpio),
+	[1] = PINGROUP(1, qup2_se0, ibi_i3c, _, _, _, _, _, _, _, _, egpio),
+	[2] = PINGROUP(2, qup2_se0, qdss_cti, _, _, _, _, _, _, _, _, egpio),
+	[3] = PINGROUP(3, qup2_se0, qdss_gpio_tracedata, _, _, _, _, _, _, _, _, egpio),
+	[4] = PINGROUP(4, qup2_se1, ibi_i3c, _, _, _, _, _, _, _, _, egpio),
+	[5] = PINGROUP(5, qup2_se1, ibi_i3c, _, _, _, _, _, _, _, _, egpio),
+	[6] = PINGROUP(6, qup2_se1, tmess_prng1, phase_flag, prng_rosc1, _, _, _, _, _, _, _),
+	[7] = PINGROUP(7, qup2_se1, cci_i2c_scl, tmess_prng2, phase_flag, prng_rosc2, _, _, _, _, _,
+			_),
+	[8] = PINGROUP(8, qup2_se2, ibi_i3c, _, _, _, _, _, _, _, _, egpio),
+	[9] = PINGROUP(9, qup2_se2, ibi_i3c, _, _, _, _, _, _, _, _, egpio),
+	[10] = PINGROUP(10, qup2_se2, cci_async_in, ddr_pxi0, _, _, _, _, _, _, _, _),
+	[11] = PINGROUP(11, qup2_se2, cci_async_in, phase_flag, _, _, _, _, _, _, _, _),
+	[12] = PINGROUP(12, qup2_se3, ibi_i3c, qup2_se2, _, _, _, _, _, _, _, _),
+	[13] = PINGROUP(13, qup2_se3, ibi_i3c, qup2_se2, _, _, _, _, _, _, _, _),
+	[14] = PINGROUP(14, qup2_se3, phase_flag, _, _, _, _, _, _, _, _, _),
+	[15] = PINGROUP(15, qup2_se3, cci_async_in, qup2_se2, phase_flag, _, _, _, _, _, _, _),
+	[16] = PINGROUP(16, qup2_se4_mira, qup2_se5, phase_flag, _, _, _, _, _, _, _, _),
+	[17] = PINGROUP(17, qup2_se4_mira, qup2_se5, _, phase_flag, _, _, _, _, _, _, _),
+	[18] = PINGROUP(18, wcn_sw_ctrl, qup2_se4_mira, phase_flag, _, _, _, _, _, _, _, _),
+	[19] = PINGROUP(19, wcn_sw, qup2_se4_mira, phase_flag, _, _, _, _, _, _, _, _),
+	[20] = PINGROUP(20, qdss_cti, _, _, _, _, _, _, _, _, _, egpio),
+	[21] = PINGROUP(21, qdss_cti, _, _, _, _, _, _, _, _, _, egpio),
+	[22] = PINGROUP(22, dp_hot, _, _, _, _, _, _, _, _, _, egpio),
+	[23] = PINGROUP(23, _, _, _, _, _, _, _, _, _, _, egpio),
+	[24] = PINGROUP(24, qup2_se6, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[25] = PINGROUP(25, qup2_se6, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[26] = PINGROUP(26, qup2_se6, phase_flag, _, qdss_gpio_tracedata, _, _, _, _, _, _, _),
+	[27] = PINGROUP(27, qup2_se6, phase_flag, _, qdss_gpio_tracedata, _, _, _, _, _, _, _),
+	[28] = PINGROUP(28, qup2_se7, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[29] = PINGROUP(29, qup2_se7, uim1_reset, ibi_i3c, _, _, _, _, _, _, _, _),
+	[30] = PINGROUP(30, qup2_se7, uim1_data, _, _, _, _, _, _, _, _, _),
+	[31] = PINGROUP(31, qup2_se7, uim1_clk, phase_flag, _, qdss_cti, _, _, _, _, _, _),
+	[32] = PINGROUP(32, qup1_se0, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[33] = PINGROUP(33, qup1_se0, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[34] = PINGROUP(34, qup1_se0, phase_flag, _, _, _, _, _, _, _, _, _),
+	[35] = PINGROUP(35, qup1_se0, _, _, _, _, _, _, _, _, _, _),
+	[36] = PINGROUP(36, qup1_se1, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[37] = PINGROUP(37, qup1_se1, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[38] = PINGROUP(38, qup1_se1, _, _, _, _, _, _, _, _, _, _),
+	[39] = PINGROUP(39, qup1_se1, _, _, _, _, _, _, _, _, _, _),
+	[40] = PINGROUP(40, qup1_se2, ddr_bist_fail, _, _, _, _, _, _, _, _, _),
+	[41] = PINGROUP(41, qup1_se2, ddr_bist_start, _, _, _, _, _, _, _, _, _),
+	[42] = PINGROUP(42, qup1_se2, phase_flag, _, _, _, _, _, _, _, _, _),
+	[43] = PINGROUP(43, qup1_se2, _, ddr_pxi2, _, _, _, _, _, _, _, _),
+	[44] = PINGROUP(44, qup1_se3, phase_flag, ddr_bist_complete, _, _, _, _, _, _, _, _),
+	[45] = PINGROUP(45, qup1_se3, phase_flag, ddr_bist_stop, _, _, _, _, _, _, _, _),
+	[46] = PINGROUP(46, qup1_se3, phase_flag, _, _, _, _, _, _, _, _, _),
+	[47] = PINGROUP(47, qup1_se3, phase_flag, _, _, _, _, _, _, _, _, _),
+	[48] = PINGROUP(48, qup1_se4, ibi_i3c, gcc_gp1, _, _, _, _, _, _, _, egpio),
+	[49] = PINGROUP(49, qup1_se4, ibi_i3c, gcc_gp2, _, _, _, _, _, _, _, egpio),
+	[50] = PINGROUP(50, qup1_se4, aoss_cti, _, _, _, _, _, _, _, _, egpio),
+	[51] = PINGROUP(51, qup1_se4, aoss_cti, ddr_pxi0, _, _, _, _, _, _, _, egpio),
+	[52] = PINGROUP(52, qup3_se4, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[53] = PINGROUP(53, qup3_se4, ibi_i3c, uim1_reset, _, _, _, _, _, _, _, _),
+	[54] = PINGROUP(54, qup3_se4, uim1_data, _, _, _, _, _, _, _, _, _),
+	[55] = PINGROUP(55, qup3_se4, qspi_cs, uim1_clk, mdp_vsync, _, _, _, _, _, _, _),
+	[56] = PINGROUP(56, qup1_se6, usb1_hs, _, _, _, _, _, _, _, _, _),
+	[57] = PINGROUP(57, qup1_se6, _, _, _, _, _, _, _, _, _, _),
+	[58] = PINGROUP(58, qup1_se6, _, _, _, _, _, _, _, _, _, _),
+	[59] = PINGROUP(59, qup1_se6, usb_phy, vsense_trigger_mirnat, _, _, _, _, _, _, _, _),
+	[60] = PINGROUP(60, qup1_se7, usb_phy, aoss_cti, qup1_se2, gnss_adc1, _, _, _, _, _, _),
+	[61] = PINGROUP(61, qup1_se7, qup1_se2, aoss_cti, _, _, _, _, _, _, _, _),
+	[62] = PINGROUP(62, qup1_se7, qup1_se2, phase_flag, _, _, _, _, _, _, _, _),
+	[63] = PINGROUP(63, qup1_se7, _, atest_usb, _, _, _, _, _, _, _, _),
+	[64] = PINGROUP(64, qup3_se0, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[65] = PINGROUP(65, qup3_se0, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[66] = PINGROUP(66, qup3_se0, _, _, _, _, _, _, _, _, _, _),
+	[67] = PINGROUP(67, qup3_se0, uim1_reset, _, _, _, _, _, _, _, _, _),
+	[68] = PINGROUP(68, qup3_se1, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[69] = PINGROUP(69, qup3_se1, ibi_i3c, _, _, _, _, _, _, _, _, _),
+	[70] = PINGROUP(70, qup3_se1, uim1_data, _, _, _, _, _, _, _, _, _),
+	[71] = PINGROUP(71, qup3_se1, uim1_clk, _, _, _, _, _, _, _, _, _),
+	[72] = PINGROUP(72, qup1_se5_mira, _, atest_usb, _, _, _, _, _, _, _, _),
+	[73] = PINGROUP(73, qup1_se5_mira, jitter_bist, atest_usb, _, _, _, _, _, _, _, _),
+	[74] = PINGROUP(74, qup1_se5_mira, _, _, _, _, _, _, _, _, _, _),
+	[75] = PINGROUP(75, qup1_se5_mira, _, _, _, _, _, _, _, _, _, _),
+	[76] = PINGROUP(76, qup3_se3, gcc_gp1, _, _, _, _, _, _, _, _, egpio),
+	[77] = PINGROUP(77, qup3_se3, gcc_gp2, _, _, _, _, _, _, _, _, egpio),
+	[78] = PINGROUP(78, qlink_little_enable, _, _, _, _, _, _, _, _, _, _),
+	[79] = PINGROUP(79, _, _, _, _, _, _, _, _, _, _, _),
+	[80] = PINGROUP(80, qup3_se2, _, qspi0, _, _, _, _, _, _, _, _),
+	[81] = PINGROUP(81, qup3_se2, _, qspi2, _, _, _, _, _, _, _, _),
+	[82] = PINGROUP(82, qup3_se2, _, _, qspi3, _, _, _, _, _, _, _),
+	[83] = PINGROUP(83, qup3_se2, _, _, qspi_clk, _, _, _, _, _, _, _),
+	[84] = PINGROUP(84, _, _, _, _, _, _, _, _, _, _, _),
+	[85] = PINGROUP(85, _, _, _, _, _, _, _, _, _, _, _),
+	[86] = PINGROUP(86, mdp_vsync, mdp_vsync0_out, mdp_vsync1_out, atest_usb, _, _, _, _, _, _,
+			_),
+	[87] = PINGROUP(87, mdp_vsync, mdp_vsync2_out, mdp_vsync3_out, mdp_vsync5_out, tb_trig_sdc2,
+			gnss_adc1, _, _, _, _, _),
+	[88] = PINGROUP(88, mdp_vsync_e, mdp_esync0_out, phase_flag, _, _, _, _, _, _, _, _),
+	[89] = PINGROUP(89, cam_mclk, qdss_gpio_tracedata, _, _, _, _, _, _, _, _, _),
+	[90] = PINGROUP(90, cam_mclk, dbg_out_clk, qdss_gpio_tracedata, gnss_adc0, _, _, _, _, _, _,
+			_),
+	[91] = PINGROUP(91, cam_mclk, qdss_gpio_tracedata, gnss_adc0, _, _, _, _, _, _, _, _),
+	[92] = PINGROUP(92, cam_mclk, qdss_gpio_traceclk, ddr_pxi1, _, _, _, _, _, _, _, _),
+	[93] = PINGROUP(93, cam_asc_mclk4, qdss_gpio_tracectl, ddr_pxi1, _, _, _, _, _, _, _, _),
+	[94] = PINGROUP(94, cam_mclk, qdss_gpio_tracedata, ddr_pxi3, _, _, _, _, _, _, _, _),
+	[95] = PINGROUP(95, host2wlan_sol, tsense_pwm1, _, _, _, _, _, _, _, _, _),
+	[96] = PINGROUP(96, sdc2_fb_clk, tsense_pwm2, _, _, _, _, _, _, _, _, _),
+	[97] = PINGROUP(97, resout_gpio_n, mdp_vsync, _, _, _, _, _, _, _, _, _),
+	[98] = PINGROUP(98, sdc2_clk, tsense_pwm3, _, _, _, _, _, _, _, _, _),
+	[99] = PINGROUP(99, sys_throttle, _, _, _, _, _, _, _, _, _, _),
+	[100] = PINGROUP(100, mdp_esync1_out, phase_flag, _, _, _, _, _, _, _, _, _),
+	[101] = PINGROUP(101, _, _, _, _, _, _, _, _, _, _, _),
+	[102] = PINGROUP(102, qup2_se5, phase_flag, _, _, _, _, _, _, _, _, _),
+	[103] = PINGROUP(103, pcie0_clk_req_n, phase_flag, _, _, _, _, _, _, _, _, _),
+	[104] = PINGROUP(104, qup2_se5, pll_bist_sync, phase_flag, _, _, _, _, _, _, _, _),
+	[105] = PINGROUP(105, qdss_cti, _, _, _, _, _, _, _, _, _, egpio),
+	[106] = PINGROUP(106, _, _, _, _, _, _, _, _, _, _, egpio),
+	[107] = PINGROUP(107, _, _, _, _, _, _, _, _, _, _, egpio),
+	[108] = PINGROUP(108, qdss_cti, _, _, _, _, _, _, _, _, _, egpio),
+	[109] = PINGROUP(109, qup2_se4_mirb, cci_timer, phase_flag, _, qdss_gpio_tracedata, _, _, _,
+			_, _, _),
+	[110] = PINGROUP(110, cci_timer, phase_flag, _, qdss_gpio_tracedata, _, _, _, _, _, _, _),
+	[111] = PINGROUP(111, cci_timer, cci_i2c_sda, pll_clk_aux, qdss_gpio_tracedata, _, _, _, _,
+			_, _, _),
+	[112] = PINGROUP(112, qdss_cti, _, _, _, _, _, _, _, _, _, egpio),
+	[113] = PINGROUP(113, cci_i2c_sda, tmess_prng3, phase_flag, prng_rosc3, _,
+			qdss_gpio_tracedata, atest_char, _, _, _, _),
+	[114] = PINGROUP(114, cci_i2c_scl, phase_flag, _, qdss_gpio_tracedata, atest_char, _, _, _,
+			_, _, _),
+	[115] = PINGROUP(115, cci_i2c_sda, atest_char, _, _, _, _, _, _, _, _, _),
+	[116] = PINGROUP(116, cci_i2c_scl, qdss_gpio_tracedata, _, _, _, _, _, _, _, _, _),
+	[117] = PINGROUP(117, cci_i2c_sda, qup2_se4_mirb, phase_flag, _, qdss_gpio_tracedata,
+			atest_char, _, _, _, _, _),
+	[118] = PINGROUP(118, cci_i2c_scl, qup2_se4_mirb, phase_flag, _, qdss_gpio_tracedata,
+			atest_char, _, _, _, _, _),
+	[119] = PINGROUP(119, qdss_cti, _, _, _, _, _, _, _, _, _, egpio),
+	[120] = PINGROUP(120, _, _, _, _, _, _, _, _, _, _, egpio),
+	[121] = PINGROUP(121, i2s1_sck, sdc2_data, tsense_pwm4, _, _, _, _, _, _, _, _),
+	[122] = PINGROUP(122, i2s1_data0, sdc2_data, tsense_pwm5, _, _, _, _, _, _, _, _),
+	[123] = PINGROUP(123, i2s1_ws, sdc2_data, tsense_pwm6, _, _, _, _, _, _, _, _),
+	[124] = PINGROUP(124, i2s1_data1, sdc2_data, audio_ext_mclk1, _, _, _, _, _, _, _, _),
+	[125] = PINGROUP(125, audio_ext_mclk0, sd_write_protect, audio_ref_clk, gcc_gp3, _,
+			atest_usb, _, _, _, _, _),
+	[126] = PINGROUP(126, i2s0_sck, _, _, _, _, _, _, _, _, _, _),
+	[127] = PINGROUP(127, i2s0_data0, _, ddr_pxi2, _, _, _, _, _, _, _, _),
+	[128] = PINGROUP(128, i2s0_data1, _, ddr_pxi3, _, _, _, _, _, _, _, _),
+	[129] = PINGROUP(129, i2s0_ws, phase_flag, _, _, _, _, _, _, _, _, _),
+	[130] = PINGROUP(130, uim0_data, _, _, _, _, _, _, _, _, _, _),
+	[131] = PINGROUP(131, uim0_clk, _, _, _, _, _, _, _, _, _, _),
+	[132] = PINGROUP(132, uim0_reset, _, _, _, _, _, _, _, _, _, _),
+	[133] = PINGROUP(133, uim0_present, _, _, _, _, _, _, _, _, _, _),
+	[134] = PINGROUP(134, uim1_data, _, _, _, _, _, _, _, _, _, _),
+	[135] = PINGROUP(135, uim1_clk, _, _, _, _, _, _, _, _, _, _),
+	[136] = PINGROUP(136, uim1_reset, gcc_gp3, _, _, _, _, _, _, _, _, _),
+	[137] = PINGROUP(137, uim1_present, _, _, _, _, _, _, _, _, _, _),
+	[138] = PINGROUP(138, _, _, _, _, _, _, _, _, _, _, _),
+	[139] = PINGROUP(139, _, _, _, _, _, _, _, _, _, _, _),
+	[140] = PINGROUP(140, _, _, _, _, _, _, _, _, _, _, _),
+	[141] = PINGROUP(141, _, _, _, _, _, _, _, _, _, _, _),
+	[142] = PINGROUP(142, _, _, _, _, _, _, _, _, _, _, _),
+	[143] = PINGROUP(143, _, _, _, _, _, _, _, _, _, _, _),
+	[144] = PINGROUP(144, _, _, _, _, _, _, _, _, _, _, _),
+	[145] = PINGROUP(145, _, _, _, _, _, _, _, _, _, _, _),
+	[146] = PINGROUP(146, qup3_se3, _, _, _, _, qspi_cs, _, _, _, _, _),
+	[147] = PINGROUP(147, qup3_se3, _, _, _, qspi1, _, _, _, _, _, _),
+	[148] = PINGROUP(148, coex_uart1_rx, _, _, _, _, _, _, _, _, _, _),
+	[149] = PINGROUP(149, coex_uart1_tx, _, _, _, _, _, _, _, _, _, _),
+	[150] = PINGROUP(150, _, vfr_0, coex_uart2_rx, _, _, _, _, _, _, _, _),
+	[151] = PINGROUP(151, _, coex_uart2_tx, _, _, _, _, _, _, _, _, _),
+	[152] = PINGROUP(152, nav_gpio2, _, _, _, _, _, _, _, _, _, _),
+	[153] = PINGROUP(153, _, _, _, _, _, _, _, _, _, _, egpio),
+	[154] = PINGROUP(154, nav_gpio0, nav_gpio3, _, _, _, _, _, _, _, _, _),
+	[155] = PINGROUP(155, nav_gpio1, vfr_1, _, _, _, _, _, _, _, _, _),
+	[156] = PINGROUP(156, qlink_little_request, _, _, _, _, _, _, _, _, _, _),
+	[157] = PINGROUP(157, _, _, _, _, _, _, _, _, _, _, _),
+	[158] = PINGROUP(158, qlink_wmss, _, _, _, _, _, _, _, _, _, _),
+	[159] = PINGROUP(159, qlink_big_request, _, _, _, _, _, _, _, _, _, _),
+	[160] = PINGROUP(160, qlink_big_enable, _, _, _, _, _, _, _, _, _, _),
+	[161] = PINGROUP(161, _, _, _, _, _, _, _, _, _, _, _),
+	[162] = PINGROUP(162, sdc2_cmd, tsense_pwm7, _, _, _, _, _, _, _, _, _),
+	[163] = PINGROUP(163, cci_timer, prng_rosc0, tmess_prng0, phase_flag, _, _, _, _, _, _, _),
+	[164] = PINGROUP(164, qup2_se4_mirb, cci_timer, qdss_gpio_tracedata, _, _, _, _, _, _, _,
+			_),
+	[165] = PINGROUP(165, _, _, _, _, _, _, _, _, _, _, egpio),
+	[166] = PINGROUP(166, _, _, _, _, _, _, _, _, _, _, egpio),
+	[167] = PINGROUP(167, _, _, _, _, _, _, _, _, _, _, egpio),
+	[168] = PINGROUP(168, _, _, _, _, _, _, _, _, _, _, egpio),
+	[169] = PINGROUP(169, _, _, _, _, _, _, _, _, _, _, egpio),
+	[170] = PINGROUP(170, _, _, _, _, _, _, _, _, _, _, egpio),
+	[171] = PINGROUP(171, _, _, _, _, _, _, _, _, _, _, egpio),
+	[172] = PINGROUP(172, _, _, _, _, _, _, _, _, _, _, egpio),
+	[173] = PINGROUP(173, _, _, _, _, _, _, _, _, _, _, egpio),
+	[174] = PINGROUP(174, _, _, _, _, _, _, _, _, _, _, egpio),
+	[175] = PINGROUP(175, _, _, _, _, _, _, _, _, _, _, egpio),
+	[176] = PINGROUP(176, _, _, _, _, _, _, _, _, _, _, egpio),
+	[177] = PINGROUP(177, _, _, _, _, _, _, _, _, _, _, egpio),
+	[178] = PINGROUP(178, _, _, _, _, _, _, _, _, _, _, egpio),
+	[179] = PINGROUP(179, _, _, _, _, _, _, _, _, _, _, egpio),
+	[180] = PINGROUP(180, _, _, _, _, _, _, _, _, _, _, egpio),
+	[181] = PINGROUP(181, _, _, _, _, _, _, _, _, _, _, egpio),
+	[182] = PINGROUP(182, _, _, _, _, _, _, _, _, _, _, egpio),
+	[183] = PINGROUP(183, _, _, _, _, _, _, _, _, _, _, egpio),
+	[184] = PINGROUP(184, _, _, _, _, _, _, _, _, _, _, egpio),
+	[185] = PINGROUP(185, _, _, _, _, _, _, _, _, _, _, egpio),
+	[186] = PINGROUP(186, _, _, _, _, _, _, _, _, _, _, egpio),
+	[187] = PINGROUP(187, _, _, _, _, _, _, _, _, _, _, egpio),
+	[188] = PINGROUP(188, _, _, _, _, _, _, _, _, _, _, egpio),
+	[189] = PINGROUP(189, _, _, _, _, _, _, _, _, _, _, egpio),
+	[190] = PINGROUP(190, _, _, _, _, _, _, _, _, _, _, egpio),
+	[191] = PINGROUP(191, _, _, _, _, _, _, _, _, _, _, egpio),
+	[192] = PINGROUP(192, _, _, _, _, _, _, _, _, _, _, egpio),
+	[193] = PINGROUP(193, _, _, _, _, _, _, _, _, _, _, egpio),
+	[194] = PINGROUP(194, _, _, _, _, _, _, _, _, _, _, egpio),
+	[195] = PINGROUP(195, _, _, _, _, _, _, _, _, _, _, egpio),
+	[196] = PINGROUP(196, _, _, _, _, _, _, _, _, _, _, egpio),
+	[197] = PINGROUP(197, _, _, _, _, _, _, _, _, _, _, egpio),
+	[198] = PINGROUP(198, _, _, _, _, _, _, _, _, _, _, egpio),
+	[199] = PINGROUP(199, _, _, _, _, _, _, _, _, _, _, egpio),
+	[200] = PINGROUP(200, _, _, _, _, _, _, _, _, _, _, egpio),
+	[201] = PINGROUP(201, _, _, _, _, _, _, _, _, _, _, egpio),
+	[202] = PINGROUP(202, qup1_se5_mirb, _, _, _, _, _, _, _, _, _, egpio),
+	[203] = PINGROUP(203, qup1_se5_mirb, _, _, _, _, _, _, _, _, _, egpio),
+	[204] = PINGROUP(204, _, _, _, _, _, _, _, _, _, _, egpio),
+	[205] = UFS_RESET(ufs_reset, 0xe8004, 0xe9000),
+};
+
+static const struct msm_gpio_wakeirq_map molokai_pdc_map[] = {
+	{ 0, 98 }, { 3, 120 }, { 4, 95 }, { 7, 105 }, { 8, 101 }, { 11, 102 },
+	{ 12, 94 }, { 15, 104 }, { 17, 171 }, { 18, 96 }, { 19, 115 },
+	{ 20, 132 }, { 21, 108 }, { 22, 110 }, { 24, 109 }, { 27, 111 },
+	{ 28, 112 }, { 31, 125 }, { 32, 118 }, { 35, 114 }, { 36, 119 },
+	{ 39, 121 }, { 43, 106 }, { 47, 116 }, { 48, 123 }, { 51, 122 },
+	{ 52, 152 }, { 55, 182 }, { 56, 153 }, { 57, 129 }, { 59, 130 },
+	{ 60, 131 }, { 61, 139 }, { 62, 141 }, { 63, 99 }, { 64, 97 },
+	{ 65, 126 }, { 66, 142 }, { 67, 100 }, { 68, 107 }, { 71, 128 },
+	{ 74, 140 }, { 75, 185 }, { 76, 93 }, { 77, 163 }, { 80, 148 },
+	{ 83, 124 }, { 84, 117 }, { 86, 149 }, { 87, 150 }, { 88, 136 },
+	{ 97, 169 }, { 103, 156 }, { 104, 103 }, { 108, 127 }, { 110, 155 },
+	{ 112, 158 }, { 122, 187 }, { 124, 188 }, { 133, 113 }, { 137, 135 },
+	{ 147, 183 }, { 148, 159 }, { 150, 160 }, { 152, 134 }, { 153, 151 },
+	{ 154, 161 }, { 155, 133 }, { 156, 162 }, { 159, 164 }, { 162, 186 },
+	{ 164, 157 }, { 166, 167 }, { 169, 166 }, { 171, 172 }, { 172, 168 },
+	{ 174, 144 }, { 176, 173 }, { 177, 174 }, { 181, 175 }, { 182, 177 },
+	{ 185, 145 }, { 188, 184 }, { 190, 138 }, { 191, 176 }, { 192, 178 },
+	{ 193, 165 }, { 195, 154 }, { 196, 179 }, { 197, 180 }, { 198, 143 },
+	{ 199, 137 }, { 200, 146 }, { 201, 181 }, { 203, 147 }, { 204, 170 },
+};
+
+static const struct msm_pinctrl_soc_data molokai_tlmm = {
+	.pins = molokai_pins,
+	.npins = ARRAY_SIZE(molokai_pins),
+	.functions = molokai_functions,
+	.nfunctions = ARRAY_SIZE(molokai_functions),
+	.groups = molokai_groups,
+	.ngroups = ARRAY_SIZE(molokai_groups),
+	.ngpios = 206,
+	.wakeirq_map = molokai_pdc_map,
+	.nwakeirq_map = ARRAY_SIZE(molokai_pdc_map),
+	.egpio_func = 11,
+};
+
+static int molokai_tlmm_probe(struct platform_device *pdev)
+{
+	return msm_pinctrl_probe(pdev, &molokai_tlmm);
+}
+
+static const struct of_device_id molokai_tlmm_of_match[] = {
+	{ .compatible = "qcom,molokai-tlmm",},
+	{},
+};
+MODULE_DEVICE_TABLE(of, molokai_tlmm_of_match);
+
+static struct platform_driver molokai_tlmm_driver = {
+	.driver = {
+		.name = "molokai-tlmm",
+		.of_match_table = molokai_tlmm_of_match,
+	},
+	.probe = molokai_tlmm_probe,
+};
+
+static int __init molokai_tlmm_init(void)
+{
+	return platform_driver_register(&molokai_tlmm_driver);
+}
+arch_initcall(molokai_tlmm_init);
+
+static void __exit molokai_tlmm_exit(void)
+{
+	platform_driver_unregister(&molokai_tlmm_driver);
+}
+module_exit(molokai_tlmm_exit);
+
+MODULE_DESCRIPTION("QTI Molokai TLMM driver");
+MODULE_LICENSE("GPL");

-- 
2.56.1

