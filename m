From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 24 Dec 2024 09:02:12 +0100
Subject: [PATCH v2 3/3] dt-bindings: gpio: fairchild,74hc595: Document chip
 select vs. latch clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241224-gpio74-v2-3-bbcf14183191@posteo.net>
References: <20241224-gpio74-v2-0-bbcf14183191@posteo.net>
In-Reply-To: <20241224-gpio74-v2-0-bbcf14183191@posteo.net>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735027364; l=1852;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=cH5xit3DV86hTLAfvgIOa3yWbYuQXqh7Jhuym93dIKo=;
 b=wgPZt5Bm15HKsHlWSLf2fWzDXXz5ECnO5nU6CLR0GH+pCQu3++Eq8NuFFDkBTXOQSL3N09quU
 y/EBzlQ46rJBW5cuDhEMPp3YcjFIOzt72DDzM1i7rZdKA74mI5y9JM8
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From looking at the data sheets, it is not obvious that CS# and latch
clock can be treated at the same, but doing so works fine and saves the
hassle of (1) trying to specify a SPI device without CS, and (2) adding
another property to drive the latch clock[1].

[1]: https://lore.kernel.org/lkml/20241213-gpio74-v1-2-fa2c089caf41@posteo.net/

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

v2:
- new patch
---
 .../devicetree/bindings/gpio/fairchild,74hc595.yaml     | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml b/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml
index 629cf9b2ab8e4a63fbe17f56792a46d2066d40c3..a209c5b4f6e01ae9a376148b229273db7fdf0aa0 100644
--- a/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml
+++ b/Documentation/devicetree/bindings/gpio/fairchild,74hc595.yaml
@@ -6,6 +6,23 @@ $schema: http://devicetree.org/meta-schemas/core.yaml#
 
 title: Generic 8-bit shift register
 
+description: |
+  NOTE: These chips nominally don't have a chip select pin. They do however
+  have a rising-edge triggered latch clock (or storage register clock) pin,
+  which behaves like an active-low chip select.
+
+  After the bits are shifted into the shift register, CS# is driven high, which
+  the 74HC595 sees as a rising edge on the latch clock that results in a
+  transfer of the bits from the shift register to the storage register and thus
+  to the output pins.
+                      _   _       _   _
+  shift clock    ____| |_| |_..._| |_| |_________
+
+  latch clock                           * trigger
+                 ___                     ________
+  chip select#      |___________________|
+
+
 maintainers:
   - Maxime Ripard <mripard@kernel.org>
 

-- 
2.45.2

