From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:44:10 +0300
Subject: [PATCH net-next 1/5] dt-bindings: reset: Add Cortina CS7542
 network engine reset domain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-ethernet-v1-1-fdb5e8c2d508@gmail.com>
References: <20261123-b4-cs7542-ethernet-v1-0-fdb5e8c2d508@gmail.com>
In-Reply-To: <20261123-b4-cs7542-ethernet-v1-0-fdb5e8c2d508@gmail.com>
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Linus Walleij <linusw@kernel.org>, Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459449; l=2664;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=afQd1qV0B7xeIKmVAhfGJ0iLxscNrcmWGV+PpdebZtc=;
 b=tfTFkWIjfmcOGW0TyJsPhNwJ/7RsQQNGNr1PBzxNsUCebQE2Wyz4+JuGq072EW0dq4+4Z4BE8
 jSsGPN+vfVaCj+ze3S+IwQ9+oRNjzxQrLPDPyOBex52cVlc4QS+qzJK
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the atomic reset domain required to stop all network-engine and
LSO/SSP DMA users before releasing their mappings. Exclude the SDRAM
controller and independent PCIe resets. Allow this provider as a child
of the shared global syscon.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../bindings/reset/cortina,cs7542-ne-reset.yaml    | 42 ++++++++++++++++++++++
 .../soc/cortina/cortina,cs7542-syscon.yaml         |  4 +++
 2 files changed, 46 insertions(+)

diff --git a/Documentation/devicetree/bindings/reset/cortina,cs7542-ne-reset.yaml b/Documentation/devicetree/bindings/reset/cortina,cs7542-ne-reset.yaml
new file mode 100644
index 000000000..8f5b5b835
--- /dev/null
+++ b/Documentation/devicetree/bindings/reset/cortina,cs7542-ne-reset.yaml
@@ -0,0 +1,42 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/reset/cortina,cs7542-ne-reset.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 network engine reset domain
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+description: |
+  Child of the CS7542 global syscon. One reset domain covers NI, FE, TM,
+  scheduler, queue manager, NI XRAM and the entire DMA block (LSO and SSP).
+  SDRAM and unrelated peripheral reset bits are not modified. The consumer
+  must own all these blocks exclusively. This reset is not suitable for a
+  network-only consumer while a separate driver uses SSP DMA.
+
+properties:
+  compatible:
+    const: cortina,cs7542-ne-reset
+
+  "#reset-cells":
+    const: 0
+
+required:
+  - compatible
+  - "#reset-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    syscon@f0000000 {
+        compatible = "cortina,cs7542-syscon", "syscon", "simple-mfd";
+        reg = <0xf0000000 0x100>;
+        #clock-cells = <1>;
+        reset-controller {
+            compatible = "cortina,cs7542-ne-reset";
+            #reset-cells = <0>;
+        };
+    };
diff --git a/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
index fb074de87..5aca670cd 100644
--- a/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
+++ b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
@@ -33,6 +33,10 @@ properties:
     type: object
     $ref: /schemas/pinctrl/cortina,cs7542-pinctrl.yaml#
 
+  reset-controller:
+    type: object
+    $ref: /schemas/reset/cortina,cs7542-ne-reset.yaml#
+
 required:
   - compatible
   - reg

-- 
2.53.0

