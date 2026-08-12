From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 12 Aug 2026 13:34:42 +0400
Subject: [PATCH v2 07/14] dt-bindings: usb: qcom,snps-dwc3: Add clocks for
 USB3 on Qualcomm IPQ5018
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-ipq5018-usb3-v2-7-8f355d7ff0ef@outlook.com>
References: <20260812-ipq5018-usb3-v2-0-8f355d7ff0ef@outlook.com>
In-Reply-To: <20260812-ipq5018-usb3-v2-0-8f355d7ff0ef@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Praveenkumar I <quic_ipkumar@quicinc.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786527282; l=1433;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=KARoq6OCpDTtF+1+6T0u7/RZsl8zfoh1RCmTPcSabJw=;
 b=qx3/6CaTtMRbU1yODKQppI9/1qKK28Mj9CW4eY6YqpbFPbxHzcqyDfsxap00f07+jMZ6VYeYK
 vqSbF+xX8SGDY9E5Dz4meOg5+jbdef+hdQ8nCrAP2vozT1K55YcAx91
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add aux and lfps clocks in Qualcomm IPQ5018. These clocks are required
only for USB Super-Speed support.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../devicetree/bindings/usb/qcom,snps-dwc3.yaml     | 21 ++++++++++++++++++++-
 1 file changed, 20 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml b/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml
index ce36109f5df7..e87cdf41f5f2 100644
--- a/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml
+++ b/Documentation/devicetree/bindings/usb/qcom,snps-dwc3.yaml
@@ -184,6 +184,26 @@ allOf:
             - const: sleep
             - const: mock_utmi
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,ipq5018-dwc3
+    then:
+      properties:
+        clocks:
+          minItems: 6
+          maxItems: 6
+        clock-names:
+          items:
+            - const: core
+            - const: iface
+            - const: sleep
+            - const: mock_utmi
+            - const: aux
+            - const: lfps
+
   - if:
       properties:
         compatible:
@@ -304,7 +324,6 @@ allOf:
         compatible:
           contains:
             enum:
-              - qcom,ipq5018-dwc3
               - qcom,msm8994-dwc3
               - qcom,qcs404-dwc3
     then:

-- 
2.53.0

