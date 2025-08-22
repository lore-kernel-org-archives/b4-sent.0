From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 22 Aug 2025 13:39:55 +0800
Subject: [PATCH 1/5] dt-bindings: power: add Amlogic S6 S7 S7D power
 domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250822-pm-s6-s7-s7d-v1-1-82e3f3aff327@amlogic.com>
References: <20250822-pm-s6-s7-s7d-v1-0-82e3f3aff327@amlogic.com>
In-Reply-To: <20250822-pm-s6-s7-s7d-v1-0-82e3f3aff327@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 "hongyu.chen1" <hongyu.chen1@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755841286; l=4197;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=rDe2MvG1qbv0VUQE4y/E8LC5I45fmELEIBYCB0B5NkY=;
 b=MxArxjiZLEg5X5S2V8GYItRjycPJtxsQAxo+PCbv7Qh+80U93vSBt/w1iFUzp2AIkO+OCPim/
 aNKISq1F598C8eEN6/OwOEHW1ECi7huZNruPlQjTep8MrYjxtTKVaW9
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "hongyu.chen1" <hongyu.chen1@amlogic.com>

Add devicetree binding document and related header file for
Amlogic S6 S7 S7D secure power domains.

Signed-off-by: hongyu.chen1 <hongyu.chen1@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/power/amlogic,meson-sec-pwrc.yaml     |  3 +++
 include/dt-bindings/power/amlogic,s6-pwrc.h        | 29 ++++++++++++++++++++++
 include/dt-bindings/power/amlogic,s7-pwrc.h        | 20 +++++++++++++++
 include/dt-bindings/power/amlogic,s7d-pwrc.h       | 27 ++++++++++++++++++++
 4 files changed, 79 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
index 15d74138baa3..12b71688dd34 100644
--- a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
+++ b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
@@ -24,6 +24,9 @@ properties:
       - amlogic,a5-pwrc
       - amlogic,c3-pwrc
       - amlogic,t7-pwrc
+      - amlogic,s6-pwrc
+      - amlogic,s7-pwrc
+      - amlogic,s7d-pwrc
 
   "#power-domain-cells":
     const: 1
diff --git a/include/dt-bindings/power/amlogic,s6-pwrc.h b/include/dt-bindings/power/amlogic,s6-pwrc.h
new file mode 100644
index 000000000000..2c005864ae73
--- /dev/null
+++ b/include/dt-bindings/power/amlogic,s6-pwrc.h
@@ -0,0 +1,29 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (C) 2025 Amlogic, Inc. All rights reserved
+ */
+#ifndef _DT_BINDINGS_AMLOGIC_S6_POWER_H
+#define _DT_BINDINGS_AMLOGIC_S6_POWER_H
+
+#define PWRC_S6_DSPA_ID				0
+#define PWRC_S6_DOS_HEVC_ID			1
+#define PWRC_S6_DOS_VDEC_ID			2
+#define PWRC_S6_VPU_HDMI_ID			3
+#define PWRC_S6_U2DRD_ID			4
+#define PWRC_S6_U3DRD_ID			5
+#define PWRC_S6_SD_EMMC_C_ID			6
+#define PWRC_S6_GE2D_ID				7
+#define PWRC_S6_AMFC_ID				8
+#define PWRC_S6_VC9000E_ID			9
+#define PWRC_S6_DEWARP_ID			10
+#define PWRC_S6_VICP_ID				11
+#define PWRC_S6_SD_EMMC_A_ID			12
+#define PWRC_S6_SD_EMMC_B_ID			13
+#define PWRC_S6_ETH_ID				14
+#define PWRC_S6_PCIE_ID				15
+#define PWRC_S6_NNA_4T_ID			16
+#define PWRC_S6_AUDIO_ID			17
+#define PWRC_S6_AUCPU_ID			18
+#define PWRC_S6_ADAPT_ID			19
+
+#endif
diff --git a/include/dt-bindings/power/amlogic,s7-pwrc.h b/include/dt-bindings/power/amlogic,s7-pwrc.h
new file mode 100644
index 000000000000..3f21d095f784
--- /dev/null
+++ b/include/dt-bindings/power/amlogic,s7-pwrc.h
@@ -0,0 +1,20 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (C) 2025 Amlogic, Inc. All rights reserved
+ */
+#ifndef _DT_BINDINGS_AMLOGIC_S7_POWER_H
+#define _DT_BINDINGS_AMLOGIC_S7_POWER_H
+
+#define PWRC_S7_DOS_HEVC_ID			0
+#define PWRC_S7_DOS_VDEC_ID		        1
+#define PWRC_S7_VPU_HDMI_ID		        2
+#define PWRC_S7_USB_COMB_ID		        3
+#define PWRC_S7_SD_EMMC_C_ID			4
+#define PWRC_S7_GE2D_ID				5
+#define PWRC_S7_SD_EMMC_A_ID			6
+#define PWRC_S7_SD_EMMC_B_ID			7
+#define PWRC_S7_ETH_ID				8
+#define PWRC_S7_AUCPU_ID			9
+#define PWRC_S7_AUDIO_ID			10
+
+#endif
diff --git a/include/dt-bindings/power/amlogic,s7d-pwrc.h b/include/dt-bindings/power/amlogic,s7d-pwrc.h
new file mode 100644
index 000000000000..c6998553670a
--- /dev/null
+++ b/include/dt-bindings/power/amlogic,s7d-pwrc.h
@@ -0,0 +1,27 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (C) 2025 Amlogic, Inc. All rights reserved
+ */
+#ifndef _DT_BINDINGS_AMLOGIC_S7D_POWER_H
+#define _DT_BINDINGS_AMLOGIC_S7D_POWER_H
+
+#define PWRC_S7D_DOS_HCODEC_ID			0
+#define PWRC_S7D_DOS_HEVC_ID			1
+#define PWRC_S7D_DOS_VDEC_ID			2
+#define PWRC_S7D_VPU_HDMI_ID			3
+#define PWRC_S7D_USB_U2DRD_ID			4
+#define PWRC_S7D_USB_U2H_ID			5
+#define PWRC_S7D_SSD_EMMC_C_ID			6
+#define PWRC_S7D_GE2D_ID			7
+#define PWRC_S7D_AMFC_ID			8
+#define PWRC_S7D_EMMC_A_ID			9
+#define PWRC_S7D_EMMC_B_ID			10
+#define PWRC_S7D_ETH_ID				11
+#define PWRC_S7D_AUCPU_ID			12
+#define PWRC_S7D_AUDIO_ID			13
+#define PWRC_S7D_SRAMA_ID			14
+#define PWRC_S7D_DMC0_ID			15
+#define PWRC_S7D_DMC1_ID			16
+#define PWRC_S7D_DDR_ID				17
+
+#endif

-- 
2.37.1

