From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Sat, 28 Nov 2026 00:08:31 +0530
Subject: [PATCH 1/2] dt-bindings: interconnect: qcom: Add Molokai RPMh NoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-molokai-icc-v1-1-a5e1754f086d@yahoo.com>
References: <20261128-molokai-icc-v1-0-a5e1754f086d@yahoo.com>
In-Reply-To: <20261128-molokai-icc-v1-0-a5e1754f086d@yahoo.com>
To: Georgi Djakov <djakov@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Abel Vesa <abel.vesa@oss.qualcomm.com>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795804710; l=6144;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=Xxt8D8wMK92grXZn8O4mppTs+YgJ/y35V+I07aULN64=;
 b=WdbQ75oZj0nU64WpFqTLszvav7+JOUQytzEfViXsY/Gvs3fXrto4Gir1fW5QJ2rVkn5UdedSp
 HjOa2yBRN97AA5/S7gc9lboABxBq2dTHutc3KrDdQIxjgyDBv99XH7S
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the RPMh Network-On-Chip interconnect providers of the Qualcomm
Molokai (SM8845) SoC.

Molokai is close to Kaanapali, but its NoCs differ: the aggregate NoC is
split into aggre1 (0x16e0000) and aggre2 (0x1700000), the MMSS NoC config
and service ports are split into HF and SF halves, and some masters and
slaves are missing. aggre1 needs the UFS and USB3 AXI clocks for QoS
programming, aggre2 the IPA clock.

The header keeps the Kaanapali IDs for every node the two SoCs share and
adds only the new MMSS config nodes, so molokai.dtsi can keep the
interconnect paths it inherits from kaanapali.dtsi.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 .../bindings/interconnect/qcom,molokai-rpmh.yaml   | 144 +++++++++++++++++++++
 .../dt-bindings/interconnect/qcom,molokai-rpmh.h   |  26 ++++
 2 files changed, 170 insertions(+)

diff --git a/Documentation/devicetree/bindings/interconnect/qcom,molokai-rpmh.yaml b/Documentation/devicetree/bindings/interconnect/qcom,molokai-rpmh.yaml
new file mode 100644
index 000000000000..fd94f6dae1a6
--- /dev/null
+++ b/Documentation/devicetree/bindings/interconnect/qcom,molokai-rpmh.yaml
@@ -0,0 +1,144 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/interconnect/qcom,molokai-rpmh.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm RPMh Network-On-Chip Interconnect on Molokai
+
+maintainers:
+  - Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+
+description: |
+  RPMh interconnect providers support system bandwidth requirements through
+  RPMh hardware accelerators known as Bus Clock Manager (BCM). The provider is
+  able to communicate with the BCM through the Resource State Coordinator (RSC)
+  associated with each execution environment. Provider nodes must point to at
+  least one RPMh device child node pertaining to their RSC and each provider
+  can map to multiple RPMh resources.
+
+  See also: include/dt-bindings/interconnect/qcom,molokai-rpmh.h
+
+properties:
+  compatible:
+    enum:
+      - qcom,molokai-aggre1-noc
+      - qcom,molokai-aggre2-noc
+      - qcom,molokai-clk-virt
+      - qcom,molokai-cnoc-cfg
+      - qcom,molokai-cnoc-main
+      - qcom,molokai-gem-noc
+      - qcom,molokai-lpass-ag-noc
+      - qcom,molokai-lpass-lpiaon-noc
+      - qcom,molokai-lpass-lpicx-noc
+      - qcom,molokai-mc-virt
+      - qcom,molokai-mmss-noc
+      - qcom,molokai-nsp-noc
+      - qcom,molokai-pcie-anoc
+      - qcom,molokai-system-noc
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    minItems: 1
+    maxItems: 2
+
+required:
+  - compatible
+
+allOf:
+  - $ref: qcom,rpmh-common.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,molokai-clk-virt
+              - qcom,molokai-mc-virt
+    then:
+      properties:
+        reg: false
+    else:
+      required:
+        - reg
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,molokai-pcie-anoc
+    then:
+      properties:
+        clocks:
+          items:
+            - description: aggre-NOC PCIe AXI clock
+            - description: cfg-NOC PCIe a-NOC AHB clock
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,molokai-aggre1-noc
+    then:
+      properties:
+        clocks:
+          items:
+            - description: aggre UFS PHY AXI clock
+            - description: aggre USB3 PRIM AXI clock
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,molokai-aggre2-noc
+    then:
+      properties:
+        clocks:
+          items:
+            - description: RPMH CC IPA clock
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,molokai-aggre1-noc
+              - qcom,molokai-aggre2-noc
+              - qcom,molokai-pcie-anoc
+    then:
+      required:
+        - clocks
+    else:
+      properties:
+        clocks: false
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    clk_virt: interconnect-0 {
+      compatible = "qcom,molokai-clk-virt";
+      #interconnect-cells = <2>;
+      qcom,bcm-voters = <&apps_bcm_voter>;
+    };
+
+    aggre1_noc: interconnect@16e0000 {
+      compatible = "qcom,molokai-aggre1-noc";
+      reg = <0x016e0000 0x16400>;
+      #interconnect-cells = <2>;
+      clocks = <&gcc_aggre_ufs_phy_axi_clk>,
+               <&gcc_aggre_usb3_prim_axi_clk>;
+      qcom,bcm-voters = <&apps_bcm_voter>;
+    };
+
+    aggre2_noc: interconnect@1700000 {
+      compatible = "qcom,molokai-aggre2-noc";
+      reg = <0x01700000 0x22400>;
+      #interconnect-cells = <2>;
+      clocks = <&rpmhcc_ipa_clk>;
+      qcom,bcm-voters = <&apps_bcm_voter>;
+    };
diff --git a/include/dt-bindings/interconnect/qcom,molokai-rpmh.h b/include/dt-bindings/interconnect/qcom,molokai-rpmh.h
new file mode 100644
index 000000000000..88efa9f1d7a7
--- /dev/null
+++ b/include/dt-bindings/interconnect/qcom,molokai-rpmh.h
@@ -0,0 +1,26 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Molokai interconnect IDs
+ *
+ * Molokai keeps the Kaanapali node IDs for every node the two SoCs share,
+ * so this only adds the nodes Kaanapali does not have. On Molokai the
+ * aggre1-noc and aggre2-noc providers use the Kaanapali aggre-noc IDs,
+ * and cnoc-main also carries SLAVE_PCIE_CFG.
+ */
+
+#ifndef __DT_BINDINGS_INTERCONNECT_QCOM_MOLOKAI_H
+#define __DT_BINDINGS_INTERCONNECT_QCOM_MOLOKAI_H
+
+#include <dt-bindings/interconnect/qcom,kaanapali-rpmh.h>
+
+/* cnoc-cfg */
+#define SLAVE_CNOC_MNOC_HF_CFG			36
+#define SLAVE_CNOC_MNOC_SF_CFG			37
+
+/* mmss-noc */
+#define MASTER_CNOC_MNOC_HF_CFG			15
+#define MASTER_CNOC_MNOC_SF_CFG			16
+#define SLAVE_SERVICE_MNOC_HF			17
+#define SLAVE_SERVICE_MNOC_SF			18
+
+#endif

-- 
2.56.1

