From: David Heidelberg <david@ixit.cz>
Date: Fri, 16 Oct 2026 19:38:33 +0200
Subject: [PATCH v6 1/3] dt-bindings: media: i2c: dongwoon,dw9714: Document
 DW9714A and V variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-dw9714v-v6-1-ae730c77bfb1@ixit.cz>
References: <20261016-dw9714v-v6-0-ae730c77bfb1@ixit.cz>
In-Reply-To: <20261016-dw9714v-v6-0-ae730c77bfb1@ixit.cz>
To: Alexander Martinz <amartinz@shiftphones.com>, 
 Bjorn Andersson <andersson@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2393; i=david@ixit.cz;
 h=from:subject:message-id; bh=MctnB/YBUlKBkfY6HkmVWzrj67EeGRulizfUpQ/8RY4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq0mEZGjzQWm7pugnXYSI5t0cbILpmJn+9vJA3W
 R63z150G0uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCatJhGQAKCRBgAj/E00kg
 cmWfEACTrD1sgz/x20f4cXVOD3STWfIkCm9s5xY0nI37DBv3FzXuyc5S/UNE3ZALSxd/roBdQ0Q
 c+r6fZwSD2riug2apE77jEvd45JSGybE3foTFqNa5rlhyQFqA2syY3z5wv++Rst4LdBEvHYOUZW
 aQEq7i0esNHlhqp1t65jVUz9Qk/PCw8zDB8HNq6z5++yrXkrx4W07/Z4501CajECA/yAExLAXfG
 QE9DauqxDkKTjjlBTUYWHl8LeINukM1ZUcSKG7O1ss7ta9/7pSYVmdzrk4MBE1J8Ik7Ude8hWPk
 xKokM0Ejt3Ma7WYkF6ctNH8tFAZOoMoeNgQXl0YexV247oslIoNBjnDPlk7LwDdca6Ztx73Duvo
 m5Y4GMKFIlgkjgsUNDwd1XUTb8ShFU7u2AuexVH+DUgMlubQWQrvK3GhdVYGWYBeR0FmjW5PFm9
 vZNL/dzycDNnlBgNJnUuu4Y8SNMDuv8L3ddhyZQ8nMw56rewz7wLUCWFVefXtIZKhxh/CPxYcY/
 97euTOFzJk7BwTWZWgMIBAn+vdrqUi+bJL2UMZzbRXHvj3Y5aSJG/6vHdKRNv/o4HIFHiiVHCHl
 88nxJG3Y1PHWP9mp7ytLcFL3ofzFLTIOMk5/aQlu7JQ7FwzlBSuAQ/U78yQzXMQT6mIRkydBzqM
 LgCDmvrGcgZGxyA==
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

