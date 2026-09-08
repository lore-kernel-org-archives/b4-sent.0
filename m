From: =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>
Date: Tue, 08 Sep 2026 17:57:01 +0200
Subject: [PATCH v3 3/3] arm64: dts: qcom: sm8250: add device tree for the
 Xiaomi Mi Pad 5 Pro 5G
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260908-sm8250-xiaomi-enuma-v3-3-0198c3bf954a@dawidwrobel.com>
References: <20260908-sm8250-xiaomi-enuma-v3-0-0198c3bf954a@dawidwrobel.com>
In-Reply-To: <20260908-sm8250-xiaomi-enuma-v3-0-0198c3bf954a@dawidwrobel.com>
To: Jianhua Lu <lujianhua000@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2890; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=WjYBVrEZzP3ExAdg6WDhwCT+UwHmbXt9I8SNxESJ/BU=;
 b=owGbwMvMwCV2qrTGfeXVd28ZT6slMWQtMAiJPyGz9fSSzfH2R1vMX/KtE9EQK30gVfKTb+2Ok
 uK1sUUsHaUsDGJcDLJiiix6aUF7rIJffn/34nc4zBxWJpAhDFycAjCRvo8M/5Prfb86hXeUfvKI
 T/+ndmv3ZHmFKTumuTzN02Y/fVNaV5qR4fNdycKTqu1OzVXfb5iqla3fZ9NgW7fmzgaNxdND/s5
 ayAEA
X-Developer-Key: i=me@dawidwrobel.com; a=openpgp;
 fpr=B64A778E0E64049A70C831C8B7B81FA12B282A92
X-Endpoint-Received: by B4 Relay for me@dawidwrobel.com/default with auth_id=901
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Mi Pad 5 Pro 5G (enuma, 2021) is the modem-equipped variant of the
Mi Pad 5 Pro. The board is otherwise the elish design, so describe it as
the common device tree plus its own board ID, panel compatible and WiFi
board data variant.

Unlike elish, this model shipped with a single display variant, so there
is one device tree rather than a per-panel pair.

The WiFi node in the common device tree gains a label, so this board can
override its calibration variant.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Dawid Wróbel <me@dawidwrobel.com>
---
 arch/arm64/boot/dts/qcom/Makefile                  |  1 +
 .../boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi  |  2 +-
 arch/arm64/boot/dts/qcom/sm8250-xiaomi-enuma.dts   | 27 ++++++++++++++++++++++
 3 files changed, 29 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index e05414290d8e..529e29ffb25a 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -369,6 +369,7 @@ dtb-$(CONFIG_ARCH_QCOM)	+= sm8250-sony-xperia-edo-pdx203.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm8250-sony-xperia-edo-pdx206.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm8250-xiaomi-elish-boe.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm8250-xiaomi-elish-csot.dtb
+dtb-$(CONFIG_ARCH_QCOM)	+= sm8250-xiaomi-enuma.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm8250-xiaomi-pipa.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm8350-hdk.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= sm8350-microsoft-surface-duo2.dtb
diff --git a/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi
index 19aff83ecf7b..12a2ba48340f 100644
--- a/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi
@@ -817,7 +817,7 @@ &pcie0_phy {
 };
 
 &pcieport0 {
-	wifi@0 {
+	wifi_0: wifi@0 {
 		compatible = "pci17cb,1101";
 		reg = <0x10000 0x0 0x0 0x0 0x0>;
 
diff --git a/arch/arm64/boot/dts/qcom/sm8250-xiaomi-enuma.dts b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-enuma.dts
new file mode 100644
index 000000000000..45bcc0438138
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-enuma.dts
@@ -0,0 +1,27 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Copyright (c) 2025-2026 Dawid Wróbel <me@dawidwrobel.com>
+ */
+
+/dts-v1/;
+
+#include "sm8250-xiaomi-elish-common.dtsi"
+
+/ {
+	model = "Xiaomi Mi Pad 5 Pro 5G";
+	compatible = "xiaomi,enuma", "xiaomi,elish", "qcom,sm8250";
+
+	/* Platform type differs from elish; msm-id is inherited unchanged. */
+	qcom,board-id = <0x2e 0>;
+};
+
+&display_panel {
+	compatible = "xiaomi,enuma-csot-nt36523", "xiaomi,elish-csot-nt36523",
+		     "novatek,nt36523";
+
+	status = "okay";
+};
+
+&wifi_0 {
+	qcom,calibration-variant = "Xiaomi_Pad_5Pro_5G";
+};

-- 
2.55.0

