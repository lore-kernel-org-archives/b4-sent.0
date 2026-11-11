From: Andrew Gigena <mail@andrewgigena.dev>
Date: Wed, 11 Nov 2026 17:53:22 +0000
Subject: [PATCH v4 2/3] dt-bindings: ufs: qcom: classify sm8150-ufshc as
 standalone ICE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-sm8150-ice-rfc-v4-2-0311eac35609@andrewgigena.dev>
References: <20261111-sm8150-ice-rfc-v4-0-0311eac35609@andrewgigena.dev>
In-Reply-To: <20261111-sm8150-ice-rfc-v4-0-0311eac35609@andrewgigena.dev>
To: Abel Vesa <abelvesa@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Bart Van Assche <bvanassche@acm.org>, 
 Bean Huo <beanhuo@micron.com>, Stanley Jhu <stanleyjhu@google.com>, 
 Bjorn Andersson <andersson@kernel.org>, Andy Gross <agross@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-scsi@vger.kernel.org, Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794419696; l=3635;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=FS7Osahusmu8N0/dDWHi/whzavzMhLE9W6HGDRPIxVE=;
 b=1RgxFyQEX5ixoaib1a+Rz6YLvEbJgQ7NF+6htF1K53masaniU4KW1VivCpVOlfawJKFoThV/3
 bPIMobs0swfBOL+YZoPVuPlUX9uRar9YvPYddquHeIwM1QCdQs9X7pq
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8150 UFS uses a standalone ICE node, so its compatible belongs to the
standalone-ICE binding rather than the embedded-ICE one.

This tightens the schema for qcom,sm8150-ufshc: the standalone-ICE
binding allows one reg entry and eight clocks, while existing DTs
still use the embedded-ICE layout. This causes a transient,
validation-only dtbs_check warning until those DTs are converted
(sm8150.dtsi follows in the next patch); existing DTBs still boot.

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
 Documentation/devicetree/bindings/ufs/qcom,sc7180-ufshc.yaml |  2 ++
 Documentation/devicetree/bindings/ufs/qcom,ufs.yaml          | 11 ++++-------
 2 files changed, 6 insertions(+), 7 deletions(-)

diff --git a/Documentation/devicetree/bindings/ufs/qcom,sc7180-ufshc.yaml b/Documentation/devicetree/bindings/ufs/qcom,sc7180-ufshc.yaml
index 3c407426d697..572eec814a60 100644
--- a/Documentation/devicetree/bindings/ufs/qcom,sc7180-ufshc.yaml
+++ b/Documentation/devicetree/bindings/ufs/qcom,sc7180-ufshc.yaml
@@ -23,6 +23,7 @@ select:
           - qcom,sc7280-ufshc
           - qcom,sc8180x-ufshc
           - qcom,sc8280xp-ufshc
+          - qcom,sm8150-ufshc
           - qcom,sm8250-ufshc
           - qcom,sm8350-ufshc
           - qcom,sm8450-ufshc
@@ -48,6 +49,7 @@ properties:
               - qcom,sc7280-ufshc
               - qcom,sc8180x-ufshc
               - qcom,sc8280xp-ufshc
+              - qcom,sm8150-ufshc
               - qcom,sm8250-ufshc
               - qcom,sm8350-ufshc
               - qcom,sm8450-ufshc
diff --git a/Documentation/devicetree/bindings/ufs/qcom,ufs.yaml b/Documentation/devicetree/bindings/ufs/qcom,ufs.yaml
index 516bb61a4624..ef4d1d055169 100644
--- a/Documentation/devicetree/bindings/ufs/qcom,ufs.yaml
+++ b/Documentation/devicetree/bindings/ufs/qcom,ufs.yaml
@@ -23,7 +23,6 @@ select:
           - qcom,sm6115-ufshc
           - qcom,sm6125-ufshc
           - qcom,sm6350-ufshc
-          - qcom,sm8150-ufshc
   required:
     - compatible
 
@@ -38,7 +37,6 @@ properties:
           - qcom,sm6115-ufshc
           - qcom,sm6125-ufshc
           - qcom,sm6350-ufshc
-          - qcom,sm8150-ufshc
       - const: qcom,ufshc
       - const: jedec,ufs-2.0
 
@@ -69,7 +67,6 @@ allOf:
             enum:
               - qcom,sdm845-ufshc
               - qcom,sm6350-ufshc
-              - qcom,sm8150-ufshc
     then:
       properties:
         clocks:
@@ -175,10 +172,10 @@ unevaluatedProperties: false
 
 examples:
   - |
-    #include <dt-bindings/clock/qcom,gcc-sm8150.h>
+    #include <dt-bindings/clock/qcom,gcc-sdm845.h>
     #include <dt-bindings/clock/qcom,rpmh.h>
     #include <dt-bindings/gpio/gpio.h>
-    #include <dt-bindings/interconnect/qcom,sm8150.h>
+    #include <dt-bindings/interconnect/qcom,sdm845.h>
     #include <dt-bindings/interrupt-controller/arm-gic.h>
 
     soc {
@@ -186,7 +183,7 @@ examples:
         #size-cells = <2>;
 
         ufs@1d84000 {
-            compatible = "qcom,sm8150-ufshc", "qcom,ufshc",
+            compatible = "qcom,sdm845-ufshc", "qcom,ufshc",
                          "jedec,ufs-2.0";
             reg = <0x0 0x01d84000 0x0 0x2500>,
                   <0x0 0x01d90000 0x0 0x8000>;
@@ -207,7 +204,7 @@ examples:
             vccq-max-microamp = <1200000>;
 
             power-domains = <&gcc UFS_PHY_GDSC>;
-            iommus = <&apps_smmu 0x300 0>;
+            iommus = <&apps_smmu 0x100 0xf>;
 
             clocks = <&gcc GCC_UFS_PHY_AXI_CLK>,
                      <&gcc GCC_AGGRE_UFS_PHY_AXI_CLK>,

-- 
2.56.0

