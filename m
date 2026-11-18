From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 17:23:56 +0100
Subject: [PATCH RESEND v6 1/3] dt-bindings: media: i2c: dongwoon,dw9714:
 Document DW9714A and V variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-dw9714v-v6-1-48cfd8ee4c4c@ixit.cz>
References: <20261118-dw9714v-v6-0-48cfd8ee4c4c@ixit.cz>
In-Reply-To: <20261118-dw9714v-v6-0-48cfd8ee4c4c@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/dFSfbanzBkVKEUdzbIRWUm26RyYZMeX/trR9
 fWxIc3JZ6SJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3RUgAKCRBgAj/E00kg
 cu43D/wM3kahxulqMtdpQMfZlethaBetxXfjD1Rudb0vrDeQajTyb9okO8MeqEjgSa0JkTkw/TX
 Tydpf++oqQ4zp8XlU4X2v3/pLz3iGzxLomNX2wEuOWpAQK4pY6ZN0SrL5x0RJY6c3FoiSttfp24
 O2413uemhzLGTFcypS2jpwksl3GJuc4SDVygIrd4ucARmV77eNqL5mDIadMaRXtTfbMPpXKwFTh
 tF0EALpBUvUmz/nbK23GblqSQIFkN+pNG+5JIegRCzO8abgUQTrvdGjB9epNdRvzhVxt0xw5vKK
 eGoq/ACHq3j6xdMlnd49ET77C6XG8pUyF1KFnECsx91zssENgXG4OifPlruhRKYGgvEbW8017Ph
 7RckOpob7/DAUSmgrwatw27DwX3Tk3yVl3iD6vMg6nRgoxbUiAlFNK153sN93qxSB6w3EqEJpvq
 PG4r69F+QK/AgqshE2TTLO+BP+Z117R8h9PwCgKbN0fECV1jODJFKzDDexxtU+JOrMNtGtE5kqb
 8ETGCe7sd6cp0uyHRhzc5p60/X3RHoqMS7A45fwS7bGBSyr4nUF/j5mRX22vMAsSy3BOzr/vAK+
 xi4C/Wz/+TEpvRpnwMv8Y5opwtFYipdW333vi12DzkO8kQtX6lFzQeb2mFFQvLSAioU0c8yK+pi
 mwy4n7R0rjgjo8A==
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

