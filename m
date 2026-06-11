From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 11 Jun 2026 07:54:33 +0000
Subject: [PATCH RFC 1/2] dt-bindings: pinctl: amlogic,pinctrl-a4: Add gpio
 irq property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260611-gpio-to-irq-v1-1-12201716f23f@amlogic.com>
References: <20260611-gpio-to-irq-v1-0-12201716f23f@amlogic.com>
In-Reply-To: <20260611-gpio-to-irq-v1-0-12201716f23f@amlogic.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781164479; l=1026;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=f2QomikSfT1qCooaMl1RhIsTgkvu22kj3kqZBPEonnA=;
 b=kaz9R4lN17UNqFjm0N1XpjPESjtpT6n3pIrJdL7Z+WLfsXg1x0aUsq1/0YcSbykV67lX+yyIy
 lAZ/lmz9+MMA+WvF4oAY7e1cekHyQr9DKu+yJwM0Z0cZHT/CeyO+rRL
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the hw-irq property for each GPIO bank and enable interrupt-parent
for pinctrl so that gpiod_to_irq() can translate GPIO lines to IRQs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
index b69db1b95345..65ec9121300e 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
@@ -37,6 +37,8 @@ properties:
 
   ranges: true
 
+  interrupt-parent: true
+
 patternProperties:
   "^gpio@[0-9a-f]+$":
     type: object
@@ -65,6 +67,9 @@ patternProperties:
       gpio-ranges:
         maxItems: 1
 
+      hw-irq:
+        $ref: /schemas/types.yaml#/definitions/uint32
+
     required:
       - reg
       - reg-names

-- 
2.52.0

