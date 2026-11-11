From: Michiel van Beers <michielvanbeers@gmail.com>
Date: Wed, 11 Nov 2026 17:21:41 +0100
Subject: [PATCH v2 1/2] dt-bindings: backlight: lm3630a: Add
 led-max-microamp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-lm3630a-led-max-microamp-v2-1-aff11756e7be@gmail.com>
References: <20261111-lm3630a-led-max-microamp-v2-0-aff11756e7be@gmail.com>
In-Reply-To: <20261111-lm3630a-led-max-microamp-v2-0-aff11756e7be@gmail.com>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Griffin Kroah-Hartman <griffin@kroah.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, Michiel van Beers <michielvanbeers@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794414160; l=1951;
 i=michielvanbeers@gmail.com; s=20261107; h=from:subject:message-id;
 bh=cVMp5TfdJqEv4/BLWzYSV7umn1bMpBqTXaN1LwgWfA0=;
 b=sKRGK7iQM4/JTa7sbXtUPCIl83y0BsZndAyrc2ZqLpu30HlBCBHiNfTmmr5Ca16CUyCW4pKJC
 4mZbHc/UG1lCDNOsiZWu8H137CPjB7L/RUE5JJ6KxfoXzMkQS5NB4+h
X-Developer-Key: i=michielvanbeers@gmail.com; a=ed25519;
 pk=C+lOje7u3+2x3o2NLMXrwz2veP2++eXfIi9MtYsUo4k=
X-Endpoint-Received: by B4 Relay for michielvanbeers@gmail.com/20261107 with auth_id=1444
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LM3630A has a full-scale current setting per control bank, from
5 mA to 28.25 mA in steps of 750 uA. Boards whose LED strings are rated
for less than the chip default of 28.25 mA have no way to describe that
limit.

Add the common led-max-microamp property to the led@0 and led@1 nodes,
and reference leds/common.yaml from them, where that property is
defined. The property is optional, so existing devicetrees remain
valid.

Signed-off-by: Michiel van Beers <michielvanbeers@gmail.com>
---
 .../devicetree/bindings/leds/backlight/lm3630a-backlight.yaml  | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Documentation/devicetree/bindings/leds/backlight/lm3630a-backlight.yaml b/Documentation/devicetree/bindings/leds/backlight/lm3630a-backlight.yaml
index 6393cbf3afdf..92a7236eae1b 100644
--- a/Documentation/devicetree/bindings/leds/backlight/lm3630a-backlight.yaml
+++ b/Documentation/devicetree/bindings/leds/backlight/lm3630a-backlight.yaml
@@ -42,6 +42,7 @@ required:
 patternProperties:
   "^led@[01]$":
     type: object
+    $ref: /schemas/leds/common.yaml#
     description: |
       Properties for a string of connected LEDs.
 
@@ -77,6 +78,14 @@ patternProperties:
         minimum: 0
         maximum: 255
 
+      led-max-microamp:
+        description:
+          Full-scale current of the LED strings driven by this control bank.
+          The LM3630A sets it from 5 mA to 28.25 mA in steps of 750 uA.
+        minimum: 5000
+        maximum: 28250
+        default: 28250
+
       ti,linear-mapping-mode:
         description: |
           Enable linear mapping mode. If disabled, then it will use exponential
@@ -112,6 +121,7 @@ examples:
                 label = "lcd-backlight";
                 default-brightness = <200>;
                 max-brightness = <255>;
+                led-max-microamp = <20000>;
             };
         };
     };

-- 
2.43.0

