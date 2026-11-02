From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 02 Nov 2026 17:22:56 +0200
Subject: [PATCH 1/2] dt-bindings: leds: irled: pwm-ir-tx: add power supply
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-6768-irled-v1-1-c7064f3afed1@protonmail.com>
References: <20261102-6768-irled-v1-0-c7064f3afed1@protonmail.com>
In-Reply-To: <20261102-6768-irled-v1-0-c7064f3afed1@protonmail.com>
To: Sean Young <sean@mess.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: linux-media@vger.kernel.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793632976; l=912;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=lrAuDDWc631H8kDzeXXaEWZPrYdjJgCBsuDfNWjP9es=;
 b=QonYg6UGNgFyURq5T7Isz6r0IAf56o1L6vgClckpFuFmgYzieXOhemc4SwTYnbWOcbrKBkSEi
 OfuiQb1E3n4BoNCtnJScVv8SxCNs3M6cweo9I/v6/hbh9buCWI/GMI3
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some boards, the IR LED is connected to a switchable power rail, such
as an eMMC supply. If this regulator is disabled, IR transmission fails.

Add an optional power-supply property to document this regulator.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/leds/irled/pwm-ir-tx.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/leds/irled/pwm-ir-tx.yaml b/Documentation/devicetree/bindings/leds/irled/pwm-ir-tx.yaml
index 7526e3149f72..35a601cc068b 100644
--- a/Documentation/devicetree/bindings/leds/irled/pwm-ir-tx.yaml
+++ b/Documentation/devicetree/bindings/leds/irled/pwm-ir-tx.yaml
@@ -23,6 +23,10 @@ properties:
   pwms:
     maxItems: 1
 
+  power-supply:
+    description:
+      The regulator controlling the current to the LED.
+
 required:
   - compatible
   - pwms

-- 
2.56.0

