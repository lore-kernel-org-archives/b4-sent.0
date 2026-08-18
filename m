From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 18 Aug 2026 22:58:35 +0100
Subject: [PATCH v2 1/3] dt-bindings: clock: Add Exynos5515 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-for-next-lucky7-clock-v2-1-cda0cc80f158@member.fsf.org>
References: <20260818-for-next-lucky7-clock-v2-0-cda0cc80f158@member.fsf.org>
In-Reply-To: <20260818-for-next-lucky7-clock-v2-0-cda0cc80f158@member.fsf.org>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Aiden Isik <aidenisik+git@member.fsf.org>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=11863;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=iQxaGTwc8G8+OKSFWTaD9N9iW0tK7hc9mKG0dkjGxWE=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhNWSPBqkCnqqedLNsH6rHWFMy/8HJT4N6cPAI
 Wlpjh2UjomJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoTVkgAKCRBJJwGyxHrX
 69RmEADAjPL4qbxXPjtTGQ9l7hTFEzNfFUoutVDrZm92WmG1i1f/G+8vDAxYxVmlgEb5s4UTU9x
 1sTq2HzaTRh+Rj3wa0lluaQxO12WvTt/3zmMDXHHUbaw6di5tyE7miJKnp1zkQH9SuZtAL/K7Sk
 Pu0g/0VONNpVsQDK64jryCYWE9usT83rynWNzfigQeoywulE64d6MYywQuVoJDRQ6SyD6yzeDHC
 cwkqqnieIFWYK+pNw5PP3EmaGN1em9Z1fEdsY+m7c4Fvc68SZZj94hokP3YoMbbhLaS8wFRN+DJ
 jUFykAbsObwsSM7eIoNrnRIhBQofqxL1D5sysASK69PD20ZkA1yBsKswFCUJB3yf7jouW2F2zDs
 OqNHeFp+RcKHVAS/+8s3yjMDozCkld+XGVUgmlvldHuk+sOP8Laf9wx3I5tSNTwthVZBOwe2ODK
 RJ0ktvB60JaWdrAjkkmyMsrLJ9Usic2vCJ7nflmKtoMbEWvALar4jLcvVfW6a0f2xGQgHG8Uend
 nEWteM4LbWkzno7kkfY1Pm92rOGqLgFKLm1R21m9CNSqbKZy9MviJ1Al//7Q9ZaY2nG8oC+wzDl
 6CA3h84jJPQyt0KGIMBcTsqXcp2qRPptNOvIfp9fSB8CiBPIEI71X7yWnTPsvC7Dd7NQNdLGgis
 WMwQa0tyEhMl3vw==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree documentation for the Exynos5515 SoC's CMUs.

Add device tree bindings for the following CMUs:
- CMU_TOP
- CMU_PERI
- CMU_FSYS

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 .../bindings/clock/samsung,exynos5515-cmu.yaml     | 145 ++++++++++++++++
 include/dt-bindings/clock/samsung,exynos5515-cmu.h | 191 +++++++++++++++++++++
 2 files changed, 336 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/samsung,exynos5515-cmu.yaml b/Documentation/devicetree/bindings/clock/samsung,exynos5515-cmu.yaml
new file mode 100644
index 000000000000..1be8962cda1c
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/samsung,exynos5515-cmu.yaml
@@ -0,0 +1,145 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/samsung,exynos5515-cmu.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Samsung Exynos5515 SoC clock controller
+
+maintainers:
+  - Aiden Isik <aidenisik+git@member.fsf.org>
+  - Chanwoo Choi <cw00.choi@samsung.com>
+  - Krzysztof Kozlowski <krzk@kernel.org>
+
+description: |
+  Exynos5515 clock controller is comprised of several CMU units, generating
+  clocks for different domains. Those CMU units are modeled as separate device
+  tree nodes, and might depend on each other. The root clock in that root tree
+  is an external clock: OSCCLK (26 MHz). This external clock must be defined
+  as a fixed-rate clock in dts.
+
+  CMU_TOP is a top-level CMU, where all base clocks are prepared using PLLs and
+  dividers; all other clocks of function blocks (other CMUs) are usually
+  derived from CMU_TOP.
+
+  Each clock is assigned an identifier and client nodes can use this identifier
+  to specify the clock which they consume. All clocks available for usage
+  in clock consumer nodes are defined as preprocessor macros in
+  'include/dt-bindings/clock/samsung,exynos5515-cmu.h' header.
+
+properties:
+  compatible:
+    enum:
+      - samsung,exynos5515-cmu-fsys
+      - samsung,exynos5515-cmu-peri
+      - samsung,exynos5515-cmu-top
+
+  clocks:
+    minItems: 1
+    maxItems: 5
+
+  clock-names:
+    minItems: 1
+    maxItems: 5
+
+  "#clock-cells":
+    const: 1
+
+  reg:
+    maxItems: 1
+
+  samsung,sysreg:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description:
+      Phandle to system registers interface.
+
+required:
+  - compatible
+  - clocks
+  - clock-names
+  - "#clock-cells"
+  - reg
+  - samsung,sysreg
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - samsung,exynos5515-cmu-fsys
+
+    then:
+      properties:
+        clocks:
+          items:
+            - description: External reference clock (26MHz)
+            - description: CMU_FSYS BUS clock (from CMU_TOP)
+            - description: CMU_FSYS MMC card clock (from CMU_TOP)
+            - description: CMU_FSYS MMC embedded clock (from CMU_TOP)
+            - description: CMU_FSYS USB20DRD clock (from CMU_TOP)
+
+        clock-names:
+          items:
+            - const: oscclk
+            - const: bus
+            - const: mmc_card
+            - const: mmc_embd
+            - const: usb20drd
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - samsung,exynos5515-cmu-peri
+
+    then:
+      properties:
+        clocks:
+          items:
+            - description: External reference clock (26MHz)
+            - description: CMU_PERI BUS clock (from CMU_TOP)
+            - description: CMU_PERI IP clock (from CMU_TOP)
+            - description: CMU_PERI UART clock (from CMU_TOP)
+
+        clock-names:
+          items:
+            - const: oscclk
+            - const: bus
+            - const: ip
+            - const: uart
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: samsung,exynos5515-cmu-top
+
+    then:
+      properties:
+        clocks:
+          items:
+            - description: External reference clock (26 MHz)
+
+        clock-names:
+          items:
+            - const: oscclk
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/samsung,exynos5515-cmu.h>
+
+    cmu_top: clock-controller@15410000 {
+        compatible = "samsung,exynos5515-cmu-top";
+        reg = <0x15410000 0x10000>;
+        #clock-cells = <1>;
+
+        clocks = <&oscclk>;
+        clock-names = "oscclk";
+        samsung,sysreg = <&sysreg_top>;
+    };
+
+...
diff --git a/include/dt-bindings/clock/samsung,exynos5515-cmu.h b/include/dt-bindings/clock/samsung,exynos5515-cmu.h
new file mode 100644
index 000000000000..2877d3681b55
--- /dev/null
+++ b/include/dt-bindings/clock/samsung,exynos5515-cmu.h
@@ -0,0 +1,191 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (c) 2026 Aiden Isik <aidenisik+git@member.fsf.org>
+ * Author: Aiden Isik <aidenisik+git@member.fsf.org>
+ *
+ * Device Tree binding constants for Exynos5515 clock controller.
+ */
+
+#ifndef _DT_BINDINGS_CLOCK_EXYNOS5515_H
+#define _DT_BINDINGS_CLOCK_EXYNOS5515_H
+
+/* CMU_TOP */
+#define CLK_FOUT_AUD_PLL			1
+#define CLK_FOUT_SHARED0_PLL			2
+#define CLK_FOUT_SHARED1_PLL			3
+
+#define CLK_MOUT_CMU_APM_BUS			4
+#define CLK_MOUT_CMU_CORE_BUS			5
+#define CLK_MOUT_CMU_CORE_SSS			6
+#define CLK_MOUT_CMU_CPUCL0_BUSP		7
+#define CLK_MOUT_CMU_CPUCL0_CPU			8
+#define CLK_MOUT_CMU_CPUCL0_DBG			9
+#define CLK_MOUT_CMU_DPU_AUDIF			10
+#define CLK_MOUT_CMU_DPU_AUD_BUS		11
+#define CLK_MOUT_CMU_DPU_AUD_CPU		12
+#define CLK_MOUT_CMU_DPU_BUS			13
+#define CLK_MOUT_CMU_FSYS_BUS			14
+#define CLK_MOUT_CMU_FSYS_MMC_CARD		15
+#define CLK_MOUT_CMU_FSYS_MMC_EMBD		16
+#define CLK_MOUT_CMU_FSYS_USB20DRD		17
+#define CLK_MOUT_CMU_G3D_BUS			18
+#define CLK_MOUT_CMU_MFC_BUS			19
+#define CLK_MOUT_CMU_MIF_BUSP			20
+#define CLK_MOUT_CMU_MIF_SWITCH			21
+#define CLK_MOUT_CMU_MODEM_SHARED1		22
+#define CLK_MOUT_CMU_PERI_BUS			23
+#define CLK_MOUT_CMU_PERI_IP			24
+#define CLK_MOUT_CMU_PERI_UART			25
+#define CLK_MOUT_CMU_CMUREF			26
+
+#define CLK_DOUT_AP2CP_SHARED0_PLL		27
+#define CLK_DOUT_AP2CP_SHARED1_PLL		28
+#define CLK_DOUT_AP2CP_SHARED2_PLL		29
+#define CLK_DOUT_CMU_APM_BUS			30
+#define CLK_DOUT_CMU_CMU_BOOST			31
+#define CLK_DOUT_CMU_CORE_BUS			32
+#define CLK_DOUT_CMU_CORE_SSS			33
+#define CLK_DOUT_CMU_CPUCL0_BUSP		34
+#define CLK_DOUT_CMU_CPUCL0_CPU			35
+#define CLK_DOUT_CMU_CPUCL0_DBG			36
+#define CLK_DOUT_CMU_DPU_AUDIF			37
+#define CLK_DOUT_CMU_DPU_AUD_BUS		38
+#define CLK_DOUT_CMU_DPU_AUD_CPU		39
+#define CLK_DOUT_CMU_DPU_BUS			40
+#define CLK_DOUT_CMU_FSYS_BUS			41
+#define CLK_DOUT_CMU_FSYS_MMC_CARD		42
+#define CLK_DOUT_CMU_FSYS_MMC_EMBD		43
+#define CLK_DOUT_CMU_FSYS_USB20DRD		44
+#define CLK_DOUT_CMU_G3D_BUS			45
+#define CLK_DOUT_CMU_MFC_BUS			46
+#define CLK_DOUT_CMU_MIF_BUSP			47
+#define CLK_DOUT_CMU_PERI_BUS			48
+#define CLK_DOUT_CMU_PERI_IP			49
+#define CLK_DOUT_CMU_PERI_UART			50
+#define CLK_DOUT_CMU_CMUREF			51
+
+#define CLK_DOUT_SHARED0_DIV2			52
+#define CLK_DOUT_SHARED0_DIV3			53
+#define CLK_DOUT_SHARED0_DIV4			54
+#define CLK_DOUT_SHARED1_DIV2			55
+#define CLK_DOUT_SHARED1_DIV3			56
+#define CLK_DOUT_SHARED1_DIV4			57
+#define CLK_DOUT_AUD_DIV2			58
+#define CLK_DOUT_AUD_DIV3			59
+#define CLK_DOUT_AUD_DIV4			60
+
+#define CLK_GOUT_CMU_MIF_SWITCH			61
+#define CLK_GOUT_CMU_APM_BUS			62
+#define CLK_GOUT_CMU_CORE_BUS			63
+#define CLK_GOUT_CMU_CORE_SSS			64
+#define CLK_GOUT_CMU_CPUCL0_BUSP		65
+#define CLK_GOUT_CMU_CPUCL0_CPU			66
+#define CLK_GOUT_CMU_CPUCL0_DBG			67
+#define CLK_GOUT_CMU_DPU_AUDIF			68
+#define CLK_GOUT_CMU_DPU_AUD_BUS		69
+#define CLK_GOUT_CMU_DPU_AUD_CPU		70
+#define CLK_GOUT_CMU_DPU_BUS			71
+#define CLK_GOUT_CMU_FSYS_BUS			72
+#define CLK_GOUT_CMU_FSYS_MMC_CARD		73
+#define CLK_GOUT_CMU_FSYS_MMC_EMBD		74
+#define CLK_GOUT_CMU_FSYS_USB20DRD		75
+#define CLK_GOUT_CMU_G3D_BUS			76
+#define CLK_GOUT_CMU_MFC_BUS			77
+#define CLK_GOUT_CMU_MIF_BUSP			78
+#define CLK_GOUT_CMU_MODEM_SHARED0		79
+#define CLK_GOUT_CMU_MODEM_SHARED1		80
+#define CLK_GOUT_CMU_MODEM_SHARED2		81
+#define CLK_GOUT_CMU_PERI_BUS			82
+#define CLK_GOUT_CMU_PERI_IP			83
+#define CLK_GOUT_CMU_PERI_UART			84
+
+/* CMU_PERI */
+#define CLK_MOUT_PLL_PERI_BUS_USER		1
+#define CLK_MOUT_PLL_PERI_IP_USER		2
+#define CLK_MOUT_PLL_PERI_UART_USER		3
+#define CLK_MOUT_PERI_SPI			4
+#define CLK_MOUT_PERI_USI00_USI			5
+
+#define CLK_DOUT_PERI_OTP			6
+
+#define CLK_DOUT_PERI_I2C_0			7
+#define CLK_DOUT_PERI_I2C_1			8
+#define CLK_DOUT_PERI_I2C_2			9
+#define CLK_DOUT_PERI_I2C_3			10
+#define CLK_DOUT_PERI_SPI			11
+#define CLK_DOUT_PERI_USI00_I2C			12
+#define CLK_DOUT_PERI_USI00_USI			13
+
+#define CLK_GOUT_PERI_BUSIF_TMU_PCLK		14
+#define CLK_GOUT_PERI_D_TZPC_PCLK		15
+#define CLK_GOUT_PERI_GPIO_PCLK			16
+#define CLK_GOUT_PERI_I2C_0_IPCLK		17
+#define CLK_GOUT_PERI_I2C_0_PCLK		18
+#define CLK_GOUT_PERI_I2C_1_IPCLK		19
+#define CLK_GOUT_PERI_I2C_1_PCLK		20
+#define CLK_GOUT_PERI_I2C_2_IPCLK		21
+#define CLK_GOUT_PERI_I2C_2_PCLK		22
+#define CLK_GOUT_PERI_I2C_3_IPCLK		23
+#define CLK_GOUT_PERI_I2C_3_PCLK		24
+#define CLK_GOUT_PERI_MCT_PCLK			25
+#define CLK_GOUT_PERI_OTP_OSCCLK		26
+#define CLK_GOUT_PERI_OTP_PCLK			27
+#define CLK_GOUT_PERI_CMU_PCLK			28
+#define CLK_GOUT_PERI_PWM_MOTOR_PCLK		29
+#define CLK_GOUT_PERI_BUS_CLK			30
+#define CLK_GOUT_PERI_I2C_0_CLK			31
+#define CLK_GOUT_PERI_I2C_1_CLK			32
+#define CLK_GOUT_PERI_I2C_2_CLK			33
+#define CLK_GOUT_PERI_I2C_3_CLK			34
+#define CLK_GOUT_PERI_OSCCLK			35
+#define CLK_GOUT_PERI_SPI_CLK			36
+#define CLK_GOUT_PERI_UART_CLK			37
+#define CLK_GOUT_PERI_USI00_I2C_CLK		38
+#define CLK_GOUT_PERI_USI00_USI_CLK		39
+#define CLK_GOUT_PERI_SLH_AXI_MI_P_CLK		40
+#define CLK_GOUT_PERI_SYSREG_PCLK		41
+#define CLK_GOUT_PERI_USI00_I2C_IPCLK		42
+#define CLK_GOUT_PERI_USI00_I2C_PCLK		43
+#define CLK_GOUT_PERI_USI00_USI_IPCLK		44
+#define CLK_GOUT_PERI_USI00_USI_PCLK		45
+#define CLK_GOUT_PERI_USI_SPI_IPCLK		46
+#define CLK_GOUT_PERI_USI_SPI_PCLK		47
+#define CLK_GOUT_PERI_USI_UART_IPCLK		48
+#define CLK_GOUT_PERI_USI_UART_PCLK		49
+#define CLK_GOUT_PERI_WDT0_PCLK			50
+#define CLK_GOUT_PERI_WDT1_PCLK			51
+#define CLK_GOUT_PERI_I2C_0			52
+#define CLK_GOUT_PERI_I2C_1			53
+#define CLK_GOUT_PERI_I2C_2			54
+#define CLK_GOUT_PERI_I2C_3			55
+#define CLK_GOUT_PERI_USI00_I2C			56
+
+/* CMU_FSYS */
+#define CLK_MOUT_PLL_FSYS_BUS_USER		1
+#define CLK_MOUT_PLL_FSYS_MMC_CARD_USER		2
+#define CLK_MOUT_PLL_FSYS_MMC_EMBD_USER		3
+#define CLK_MOUT_PLL_FSYS_USB20DRD_USER		4
+
+#define CLK_GOUT_FSYS_CMU_PCLK			5
+#define CLK_GOUT_FSYS_MMC_CARD_SDCLKIN		6
+#define CLK_GOUT_FSYS_MMC_EMBD_SDCLKIN		7
+#define CLK_GOUT_FSYS_OSCCLK			8
+#define CLK_GOUT_FSYS_USB20DRD_REFCLK		9
+#define CLK_GOUT_FSYS_USB20DRD_PHY_REFCLK	10
+#define CLK_GOUT_FSYS_D_TZPC_PCLK		11
+#define CLK_GOUT_FSYS_GPIO_PCLK			12
+#define CLK_GOUT_FSYS_MMC_CARD_ACLK		13
+#define CLK_GOUT_FSYS_MMC_EMBD_ACLK		14
+#define CLK_GOUT_FSYS_PPMU_ACLK			15
+#define CLK_GOUT_FSYS_PPMU_PCLK			16
+#define CLK_GOUT_FSYS_BUS_CLK			17
+#define CLK_GOUT_FSYS_SLH_AXI_MI_P_CLK		18
+#define CLK_GOUT_FSYS_SLH_AXI_SI_D_CLK		19
+#define CLK_GOUT_FSYS_SYSREG_PCLK		20
+#define CLK_GOUT_FSYS_USB20DRD_ACLK_PHYCTRL	21
+#define CLK_GOUT_FSYS_USB20DRD_BUS_CLK_EARLY	22
+#define CLK_GOUT_FSYS_US_64TO128_ACLK		23
+#define CLK_GOUT_FSYS_XIU_D_ACLK		24
+#define CLK_GOUT_FSYS_XIU_P_ACLK		25
+
+#endif /* _DT_BINDINGS_CLOCK_EXYNOS5515_H */

-- 
2.54.0

