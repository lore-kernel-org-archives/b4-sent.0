From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Tue, 06 May 2025 13:18:38 -0500
Subject: [PATCH RESEND v4 1/4] dt-bindings: input: touchscreen: edt-ft5x06:
 use unevaluatedProperties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250506-pocof1-touchscreen-support-v4-1-bfb53da52945@joelselvaraj.com>
References: <20250506-pocof1-touchscreen-support-v4-0-bfb53da52945@joelselvaraj.com>
In-Reply-To: <20250506-pocof1-touchscreen-support-v4-0-bfb53da52945@joelselvaraj.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 Joel Selvaraj <foss@joelselvaraj.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746555528; l=1632;
 i=foss@joelselvaraj.com; s=20250506; h=from:subject:message-id;
 bh=VdNFQQYZg3DtBiz7djqa47zvKcz3+ph7toNxgsM7vNg=;
 b=ckbNOn8YgQSIWuQzufuxsyNDrsvMYBvd/mXNqEEz63m0XnDuNEydiO7g0dyLTH9YPo5D9tTrv
 p0SN8gd78bGDTsoK1GMKsjwQK9vsyalp0PtKpLpR4VliqE4761qbogM
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=/jk63vyofgC3YCat+t/kcBv+rlSEVcI4PLN/LN0SQlQ=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20250506 with auth_id=399
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In Xiaomi Poco F1 (qcom/sdm845-xiaomi-beryllium-ebbg.dts), the FocalTech
FT8719 touchscreen is integrally connected to the display panel
(EBBG FT8719) and thus should be power sequenced together with display
panel using the panel property. Since the edt-ft5x06 touchscreen binding
uses almost all the properties present in touchscreen.yaml, let's remove
additionalProperties: false and use unevaluatedProperties to include all
the properties, including the needed panel property.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Acked-by: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
 .../devicetree/bindings/input/touchscreen/edt-ft5x06.yaml        | 9 +--------
 1 file changed, 1 insertion(+), 8 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
index 70a922e213f2a62e3d0bd403e24ed9c3ccffd2d5..ab821490284ac0ea13568cb9ee357aea3faaa1b7 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
@@ -103,16 +103,9 @@ properties:
     minimum: 0
     maximum: 255
 
-  touchscreen-size-x: true
-  touchscreen-size-y: true
-  touchscreen-fuzz-x: true
-  touchscreen-fuzz-y: true
-  touchscreen-inverted-x: true
-  touchscreen-inverted-y: true
-  touchscreen-swapped-x-y: true
   interrupt-controller: true
 
-additionalProperties: false
+unevaluatedProperties: false
 
 required:
   - compatible

-- 
2.49.0

