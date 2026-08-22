From: David Heidelberg <david@ixit.cz>
Date: Sat, 22 Aug 2026 07:15:16 +0200
Subject: [PATCH v5 1/3] dt-bindings: media: i2c: dongwoon,dw9714: Document
 DW9714A and V variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-dw9714v-v5-1-502bc7f43b8f@ixit.cz>
References: <20260822-dw9714v-v5-0-502bc7f43b8f@ixit.cz>
In-Reply-To: <20260822-dw9714v-v5-0-502bc7f43b8f@ixit.cz>
To: Alexander Martinz <amartinz@shiftphones.com>, 
 Bjorn Andersson <andersson@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2393; i=david@ixit.cz;
 h=from:subject:message-id; bh=MctnB/YBUlKBkfY6HkmVWzrj67EeGRulizfUpQ/8RY4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqiTB9j6/jFLwCxqgYxpUH8LT2DL2zrUTvujR2N
 Tabh7AIxweJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaokwfQAKCRBgAj/E00kg
 cvQyD/9xiCxwFXfRvXj4cqKxdIirjmF73HdbonOQJN/aQQhoCDpLx1vIeV0GALyCQlAtJUpx+wL
 BXKHCteBgM9lnzKdoBr7z3uTKlOxiNORXh4b6Low1s9yM+DLM892ew1eS9HXOiEH7+srYuTwVnH
 6h1S6WJkMse4qeo5sQ5UOHRIiuhthaEOMCHFv8sFjJ9y9BpAeg1f3cBvmb3IuWxJylYMn/e/e8A
 Xvq0KfQ7jZLDHFpL/6WiiSWWSiqBX5ePKXf3Aq5vX5N+wWtEzO8ofRT0WQGgIYIuGeYUEUX/i3F
 YMZoTTM5uipANkKgsZrfKq9jUT0ZRtpKcYxFEBZM9/0UxokfswGXvwznmp0aPPEVcXXi+C8sUB3
 yYWW7WnoXeRzRH53A7juUuP6eCJKbF6Bm9Ez4QRr5qm0q3DbGcQz28MWw0iPRIiP0dvUL0OEHsV
 MXEQkJ/nTIyWZoige7DKcKaSkan+EM4YDv6zuC5YQB/T+geNVxA1O+/4AGNbsxnUpz3oqrIF6e9
 83WOOJhui8USKTUF9yp3tpkdeIeyXRJ29u7rjynSHwR4XuMMBx+1LhyM6ElQobFdfPRekPBdt/p
 ELhwbYlxkVdP6CIDjWo2U7YV0NLecGZw54vjxbHeua1icupQReMD0pe++TmZGDjmJwVEscKkpxH
 5T2n1lehH3Ax/ZQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DW9714A is a successor of DW9714 and DW9714V is a successor of DW9714A.

All three are compatible in their normal mode: a 10-bit DAC with the same
Direct/LSC/DLC slew rate control. DW9714V additionally has an "advanced
mode", which exposes Smart Actuator Control (SAC2/SAC3/SAC3.5/SLSC) and
soft start/landing. Out of reset the DW9714V comes up in normal mode
with ringing control disabled, i.e. behaving as a plain DW9714,
so nothing has to be configured for it to work today.

Should SAC support be added later, it is board data rather than a userspace
knob: the mode and the vibration period (SAC_CFG/PRESC/SACT) have to match
the mechanical tVIB of the actuator and lens assembly of the given camera
module. Those properties are left out until there is driver support and
measured values.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/media/i2c/dongwoon,dw9714.yaml     | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
index 66229a3dc05d6..7c2769e6c4880 100644
--- a/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
@@ -5,22 +5,30 @@ $id: http://devicetree.org/schemas/media/i2c/dongwoon,dw9714.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
 title: Dongwoon Anatech DW9714 camera voice coil lens driver
 
 maintainers:
   - Krzysztof Kozlowski <krzk@kernel.org>
 
 description:
-  DW9174 is a 10-bit DAC with current sink capability. It is intended for
-  driving voice coil lenses in camera modules.
+  10-bit DAC with current sink capability. It is intended for driving
+  voice coil lenses in camera modules.
 
 properties:
   compatible:
-    const: dongwoon,dw9714
+    oneOf:
+      - items:
+          - const: dongwoon,dw9714v
+          - const: dongwoon,dw9714a
+          - const: dongwoon,dw9714
+      - items:
+          - const: dongwoon,dw9714a
+          - const: dongwoon,dw9714
+      - const: dongwoon,dw9714
 
   reg:
     maxItems: 1
 
   powerdown-gpios:
     description:
       XSD pin for shutdown (active low)
 

-- 
2.55.0

