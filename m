From: Esteban Urrutia <esteuwu@proton.me>
Date: Thu, 23 Jul 2026 10:53:52 -0400
Subject: [PATCH 1/2] regulator: dt-bindings: qcom,rpmh: Add support for
 PM8350B
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-pm8350b-ldo-v1-1-42b5428a0d3f@proton.me>
References: <20260723-pm8350b-ldo-v1-0-42b5428a0d3f@proton.me>
In-Reply-To: <20260723-pm8350b-ldo-v1-0-42b5428a0d3f@proton.me>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784818498; l=1661;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=LdzXIMsptuIjQd8m41gLdX8Sp15lL0imXwUrErODm0o=;
 b=g2TsnYFqdpkODkHzPse5iQVKHcMZ7aNZ6Yw3ZOEWvHECg0X24SITN3F9+PSkAUfiNZ59PYlXN
 4fl72+kxXr6B74kdTAOz00IkynKSaop/83cD0MjiuvUAuv4U9Kk9VJB
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PM8350B has only one LDO, which gets its power from a dedicated input.
Add support for it.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 .../devicetree/bindings/regulator/qcom,rpmh-regulator.yaml    | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/Documentation/devicetree/bindings/regulator/qcom,rpmh-regulator.yaml b/Documentation/devicetree/bindings/regulator/qcom,rpmh-regulator.yaml
index d93594304651..eed2ce7fa861 100644
--- a/Documentation/devicetree/bindings/regulator/qcom,rpmh-regulator.yaml
+++ b/Documentation/devicetree/bindings/regulator/qcom,rpmh-regulator.yaml
@@ -47,6 +47,7 @@ description: |
       For PM8150, smps1 - smps10, ldo1 - ldo18
       For PM8150L, smps1 - smps8, ldo1 - ldo11, bob, flash, rgb
       For PM8350, smps1 - smps12, ldo1 - ldo10
+      For PM8350B, ldo1
       For PM8350C, smps1 - smps10, ldo1 - ldo13, bob
       For PM8450, smps1 - smps6, ldo1 - ldo4
       For PM8550, smps1 - smps6, ldo1 - ldo17, bob1 - bob2
@@ -82,6 +83,7 @@ properties:
       - qcom,pm8150-rpmh-regulators
       - qcom,pm8150l-rpmh-regulators
       - qcom,pm8350-rpmh-regulators
+      - qcom,pm8350b-rpmh-regulators
       - qcom,pm8350c-rpmh-regulators
       - qcom,pm8450-rpmh-regulators
       - qcom,pm8550-rpmh-regulators
@@ -337,6 +339,15 @@ allOf:
       patternProperties:
         "^vdd-s([1-9]|1[0-2])-supply$": true
 
+  - if:
+      properties:
+        compatible:
+          enum:
+            - qcom,pm8350b-rpmh-regulators
+    then:
+      properties:
+        vdd-l1-supply: true
+
   - if:
       properties:
         compatible:

-- 
2.55.0

