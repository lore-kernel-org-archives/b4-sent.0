From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:37:55 +0100
Subject: [PATCH v3 01/12] regulator: dt-bindings: qcom,usb-vbus-regulator:
 Add pmi8998 and pm660
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-1-91ba2e61a877@ixit.cz>
References: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
In-Reply-To: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Markus Rathgeb <maggu2810@mailbox.org>, Rob Herring <robh@kernel.org>, 
 Robin Snyders <robin@snyders.xyz>, Sebastian Reichel <sre@kernel.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3908; i=david@ixit.cz;
 h=from:subject:message-id; bh=uY38OOoOv7AGRyzhEMqIBpg8bK80KZsXFqsa90ruurA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1aZ71OU7nXEzGksm9JPBqUjPCMKJQIwl0AR
 /GgYR1ikoGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWgAKCRBgAj/E00kg
 crzrEACvV8hZp+8Nvex937epX+wbnJpLE+R4rEnKDaBYvYJasLsS4i7V176Fpr1lzgZVqn2X2be
 A24nn3e9hYzSDgRsGY1EahzxU7y1xxVS3uWfENPH6N2uv9/pOBPyFacjzD4Gb4AWW8Puh2ykUUO
 n4uCZuUH5CEOMMXdEWGqznkA4C7/xVj/CmdxhPlZCDFR7/q9yZCM0qBsGY7yBrgvBtmTwfPLCqI
 TIfLJhSqgYLFwbb77X6SUNuCYxJHOgH3+NDmfwENUA6f2qAjN4flYy0zsv5B3g+IketMeOBa1Wo
 RuEvnRzsFV+WCrmNCdQXRPeFIWF/OkYce1VravKDOXYC8W/JibanTSZpalLa92uZQCtkiHjXyf2
 DG/CLoB0+o7FxKF+ZRVY5Dgen78IevGVAvaErCy3WGB81nX8vTWFcKFs5uz1gL3s/BLl8tl+SLn
 mvab9y/NQ46sotGVTyN5rjcJuF8XHDzwk9vfnkqEPEEILiAs95eFK9/uCNvgGwzrY4eBrsDK31J
 kHWKa5HvJL08xthSrVv4NQxbHo3/RiVeTaZ6+G0BaHXCR+EU04LTmDTURyekkpf8rHG7EQJQD8m
 SIm66DualkV8214cYVk/uZahvSA8HrDq8kjVkS42C/UbAAIGma9yK8ITT/x0IUW/p5Pa3+NzdAk
 BTnzG7xO4yUobIg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VBUS register block on the PMI8998 and PM660 PMIC shares the design.
Define corresponding compatible string, having the
qcom,pmi8998-vbus-reg as a fallback.

As a part of the definition properly define existing chips using
min/max/multipleOf properties.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../regulator/qcom,usb-vbus-regulator.yaml         | 56 ++++++++++++++++++++--
 1 file changed, 52 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml b/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml
index 024b34d0eb1a6..7e984ab9a1474 100644
--- a/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml
+++ b/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml
@@ -9,35 +9,38 @@ title: The Qualcomm PMIC VBUS output regulator driver
 maintainers:
   - Wesley Cheng <quic_wcheng@quicinc.com>
 
 description: |
   This regulator driver controls the VBUS output by the Qualcomm PMIC.  This
   regulator will be enabled in situations where the device is required to
   provide power to the connected peripheral.
 
-  The pm8150b variant uses an OTG current-limit selector, supporting limits
-  of 500 mA, 1000 mA, 1500 mA, 2000 mA, 2500 mA and 3000 mA.
+  The pm8150b and pmi8998 variant uses an OTG current-limit selector.
 
   The pm4125 variant uses a different register layout with a 2-bit VBOOST
-  voltage selector supporting output voltages of 4.25 V, 4.5 V, 4.75 V
-  and 5.0 V.
+  voltage selector.
 
 properties:
   compatible:
     oneOf:
       - enum:
           - qcom,pm8150b-vbus-reg
           - qcom,pm4125-vbus-reg
+          - qcom,pmi8998-vbus-reg
       - items:
           - enum:
               - qcom,pm6150-vbus-reg
               - qcom,pm7250b-vbus-reg
               - qcom,pmi632-vbus-reg
           - const: qcom,pm8150b-vbus-reg
+      - items:
+          - enum:
+              - qcom,pm660-vbus-reg
+          - const: qcom,pmi8998-vbus-reg
 
   reg:
     maxItems: 1
     description: VBUS output base address
 
 allOf:
   - $ref: regulator.yaml#
   - if:
@@ -45,26 +48,71 @@ allOf:
         compatible:
           contains:
             enum:
               - qcom,pm8150b-vbus-reg
               - qcom,pm6150-vbus-reg
               - qcom,pm7250b-vbus-reg
               - qcom,pmi632-vbus-reg
     then:
+      properties:
+        regulator-min-microamp:
+          multipleOf: 500000
+          minimum: 500000
+          maximum: 3000000
+
+        regulator-max-microamp:
+          multipleOf: 500000
+          minimum: 500000
+          maximum: 3000000
+
+      required:
+        - regulator-min-microamp
+        - regulator-max-microamp
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,pm660-vbus-reg
+              - qcom,pmi8998-vbus-reg
+    then:
+      properties:
+        regulator-min-microamp:
+          multipleOf: 250000
+          minimum: 250000
+          maximum: 2000000
+
+        regulator-max-microamp:
+          multipleOf: 250000
+          minimum: 250000
+          maximum: 2000000
+
       required:
         - regulator-min-microamp
         - regulator-max-microamp
 
   - if:
       properties:
         compatible:
           contains:
             const: qcom,pm4125-vbus-reg
     then:
+      properties:
+        regulator-min-microvolt:
+          multipleOf: 250000
+          minimum: 4250000
+          maximum: 5000000
+
+        regulator-max-microvolt:
+          multipleOf: 250000
+          minimum: 4250000
+          maximum: 5000000
+
       required:
         - regulator-min-microvolt
         - regulator-max-microvolt
 
 required:
   - compatible
   - reg
 

-- 
2.55.0

