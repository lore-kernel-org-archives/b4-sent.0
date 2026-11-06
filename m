From: Andrew Gigena <mail@andrewgigena.dev>
Date: Fri, 06 Nov 2026 18:35:34 +0000
Subject: [PATCH v3 2/7] dt-bindings: media: qcom,sm8150-camss: Add SM8150
 CAMSS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-sm8150-v7.4-rc1-camss-v3-2-0103e8a0bbcd@andrewgigena.dev>
References: <20261106-sm8150-v7.4-rc1-camss-v3-0-0103e8a0bbcd@andrewgigena.dev>
In-Reply-To: <20261106-sm8150-v7.4-rc1-camss-v3-0-0103e8a0bbcd@andrewgigena.dev>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Robert Foss <rfoss@kernel.org>, Andi Shyti <andi.shyti@linaro.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-phy@lists.infradead.org, 
 Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793990195; l=10174;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=lAPvSNOJB8lII0U+qtMrDtqFoZDfOKFHLlca6xqLLMk=;
 b=/d7qwhpKPMkhy+no9/2Frp28Q1YCfQVwySWuEdWXI9MgZjtznUPSIpjVs32Xw+l07UyvKoKmB
 LzY9dsiKJoPDoDZ0o1O/fLEnylGIreBtRYlb43V3PDED8LWOM6LGqwL
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Qualcomm SM8150 Camera Subsystem. The IP integrates four
CSIPHY, four CSID (two full and two lite), two VFE and two VFE-Lite
instances, with 19 clocks, 8 interrupts, eight IOMMU streams, four
interconnect paths and three power domains.

The CSIPHY I/O spaces are not part of the CAMSS container device: each
CSIPHY is driven by the dedicated qcom,sm8150-csi2-phy driver, so this
binding only describes the VFE and CSID resources. Each CSI input port
is described with data lanes starting at 1, as required by the CAMSS
PHY mode.

Describe SM8150 in a dedicated schema instead of reusing another SoC's
schema.

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
 .../bindings/media/qcom,sm8150-camss.yaml          | 285 +++++++++++++++++++++
 1 file changed, 285 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/qcom,sm8150-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sm8150-camss.yaml
new file mode 100644
index 000000000000..371ff1ce0bd2
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/qcom,sm8150-camss.yaml
@@ -0,0 +1,285 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/qcom,sm8150-camss.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm SM8150 Camera Subsystem (CAMSS)
+
+maintainers:
+  - Andrew Gigena <mail@andrewgigena.dev>
+
+description:
+  The CAMSS IP is a CSI decoder and ISP present on Qualcomm platforms.
+
+properties:
+  compatible:
+    const: qcom,sm8150-camss
+
+  reg:
+    maxItems: 8
+
+  reg-names:
+    items:
+      - const: vfe0
+      - const: csid0
+      - const: vfe1
+      - const: csid1
+      - const: vfe_lite0
+      - const: csid_lite0
+      - const: vfe_lite1
+      - const: csid_lite1
+
+  clocks:
+    maxItems: 19
+
+  clock-names:
+    items:
+      - const: camnoc_axi
+      - const: cpas_ahb
+      - const: vfe0_axi
+      - const: vfe0
+      - const: vfe0_cphy_rx
+      - const: vfe0_csid
+      - const: vfe1_axi
+      - const: vfe1
+      - const: vfe1_cphy_rx
+      - const: vfe1_csid
+      - const: vfe_lite0
+      - const: vfe_lite0_cphy_rx
+      - const: vfe_lite0_csid
+      - const: vfe_lite1
+      - const: vfe_lite1_cphy_rx
+      - const: vfe_lite1_csid
+      - const: gcc_ahb
+      - const: gcc_axi_hf
+      - const: gcc_axi_sf
+
+  interrupts:
+    maxItems: 8
+
+  interrupt-names:
+    items:
+      - const: vfe0
+      - const: csid0
+      - const: vfe1
+      - const: csid1
+      - const: vfe_lite0
+      - const: csid_lite0
+      - const: vfe_lite1
+      - const: csid_lite1
+
+  interconnects:
+    maxItems: 4
+
+  interconnect-names:
+    items:
+      - const: cam_ahb
+      - const: cam_hf_0_mnoc
+      - const: cam_sf_0_mnoc
+      - const: cam_hf_1_mnoc
+
+  iommus:
+    maxItems: 8
+
+  power-domains:
+    items:
+      - description: IFE0 GDSC - Image Front End, Global Distributed Switch Controller.
+      - description: IFE1 GDSC - Image Front End, Global Distributed Switch Controller.
+      - description: Titan Top GDSC - Titan ISP Block, Global Distributed Switch Controller.
+
+  power-domain-names:
+    items:
+      - const: ife0
+      - const: ife1
+      - const: top
+
+  ports:
+    $ref: /schemas/graph.yaml#/properties/ports
+
+    description:
+      CSI input ports, one per CSI2 PHY instance.
+
+    patternProperties:
+      "^port@[0-3]$":
+        $ref: /schemas/graph.yaml#/$defs/port-base
+        unevaluatedProperties: false
+
+        description:
+          Input port for receiving CSI data from a CSIPHY.
+
+        properties:
+          endpoint:
+            $ref: video-interfaces.yaml#
+            unevaluatedProperties: false
+
+            properties:
+              data-lanes:
+                minItems: 1
+                maxItems: 4
+                items:
+                  minimum: 1
+                  maximum: 4
+
+              bus-type:
+                enum:
+                  - 4 # MEDIA_BUS_TYPE_CSI2_DPHY
+
+            required:
+              - data-lanes
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - clocks
+  - clock-names
+  - interconnects
+  - interconnect-names
+  - interrupts
+  - interrupt-names
+  - iommus
+  - power-domains
+  - power-domain-names
+  - ports
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/clock/qcom,gcc-sm8150.h>
+    #include <dt-bindings/clock/qcom,sm8150-camcc.h>
+    #include <dt-bindings/interconnect/qcom,sm8150.h>
+    #include <dt-bindings/media/video-interfaces.h>
+
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        isp@acaf000 {
+            compatible = "qcom,sm8150-camss";
+
+            reg = <0 0xacaf000 0 0x4000>,
+                  <0 0xacb3000 0 0x1000>,
+                  <0 0xacb6000 0 0x4000>,
+                  <0 0xacba000 0 0x1000>,
+                  <0 0xacc4000 0 0x4000>,
+                  <0 0xacc8000 0 0x1000>,
+                  <0 0xaccb000 0 0x4000>,
+                  <0 0xaccf000 0 0x1000>;
+
+            reg-names = "vfe0",
+                        "csid0",
+                        "vfe1",
+                        "csid1",
+                        "vfe_lite0",
+                        "csid_lite0",
+                        "vfe_lite1",
+                        "csid_lite1";
+
+            clocks = <&camcc CAM_CC_CAMNOC_AXI_CLK>,
+                     <&camcc CAM_CC_CPAS_AHB_CLK>,
+                     <&camcc CAM_CC_IFE_0_AXI_CLK>,
+                     <&camcc CAM_CC_IFE_0_CLK>,
+                     <&camcc CAM_CC_IFE_0_CPHY_RX_CLK>,
+                     <&camcc CAM_CC_IFE_0_CSID_CLK>,
+                     <&camcc CAM_CC_IFE_1_AXI_CLK>,
+                     <&camcc CAM_CC_IFE_1_CLK>,
+                     <&camcc CAM_CC_IFE_1_CPHY_RX_CLK>,
+                     <&camcc CAM_CC_IFE_1_CSID_CLK>,
+                     <&camcc CAM_CC_IFE_LITE_0_CLK>,
+                     <&camcc CAM_CC_IFE_LITE_0_CPHY_RX_CLK>,
+                     <&camcc CAM_CC_IFE_LITE_0_CSID_CLK>,
+                     <&camcc CAM_CC_IFE_LITE_1_CLK>,
+                     <&camcc CAM_CC_IFE_LITE_1_CPHY_RX_CLK>,
+                     <&camcc CAM_CC_IFE_LITE_1_CSID_CLK>,
+                     <&gcc GCC_CAMERA_AHB_CLK>,
+                     <&gcc GCC_CAMERA_HF_AXI_CLK>,
+                     <&gcc GCC_CAMERA_SF_AXI_CLK>;
+
+            clock-names = "camnoc_axi",
+                          "cpas_ahb",
+                          "vfe0_axi",
+                          "vfe0",
+                          "vfe0_cphy_rx",
+                          "vfe0_csid",
+                          "vfe1_axi",
+                          "vfe1",
+                          "vfe1_cphy_rx",
+                          "vfe1_csid",
+                          "vfe_lite0",
+                          "vfe_lite0_cphy_rx",
+                          "vfe_lite0_csid",
+                          "vfe_lite1",
+                          "vfe_lite1_cphy_rx",
+                          "vfe_lite1_csid",
+                          "gcc_ahb",
+                          "gcc_axi_hf",
+                          "gcc_axi_sf";
+
+            interrupts = <GIC_SPI 465 IRQ_TYPE_EDGE_RISING>,
+                         <GIC_SPI 464 IRQ_TYPE_EDGE_RISING>,
+                         <GIC_SPI 467 IRQ_TYPE_EDGE_RISING>,
+                         <GIC_SPI 466 IRQ_TYPE_EDGE_RISING>,
+                         <GIC_SPI 469 IRQ_TYPE_EDGE_RISING>,
+                         <GIC_SPI 468 IRQ_TYPE_EDGE_RISING>,
+                         <GIC_SPI 360 IRQ_TYPE_EDGE_RISING>,
+                         <GIC_SPI 359 IRQ_TYPE_EDGE_RISING>;
+
+            interrupt-names = "vfe0",
+                              "csid0",
+                              "vfe1",
+                              "csid1",
+                              "vfe_lite0",
+                              "csid_lite0",
+                              "vfe_lite1",
+                              "csid_lite1";
+
+            power-domains = <&camcc IFE_0_GDSC>,
+                            <&camcc IFE_1_GDSC>,
+                            <&camcc TITAN_TOP_GDSC>;
+
+            power-domain-names = "ife0",
+                                 "ife1",
+                                 "top";
+
+            interconnects = <&gem_noc MASTER_AMPSS_M0 0
+                             &config_noc SLAVE_CAMERA_CFG 0>,
+                            <&mmss_noc MASTER_CAMNOC_HF0 0
+                             &mc_virt SLAVE_EBI_CH0 0>,
+                            <&mmss_noc MASTER_CAMNOC_SF 0
+                             &mc_virt SLAVE_EBI_CH0 0>,
+                            <&mmss_noc MASTER_CAMNOC_HF1 0
+                             &mc_virt SLAVE_EBI_CH0 0>;
+
+            interconnect-names = "cam_ahb",
+                                 "cam_hf_0_mnoc",
+                                 "cam_sf_0_mnoc",
+                                 "cam_hf_1_mnoc";
+
+            iommus = <&apps_smmu 0x840 0x620>,
+                     <&apps_smmu 0x860 0x620>,
+                     <&apps_smmu 0xa40 0x620>,
+                     <&apps_smmu 0xa60 0x620>,
+                     <&apps_smmu 0xc40 0x620>,
+                     <&apps_smmu 0xc60 0x620>,
+                     <&apps_smmu 0xe40 0x620>,
+                     <&apps_smmu 0xe60 0x620>;
+
+            ports {
+                #address-cells = <1>;
+                #size-cells = <0>;
+
+                port@0 {
+                    reg = <0>;
+
+                    endpoint {
+                        bus-type = <MEDIA_BUS_TYPE_CSI2_DPHY>;
+                        data-lanes = <1 2 3 4>;
+                        remote-endpoint = <&csiphy0_out>;
+                    };
+                };
+            };
+        };
+    };

-- 
2.56.0

