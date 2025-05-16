From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 16 May 2025 15:43:05 +0400
Subject: [PATCH v3 2/5] dt-bindings: clock: qcom: Add CMN PLL support for
 IPQ5018 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250516-ipq5018-cmn-pll-v3-2-f3867c5a2076@outlook.com>
References: <20250516-ipq5018-cmn-pll-v3-0-f3867c5a2076@outlook.com>
In-Reply-To: <20250516-ipq5018-cmn-pll-v3-0-f3867c5a2076@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Luo Jie <quic_luoj@quicinc.com>, 
 Lee Jones <lee@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747395784; l=1855;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=aD8B+18ScDcHtu0wgN3a3xFwWsO42AOs4yTmUEt8w/0=;
 b=ggusxMAiNh1P6l+yIUj0dmH5Os8r/sWqU5XPHACRD/cF4pzbLw0cctLk1clr6ipW8ItEiHCYe
 yuzi8BSLpy/AEpj2ZYmbxYA5lH4GzXcGAHJ7DDNg8S8FuPOJlCnFKht
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CMN PLL block in the IPQ5018 SoC takes 96 MHZ as the reference
input clock. Its output clocks are the XO (24Mhz), sleep (32Khz), and
ethernet (50Mhz) clocks.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml  |  1 +
 include/dt-bindings/clock/qcom,ipq5018-cmn-pll.h         | 16 ++++++++++++++++
 2 files changed, 17 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml b/Documentation/devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml
index cb6e09f4247f4b25105b25f4ae746c0b3ef47616..817d51135fbfdf0f518af1007ec7d6b120a91818 100644
--- a/Documentation/devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml
+++ b/Documentation/devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml
@@ -24,6 +24,7 @@ description:
 properties:
   compatible:
     enum:
+      - qcom,ipq5018-cmn-pll
       - qcom,ipq5424-cmn-pll
       - qcom,ipq9574-cmn-pll
 
diff --git a/include/dt-bindings/clock/qcom,ipq5018-cmn-pll.h b/include/dt-bindings/clock/qcom,ipq5018-cmn-pll.h
new file mode 100644
index 0000000000000000000000000000000000000000..586d1c9b33b374331bef413f543c526212c18494
--- /dev/null
+++ b/include/dt-bindings/clock/qcom,ipq5018-cmn-pll.h
@@ -0,0 +1,16 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (c) 2024 Qualcomm Innovation Center, Inc. All rights reserved.
+ */
+
+#ifndef _DT_BINDINGS_CLK_QCOM_IPQ5018_CMN_PLL_H
+#define _DT_BINDINGS_CLK_QCOM_IPQ5018_CMN_PLL_H
+
+/* CMN PLL core clock. */
+#define IPQ5018_CMN_PLL_CLK			0
+
+/* The output clocks from CMN PLL of IPQ5018. */
+#define IPQ5018_XO_24MHZ_CLK			1
+#define IPQ5018_SLEEP_32KHZ_CLK			2
+#define IPQ5018_ETH_50MHZ_CLK			3
+#endif

-- 
2.49.0

