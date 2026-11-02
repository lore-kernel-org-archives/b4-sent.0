From: Long Zhao <longzhao@ambarella.com>
Date: Mon, 02 Nov 2026 14:45:54 +0800
Subject: [PATCH v13 01/13] dt-bindings: gpio: pl061: add Ambarella CV75
 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-cv75-gpio-v13-1-4f93114ea204@ambarella.com>
References: <20261102-cv75-gpio-v13-0-4f93114ea204@ambarella.com>
In-Reply-To: <20261102-cv75-gpio-v13-0-4f93114ea204@ambarella.com>
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, Mika Westerberg <westeri@kernel.org>, 
 linux-acpi@vger.kernel.org, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793602013; l=2175;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=ecrzSAMMaNZiFiJHNHyvnNwBNYVIUrMbREC+e46Wpqs=;
 b=aK45sE7xMsnVeUkJVEYGNztWds5bR4QSt+NBrfZ1irIoqSH/N4oPJ438vdEhKbnLDYnPFiP5L
 nJIfQd9zIWLC5joFcwOJbdjBu2gqDxn8xQNuHmwJsEdoxXGomUrSmuZ
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CV75 GPIO is a modified PL061. The basic registers have the same
names and roles (DAT/DIR/IS/IBE/IEV/IE/MIS/IC). Each bank is 32-bit
and 32 lines and adds MASK and ENABLE, so it is not
register-compatible with the ARM PL061 and arm,pl061 must not be
used as a fallback.

The AMBA core matches the PL061 driver by PrimeCell ID, not by the DT
compatible string. These blocks do not implement the standard PL061 ID
(0x00041061) in the ID registers, so arm,primecell-periphid is required
and is fixed to 0x000e8061; the driver uses that ID to select the
Ambarella layout. gpio-ranges is required because each bank is a slice
of the SoC pinctrl pin space.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Reviewed-by: Linus Walleij <linusw@kernel.org>
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

