From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Wed, 02 Jul 2025 23:22:35 +0200
Subject: [PATCH v2 3/3] arm64: dts: qcom: x1-hp-x14: Add support for
 X1P42100 HP Omnibook X14
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250702-hp-x14-x1p-v2-3-af5b588d1979@oldschoolsolutions.biz>
References: <20250702-hp-x14-x1p-v2-0-af5b588d1979@oldschoolsolutions.biz>
In-Reply-To: <20250702-hp-x14-x1p-v2-0-af5b588d1979@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751491354; l=2967;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=9ZthgVGhEJbafJD5mTNmfnnlMO4dAvYooqbC1ezI11A=;
 b=CeYuUilPkNqmgxYya6tF9ldqs+48bVbcSZpnrZg77miDRsTk7zdDvW7u2dCYnzq+/ZgouDskG
 rg1BDdkq2PqCRD1sB7iwYdfpQzFWth3g/sxrA2fTHGY2YGf1z+iHBmZ
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These laptops are the same as the already known 14-fe0xxx models, but
with a Purwa SoC, SKU number 14-fe1xxx. [1]

The supported features are the same as for the original Omnibook X14:

- Keyboard (no function keys though)
- Display
- PWM brightness control
- Touchpad
- Touchscreen
- PCIe ports (pcie4, pcie6a)
- USB type-c, type-a
- WCN6855 Wifi-6E
- WCN6855 Bluetooth
- ADSP and CDSP
- X1 GPU
- GPIO Keys (Lid switch)
- Audio definition (works via USB and with internal speakers)

https://www.hp.com/us-en/shop/pdp/hp-omnibook-x-laptop-next-gen-ai-pc-14-fe100-14-a4nd1av-1#techSpecs

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 arch/arm64/boot/dts/qcom/Makefile                  |  2 ++
 .../boot/dts/qcom/x1p42100-hp-omnibook-x14.dts     | 42 ++++++++++++++++++++++
 2 files changed, 44 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index 4bfa926b6a0850c3c459bcba28129c559d50a7cf..63bf3ccc11124a70efb09782b57970b274d80d49 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -333,3 +333,5 @@ x1p42100-asus-zenbook-a14-el2-dtbs	:= x1p42100-asus-zenbook-a14.dtb x1-el2.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= x1p42100-asus-zenbook-a14.dtb x1p42100-asus-zenbook-a14-el2.dtb
 x1p42100-crd-el2-dtbs	:= x1p42100-crd.dtb x1-el2.dtbo
 dtb-$(CONFIG_ARCH_QCOM)	+= x1p42100-crd.dtb x1p42100-crd-el2.dtb
+x1p42100-hp-omnibook-x14-el2-dtbs := x1p42100-hp-omnibook-x14.dtb x1-el2.dtbo
+dtb-$(CONFIG_ARCH_QCOM)	+= x1p42100-hp-omnibook-x14.dtb x1p42100-hp-omnibook-x14-el2.dtb
diff --git a/arch/arm64/boot/dts/qcom/x1p42100-hp-omnibook-x14.dts b/arch/arm64/boot/dts/qcom/x1p42100-hp-omnibook-x14.dts
new file mode 100644
index 0000000000000000000000000000000000000000..0eeb360489e2a916e1aa24df677700f539786841
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/x1p42100-hp-omnibook-x14.dts
@@ -0,0 +1,42 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
+ * Copyright (c) 2024, Xilin Wu <wuxilin123@gmail.com>
+ * Copyright (c) 2025 Jens Glathe
+ */
+
+/dts-v1/;
+
+#include "x1p42100.dtsi"
+#include "x1e80100-pmics.dtsi"
+#include "x1-hp-omnibook-x14.dtsi"
+/delete-node/ &pmc8380_6;
+/delete-node/ &pmc8380_6_thermal;
+
+/ {
+	model = "HP Omnibook X 14-fe1";
+	compatible = "hp,omnibook-x14-fe1", "qcom,x1p42100";
+	chassis-type = "laptop";
+};
+
+&gpu {
+	status = "okay";
+
+	zap-shader {
+		firmware-name = "qcom/x1p42100/hp/omnibook-x14/qcdxkmsucpurwa.mbn";
+	};
+};
+
+&remoteproc_adsp {
+	firmware-name = "qcom/x1p42100/hp/omnibook-x14/qcadsp8380.mbn",
+			"qcom/x1p42100/hp/omnibook-x14/adsp_dtbs.elf";
+
+	status = "okay";
+};
+
+&remoteproc_cdsp {
+	firmware-name = "qcom/x1p42100/hp/omnibook-x14/qccdsp8380.mbn",
+			"qcom/x1p42100/hp/omnibook-x14/cdsp_dtbs.elf";
+
+	status = "okay";
+};

-- 
2.48.1

