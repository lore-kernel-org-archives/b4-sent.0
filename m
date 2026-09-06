From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sun, 06 Sep 2026 14:22:36 +0200
Subject: [PATCH 1/3] dt-bindings: arm: qcom: Add Lenovo Ideapad Slim 5
 variants
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-x1-ideapad-slim5x-v1-1-7ccffbe6bc4a@oldschoolsolutions.biz>
References: <20260906-x1-ideapad-slim5x-v1-0-7ccffbe6bc4a@oldschoolsolutions.biz>
In-Reply-To: <20260906-x1-ideapad-slim5x-v1-0-7ccffbe6bc4a@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788697362; l=1259;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=MOSjjYpfBBIQPVl/BSuVZwV6HsAN8S+mDS114WZka/8=;
 b=Gx0SpB6xcZvE/6QipUjHyt8CoMyDq4M9OdImzrUBHT7f5ziP7Rq/srxtiSawCgCyYr2TJCXeK
 S/sBD+Xo/XPAh9LG4aYyVInEvbFRug75UcUKXBkmTmMxGsxGFLFmeBg
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Lenovo IdeaPad Slim 5x 14Q8X9 (machine type 83HL),
a Snapdragon X Plus X1P42100 (Purwa) clamshell.

The chassis is sold with either an LCD panel that needs a PWM
backlight or an OLED panel that does not, so give each SKU its
own compatible. Also add a generic "lenovo,ideapad-5" fallback
for drivers that match a whole family, such as the QSEECOM
allowlist.

Assisted-by: Grok 4.5 (xAI)
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 5ccb571520d1d..da72181b55e2a 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1247,6 +1247,13 @@ properties:
           - const: asus,zenbook-a14-ux3407qa
           - const: qcom,x1p42100
 
+      - items:
+          - enum:
+              - lenovo,ideapad-slim5x-lcd
+              - lenovo,ideapad-slim5x-oled
+          - const: lenovo,ideapad-5
+          - const: qcom,x1p42100
+
       - items:
           - enum:
               - asus,vivobook-s15-x1p4

-- 
2.53.0

