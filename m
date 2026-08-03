From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:33:59 +0200
Subject: [PATCH 01/28] dt-bindings: phy: qcom: Describe QMP USB and UFS PHY
 vdda-phy/vdda-pll voltages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-1-5880630cde3e@oss.qualcomm.com>
References: <20260803-phy-supply-fix-v1-0-5880630cde3e@oss.qualcomm.com>
In-Reply-To: <20260803-phy-supply-fix-v1-0-5880630cde3e@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5004;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=V97d3d49T3Ee08UA2ANGKnoJaHfjqiGr+dmZjl7gLmg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZhEYjetD5xsCIhq6BRmQLvzv4sSqmowK7vh
 L1GGmGwBhCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2YQAKCRBVnxHm/pHO
 9QiECACV+yoFC7pE5pmYnGXoGG7FFf9w4afdXw7XUlEjXsJlvsfkwHzdyyrMytZj7U2cCWhqTJI
 gPYq9t+EN48ves/mp58BYPfis9YV9ewCvicSAYkgGASORq1C63QyBjql+4bH9bB9oiydkNsVBty
 w0v2oSwEGSwUIgg80+0cvFV4F+trc9Z9CetFrLOI0Z52/uZ9hR80JlMotmfG2YAGKuxk3pIGZt8
 3ZSikojHUuZNiwMP64HPlgUrpFew4nK6plmV6oOGVyotb1orDafCrpnRZn5PUtkYMPAYDbbk3iX
 JzLKfmKX1GbGAZJjgAgO0mWFGV9fN1CbZsSLqUq78qr1Xvob
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vdda-phy and vdda-pll supplies of the QMP USB and UFS PHYs are
frequently swapped in devicetrees, as the naming does not make clear
which supply expects which voltage. Document that vdda-phy is around
0.8V and vdda-pll is around 1.2V, with the exact voltage varying per
SoC, so that the correct supplies can be assigned.

Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 .../devicetree/bindings/phy/qcom,msm8998-qmp-usb3-phy.yaml   | 10 ++++++++--
 .../devicetree/bindings/phy/qcom,qcs615-qmp-usb3dp-phy.yaml  | 10 ++++++++--
 .../devicetree/bindings/phy/qcom,sc8280xp-qmp-ufs-phy.yaml   | 12 +++++++++---
 .../bindings/phy/qcom,sc8280xp-qmp-usb3-uni-phy.yaml         | 12 +++++++++---
 .../bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml          | 10 ++++++++--
 5 files changed, 42 insertions(+), 12 deletions(-)

diff --git a/Documentation/devicetree/bindings/phy/qcom,msm8998-qmp-usb3-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,msm8998-qmp-usb3-phy.yaml
index 1636285fbe53..4cbcf54aef2c 100644
--- a/Documentation/devicetree/bindings/phy/qcom,msm8998-qmp-usb3-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/qcom,msm8998-qmp-usb3-phy.yaml
@@ -39,9 +39,15 @@ properties:
       - const: phy
       - const: phy_phy
 
-  vdda-phy-supply: true
+  vdda-phy-supply:
+    description:
+      Supply for the PHY, typically around 0.8V, though the exact voltage
+      varies per SoC.
 
-  vdda-pll-supply: true
+  vdda-pll-supply:
+    description:
+      Supply for the PLL, typically around 1.2V, though the exact voltage
+      varies per SoC.
 
   "#clock-cells":
     const: 0
diff --git a/Documentation/devicetree/bindings/phy/qcom,qcs615-qmp-usb3dp-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,qcs615-qmp-usb3dp-phy.yaml
index efb465c71c1b..9dbe49afaa6c 100644
--- a/Documentation/devicetree/bindings/phy/qcom,qcs615-qmp-usb3dp-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/qcom,qcs615-qmp-usb3dp-phy.yaml
@@ -40,9 +40,15 @@ properties:
       - const: phy_phy
       - const: dp_phy
 
-  vdda-phy-supply: true
+  vdda-phy-supply:
+    description:
+      Supply for the PHY, typically around 0.8V, though the exact voltage
+      varies per SoC.
 
-  vdda-pll-supply: true
+  vdda-pll-supply:
+    description:
+      Supply for the PLL, typically around 1.2V, though the exact voltage
+      varies per SoC.
 
   "#clock-cells":
     const: 1
diff --git a/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-ufs-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-ufs-phy.yaml
index b2c5c9a375a3..968a700d2a55 100644
--- a/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-ufs-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-ufs-phy.yaml
@@ -81,9 +81,15 @@ properties:
     items:
       - const: ufsphy
 
-  vdda-phy-supply: true
-
-  vdda-pll-supply: true
+  vdda-phy-supply:
+    description:
+      Supply for the PHY, typically around 0.8V, though the exact voltage
+      varies per SoC.
+
+  vdda-pll-supply:
+    description:
+      Supply for the PLL, typically around 1.2V, though the exact voltage
+      varies per SoC.
 
   "#clock-cells":
     const: 1
diff --git a/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb3-uni-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb3-uni-phy.yaml
index 01342823e57f..532afa116ba0 100644
--- a/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb3-uni-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb3-uni-phy.yaml
@@ -64,9 +64,15 @@ properties:
       - const: phy
       - const: phy_phy
 
-  vdda-phy-supply: true
-
-  vdda-pll-supply: true
+  vdda-phy-supply:
+    description:
+      Supply for the PHY, typically around 0.8V, though the exact voltage
+      varies per SoC.
+
+  vdda-pll-supply:
+    description:
+      Supply for the PLL, typically around 1.2V, though the exact voltage
+      varies per SoC.
 
   refgen-supply: true
 
diff --git a/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml
index 4eff92343ce4..865395fe1416 100644
--- a/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml
@@ -69,9 +69,15 @@ properties:
       - const: phy
       - const: common
 
-  vdda-phy-supply: true
+  vdda-phy-supply:
+    description:
+      Supply for the PHY, typically around 0.8V, though the exact voltage
+      varies per SoC.
 
-  vdda-pll-supply: true
+  vdda-pll-supply:
+    description:
+      Supply for the PLL, typically around 1.2V, though the exact voltage
+      varies per SoC.
 
   refgen-supply: true
 

-- 
2.43.0

