From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 07 Feb 2025 22:30:21 +0100
Subject: [PATCH v2 04/12] dt-bindings: mfd: Convert fsl,mcu-mpc8349emitx to
 YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250207-ppcyaml-v2-4-8137b0c42526@posteo.net>
References: <20250207-ppcyaml-v2-0-8137b0c42526@posteo.net>
In-Reply-To: <20250207-ppcyaml-v2-0-8137b0c42526@posteo.net>
To: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: imx@lists.linux.dev, Scott Wood <oss@buserror.net>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>, Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Lee Jones <lee@kernel.org>, 
 Vinod Koul <vkoul@kernel.org>, Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.neuschaefer@gmx.net>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Mark Brown <broonie@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org, 
 linux-crypto@vger.kernel.org, dmaengine@vger.kernel.org, 
 linux-pci@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 linux-spi@vger.kernel.org, linux-mtd@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738963832; l=2984;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=uDy6u7+vjMysytDO3zWjx3Kn3oUqiW3GteoXfkCwZKA=;
 b=iFXGU+mNZUpUqA9uza05gJYMsMBoJdg86aLQh1PgURVUwU/03DcfeAfebz0wdehh60plhBbPb
 sqQK+Qjx2SFBGdyjhZLJG40nneXpeIDU6GM+y26pfUBo0zsE2hF9wE4
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert mcu-mpc8349emitx.txt to YAML and list the compatible strings
currently in use.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

V2:
- trim subject line (remove "binding")
- fix property order to comply with dts coding style
---
 .../bindings/mfd/fsl,mcu-mpc8349emitx.yaml         | 53 ++++++++++++++++++++++
 .../bindings/powerpc/fsl/mcu-mpc8349emitx.txt      | 17 -------
 2 files changed, 53 insertions(+), 17 deletions(-)

diff --git a/Documentation/devicetree/bindings/mfd/fsl,mcu-mpc8349emitx.yaml b/Documentation/devicetree/bindings/mfd/fsl,mcu-mpc8349emitx.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..d20de7a4142546c95f65814a3f1b03dd0949cffb
--- /dev/null
+++ b/Documentation/devicetree/bindings/mfd/fsl,mcu-mpc8349emitx.yaml
@@ -0,0 +1,53 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mfd/fsl,mcu-mpc8349emitx.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale MPC8349E-mITX-compatible Power Management Micro Controller Unit (MCU)
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - fsl,mc9s08qg8-mpc8315erdb
+              - fsl,mc9s08qg8-mpc8349emitx
+              - fsl,mc9s08qg8-mpc8377erdb
+              - fsl,mc9s08qg8-mpc8378erdb
+              - fsl,mc9s08qg8-mpc8379erdb
+          - const: fsl,mcu-mpc8349emitx
+
+  reg:
+    maxItems: 1
+
+  "#gpio-cells":
+    const: 2
+
+  gpio-controller: true
+
+required:
+  - compatible
+  - reg
+  - "#gpio-cells"
+  - gpio-controller
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        mcu@a {
+            compatible = "fsl,mc9s08qg8-mpc8349emitx",
+                         "fsl,mcu-mpc8349emitx";
+            reg = <0x0a>;
+            #gpio-cells = <2>;
+            gpio-controller;
+        };
+    };
diff --git a/Documentation/devicetree/bindings/powerpc/fsl/mcu-mpc8349emitx.txt b/Documentation/devicetree/bindings/powerpc/fsl/mcu-mpc8349emitx.txt
deleted file mode 100644
index 37f91fa576545aa245d893c24248bdbb2c0fcc07..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/powerpc/fsl/mcu-mpc8349emitx.txt
+++ /dev/null
@@ -1,17 +0,0 @@
-Freescale MPC8349E-mITX-compatible Power Management Micro Controller Unit (MCU)
-
-Required properties:
-- compatible : "fsl,<mcu-chip>-<board>", "fsl,mcu-mpc8349emitx".
-- reg : should specify I2C address (0x0a).
-- #gpio-cells : should be 2.
-- gpio-controller : should be present.
-
-Example:
-
-mcu@a {
-	#gpio-cells = <2>;
-	compatible = "fsl,mc9s08qg8-mpc8349emitx",
-		     "fsl,mcu-mpc8349emitx";
-	reg = <0x0a>;
-	gpio-controller;
-};

-- 
2.48.0.rc1.219.gb6b6757d772

