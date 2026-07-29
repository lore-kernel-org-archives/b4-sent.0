From: David Heidelberg <david@ixit.cz>
Date: Thu, 30 Jul 2026 00:20:12 +0200
Subject: [PATCH v2 1/2] dt-bindings: media: i2c: dongwoon,dw9714: Document
 DW9714A and V variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-dw9714v-v2-1-d5da19e6c60b@ixit.cz>
References: <20260730-dw9714v-v2-0-d5da19e6c60b@ixit.cz>
In-Reply-To: <20260730-dw9714v-v2-0-d5da19e6c60b@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Alexander Martinz <amartinz@shiftphones.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1356; i=david@ixit.cz;
 h=from:subject:message-id; bh=q0K6E/Plbn+LUlzxJz5kdbAH/8vBaD17SvTrwnOusfY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqanydbQVqJUFtryrNmvezy16D4GoZ5BWCumOws
 pJg8w73H+uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCamp8nQAKCRBgAj/E00kg
 cuX/EACLduG3kV31Uo5ZqXNcRqOLtGXgyTyNIprhOAlUgMWYE9/ezecJFaP9ZmAlDJbdNzG2mLt
 b/VNw6bXRQmiLU6egwD8LiwOftvbGljav66N4/Rb1OBOoosDsb6jlRl5MdY0D7eWCdYffk05JjY
 d5RebGWppOxVEN6n7k3vYJbE3eDktmTkeRUfbIhGTPRATNmyvd2dJf8c3299QFWvv21aLyjX3Hv
 P5wjUn+rieN8sPZf9blZDSw+0hRp1lnePWMEGepLyvkxPVTMpeav+1ZaP0zGSG2/qejlb2D1LYe
 vjL8fX82XAzh8PRQOeSiD8zhEfkYuwRja8qNssdCxoikGZeKiWeZWqyE8VbSGt6HEsK8px+wU6V
 9IDP6LuKwj4QqJmTYOVFigkzepQbW429edJUR5P2TZP2zH6hqMmuh67sKT97buNMhXM4kP9i8FZ
 0Cl6WiBjtCfDGsAO8DguPslQ+1bb1OJw181iyvgn8CtWLaS5SYZUbDypb2e/9/7h2Eoj2teobdv
 lr9DDBEJB9qgXLkYv8um96xhEffHwtffjnqCFYdrv9SIsIn0gVye6AwD3+ac8uuf6am4OlOqAud
 wVHhpHWDPhIaxbMp/pZh4iXVR1GiswrCxhwiuw8CDYacpNjL+5vKp7Azj1OLrqcrSlBZXYbWi37
 t4+f/RhGP4/44xw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DW9714A is successor of DW9714 and DW9714V is successor of the DW9714A.

All actuators are backward compatible, but they do introduce new features.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/media/i2c/dongwoon,dw9714.yaml         | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
index 66229a3dc05d6..e8ad2d3448d5f 100644
--- a/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
@@ -10,17 +10,25 @@ maintainers:
   - Krzysztof Kozlowski <krzk@kernel.org>
 
 description:
   DW9174 is a 10-bit DAC with current sink capability. It is intended for
   driving voice coil lenses in camera modules.
 
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
2.53.0

