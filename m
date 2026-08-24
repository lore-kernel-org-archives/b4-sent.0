From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 24 Aug 2026 17:48:51 +0200
Subject: [PATCH] dt-bindings: gpio: fsl,qoriq-gpio: allow gpio-hog child
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-for-upstream-dt-qoriq-gpio-hog-v1-1-d75923bcecad@free.fr>
X-B4-Tracking: v=1; b=H4sIAOJnjGoC/x3NwQqDMAyA4VeRnA3E4obuVcRDWdOaw0xN3RiI7
 27x+F3+/4DCJlzg1Rxg/JMiulZ0bQPvxa+JUUI1OHJPGlyPUQ2/uezG/oNhx01NNkxZFBdN+KD
 ReYp9oGGEGsnGUf73YJrP8wJqDSircAAAAA==
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787586532; l=1584;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=qt8u1pcOwjvjD2kGag7Qjh2sfmvzstUBk/iBZTZZ0oo=;
 b=pXqaykBNOpFFaSmjGjMEEsngg26noICqXld0sY3tOpzZm1b0/S8moly//tMAbHa06zD6AgC6n
 5P1UrlGj246DEDU6C8SIgQ3dtywUK3HScsphobIjlIpV4VV58qS6Nlj
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The binding sets additionalProperties: false and describes no child
nodes, so every gpio-hog on a QorIQ/Layerscape GPIO controller is a
dtbs_check failure:

  gpio@2310000 (fsl,ls2080a-gpio): 'ethsw-reset-hog', 'flash-reset-hog',
  'pltrst-hog', 'thermtrip-hog' do not match any of the regexes:
  '^pinctrl-[0-9]+$'

hogs are handled generically by gpiolib rather than by the controller
driver, so they work on this controller exactly as anywhere else, only
the schema disallows them.

Note: some other GPIO bindings already have such pattern:
gpio-mvebu, gpio-davinci, aspeed,ast2400-gpio and fairchild,74hc595

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml b/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
index 4cb2a6b9fabfb..a6252440e099b 100644
--- a/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
+++ b/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
@@ -63,6 +63,13 @@ properties:
       GPIO registers are used as little endian. If not
       present registers are used as big endian by default.
 
+patternProperties:
+  "^(.+-hog(-[0-9]+)?)$":
+    type: object
+
+    required:
+      - gpio-hog
+
 required:
   - compatible
   - reg

---
base-commit: 0a0d1d55dad570724bf8c7ea83409639cfb4be9b
change-id: 20260824-for-upstream-dt-qoriq-gpio-hog-5092a0f4d089

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

