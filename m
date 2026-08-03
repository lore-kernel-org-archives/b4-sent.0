From: David Heidelberg <david@ixit.cz>
Date: Mon, 03 Aug 2026 11:50:25 +0200
Subject: [PATCH v3 1/2] dt-bindings: media: i2c: dongwoon,dw9714: Document
 DW9714A and V variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-dw9714v-v3-1-8e10278dcd0d@ixit.cz>
References: <20260803-dw9714v-v3-0-8e10278dcd0d@ixit.cz>
In-Reply-To: <20260803-dw9714v-v3-0-8e10278dcd0d@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1991; i=david@ixit.cz;
 h=from:subject:message-id; bh=oVcaXqpDOcmHSgqIwupuG6hdi0uMYFAB5Ml2YkH3+nk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqcGRi5amBf5BMjN/Bz5MCOgoq1ms+Zcv0dvuYv
 WAc9xxBqLeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCanBkYgAKCRBgAj/E00kg
 ckH6D/0avCTu0ct8uzwpG+Ml0gfJMd/EzQDGcMcGTLVJFl6GIFzYokXj3rFpbkdJM+X9k14UTwu
 zbAKLKjXOCs3P9chD/3kFFUp+QZfUxfTspIU+hC6k9pkMCI9o7A3ZwRaZM7hbOedE7KBeqdjzsa
 Ormw4tX5IJ48EM4kELWM1rmIb7jvRlXGv/EuX22y9OwfJQHpPmnqbsxQTsjj6xBviF3kyu1KohN
 SQGI4RmL42mpG/7ysa5DJM1yeNSq/e5Nx4Grzsp3kF+8RKA0Jxj/sotkAY7H0FKAPrn3ZgzOwxM
 mAS0/lpa9HRQavcsC7P81VgVPyEnuX3ClL4eXVFtL+MpRR2XHjJjVKiKdYCMMGF/RXH2PCCWSM8
 3DxFosTFDMgy/+0ox4XxT1ke6fwFphbTRms7BqFS2cFQmJfJVMU3Vxz72SDfK+or+QWWluozn8f
 aVFIQ2qXfqKBABQscU6zV9YKDovEJEG1FompWDlDI5ZnzOZAF2YmbJ8FeRFh21PqoHGMGIahOzC
 pi4mz7BXUk7p/r0AbQhvoLbmjVBXAa6+Thv1USnGPvInNznNLHc+7nJrjTFil+Qiw+gV5aGYTTl
 8fwI2WnCi4On7F4ETHu/wNAVbJfqLOnMSrv9RnSeB5I04uEyrwHe3Jhn/qbB6CWPLByQe+XIOJq
 7pNFfZoR0ZucxVQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DW9714A is successor of DW9714 and DW9714V is successor of the DW9714A.

All actuators are backward compatible, but they do introduce new features,
such as Smart Actuator Control (SAC) mode which can minimize the
mechanical vibration and achieve very fast mechanical settling time.
Support for SAC can be implemented in the future.

Nit: fix typo in description by removing duplicate information.

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

