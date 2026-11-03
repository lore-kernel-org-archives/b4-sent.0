From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 03 Nov 2026 14:50:19 +0800
Subject: [PATCH 1/5] dt-bindings: media: ite,it6625: add audio DAI
 properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-upstream-it6625-alsa-i2s-v1-1-bb91e2879b01@ite.com.tw>
References: <20261103-upstream-it6625-alsa-i2s-v1-0-bb91e2879b01@ite.com.tw>
In-Reply-To: <20261103-upstream-it6625-alsa-i2s-v1-0-bb91e2879b01@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Brown <broonie@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, linux-sound@vger.kernel.org, 
 linux-api@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793688630; l=2381;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=YquEGnkfejE8LQ3h36bXPBE3tLh6TFPGHJoLWRG719M=;
 b=lLa4lYyu0HCAvAC77t+VFLi8mHRGaDxq0l3ShmMhyDEv9x09C/rJmAzz4NtI+UYwIy0FFRS6Z
 MWSSGIdCtJACYzF2hCf13F7H0z7i5eJ3X0FqCs3gET+azSqwYf7rqnZ
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IT6625 and IT6626 decode the HDMI audio stream and output it on an I2S
interface, driving the bit and frame clocks themselves. The bridge has up
to eight I2S data pins.

Add '#sound-dai-cells' so the bridge can be referenced as an audio codec
DAI, and 'ite,i2s-data-lanes' to describe which data pins are connected
to the audio receiver, in HDMI channel-pair order. Without the property
only SD0 is connected.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 .../devicetree/bindings/media/i2c/ite,it6625.yaml  | 23 +++++++++++++++++++++-
 1 file changed, 22 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
index 9b621f726249189255692da02049ebcbf1d5b43c..9304a0507903e7eaee44fa565e49c6938e9eb7d8 100644
--- a/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
@@ -43,6 +43,23 @@ properties:
   ovdd-supply:
     description: I/O supply voltage
 
+  '#sound-dai-cells':
+    const: 0
+
+  ite,i2s-data-lanes:
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 1
+    maxItems: 8
+    uniqueItems: true
+    items:
+      enum: [ 0, 1, 2, 3, 4, 5, 6, 7 ]
+    description:
+      I2S audio data pins (SD0 - SD7) that are connected to the audio
+      receiver, in HDMI channel-pair order. The first entry is the pin
+      carrying HDMI channels 1 and 2, the second the pin carrying channels 3
+      and 4, and so on. The bridge drives the I2S bit and frame clocks. If
+      the property is absent, only SD0 is connected.
+
   ports:
     $ref: /schemas/graph.yaml#/properties/ports
     properties:
@@ -111,6 +128,7 @@ required:
   - ovdd-supply
 
 allOf:
+  - $ref: /schemas/sound/dai-common.yaml#
   - if:
       properties:
         compatible:
@@ -131,7 +149,7 @@ allOf:
                   required:
                     - bus-type
 
-additionalProperties: false
+unevaluatedProperties: false
 
 examples:
   - |
@@ -153,6 +171,9 @@ examples:
         vdd33-supply = <&vdd33_reg>;
         ovdd-supply = <&ovdd_reg>;
 
+        #sound-dai-cells = <0>;
+        ite,i2s-data-lanes = <0 1 2 3>;
+
         ports {
           #address-cells = <1>;
           #size-cells = <0>;

-- 
2.34.1

