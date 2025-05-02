From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 02 May 2025 14:15:43 +0400
Subject: [PATCH 1/6] dt-bindings: clock: qcom: Add CMN PLL support for
 IPQ5018 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250502-ipq5018-cmn-pll-v1-1-27902c1c4071@outlook.com>
References: <20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com>
In-Reply-To: <20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Luo Jie <quic_luoj@quicinc.com>, 
 Lee Jones <lee@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746180945; l=2537;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=xMsnswH7lfsZOMdAFG5L88fjf8jqYYNAJSbGO9nECgc=;
 b=7+PZxKnRPFSXkwIqCDngsDZjv0Ccl/GljGOBpZt45o/525VNJJBP5j1WbKqTcVlOYbdtF4XIy
 cg4neOqVkaPABNsGuww3237zj0QlAtE2I7kTYca9XgcEr+QBd+kYvlK
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CMN PLL block in the IPQ5018 SoC takes 96 MHZ as the reference
input clock. Its output clocks are the XO (24Mhz), sleep (32Khz), and
ethernet (50Mhz) clocks.

Unlike IPQ9574, the CMN PLL to the ethernet block needs to be enabled
first in IPQ5018. Hence, add optional phandle to TCSR register space
and offset to do so.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml  | 11 ++++++++---
 include/dt-bindings/clock/qcom,ipq5018-cmn-pll.h         | 16 ++++++++++++++++
 2 files changed, 24 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml b/Documentation/devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml
index cb6e09f4247f4b25105b25f4ae746c0b3ef47616..25006d65d30e20ef8e1f43537bcf3dca65bae73d 100644
--- a/Documentation/devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml
+++ b/Documentation/devicetree/bindings/clock/qcom,ipq9574-cmn-pll.yaml
@@ -24,12 +24,10 @@ description:
 properties:
   compatible:
     enum:
+      - qcom,ipq5018-cmn-pll
       - qcom,ipq5424-cmn-pll
       - qcom,ipq9574-cmn-pll
 
-  reg:
-    maxItems: 1
-
   clocks:
     items:
       - description: The reference clock. The supported clock rates include
@@ -50,6 +48,13 @@ properties:
   "#clock-cells":
     const: 1
 
+  qcom,cmn-pll-eth-enable:
+    description: Register in TCSR to enable CMN PLL to ethernet
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+    items:
+        - description: phandle of TCSR syscon
+        - description: offset of TCSR register to enable CMN PLL to ethernet
+
 required:
   - compatible
   - reg
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

