From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 07 Feb 2025 22:30:24 +0100
Subject: [PATCH v2 07/12] dt-bindings: watchdog: Convert mpc8xxx-wdt to
 YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250207-ppcyaml-v2-7-8137b0c42526@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738963832; l=3875;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=IzmYTjKFSaMe8r78V7lDGgTUX3OYdgsgRQLqgb3+W5E=;
 b=TIcbvGAq3Pd5vRP/+yayQPTA4eKxHfJJoBevDPlnNqk/TGLY/RAUlfbrPChXuI2XTMp9PTJ3j
 xT5C+X1jArUDzNFPHWmc4Z83M+LYPrzacfBFMNuxejNmMMtEVUUSfdW
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert mpc83xx-wdt.txt to YAML to enable automatic schema validation.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

V2:
- trim subject line (remove "binding")
- fix property order to comply with dts coding style
---
 .../devicetree/bindings/watchdog/mpc8xxx-wdt.txt   | 25 ---------
 .../devicetree/bindings/watchdog/mpc8xxx-wdt.yaml  | 64 ++++++++++++++++++++++
 2 files changed, 64 insertions(+), 25 deletions(-)

diff --git a/Documentation/devicetree/bindings/watchdog/mpc8xxx-wdt.txt b/Documentation/devicetree/bindings/watchdog/mpc8xxx-wdt.txt
deleted file mode 100644
index a384ff5b3ce8c62d813fc23d72f74e2158ff543e..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/watchdog/mpc8xxx-wdt.txt
+++ /dev/null
@@ -1,25 +0,0 @@
-* Freescale mpc8xxx watchdog driver (For 83xx, 86xx and 8xx)
-
-Required properties:
-- compatible: Shall contain one of the following:
-	"mpc83xx_wdt" for an mpc83xx
-	"fsl,mpc8610-wdt" for an mpc86xx
-	"fsl,mpc823-wdt" for an mpc8xx
-- reg: base physical address and length of the area hosting the
-       watchdog registers.
-		On the 83xx, "Watchdog Timer Registers" area:	<0x200 0x100>
-		On the 86xx, "Watchdog Timer Registers" area:	<0xe4000 0x100>
-		On the 8xx, "General System Interface Unit" area: <0x0 0x10>
-
-Optional properties:
-- reg: additional physical address and length (4) of location of the
-       Reset Status Register (called RSTRSCR on the mpc86xx)
-		On the 83xx, it is located at offset 0x910
-		On the 86xx, it is located at offset 0xe0094
-		On the 8xx, it is located at offset 0x288
-
-Example:
-		WDT: watchdog@0 {
-		    compatible = "fsl,mpc823-wdt";
-		    reg = <0x0 0x10 0x288 0x4>;
-		};
diff --git a/Documentation/devicetree/bindings/watchdog/mpc8xxx-wdt.yaml b/Documentation/devicetree/bindings/watchdog/mpc8xxx-wdt.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..09e6dcf5bf186e4d15ee84f03ce64dd53155198d
--- /dev/null
+++ b/Documentation/devicetree/bindings/watchdog/mpc8xxx-wdt.yaml
@@ -0,0 +1,64 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/watchdog/mpc8xxx-wdt.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale MPC8xxx watchdog timer (For 83xx, 86xx and 8xx)
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+properties:
+  compatible:
+    enum:
+      - mpc83xx_wdt       # for an mpc83xx
+      - fsl,mpc8610-wdt   # for an mpc86xx
+      - fsl,mpc823-wdt    # for an mpc8xx
+
+  device_type:
+    const: watchdog
+
+  reg:
+    minItems: 1
+    items:
+      - description: |
+          Base physical address and length of the area hosting the watchdog
+          registers.
+
+          On the 83xx, "Watchdog Timer Registers" area:     <0x200 0x100>
+          On the 86xx, "Watchdog Timer Registers" area:     <0xe4000 0x100>
+          On the 8xx, "General System Interface Unit" area: <0x0 0x10>
+
+      - description: |
+          Additional optional physical address and length (4) of location of
+          the Reset Status Register (called RSTRSCR on the mpc86xx)
+
+          On the 83xx, it is located at offset 0x910
+          On the 86xx, it is located at offset 0xe0094
+          On the 8xx, it is located at offset 0x288
+
+required:
+  - compatible
+  - reg
+
+allOf:
+  - $ref: watchdog.yaml#
+
+additionalProperties: false
+
+examples:
+  - |
+    WDT: watchdog@0 {
+        compatible = "fsl,mpc823-wdt";
+        reg = <0x0 0x10 0x288 0x4>;
+    };
+
+  - |
+    wdt: watchdog@200 {
+        compatible = "mpc83xx_wdt";
+        reg = <0x200 0x100>;
+        device_type = "watchdog";
+    };
+
+...

-- 
2.48.0.rc1.219.gb6b6757d772

