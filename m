From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 22 Oct 2026 03:53:26 +0800
Subject: [PATCH 06/18] dt-bindings: reset: add Zhihe A210 reset controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-a210-init-v1-6-5e438f972d24@iscas.ac.cn>
References: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
In-Reply-To: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Icenowy Zheng <uwu@icenowy.me>, 
 Drew Fustini <fustini@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792612403; l=12824;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=QQMThKS/O1WKp2BeqIiVr0QDDnLDOpXgcmQ2rChrXdA=;
 b=RiCe3SILdnTTqAR1vz0jJUjnUosSS3KCb40+hGCd+chsGzM2ZW01S4w9fQKkiv3vBffdOVKo9
 HfrJBr4Dy7vC7G271mCwCQ3frsAVUPw/zeSHafNPnUcY/PJ4qe2gQFN
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>

Add bindings for the A210 reset controllers and their reset IDs.

Signed-off-by: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 .../bindings/reset/zhihe,a210-reset.yaml           |  56 ++++
 include/dt-bindings/reset/zhihe,a210-resets.h      | 351 +++++++++++++++++++++
 2 files changed, 407 insertions(+)

diff --git a/Documentation/devicetree/bindings/reset/zhihe,a210-reset.yaml b/Documentation/devicetree/bindings/reset/zhihe,a210-reset.yaml
new file mode 100644
index 000000000000..708cb49444eb
--- /dev/null
+++ b/Documentation/devicetree/bindings/reset/zhihe,a210-reset.yaml
@@ -0,0 +1,56 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/reset/zhihe,a210-reset.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Zhihe A210 Reset Controller
+
+maintainers:
+  - Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
+
+description:
+  Reset controllers for the Zhihe A210 SoC. Each subsystem exposes a
+  separate reset controller register block and has its own compatible.
+
+properties:
+  compatible:
+    enum:
+      - zhihe,a210-vp-reset
+      - zhihe,a210-vi-reset
+      - zhihe,a210-npu-reset
+      - zhihe,a210-vo-reset
+      - zhihe,a210-peri0-reset
+      - zhihe,a210-peri1-reset
+      - zhihe,a210-peri2-reset
+      - zhihe,a210-peri3-reset
+      - zhihe,a210-pcie-reset
+      - zhihe,a210-usb-reset
+      - zhihe,a210-tee-reset
+      - zhihe,a210-gpu-reset
+
+  reg:
+    maxItems: 1
+
+  "#reset-cells":
+    const: 1
+    description:
+      The single cell is the reset ID defined in
+      include/dt-bindings/reset/zhihe,a210-resets.h.
+
+required:
+  - compatible
+  - reg
+  - "#reset-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/reset/zhihe,a210-resets.h>
+
+    reset-controller@6b20400 {
+        compatible = "zhihe,a210-vp-reset";
+        reg = <0x06b20400 0x200>;
+        #reset-cells = <1>;
+    };
diff --git a/include/dt-bindings/reset/zhihe,a210-resets.h b/include/dt-bindings/reset/zhihe,a210-resets.h
new file mode 100644
index 000000000000..2845c0e9e5ed
--- /dev/null
+++ b/include/dt-bindings/reset/zhihe,a210-resets.h
@@ -0,0 +1,351 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (C) 2025 Zhihe Computing Limited.
+ */
+
+#ifndef _DT_BINDINGS_RESET_ZHIHE_A210_RESETS_H
+#define _DT_BINDINGS_RESET_ZHIHE_A210_RESETS_H
+
+#define VP_VDEC_PRST		0
+#define VP_VDEC_CRST		1
+#define VP_VDEC_ARST		2
+#define VP_VENC_PRST		3
+#define VP_VENC_CRST		4
+#define VP_VENC_ARST		5
+#define VP_G2D_PRST		6
+#define VP_G2D_CRST		7
+#define VP_G2D_ARST		8
+#define VP_COMP_PRST		9
+#define VP_COMP_CRST		10
+#define VP_COMP_ARST		11
+#define VP_DECOMP_PRST		12
+#define VP_DECOMP_CRST		13
+#define VP_DECOMP_ARST		14
+#define VP_DFMU_PRST		15
+#define VP_DFMU_ARST		16
+#define VP_ARB_PRST		17
+#define VP_ARB_ARST		18
+#define VP_VDEC_RS_ARST		19
+#define VP_VENC_RS_ARST		20
+#define VP_COMP_EXTPRST		21
+#define VP_DECOMP_EXTPRST	22
+
+#define VI_MIPI0_CSI0_PRST	0
+#define VI_MIPI0_CSI1_PRST	1
+#define VI_MIPI0_FIFO_RST	2
+#define VI_MIPI1_CSI0_PRST	3
+#define VI_MIPI1_CSI1_PRST	4
+#define VI_MIPI1_FIFO_RST	5
+#define VI_VIPRE_PRST		6
+#define VI_VIPRE_I0_PIX_RST	7
+#define VI_VIPRE_I1_PIX_RST	8
+#define VI_VIPRE_ISPIF_RST	9
+#define VI_VIPRE_ARST		10
+#define VI_ISP_RST		11
+#define VI_COMP_PRST		12
+#define VI_COMP_ARST		13
+#define VI_COMP_ISPOUT_RST	14
+#define VI_COMP_DECOUT_RST	15
+#define VI_COMP_VSEOUT_RST	16
+#define VI_COMP0_RST		17
+#define VI_COMP1_RST		18
+#define VI_DECOMP_RST		19
+#define VI_DW200_RST		20
+#define VI_DFMU_PRST		21
+#define VI_DFMU_ARST		22
+#define VI_ARB_PRST		23
+#define VI_ARB_ARST		24
+#define VI_X2H0_HRST		25
+#define VI_X2H1_HRST		26
+#define VI_X2H2_HRST		27
+#define VI_REC_PRST		28
+#define VI_REC_ARST		29
+
+#define NPU_AAB_MST_RST		0
+#define NPU_AFENCE_RST		1
+#define NPU_AXI_CCU_PRST	2
+#define NPU_AXI_CCU_RST		3
+#define NPU_AXI_M2S1_RST	4
+#define NPU_AXI_RST		5
+#define NPU_CLK_CALC_RST	6
+#define NPU_DFMU_ARST		7
+#define NPU_DFMU_PRST		8
+#define NPU_LPC_C_RST		9
+#define NPU_LPE_C_PRST		10
+#define NPU_LPE_C_RST		11
+#define NPU_ARST		12
+#define NPU_CRST		13
+#define NPU_HRST		14
+#define NPU_PCTRL_PB_RST	15
+#define NPU_PCTRL_PRST		16
+#define NPU_PCTRL_RST		17
+#define NPU_PTW_CCU_PRST	18
+#define NPU_PTW_CCU_RST		19
+#define NPU_SEMA_ARST		20
+#define NPU_SEMA_PRST		21
+#define NPU_DROOP_CCTRL_PRST	22
+#define NPU_DROOP_CCTRL_RST	23
+#define NPU_X2H_RST		24
+#define NPU_X2P_RST		25
+#define NPU_LDIP_RST		26
+#define NPU_SRAM_RST		27
+
+#define VO_X2H0_RST		0
+#define VO_X2H1_RST		1
+#define VO_DPU_HRST		2
+#define VO_DPU_CRST		3
+#define VO_DPU_ARST		4
+#define VO_AUXDISP_PRST		5
+#define VO_AUXDISP_PIX_RST	6
+#define VO_AUXDISP_ARST		7
+#define VO_HDMI_PRST		8
+#define VO_HDMI_MAIN_RST	9
+#define VO_MIPI_PRST		10
+#define VO_DECOMP_PRST		11
+#define VO_DECOMP0_CRST		12
+#define VO_DECOMP1_CRST		13
+#define VO_DECOMP_ARST		14
+#define VO_ARB_PRST		15
+#define VO_ARB_ARST		16
+#define VO_DFMU_PRST		17
+#define VO_DFMU_ARST		18
+
+#define PERI0_TIMER0_CRST	0
+#define PERI0_TIMER0_PRST	1
+#define PERI0_TIMER1_CRST	2
+#define PERI0_TIMER1_PRST	3
+#define PERI0_WDT0_PRST		4
+#define PERI0_MBOX0_PRST	5
+#define PERI0_MBOX1_PRST	6
+#define PERI0_TIMER0_RST	7
+#define PERI0_TIMER1_RST	8
+
+#define PERI1_GMAC0_ARST	0
+#define PERI1_GMAC0_HRST	1
+#define PERI1_GMAC1_ARST	2
+#define PERI1_GMAC1_HRST	3
+#define PERI1_GPIO0_DBRST	4
+#define PERI1_GPIO0_PRST	5
+#define PERI1_GPIO1_DBRST	6
+#define PERI1_GPIO1_PRST	7
+#define PERI1_I2C0_IC_RST	8
+#define PERI1_I2C0_PRST		9
+#define PERI1_I2C1_IC_RST	10
+#define PERI1_I2C1_PRST		11
+#define PERI1_I2C2_IC_RST	12
+#define PERI1_I2C2_PRST		13
+#define PERI1_I2S0_PRST		14
+#define PERI1_MST_BUS_ARST	15
+#define PERI1_MST_BUS_PRST	16
+#define PERI1_PWM0_CRST		17
+#define PERI1_PWM0_PRST		18
+#define PERI1_QSPI0_PRST	19
+#define PERI1_QSPI0_SSI_RST	20
+#define PERI1_SPI0_PRST		21
+#define PERI1_SPI0_SSI_RST	22
+#define PERI1_UART0_PRST	23
+#define PERI1_UART0_S_RST	24
+#define PERI1_UART1_PRST	25
+#define PERI1_UART1_S_RST	26
+#define PERI1_UART2_PRST	27
+#define PERI1_UART2_S_RST	28
+#define PERI1_UART3_PRST	29
+#define PERI1_UART3_S_RST	30
+#define PERI1_X2H_GMAC0_ARST	31
+#define PERI1_X2H_GMAC0_HRST	32
+#define PERI1_X2H_GMAC1_ARST	33
+#define PERI1_X2H_GMAC1_HRST	34
+#define PERI1_DFMU_ARESET	35
+#define PERI1_DFMU_PRESET	36
+#define PERI1_PAD_CTRL_PRST	37
+#define PERI1_PDM0_MRST		38
+#define PERI1_PDM0_PRST		39
+#define PERI1_TDM0_RST		40
+#define PERI1_CAN0_IPG_PE_RST	41
+#define PERI1_CAN0_IPG_RST	42
+#define PERI1_CAN0_IPG_SOFT_RST	43
+#define PERI1_CAN0_IPG_TS_RST	44
+#define PERI1_CAN0_PRST		45
+#define PERI1_CAN1_IPG_PE_RST	46
+#define PERI1_CAN1_IPG_RST	47
+#define PERI1_CAN1_IPG_SOFT_RST	48
+#define PERI1_CAN1_IPG_TS_RST	49
+#define PERI1_CAN1_PRST		50
+#define PERI1_CHIP_DBG_ARST	51
+#define PERI1_CHIP_DBG_CRST	52
+#define PERI1_CHIP_DBG_PRST	53
+#define PERI1_GMAC_CRST		54
+#define PERI1_X2H_GMAC2_ARST	55
+#define PERI1_X2H_GMAC2_HRST	56
+#define PERI1_ZGMAC_X2X_ARST	57
+#define PERI1_SPI0_RST		58
+#define PERI1_I2C0_RST		59
+#define PERI1_I2C1_RST		60
+#define PERI1_I2C2_RST		61
+#define PERI1_GMAC0_RST		62
+#define PERI1_GMAC0_X2H_RST	63
+#define PERI1_GMAC1_RST		64
+#define PERI1_GMAC1_X2H_RST	65
+
+#define PERI2_CAN2_IPG_PE_RST	0
+#define PERI2_CAN2_IPG_RST	1
+#define PERI2_CAN2_IPG_SOFT_RST	2
+#define PERI2_CAN2_IPG_TS_RST	3
+#define PERI2_CAN2_PRST		4
+#define PERI2_GPIO2_DBRST	5
+#define PERI2_GPIO2_PRST	6
+#define PERI2_I2C4_IC_RST	7
+#define PERI2_I2C4_PRST		8
+#define PERI2_I2S2_PRST		9
+#define PERI2_SPI1_PRST		10
+#define PERI2_SPI1_SSI_RST	11
+#define PERI2_UART4_PRST	12
+#define PERI2_UART4_S_RST	13
+#define PERI2_UART5_PRST	14
+#define PERI2_UART5_S_RST	15
+#define PERI2_UART6_PRST	16
+#define PERI2_UART6_S_RST	17
+#define PERI2_PAD_CTRL_PRST	18
+#define PERI2_GPIO3_DBRST	19
+#define PERI2_GPIO3_PRST	20
+#define PERI2_I2C3_IC_RST	21
+#define PERI2_I2C3_PRST		22
+#define PERI2_I2C5_IC_RST	23
+#define PERI2_I2C5_PRST		24
+#define PERI2_I2C6_IC_RST	25
+#define PERI2_I2C6_PRST		26
+#define PERI2_I2C7_IC_RST	27
+#define PERI2_I2C7_PRST		28
+#define PERI2_I2S1_PRST		29
+#define PERI2_I2S3_PRST		30
+#define PERI2_UART7_PRST	31
+#define PERI2_UART7_S_RST	32
+#define PERI2_UART8_PRST	33
+#define PERI2_UART8_S_RST	34
+#define PERI2_UART9_PRST	35
+#define PERI2_UART9_S_RST	36
+#define PERI2_QSPI1_PRST	37
+#define PERI2_QSPI1_SSI_RST	38
+#define PERI2_PWM1_CRST		39
+#define PERI2_PWM1_PRST		40
+#define PERI2_PWM2_CRST		41
+#define PERI2_PWM2_PRST		42
+#define PERI2_I2C3_RST		43
+#define PERI2_I2C4_RST		44
+#define PERI2_I2C5_RST		45
+#define PERI2_I2C6_RST		46
+#define PERI2_I2C7_RST		47
+#define PERI2_SPI1_RST		48
+
+#define PERI3_DMAC_ARST				0
+#define PERI3_DMAC_HRST				1
+#define PERI3_EMMC_SDIO_CLKGEN_RST		2
+#define PERI3_EMMC_RST				3
+#define PERI3_EMMC_X2X_ARST_M			4
+#define PERI3_EMMC_X2X_ARST_S			5
+#define PERI3_SDIO_RST				6
+#define PERI3_SDIO_X2X_ARST_M			7
+#define PERI3_SDIO_X2X_ARST_S			8
+#define PERI3_AXI_MST_ARST			9
+#define PERI3_AXI_MST_PRST			10
+#define PERI3_ADC_PRST				11
+#define PERI3_TEE_X2X_ARST_M			12
+#define PERI3_TEE_X2X_ARST_S			13
+#define PERI3_TEE_H2H_HRST			14
+#define PERI3_GPIO4_DBRST			15
+#define PERI3_GPIO4_PRST			16
+#define PERI3_PAD_CTRL_PRST			17
+
+/* pcie common */
+#define PCIE_X2X_PERI_SLV_ARST			0
+#define PCIE_X2X_PERI_MST_ARST			1
+#define PCIE_AXI4_PCIE_MST_ARST			2
+#define PCIE_AXI4_PCIE_MST_PRST			3
+#define PCIE_DFMU_PRST				4
+#define PCIE_DFMU_ARST				5
+#define PCIE_E16PHY_PHY_RST			6
+#define PCIE_E16PHY_APBS_PRST			7
+#define PCIE_X2X_SATA_MST_ARST			8
+#define PCIE_X2X_SATA_SLV_ARST			9
+
+/* sata */
+#define PCIE_SATA_ARESET			10
+#define PCIE_SATA_RST_PMALIVE			11
+#define PCIE_SATA_SLV_AFENCE_ARST		12
+#define PCIE_SATA_MST_AFENCE_ARST		13
+#define PCIE_SATA_RST_ASIC0			14
+#define PCIE_SATA_RST_ASIC1			15
+#define PCIE_SATA_RST_RXOOB0			16
+#define PCIE_SATA_RST_RXOOB1			17
+
+/* pcie0 */
+#define PCIE_DM_GEN3X4_APBS_PRST		18
+#define PCIE_DM_GEN3X4_POWER_UP_RST		19
+#define PCIE_DM_SLV_AFENCE_ARST			20
+#define PCIE_DM_MST_AFENCE_ARST			21
+
+/* pcie1 */
+#define PCIE_RP_GEN3X1_APBS_PRST		22
+#define PCIE_RP_GEN3X1_POWER_UP_RST		23
+#define PCIE_RP_SLV_AFENCE_ARST			24
+#define PCIE_RP_MST_AFENCE_ARST			25
+
+#define USB_DFMU_PRST				0
+#define USB_DFMU_ARST				1
+#define USB_AXI4_MST_ARST			2
+#define USB_AXI4_MST_PRST			3
+#define USB_DPTX_APBS_PRST			4
+#define USB_DPTX_VCC_RST			5
+#define USB_USB31_APBS_PRST			6
+#define USB_USB31_VCC_RST			7
+#define USB_USB31_PHY_RST			8
+#define USB_USB31_SLV_AFENCE_ARST		9
+#define USB_C10PHY_PHY_RST			10
+#define USB_C10PHY_APBS_PRST			11
+#define USB_USB20_BLK_X2H_HRST			12
+#define USB_USB20_BLK_X2H_ARST			13
+#define USB_USB20_SLV_AFENCE_ARST		14
+#define USB_USB20_BLK_H2P_HRST			15
+#define USB_USB20_BLK_AHB_SLV_HRST		16
+#define USB_USB20_BLK_AXI_MST_ARST		17
+#define USB_USB20_BLK_USB2_SYSREG_PRST		18
+#define USB_USB20_BLK_USB2_WRAP0_PRST		19
+#define USB_USB20_BLK_USB2_WRAP0_HRST		20
+#define USB_USB20_BLK_USB2_WRAP1_PRST		21
+#define USB_USB20_BLK_USB2_WRAP1_HRST		22
+#define USB_USB20_BLK_A2X0_HRST			23
+#define USB_USB20_BLK_A2X0_ARST			24
+#define USB_USB20_BLK_A2X1_HRST			25
+#define USB_USB20_BLK_A2X1_ARST			26
+#define USB_USB20_BLK_USB0_PHY_PON_RESET	27
+#define USB_USB20_BLK_USB1_PHY_PON_RESET	28
+#define USB_PERI2_SS_RST			29
+#define USB_PERI2_SLV_AFENCE_ARST		30
+
+#define TEE_KEYRAM_PRST				0
+#define TEE_DS_PRST				1
+#define TEE_EFUSE_PRST				2
+#define TEE_OCRAM_HRST				3
+#define TEE_SYSREG_PRST				4
+#define TEE_CCU_PRST				5
+#define TEE_CCU_CRST				6
+#define TEE_EIP150B_HRST			7
+#define TEE_EIP120SIII_HRST			8
+#define TEE_EIP120SIII_ARST			9
+#define TEE_EIP120SII_HRST			10
+#define TEE_EIP120SII_ARST			11
+#define TEE_EIP120SI_HRST			12
+#define TEE_EIP120SI_ARST			13
+#define TEE_DMAC_HRST				14
+#define TEE_DMAC_ARST				15
+#define TEE_X2P_TEESYS_PRST			16
+#define TEE_X2P_TEESYS_ARST			17
+#define TEE_AXI4_TEESYS_ARST			18
+#define TEE_APB3_TEESYS_PRST			19
+#define TEE_APB3_TEESYS_HRST			20
+#define TEE_AHB2_TEESYS_HRST			21
+
+#define GPU_PWR_WRAP_RGX_HOOD_RST		0
+#define GPU_PWR_WRAP_DFMU_RST			1
+
+#endif

-- 
2.55.0

