From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Sat, 01 Mar 2025 17:43:07 -0600
Subject: [PATCH v3 1/4] dt-bindings: input: touchscreen: edt-ft5x06: use
 unevaluatedProperties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250301-pocof1-touchscreen-support-v3-1-af01c3b30b55@joelselvaraj.com>
References: <20250301-pocof1-touchscreen-support-v3-0-af01c3b30b55@joelselvaraj.com>
In-Reply-To: <20250301-pocof1-touchscreen-support-v3-0-af01c3b30b55@joelselvaraj.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740872603; l=1445;
 i=foss@joelselvaraj.com; s=20241007; h=from:subject:message-id;
 bh=Hy7fx86jeHjmZUnnNlmFO22hJjV8J6P/Dt8ZLHz4/64=;
 b=w3OaW0bwYui19t6U+QjdY67xgmlCjqsQuvyEUP05iuber/3fCzp3Pyi1Ie8IlLa6z3AWLcWgR
 RD41JNDNl7PAeV4UHn615pYM21rfiwSz+Q75gT0yJYNKL/8nYsgFUHG
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=pqYvzJftxCPloaoUbVsfQE7Gwv8bynZPy8mjYohwMCc=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20241007 with auth_id=238
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In Xiaomi Poco F1 (qcom/sdm845-xiaomi-beryllium-ebbg.dts), the FocalTech
FT8719 touchscreen is integrally connected to the display panel
(EBBG FT8719) and thus should be power sequenced together with display
panel using the panel property. Since the touchscreen controller uses
almost all the properties present in touchscreen.yaml, let's remove
additionalProperties: false and use unevaluatedProperties to include all
the properties including the needed panel property.

Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
 .../devicetree/bindings/input/touchscreen/edt-ft5x06.yaml        | 9 +--------
 1 file changed, 1 insertion(+), 8 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
index 70a922e213f2..ab821490284a 100644
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
2.48.1

