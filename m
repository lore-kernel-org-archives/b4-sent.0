From: Matt Eaton <linux@divinehawk.com>
Date: Sat, 29 Aug 2026 21:31:25 +0200
Subject: [PATCH 1/2] dt-bindings: usb: qcom,snps-dwc3: relax interrupt
 requirements for ipq4019
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-ipq4019-dwc3-migration-v1-1-cc66b54ce21c@divinehawk.com>
References: <20260829-ipq4019-dwc3-migration-v1-0-cc66b54ce21c@divinehawk.com>
In-Reply-To: <20260829-ipq4019-dwc3-migration-v1-0-cc66b54ce21c@divinehawk.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Matt Eaton <linux@divinehawk.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788031913; l=3070;
 i=linux@divinehawk.com; s=20260828; h=from:subject:message-id;
 bh=0I9pzx+6YLuKTnpvjptQRbcepTykbRTTfqfao05DWJI=;
 b=QUmFMQqpbC9g1l0FYCO/8hfQ2N4XIhJdxr/G2oyA1HRvIcAqTqbrIIWyNhG9Ce2gNO/aKXIkL
 y/d0mHUk22XAhSFN67n6e7g9a8ATfEJI5PbGb0ea+8T7AYyYqcHr2Ed
X-Developer-Key: i=linux@divinehawk.com; a=ed25519;
 pk=UG4KnKXGwxjTNdirUPh/nySblET4aRxWYWSMTQwzlMw=
X-Endpoint-Received: by B4 Relay for linux@divinehawk.com/20260828 with auth_id=982
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qcom,ipq4019-dwc3 is grouped with the platforms that must supply five or
six named interrupts, but neither mainline nor Qualcomm's own IPQ4019
vendor devicetree specifies any wakeup interrupts for this SoC. Both
describe only the core dwc_usb3 interrupt: GIC_SPI 132 for the usb3
instance and GIC_SPI 136 for the usb2 instance.

commit dd566faebe9f ("dt-bindings: usb: qcom,dwc3: refine interrupt
requirements") listed ipq4019 among the compatibles in this position and
chose to keep the schema warnings for the time being.

Migrating the ipq4019 devicetree onto this binding otherwise fails
dtbs_check:

usb@8a00000 (qcom,ipq4019-dwc3): interrupts: [[0, 132, 4]] is too short
usb@8a00000 (qcom,ipq4019-dwc3): interrupt-names: ['dwc_usb3'] is too short

Give ipq4019 its own clause allowing a single interrupt, and lower the
top-level minimum to match. The per-SoC clause cannot loosen the
top-level constraint on its own, since allOf intersects.

dwc3-qcom.c looks all four wakeup interrupts up with
platform_get_irq_byname_optional(), so nothing in the driver depends on
their presence. If the wakeup interrupt numbers are established later
they can be added without another binding change.

Note that qcom,ipq9574-dwc3, qcom,qcm2290-dwc3, qcom,sar2130p-dwc3 and
qcom,sm6375-dwc3 have no per-SoC interrupt clause and relied on the
top-level minimum, so they are left unconstrained at the low end by this
change.

Signed-off-by: Matt Eaton <linux@divinehawk.com>
---
 .../devicetree/bindings/usb/qcom,snps-dwc3.yaml    | 23 ++++++++++++++++++++--
 1 file changed, 21 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml b/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml
index 7d784a648b7d..28e78302b814 100644
--- a/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml
+++ b/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml
@@ -137,11 +137,11 @@ properties:
                                only on SoCs with non-QUSB2 targets with
                                exception of SDM670/SDM845/SM6350.
         - ss_phy_irq: Used for remote wakeup in Super Speed mode of operation.
-    minItems: 3
+    minItems: 1
     maxItems: 19
 
   interrupt-names:
-    minItems: 3
+    minItems: 1
     maxItems: 19
 
   qcom,select-utmi-as-pipe-clk:
@@ -508,6 +508,25 @@ allOf:
           contains:
             enum:
               - qcom,ipq4019-dwc3
+    then:
+      properties:
+        interrupts:
+          minItems: 1
+          maxItems: 6
+        interrupt-names:
+          minItems: 1
+          items:
+            - const: dwc_usb3
+            - const: pwr_event
+            - const: hs_phy_irq
+            - const: dp_hs_phy_irq
+            - const: dm_hs_phy_irq
+            - const: ss_phy_irq
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
               - qcom,ipq8064-dwc3
               - qcom,kaanapali-dwc3
               - qcom,qcs615-dwc3

-- 
2.43.0

