From: Long Zhao <longzhao@ambarella.com>
Date: Mon, 21 Sep 2026 12:23:24 +0800
Subject: [PATCH v8 05/18] dt-bindings: gpio: pl061: add Ambarella CV75
 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-cv75-v5-v8-5-282ff5d98dda@ambarella.com>
References: <20260921-cv75-v5-v8-0-282ff5d98dda@ambarella.com>
In-Reply-To: <20260921-cv75-v5-v8-0-282ff5d98dda@ambarella.com>
To: Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, soc@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Long Zhao <longzhao@ambarella.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Jerome Brunet <jbrunet@baylibre.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Long Zhao <zl020895@163.com>, Lee Jones <lee@kernel.org>, 
 mfd@lists.linux.dev, devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789964608; l=2025;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=GVEIXtfx8rpLQa9TzFd09VjRop28rVpySsmXjUcyqZs=;
 b=Fo85IDH9CPKUggCRVyQ2gJURzjURGeK9VwzCX0zQQavK4eGy8LQzGOd51k3V62j04DGfXFOYr
 uA2NQBL+8O5CEp+xRahSZ2xOdeR3F1E7oyUkJgBszjw14265YYekQ84
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CV75 GPIO banks sit on the AMBA PrimeCell bus but are not
register-compatible with the ARM PL061. Each bank is 32-bit and 32
lines, with extra mask/enable registers, so arm,pl061 must not be used
as a fallback compatible.

The AMBA core matches the PL061 driver by PrimeCell ID, not by the DT
compatible string. These blocks do not implement the standard PL061 ID
(0x00041061) in the ID registers, so arm,primecell-periphid is required
and is fixed to 0x000e8061; the driver uses that ID to select the
Ambarella layout. gpio-ranges is required because each bank is a slice
of the SoC pinctrl pin space.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 .../devicetree/bindings/gpio/pl061-gpio.yaml       | 25 +++++++++++++++++++---
 1 file changed, 22 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml b/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml
index 4d970e55104b..c22dd8a1d2c1 100644
--- a/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml
+++ b/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml
@@ -15,7 +15,9 @@ select:
   properties:
     compatible:
       contains:
-        const: arm,pl061
+        enum:
+          - arm,pl061
+          - ambarella,cv75-gpio
   required:
     - compatible
 
@@ -25,7 +27,9 @@ properties:
 
   compatible:
     items:
-      - const: arm,pl061
+      - enum:
+          - ambarella,cv75-gpio
+          - arm,pl061
       - const: arm,primecell
 
   reg:
@@ -64,6 +68,21 @@ required:
   - "#gpio-cells"
   - gpio-controller
 
-additionalProperties: false
+allOf:
+  - $ref: /schemas/arm/primecell.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: ambarella,cv75-gpio
+    then:
+      properties:
+        arm,primecell-periphid:
+          const: 0x000e8061
+      required:
+        - arm,primecell-periphid
+        - gpio-ranges
+
+unevaluatedProperties: false
 
 ...

-- 
2.34.1

