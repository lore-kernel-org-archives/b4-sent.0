From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 13 Dec 2024 18:32:48 +0100
Subject: [PATCH 2/4] dt-bindings: gpio: fairchild,74hc595: Add latch-gpios
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241213-gpio74-v1-2-fa2c089caf41@posteo.net>
References: <20241213-gpio74-v1-0-fa2c089caf41@posteo.net>
In-Reply-To: <20241213-gpio74-v1-0-fa2c089caf41@posteo.net>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734111175; l=1203;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=nOeQNfQ47dnRJX9VGmO7IYI+EXeck3n+BI0JGrTkkuM=;
 b=E7iVfa+/YdGqEdUsG0I01f6tT/vDlup1VkYT0mXzTQWKS4Wbk/VgYc9vvoUujh6kcBvcPU8qI
 tWfLuVgwBEgBVCYPNPBb8miPojIfAkfDcGDVxT6m33YH+j4ryu86IF/
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Fairchild MM74HC595 and other compatible parts have a latch clock
input (also known as storage register clock input), which must be
clocked once in order to apply any value that was serially shifted in.

This patch adds a latch-gpios property to the binding to allow
specifying a GPIO that connects to the latch clock.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml b/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml
index 629cf9b2ab8e4a63fbe17f56792a46d2066d40c3..38d473a3852154e53faec88dc911dc0a4f9cbd1f 100644
--- a/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml
+++ b/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml
@@ -34,6 +34,10 @@ properties:
     description: GPIO connected to the OE (Output Enable) pin.
     maxItems: 1
 
+  latch-gpios:
+    description: GPIO connected to the latch clock or storage register clock pin.
+    maxItems: 1
+
 patternProperties:
   "^(hog-[0-9]+|.+-hog(-[0-9]+)?)$":
     type: object

-- 
2.45.2

