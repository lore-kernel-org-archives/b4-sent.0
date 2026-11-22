From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:24 +0000
Subject: [PATCH 1/3] dt-bindings: media: qcom,sdm845-camss: Add
 interconnects
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-camss-sdm845-icc-v1-1-0671ef770fd0@enser.io>
References: <20261122-b4-camss-sdm845-icc-v1-0-0671ef770fd0@enser.io>
In-Reply-To: <20261122-b4-camss-sdm845-icc-v1-0-0671ef770fd0@enser.io>
To: Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Robert Foss <rfoss@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324405; l=2153;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=LulMe8vMo++IKeIIAh8v8M3uKtAlXb13KLuNcRYJ0PQ=;
 b=v+A31bhfotuokwdDizd43svOLiboSnHvUQH/g4vvxlCFBFpkOb9zv8/7CTxMWPDod3R9TrjM6
 2oPkMrQelsaC2gnmqx1KhlVsUQPqC7WrmkHTIrYNs/MxWk0/KZtm3lm
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CAMSS on SDM845 reaches DDR through two camnoc HF ports and one SF
port, and its registers through the config NoC. Describe the four
paths, named as in the sm6150 binding, which has the same two HF ports.

They are optional, so existing device trees stay valid. The driver
votes on them where they are present.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Signed-off-by: EMCP333 <emcp@enser.io>
---
 .../devicetree/bindings/media/qcom,sdm845-camss.yaml | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml
index be09cf3a3b..8c87ecd406 100644
--- a/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml
@@ -76,6 +76,16 @@ properties:
       - const: vfe1
       - const: vfe_lite
 
+  interconnects:
+    maxItems: 4
+
+  interconnect-names:
+    items:
+      - const: ahb
+      - const: hf_0
+      - const: hf_1
+      - const: sf_mnoc
+
   iommus:
     maxItems: 4
 
@@ -233,6 +243,7 @@ examples:
     #include <dt-bindings/interrupt-controller/arm-gic.h>
     #include <dt-bindings/clock/qcom,camcc-sdm845.h>
     #include <dt-bindings/clock/qcom,gcc-sdm845.h>
+    #include <dt-bindings/interconnect/qcom,sdm845.h>
 
     soc {
       #address-cells = <2>;
@@ -337,6 +348,15 @@ examples:
           "vfe1",
           "vfe_lite";
 
+        interconnects = <&gladiator_noc MASTER_APPSS_PROC 0 &config_noc SLAVE_CAMERA_CFG 0>,
+          <&mmss_noc MASTER_CAMNOC_HF0 0 &mem_noc SLAVE_EBI1 0>,
+          <&mmss_noc MASTER_CAMNOC_HF1 0 &mem_noc SLAVE_EBI1 0>,
+          <&mmss_noc MASTER_CAMNOC_SF 0 &mem_noc SLAVE_EBI1 0>;
+        interconnect-names = "ahb",
+          "hf_0",
+          "hf_1",
+          "sf_mnoc";
+
         iommus = <&apps_smmu 0x0808 0x0>,
           <&apps_smmu 0x0810 0x8>,
           <&apps_smmu 0x0c08 0x0>,

-- 
2.47.3

