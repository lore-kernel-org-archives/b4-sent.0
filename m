From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 27 Jun 2024 19:47:51 +0800
Subject: [PATCH 1/3] dt-bindings: power: add Amlogic A5 power domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240627-a5_secpower-v1-1-1f47dde1270c@amlogic.com>
References: <20240627-a5_secpower-v1-0-1f47dde1270c@amlogic.com>
In-Reply-To: <20240627-a5_secpower-v1-0-1f47dde1270c@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Hongyu Chen <hongyu.chen1@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719488872; l=1760;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=Txc3iSqLPbJi5Rszcezcb/g0/wY8paHucg8OqrKhoA4=;
 b=zuduol9Qa4JxnPSke443YVNvHYmL2hfXZ5bF3i+i0yMOzt3NZdwSLoIOjJhdk35/+t7kbV7xr
 uOlQNcygpQUCvxGKP754w1v61IbP0+gK0mzC4SGWbFobhHoVATK5R76
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding document and related header file for
Amlogic A5 secure power domains.

Signed-off-by: Hongyu Chen <hongyu.chen1@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/power/amlogic,meson-sec-pwrc.yaml      |  1 +
 include/dt-bindings/power/amlogic,a5-pwrc.h         | 21 +++++++++++++++++++++
 2 files changed, 22 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
index 59915f9d4860..15d74138baa3 100644
--- a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
+++ b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
@@ -21,6 +21,7 @@ properties:
       - amlogic,meson-a1-pwrc
       - amlogic,meson-s4-pwrc
       - amlogic,a4-pwrc
+      - amlogic,a5-pwrc
       - amlogic,c3-pwrc
       - amlogic,t7-pwrc
 
diff --git a/include/dt-bindings/power/amlogic,a5-pwrc.h b/include/dt-bindings/power/amlogic,a5-pwrc.h
new file mode 100644
index 000000000000..3a6f53eb959f
--- /dev/null
+++ b/include/dt-bindings/power/amlogic,a5-pwrc.h
@@ -0,0 +1,21 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (C) 2024 Amlogic, Inc. All rights reserved
+ */
+
+#ifndef _DT_BINDINGS_AMLOGIC_A5_POWER_H
+#define _DT_BINDINGS_AMLOGIC_A5_POWER_H
+
+#define PWRC_A5_NNA_ID			0
+#define PWRC_A5_AUDIO_ID		1
+#define PWRC_A5_SDIOA_ID		2
+#define PWRC_A5_EMMC_ID			3
+#define PWRC_A5_USB_COMB_ID		4
+#define PWRC_A5_ETH_ID			5
+#define PWRC_A5_RSA_ID			6
+#define PWRC_A5_AUDIO_PDM_ID		7
+#define PWRC_A5_DMC_ID			8
+#define PWRC_A5_SYS_WRAP_ID		9
+#define PWRC_A5_DSPA_ID			10
+
+#endif

-- 
2.37.1

