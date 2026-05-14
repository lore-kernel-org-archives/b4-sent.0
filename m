From: Antony Kurniawan Soemardi <linux@smankusors.com>
Date: Thu, 14 May 2026 21:08:30 +0700
Subject: [PATCH v2 01/10] dt-bindings: clock: qcom,rpmcc: add msm8960
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260514-msm8960-wifi-v2-1-7cbae45dab5e@smankusors.com>
References: <20260514-msm8960-wifi-v2-0-7cbae45dab5e@smankusors.com>
In-Reply-To: <20260514-msm8960-wifi-v2-0-7cbae45dab5e@smankusors.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lee Jones <lee@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778767762; l=3572;
 i=linux@smankusors.com; s=20250609; h=from:subject:message-id;
 bh=yJDZ3oI+U0ik6kyM6Iek60rqNIUI/8S+jJgZ5v5/O/A=;
 b=fmmYh5Gfdbg3cKUMUc+qEkC8K+LYzBMP75QRB7sMRRyPnKn1OvhRcnnevzpEkce4S0UXKA8j2
 vqX/MP77qafDprIo0OWksbP+KA5IK26gDnql9Oc9WybYDhZ/TTLXWxq
X-Developer-Key: i=linux@smankusors.com; a=ed25519;
 pk=65wTy06fJl2/h/EJwjr704YG+yjHFhZObJBWzzK+N00=
X-Endpoint-Received: by B4 Relay for linux@smankusors.com/20250609 with auth_id=733
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the qcom,rpmcc-msm8960 compatible.

The MSM8960 platform shares the same RPM clock definitions as
APQ8064, so extend the existing conditional schema to treat
qcom,rpmcc-msm8960 the same as qcom,rpmcc-apq8064.

Signed-off-by: Antony Kurniawan Soemardi <linux@smankusors.com>
---
 .../devicetree/bindings/clock/qcom,rpmcc.yaml      | 77 +++++++++++++---------
 1 file changed, 47 insertions(+), 30 deletions(-)

diff --git a/Documentation/devicetree/bindings/clock/qcom,rpmcc.yaml b/Documentation/devicetree/bindings/clock/qcom,rpmcc.yaml
index ab97d4b7dba8..32ef7d08e0bb 100644
--- a/Documentation/devicetree/bindings/clock/qcom,rpmcc.yaml
+++ b/Documentation/devicetree/bindings/clock/qcom,rpmcc.yaml
@@ -21,35 +21,40 @@ description: |
 
 properties:
   compatible:
-    items:
-      - enum:
-          - qcom,rpmcc-apq8060
-          - qcom,rpmcc-apq8064
-          - qcom,rpmcc-ipq806x
-          - qcom,rpmcc-mdm9607
-          - qcom,rpmcc-msm8226
-          - qcom,rpmcc-msm8660
-          - qcom,rpmcc-msm8909
-          - qcom,rpmcc-msm8916
-          - qcom,rpmcc-msm8917
-          - qcom,rpmcc-msm8936
-          - qcom,rpmcc-msm8937
-          - qcom,rpmcc-msm8940
-          - qcom,rpmcc-msm8953
-          - qcom,rpmcc-msm8974
-          - qcom,rpmcc-msm8976
-          - qcom,rpmcc-msm8992
-          - qcom,rpmcc-msm8994
-          - qcom,rpmcc-msm8996
-          - qcom,rpmcc-msm8998
-          - qcom,rpmcc-qcm2290
-          - qcom,rpmcc-qcs404
-          - qcom,rpmcc-sdm429
-          - qcom,rpmcc-sdm660
-          - qcom,rpmcc-sm6115
-          - qcom,rpmcc-sm6125
-          - qcom,rpmcc-sm6375
-      - const: qcom,rpmcc
+    oneOf:
+      - items:
+          - enum:
+              - qcom,rpmcc-apq8060
+              - qcom,rpmcc-apq8064
+              - qcom,rpmcc-ipq806x
+              - qcom,rpmcc-mdm9607
+              - qcom,rpmcc-msm8226
+              - qcom,rpmcc-msm8660
+              - qcom,rpmcc-msm8909
+              - qcom,rpmcc-msm8916
+              - qcom,rpmcc-msm8917
+              - qcom,rpmcc-msm8936
+              - qcom,rpmcc-msm8937
+              - qcom,rpmcc-msm8940
+              - qcom,rpmcc-msm8953
+              - qcom,rpmcc-msm8974
+              - qcom,rpmcc-msm8976
+              - qcom,rpmcc-msm8992
+              - qcom,rpmcc-msm8994
+              - qcom,rpmcc-msm8996
+              - qcom,rpmcc-msm8998
+              - qcom,rpmcc-qcm2290
+              - qcom,rpmcc-qcs404
+              - qcom,rpmcc-sdm429
+              - qcom,rpmcc-sdm660
+              - qcom,rpmcc-sm6115
+              - qcom,rpmcc-sm6125
+              - qcom,rpmcc-sm6375
+          - const: qcom,rpmcc
+      - items:
+          - const: qcom,rpmcc-msm8960
+          - const: qcom,rpmcc-apq8064
+          - const: qcom,rpmcc
 
   '#clock-cells':
     const: 1
@@ -90,7 +95,9 @@ allOf:
       properties:
         compatible:
           contains:
-            const: qcom,rpmcc-apq8064
+            enum:
+              - qcom,rpmcc-apq8064
+              - qcom,rpmcc-msm8960
     then:
       properties:
         clocks:
@@ -164,3 +171,13 @@ examples:
             clock-names = "pxo";
         };
     };
+
+  - |
+    rpm {
+        clock-controller {
+            compatible = "qcom,rpmcc-msm8960", "qcom,rpmcc-apq8064", "qcom,rpmcc";
+            #clock-cells = <1>;
+            clocks = <&pxo_board>, <&cxo_board>;
+            clock-names = "pxo", "cxo";
+        };
+    };

-- 
2.34.1

