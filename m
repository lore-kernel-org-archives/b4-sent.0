From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Wed, 11 Feb 2026 21:37:53 +0100
Subject: [PATCH v2 4/4] arm64: dts: qcom: x1-vivobook-s15: add
 Purwa-compatible device tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260211-b4-vivobook-v2-4-9f500415d2ed@oldschoolsolutions.biz>
References: <20260211-b4-vivobook-v2-0-9f500415d2ed@oldschoolsolutions.biz>
In-Reply-To: <20260211-b4-vivobook-v2-0-9f500415d2ed@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>, 
 "Colin K. Williams" <colin@li-nk.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770842282; l=2944;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=ptuXwHkFSH4UzSXx9epEse1Eq5mBz3kvAbkz5o95kh0=;
 b=FS1OfcFva6XjIKmivXvjBM6I5wCVLVP06OWUPzGxnFSaFAh62CfcJDmj+VsnrlKp+nF4/qBm0
 T2b0EGD5jAhDGM4yDRzMLVyUdzPIx/r3eGiF44OYFkLzpLJl+/y4993
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASUS Vivobook S15 (S5507) [1] is available with Hamoa and Purwa SoC.

Add the Purwa-based device tree.

[1]: https://www.asus.com/de/laptops/for-home/vivobook/asus-vivobook-s-15-s5507/techspec/

Tested-by: Colin K. Williams <colin@li-nk.org>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/Makefile                  |  2 +
 .../boot/dts/qcom/x1p42100-asus-vivobook-s15.dts   | 43 ++++++++++++++++++++++
 2 files changed, 45 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index f80b5d9cf1e80e4efcd70f14cef4e7d4a1ec48eb..baa7ec904b4878a41e6fd9c678025f28cb484cf3 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -380,6 +380,8 @@ x1e80100-microsoft-romulus15-el2-dtbs	:= x1e80100-microsoft-romulus15.dtb x1-el2
 dtb-$(CONFIG_ARCH_QCOM)	+= x1e80100-microsoft-romulus15.dtb x1e80100-microsoft-romulus15-el2.dtb
 x1e80100-qcp-el2-dtbs	:= x1e80100-qcp.dtb x1-el2.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= x1e80100-qcp.dtb x1e80100-qcp-el2.dtb
+x1p42100-asus-vivobook-s15-el2-dtbs	:= x1p42100-asus-vivobook-s15.dtb x1-el2.dtbo
+dtb-$(CONFIG_ARCH_QCOM)	+= x1p42100-asus-vivobook-s15.dtb x1p42100-asus-vivobook-s15-el2.dtb
 x1p42100-asus-zenbook-a14-el2-dtbs	:= x1p42100-asus-zenbook-a14.dtb x1-el2.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= x1p42100-asus-zenbook-a14.dtb x1p42100-asus-zenbook-a14-el2.dtb
 x1p42100-asus-zenbook-a14-lcd-el2-dtbs	:= x1p42100-asus-zenbook-a14-lcd.dtb x1-el2.dtbo
diff --git a/arch/arm64/boot/dts/qcom/x1p42100-asus-vivobook-s15.dts b/arch/arm64/boot/dts/qcom/x1p42100-asus-vivobook-s15.dts
new file mode 100644
index 0000000000000000000000000000000000000000..a68c295200d1a2481481f9740c1c2db9e4a7afed
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/x1p42100-asus-vivobook-s15.dts
@@ -0,0 +1,43 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
+ * Copyright (c) 2024, Xilin Wu <wuxilin123@gmail.com>
+ */
+
+/dts-v1/;
+
+#include "purwa.dtsi"
+#include "x1-asus-vivobook-s15.dtsi"
+
+/delete-node/ &pmc8380_6;
+/delete-node/ &pmc8380_6_thermal;
+
+/ {
+	model = "ASUS Vivobook S 15 X1P-42-100";
+	compatible = "asus,vivobook-s15-x1p4", "qcom,x1p42100";
+	chassis-type = "laptop";
+};
+
+&gpu_zap_shader {
+	firmware-name = "qcom/x1p42100/ASUSTeK/vivobook-s15/qcdxkmsucpurwa.mbn";
+};
+
+&iris {
+	firmware-name = "qcom/x1p42100/ASUSTeK/vivobook-s15/qcvss8380.mbn";
+	status = "okay";
+};
+
+&remoteproc_adsp {
+	firmware-name = "qcom/x1p42100/ASUSTeK/vivobook-s15/qcadsp8380.mbn",
+			"qcom/x1p42100/ASUSTeK/vivobook-s15/adsp_dtbs.elf";
+
+	status = "okay";
+};
+
+&remoteproc_cdsp {
+	firmware-name = "qcom/x1p42100/ASUSTeK/vivobook-s15/qccdsp8380.mbn",
+			"qcom/x1p42100/ASUSTeK/vivobook-s15/cdsp_dtbs.elf";
+
+	status = "okay";
+};
+

-- 
2.51.0

