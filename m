From: Ishu Brar <patches@brar.si>
Date: Fri, 23 Oct 2026 15:40:08 +0530
Subject: [PATCH 1/2] dt-bindings: clock: qcom: Add SM7250 graphics clock
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-gpucc-sm7250-v1-1-d9149cece8be@brar.si>
References: <20261023-gpucc-sm7250-v1-0-d9149cece8be@brar.si>
In-Reply-To: <20261023-gpucc-sm7250-v1-0-d9149cece8be@brar.si>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Taniya Das <taniya.das@oss.qualcomm.com>, 
 Imran Shaik <quic_imrashai@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792750212; l=2751;
 i=patches@brar.si; h=from:subject:message-id;
 bh=zNYJpd8CGDe4+jLuKQsFoERznSdYKLOwrl2HcMSC/Jw=;
 b=IWiL+WuU0aMzyFIDvNG6CyKEglNpi6iwZrVN+QBjuih/cd0siKsRB0IauF0wv2nTvBZ4f9iN9
 FUvwMdYxp40D8C9cnVj9LxlOpNMB4mDU3rltRFDrZZd617bQKUXMtjb
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatible for the graphics clock controller (GPU_CC) of the
Qualcomm SM7250 SoC (Snapdragon 765/765G/768G), and the header with its
clock, reset and GDSC indices. The clock inputs are the same as on
SM8250, so the existing clock and clock-names constraints apply unchanged.

Assisted-by: Claude
Signed-off-by: Ishu Brar <patches@brar.si>
---
 .../devicetree/bindings/clock/qcom,gpucc.yaml      |  2 ++
 include/dt-bindings/clock/qcom,gpucc-sm7250.h      | 36 ++++++++++++++++++++++
 2 files changed, 38 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/qcom,gpucc.yaml b/Documentation/devicetree/bindings/clock/qcom,gpucc.yaml
index 3ac441900..d262455f3 100644
--- a/Documentation/devicetree/bindings/clock/qcom,gpucc.yaml
+++ b/Documentation/devicetree/bindings/clock/qcom,gpucc.yaml
@@ -21,6 +21,7 @@ description: |
     include/dt-bindings/clock/qcom,gpucc-sc7280.h
     include/dt-bindings/clock/qcom,gpucc-sc8280xp.h
     include/dt-bindings/clock/qcom,gpucc-sm6350.h
+    include/dt-bindings/clock/qcom,gpucc-sm7250.h
     include/dt-bindings/clock/qcom,gpucc-sm8150.h
     include/dt-bindings/clock/qcom,gpucc-sm8250.h
     include/dt-bindings/clock/qcom,gpucc-sm8350.h
@@ -37,6 +38,7 @@ properties:
       - qcom,sc8180x-gpucc
       - qcom,sc8280xp-gpucc
       - qcom,sm6350-gpucc
+      - qcom,sm7250-gpucc
       - qcom,sm8150-gpucc
       - qcom,sm8250-gpucc
       - qcom,sm8350-gpucc
diff --git a/include/dt-bindings/clock/qcom,gpucc-sm7250.h b/include/dt-bindings/clock/qcom,gpucc-sm7250.h
new file mode 100644
index 000000000..f4536808d
--- /dev/null
+++ b/include/dt-bindings/clock/qcom,gpucc-sm7250.h
@@ -0,0 +1,36 @@
+/* SPDX-License-Identifier: GPL-2.0-only OR BSD-3-Clause */
+/*
+ * Copyright (c) 2019, The Linux Foundation. All rights reserved.
+ */
+
+#ifndef _DT_BINDINGS_CLK_QCOM_GPU_CC_SM7250_H
+#define _DT_BINDINGS_CLK_QCOM_GPU_CC_SM7250_H
+
+/* GPU_CC clock registers */
+#define GPU_CC_AHB_CLK				0
+#define GPU_CC_CRC_AHB_CLK			1
+#define GPU_CC_CX_APB_CLK			2
+#define GPU_CC_CX_GMU_CLK			3
+#define GPU_CC_CX_SNOC_DVM_CLK			4
+#define GPU_CC_CXO_AON_CLK			5
+#define GPU_CC_CXO_CLK				6
+#define GPU_CC_GMU_CLK_SRC			7
+#define GPU_CC_GX_GMU_CLK			8
+#define GPU_CC_GX_VSENSE_CLK			9
+#define GPU_CC_PLL1				10
+#define GPU_CC_SLEEP_CLK			11
+#define GPU_CC_HLOS1_VOTE_GPU_SMMU_CLK		12
+
+/* GPU_CC Resets */
+#define GPUCC_GPU_CC_ACD_BCR			0
+#define GPUCC_GPU_CC_CX_BCR			1
+#define GPUCC_GPU_CC_GFX3D_AON_BCR		2
+#define GPUCC_GPU_CC_GMU_BCR			3
+#define GPUCC_GPU_CC_GX_BCR			4
+#define GPUCC_GPU_CC_XO_BCR			5
+
+/* GPU_CC GDSCRs */
+#define GPU_CX_GDSC				0
+#define GPU_GX_GDSC				1
+
+#endif

-- 
2.56.0

