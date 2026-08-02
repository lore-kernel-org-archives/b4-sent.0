From: Esteban Urrutia <esteuwu@proton.me>
Date: Sun, 02 Aug 2026 03:30:55 -0400
Subject: [PATCH v2 2/4] pinctrl: qcom: Commonize pinctrl-sm8450 headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-sm8475-tlmm-v2-2-a93e1d1cb53b@proton.me>
References: <20260802-sm8475-tlmm-v2-0-a93e1d1cb53b@proton.me>
In-Reply-To: <20260802-sm8475-tlmm-v2-0-a93e1d1cb53b@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785656048; l=12925;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=FicDUvkiibB/pKpQsUX6I+Lshtw7HYQv+K4ifmTSe3c=;
 b=pc6MTJDxO4GfziLjj6qZf6/RHFzfOmUuOuMQARHDbkCqhbp8BAXj/6hQeulgXEq+rGNTUAci6
 w3CjChcwhKWC2viOGcwKX+3/joz5DdS3l8z6AbJI6Rs3Arv5vsLBLWY
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some headers found on pinctrl-sm8450 are compatible with SM8475.
Commonize these headers to prepare for adding pinctrl support for SM8475.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 drivers/pinctrl/qcom/pinctrl-sm8450.c | 233 +-------------------------------
 drivers/pinctrl/qcom/pinctrl-sm8450.h | 246 ++++++++++++++++++++++++++++++++++
 2 files changed, 247 insertions(+), 232 deletions(-)

diff --git a/drivers/pinctrl/qcom/pinctrl-sm8450.c b/drivers/pinctrl/qcom/pinctrl-sm8450.c
index 8bb6702cebe2..0d19e604e2e1 100644
--- a/drivers/pinctrl/qcom/pinctrl-sm8450.c
+++ b/drivers/pinctrl/qcom/pinctrl-sm8450.c
@@ -9,96 +9,7 @@
 #include <linux/platform_device.h>
 
 #include "pinctrl-msm.h"
-
-#define REG_SIZE 0x1000
-
-#define PINGROUP(id, f1, f2, f3, f4, f5, f6, f7, f8, f9)	\
-	{					        \
-		.grp = PINCTRL_PINGROUP("gpio" #id, 	\
-			gpio##id##_pins, 		\
-			ARRAY_SIZE(gpio##id##_pins)),	\
-		.funcs = (int[]){			\
-			msm_mux_gpio, /* gpio mode */	\
-			msm_mux_##f1,			\
-			msm_mux_##f2,			\
-			msm_mux_##f3,			\
-			msm_mux_##f4,			\
-			msm_mux_##f5,			\
-			msm_mux_##f6,			\
-			msm_mux_##f7,			\
-			msm_mux_##f8,			\
-			msm_mux_##f9			\
-		},				        \
-		.nfuncs = 10,				\
-		.ctl_reg = REG_SIZE * id,			\
-		.io_reg = 0x4 + REG_SIZE * id,		\
-		.intr_cfg_reg = 0x8 + REG_SIZE * id,		\
-		.intr_status_reg = 0xc + REG_SIZE * id,	\
-		.mux_bit = 2,			\
-		.pull_bit = 0,			\
-		.drv_bit = 6,			\
-		.egpio_enable = 12,		\
-		.egpio_present = 11,		\
-		.oe_bit = 9,			\
-		.in_bit = 0,			\
-		.out_bit = 1,			\
-		.intr_enable_bit = 0,		\
-		.intr_status_bit = 0,		\
-		.intr_target_bit = 5,		\
-		.intr_target_kpss_val = 3,	\
-		.intr_raw_status_bit = 4,	\
-		.intr_polarity_bit = 1,		\
-		.intr_detection_bit = 2,	\
-		.intr_detection_width = 2,	\
-	}
-
-#define SDC_QDSD_PINGROUP(pg_name, ctl, pull, drv)	\
-	{					        \
-		.grp = PINCTRL_PINGROUP(#pg_name, 	\
-			pg_name##_pins, 		\
-			ARRAY_SIZE(pg_name##_pins)),	\
-		.ctl_reg = ctl,				\
-		.io_reg = 0,				\
-		.intr_cfg_reg = 0,			\
-		.intr_status_reg = 0,			\
-		.mux_bit = -1,				\
-		.pull_bit = pull,			\
-		.drv_bit = drv,				\
-		.oe_bit = -1,				\
-		.in_bit = -1,				\
-		.out_bit = -1,				\
-		.intr_enable_bit = -1,			\
-		.intr_status_bit = -1,			\
-		.intr_target_bit = -1,			\
-		.intr_raw_status_bit = -1,		\
-		.intr_polarity_bit = -1,		\
-		.intr_detection_bit = -1,		\
-		.intr_detection_width = -1,		\
-	}
-
-#define UFS_RESET(pg_name, offset)				\
-	{					        \
-		.grp = PINCTRL_PINGROUP(#pg_name, 	\
-			pg_name##_pins, 		\
-			ARRAY_SIZE(pg_name##_pins)),	\
-		.ctl_reg = offset,			\
-		.io_reg = offset + 0x4,			\
-		.intr_cfg_reg = 0,			\
-		.intr_status_reg = 0,			\
-		.mux_bit = -1,				\
-		.pull_bit = 3,				\
-		.drv_bit = 0,				\
-		.oe_bit = -1,				\
-		.in_bit = -1,				\
-		.out_bit = 0,				\
-		.intr_enable_bit = -1,			\
-		.intr_status_bit = -1,			\
-		.intr_target_bit = -1,			\
-		.intr_raw_status_bit = -1,		\
-		.intr_polarity_bit = -1,		\
-		.intr_detection_bit = -1,		\
-		.intr_detection_width = -1,		\
-	}
+#include "pinctrl-sm8450.h"
 
 static const struct pinctrl_pin_desc sm8450_pins[] = {
 	PINCTRL_PIN(0, "GPIO_0"),
@@ -317,8 +228,6 @@ static const struct pinctrl_pin_desc sm8450_pins[] = {
 	PINCTRL_PIN(213, "SDC2_DATA"),
 };
 
-#define DECLARE_MSM_GPIO_PINS(pin) \
-	static const unsigned int gpio##pin##_pins[] = { pin }
 DECLARE_MSM_GPIO_PINS(0);
 DECLARE_MSM_GPIO_PINS(1);
 DECLARE_MSM_GPIO_PINS(2);
@@ -535,146 +444,6 @@ static const unsigned int sdc2_clk_pins[] = { 211 };
 static const unsigned int sdc2_cmd_pins[] = { 212 };
 static const unsigned int sdc2_data_pins[] = { 213 };
 
-enum sm8450_functions {
-	msm_mux_gpio,
-	msm_mux_aon_cam,
-	msm_mux_atest_char,
-	msm_mux_atest_usb,
-	msm_mux_audio_ref,
-	msm_mux_cam_mclk,
-	msm_mux_cci_async,
-	msm_mux_cci_i2c,
-	msm_mux_cci_timer,
-	msm_mux_cmu_rng,
-	msm_mux_coex_uart1,
-	msm_mux_coex_uart2,
-	msm_mux_cri_trng,
-	msm_mux_cri_trng0,
-	msm_mux_cri_trng1,
-	msm_mux_dbg_out,
-	msm_mux_ddr_bist,
-	msm_mux_ddr_pxi0,
-	msm_mux_ddr_pxi1,
-	msm_mux_ddr_pxi2,
-	msm_mux_ddr_pxi3,
-	msm_mux_dp_hot,
-	msm_mux_egpio,
-	msm_mux_gcc_gp1,
-	msm_mux_gcc_gp2,
-	msm_mux_gcc_gp3,
-	msm_mux_ibi_i3c,
-	msm_mux_jitter_bist,
-	msm_mux_mdp_vsync,
-	msm_mux_mdp_vsync0,
-	msm_mux_mdp_vsync1,
-	msm_mux_mdp_vsync2,
-	msm_mux_mdp_vsync3,
-	msm_mux_mi2s0_data0,
-	msm_mux_mi2s0_data1,
-	msm_mux_mi2s0_sck,
-	msm_mux_mi2s0_ws,
-	msm_mux_mi2s2_data0,
-	msm_mux_mi2s2_data1,
-	msm_mux_mi2s2_sck,
-	msm_mux_mi2s2_ws,
-	msm_mux_mss_grfc0,
-	msm_mux_mss_grfc1,
-	msm_mux_mss_grfc10,
-	msm_mux_mss_grfc11,
-	msm_mux_mss_grfc12,
-	msm_mux_mss_grfc2,
-	msm_mux_mss_grfc3,
-	msm_mux_mss_grfc4,
-	msm_mux_mss_grfc5,
-	msm_mux_mss_grfc6,
-	msm_mux_mss_grfc7,
-	msm_mux_mss_grfc8,
-	msm_mux_mss_grfc9,
-	msm_mux_nav,
-	msm_mux_pcie0_clkreqn,
-	msm_mux_pcie1_clkreqn,
-	msm_mux_phase_flag,
-	msm_mux_pll_bist,
-	msm_mux_pll_clk,
-	msm_mux_pri_mi2s,
-	msm_mux_prng_rosc,
-	msm_mux_qdss_cti,
-	msm_mux_qdss_gpio,
-	msm_mux_qlink0_enable,
-	msm_mux_qlink0_request,
-	msm_mux_qlink0_wmss,
-	msm_mux_qlink1_enable,
-	msm_mux_qlink1_request,
-	msm_mux_qlink1_wmss,
-	msm_mux_qlink2_enable,
-	msm_mux_qlink2_request,
-	msm_mux_qlink2_wmss,
-	msm_mux_qspi0,
-	msm_mux_qspi1,
-	msm_mux_qspi2,
-	msm_mux_qspi3,
-	msm_mux_qspi_clk,
-	msm_mux_qspi_cs,
-	msm_mux_qup0,
-	msm_mux_qup1,
-	msm_mux_qup10,
-	msm_mux_qup11,
-	msm_mux_qup12,
-	msm_mux_qup13,
-	msm_mux_qup14,
-	msm_mux_qup15,
-	msm_mux_qup16,
-	msm_mux_qup17,
-	msm_mux_qup18,
-	msm_mux_qup19,
-	msm_mux_qup2,
-	msm_mux_qup20,
-	msm_mux_qup21,
-	msm_mux_qup3,
-	msm_mux_qup4,
-	msm_mux_qup5,
-	msm_mux_qup6,
-	msm_mux_qup7,
-	msm_mux_qup8,
-	msm_mux_qup9,
-	msm_mux_qup_l4,
-	msm_mux_qup_l5,
-	msm_mux_qup_l6,
-	msm_mux_sd_write,
-	msm_mux_sdc40,
-	msm_mux_sdc41,
-	msm_mux_sdc42,
-	msm_mux_sdc43,
-	msm_mux_sdc4_clk,
-	msm_mux_sdc4_cmd,
-	msm_mux_sec_mi2s,
-	msm_mux_tb_trig,
-	msm_mux_tgu_ch0,
-	msm_mux_tgu_ch1,
-	msm_mux_tgu_ch2,
-	msm_mux_tgu_ch3,
-	msm_mux_tmess_prng0,
-	msm_mux_tmess_prng1,
-	msm_mux_tmess_prng2,
-	msm_mux_tmess_prng3,
-	msm_mux_tsense_pwm1,
-	msm_mux_tsense_pwm2,
-	msm_mux_uim0_clk,
-	msm_mux_uim0_data,
-	msm_mux_uim0_present,
-	msm_mux_uim0_reset,
-	msm_mux_uim1_clk,
-	msm_mux_uim1_data,
-	msm_mux_uim1_present,
-	msm_mux_uim1_reset,
-	msm_mux_usb2phy_ac,
-	msm_mux_usb_phy,
-	msm_mux_vfr_0,
-	msm_mux_vfr_1,
-	msm_mux_vsense_trigger,
-	msm_mux__,
-};
-
 static const char * const gpio_groups[] = {
 	"gpio0", "gpio1", "gpio2", "gpio3", "gpio4", "gpio5", "gpio6", "gpio7",
 	"gpio8", "gpio9", "gpio10", "gpio11", "gpio12", "gpio13", "gpio14",
diff --git a/drivers/pinctrl/qcom/pinctrl-sm8450.h b/drivers/pinctrl/qcom/pinctrl-sm8450.h
new file mode 100644
index 000000000000..7501c694db57
--- /dev/null
+++ b/drivers/pinctrl/qcom/pinctrl-sm8450.h
@@ -0,0 +1,246 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/*
+ * Copyright (c) 2020-2021, The Linux Foundation. All rights reserved.
+ * Copyright (c) 2021, Linaro Limited
+ */
+#ifndef __PINCTRL_SM8450_H__
+#define __PINCTRL_SM8450_H__
+
+#include <linux/array_size.h>
+
+#include <linux/pinctrl/pinctrl.h>
+
+#define REG_SIZE 0x1000
+
+#define PINGROUP(id, f1, f2, f3, f4, f5, f6, f7, f8, f9)	\
+	{					        \
+		.grp = PINCTRL_PINGROUP("gpio" #id, 	\
+			gpio##id##_pins, 		\
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
+			msm_mux_##f9			\
+		},				        \
+		.nfuncs = 10,				\
+		.ctl_reg = REG_SIZE * id,			\
+		.io_reg = 0x4 + REG_SIZE * id,		\
+		.intr_cfg_reg = 0x8 + REG_SIZE * id,		\
+		.intr_status_reg = 0xc + REG_SIZE * id,	\
+		.mux_bit = 2,			\
+		.pull_bit = 0,			\
+		.drv_bit = 6,			\
+		.egpio_enable = 12,		\
+		.egpio_present = 11,		\
+		.oe_bit = 9,			\
+		.in_bit = 0,			\
+		.out_bit = 1,			\
+		.intr_enable_bit = 0,		\
+		.intr_status_bit = 0,		\
+		.intr_target_bit = 5,		\
+		.intr_target_kpss_val = 3,	\
+		.intr_raw_status_bit = 4,	\
+		.intr_polarity_bit = 1,		\
+		.intr_detection_bit = 2,	\
+		.intr_detection_width = 2,	\
+	}
+
+#define SDC_QDSD_PINGROUP(pg_name, ctl, pull, drv)	\
+	{					        \
+		.grp = PINCTRL_PINGROUP(#pg_name, 	\
+			pg_name##_pins, 		\
+			ARRAY_SIZE(pg_name##_pins)),	\
+		.ctl_reg = ctl,				\
+		.io_reg = 0,				\
+		.intr_cfg_reg = 0,			\
+		.intr_status_reg = 0,			\
+		.mux_bit = -1,				\
+		.pull_bit = pull,			\
+		.drv_bit = drv,				\
+		.oe_bit = -1,				\
+		.in_bit = -1,				\
+		.out_bit = -1,				\
+		.intr_enable_bit = -1,			\
+		.intr_status_bit = -1,			\
+		.intr_target_bit = -1,			\
+		.intr_raw_status_bit = -1,		\
+		.intr_polarity_bit = -1,		\
+		.intr_detection_bit = -1,		\
+		.intr_detection_width = -1,		\
+	}
+
+#define UFS_RESET(pg_name, offset)				\
+	{					        \
+		.grp = PINCTRL_PINGROUP(#pg_name, 	\
+			pg_name##_pins, 		\
+			ARRAY_SIZE(pg_name##_pins)),	\
+		.ctl_reg = offset,			\
+		.io_reg = offset + 0x4,			\
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
+#define DECLARE_MSM_GPIO_PINS(pin) \
+	static const unsigned int gpio##pin##_pins[] = { pin }
+
+enum sm8450_functions {
+	msm_mux_gpio,
+	msm_mux_aon_cam,
+	msm_mux_atest_char,
+	msm_mux_atest_usb,
+	msm_mux_audio_ref,
+	msm_mux_cam_mclk,
+	msm_mux_cci_async,
+	msm_mux_cci_i2c,
+	msm_mux_cci_timer,
+	msm_mux_cmu_rng,
+	msm_mux_coex_uart1,
+	msm_mux_coex_uart2,
+	msm_mux_cri_trng,
+	msm_mux_cri_trng0,
+	msm_mux_cri_trng1,
+	msm_mux_dbg_out,
+	msm_mux_ddr_bist,
+	msm_mux_ddr_pxi0,
+	msm_mux_ddr_pxi1,
+	msm_mux_ddr_pxi2,
+	msm_mux_ddr_pxi3,
+	msm_mux_dp_hot,
+	msm_mux_egpio,
+	msm_mux_gcc_gp1,
+	msm_mux_gcc_gp2,
+	msm_mux_gcc_gp3,
+	msm_mux_ibi_i3c,
+	msm_mux_jitter_bist,
+	msm_mux_mdp_vsync,
+	msm_mux_mdp_vsync0,
+	msm_mux_mdp_vsync1,
+	msm_mux_mdp_vsync2,
+	msm_mux_mdp_vsync3,
+	msm_mux_mi2s0_data0,
+	msm_mux_mi2s0_data1,
+	msm_mux_mi2s0_sck,
+	msm_mux_mi2s0_ws,
+	msm_mux_mi2s2_data0,
+	msm_mux_mi2s2_data1,
+	msm_mux_mi2s2_sck,
+	msm_mux_mi2s2_ws,
+	msm_mux_mss_grfc0,
+	msm_mux_mss_grfc1,
+	msm_mux_mss_grfc10,
+	msm_mux_mss_grfc11,
+	msm_mux_mss_grfc12,
+	msm_mux_mss_grfc2,
+	msm_mux_mss_grfc3,
+	msm_mux_mss_grfc4,
+	msm_mux_mss_grfc5,
+	msm_mux_mss_grfc6,
+	msm_mux_mss_grfc7,
+	msm_mux_mss_grfc8,
+	msm_mux_mss_grfc9,
+	msm_mux_nav,
+	msm_mux_pcie0_clkreqn,
+	msm_mux_pcie1_clkreqn,
+	msm_mux_phase_flag,
+	msm_mux_pll_bist,
+	msm_mux_pll_clk,
+	msm_mux_pri_mi2s,
+	msm_mux_prng_rosc,
+	msm_mux_qdss_cti,
+	msm_mux_qdss_gpio,
+	msm_mux_qlink0_enable,
+	msm_mux_qlink0_request,
+	msm_mux_qlink0_wmss,
+	msm_mux_qlink1_enable,
+	msm_mux_qlink1_request,
+	msm_mux_qlink1_wmss,
+	msm_mux_qlink2_enable,
+	msm_mux_qlink2_request,
+	msm_mux_qlink2_wmss,
+	msm_mux_qspi0,
+	msm_mux_qspi1,
+	msm_mux_qspi2,
+	msm_mux_qspi3,
+	msm_mux_qspi_clk,
+	msm_mux_qspi_cs,
+	msm_mux_qup0,
+	msm_mux_qup1,
+	msm_mux_qup10,
+	msm_mux_qup11,
+	msm_mux_qup12,
+	msm_mux_qup13,
+	msm_mux_qup14,
+	msm_mux_qup15,
+	msm_mux_qup16,
+	msm_mux_qup17,
+	msm_mux_qup18,
+	msm_mux_qup19,
+	msm_mux_qup2,
+	msm_mux_qup20,
+	msm_mux_qup21,
+	msm_mux_qup3,
+	msm_mux_qup4,
+	msm_mux_qup5,
+	msm_mux_qup6,
+	msm_mux_qup7,
+	msm_mux_qup8,
+	msm_mux_qup9,
+	msm_mux_qup_l4,
+	msm_mux_qup_l5,
+	msm_mux_qup_l6,
+	msm_mux_sd_write,
+	msm_mux_sdc40,
+	msm_mux_sdc41,
+	msm_mux_sdc42,
+	msm_mux_sdc43,
+	msm_mux_sdc4_clk,
+	msm_mux_sdc4_cmd,
+	msm_mux_sec_mi2s,
+	msm_mux_tb_trig,
+	msm_mux_tgu_ch0,
+	msm_mux_tgu_ch1,
+	msm_mux_tgu_ch2,
+	msm_mux_tgu_ch3,
+	msm_mux_tmess_prng0,
+	msm_mux_tmess_prng1,
+	msm_mux_tmess_prng2,
+	msm_mux_tmess_prng3,
+	msm_mux_tsense_pwm1,
+	msm_mux_tsense_pwm2,
+	msm_mux_uim0_clk,
+	msm_mux_uim0_data,
+	msm_mux_uim0_present,
+	msm_mux_uim0_reset,
+	msm_mux_uim1_clk,
+	msm_mux_uim1_data,
+	msm_mux_uim1_present,
+	msm_mux_uim1_reset,
+	msm_mux_usb2phy_ac,
+	msm_mux_usb_phy,
+	msm_mux_vfr_0,
+	msm_mux_vfr_1,
+	msm_mux_vsense_trigger,
+	msm_mux__,
+};
+
+#endif /* __PINCTRL_SM8450_H__ */

-- 
2.55.0

