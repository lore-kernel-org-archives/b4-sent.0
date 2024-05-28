From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 28 May 2024 16:39:28 +0800
Subject: [PATCH 1/3] dt-bindings: power: add Amlogic A4 power domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240528-a4_secpowerdomain-v1-1-2a9d7df9b128@amlogic.com>
References: <20240528-a4_secpowerdomain-v1-0-2a9d7df9b128@amlogic.com>
In-Reply-To: <20240528-a4_secpowerdomain-v1-0-2a9d7df9b128@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716885570; l=1750;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=RgSjH36Qe2U+EgCLbgQ34YnSw/n5HAn5hYl8u+yR7yg=;
 b=0fO2oQhlkgQwkWydhbu+RcPN78HB4L/zQ19HTV6D8l8yETaxV2MPvQUb4RleDjl3sHKwKXzqX
 1WjcP+vIKYRAeHouzTEy4/UeFCiddZ5A1ZlqqpHBnr731DojYlwNg2W
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding document and related header file for
Amlogic A4 secure power domains.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/power/amlogic,meson-sec-pwrc.yaml      |  1 +
 include/dt-bindings/power/amlogic,a4-pwrc.h         | 21 +++++++++++++++++++++
 2 files changed, 22 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
index dab3d92bc273..59915f9d4860 100644
--- a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
+++ b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
@@ -20,6 +20,7 @@ properties:
     enum:
       - amlogic,meson-a1-pwrc
       - amlogic,meson-s4-pwrc
+      - amlogic,a4-pwrc
       - amlogic,c3-pwrc
       - amlogic,t7-pwrc
 
diff --git a/include/dt-bindings/power/amlogic,a4-pwrc.h b/include/dt-bindings/power/amlogic,a4-pwrc.h
new file mode 100644
index 000000000000..bd2f9c558d22
--- /dev/null
+++ b/include/dt-bindings/power/amlogic,a4-pwrc.h
@@ -0,0 +1,21 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (C) 2024 Amlogic, Inc. All rights reserved
+ */
+#ifndef _DT_BINDINGS_AMLOGIC_A4_POWER_H
+#define _DT_BINDINGS_AMLOGIC_A4_POWER_H
+
+#define PWRC_A4_AUDIO_ID				0
+#define PWRC_A4_SDIOA_ID				1
+#define PWRC_A4_EMMC_ID					2
+#define PWRC_A4_USB_COMB_ID				3
+#define PWRC_A4_ETH_ID					4
+#define PWRC_A4_VOUT_ID					5
+#define PWRC_A4_AUDIO_PDM_ID				6
+#define PWRC_A4_DMC_ID					7
+#define PWRC_A4_SYS_WRAP_ID				8
+#define PWRC_A4_AO_I2C_S_ID				9
+#define PWRC_A4_AO_UART_ID				10
+#define PWRC_A4_AO_IR_ID				11
+
+#endif

-- 
2.37.1

