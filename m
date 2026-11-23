From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:43:30 +0300
Subject: [PATCH 2/8] dt-bindings: clock: Describe CS7542 PCIe gates and
 resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-pcie-v1-2-4cde5201d404@gmail.com>
References: <20261123-b4-cs7542-pcie-v1-0-4cde5201d404@gmail.com>
In-Reply-To: <20261123-b4-cs7542-pcie-v1-0-4cde5201d404@gmail.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: Jingoo Han <jingoohan1@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 Krzysztof Wilczynski <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 linux-pci@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-clk@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459409; l=2658;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=dF63p0NESwL1d1J31nL8VBK3t0TGBHI629QHDWtLN0M=;
 b=q6YlorCM1VBJY6HWBaHuUxSchohP8M3owzFdU0wZ3abL+U94253u7AJ05ibgw+fhRjZiJCnkx
 RIBeAIGcQ6PDydvok9cq/tniNsbiJLPke+G7ohjoqjLYBWnbFF4OdcT
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the global-syscon child providing three PCIe controller gates
and reset lines. Port indices are shared by clock and reset specifiers.
The gate-only clocks do not claim a source frequency.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 .../clock/cortina,cs7542-pcie-control.yaml         | 47 ++++++++++++++++++++++
 .../soc/cortina/cortina,cs7542-syscon.yaml         |  4 ++
 2 files changed, 51 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/cortina,cs7542-pcie-control.yaml b/Documentation/devicetree/bindings/clock/cortina,cs7542-pcie-control.yaml
new file mode 100644
index 000000000..08e0214d2
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/cortina,cs7542-pcie-control.yaml
@@ -0,0 +1,47 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/cortina,cs7542-pcie-control.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Cortina Systems CS7542 PCIe gates and resets
+
+maintainers:
+  - Fil Dunsky <filipp.dunsky@gmail.com>
+
+description: |
+  Child of the CS7542 global control syscon. Clock and reset specifiers
+  select controller 0, 1 or 2. These clocks describe only the controller
+  enable gates; their source frequency and rate control are not described.
+  SerDes reference clocks and lane reset controls are separate.
+
+properties:
+  compatible:
+    const: cortina,cs7542-pcie-control
+
+  "#clock-cells":
+    const: 1
+
+  "#reset-cells":
+    const: 1
+
+required:
+  - compatible
+  - "#clock-cells"
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
+
+        pcie-control {
+            compatible = "cortina,cs7542-pcie-control";
+            #clock-cells = <1>;
+            #reset-cells = <1>;
+        };
+    };
diff --git a/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
index fb074de87..52597c4e8 100644
--- a/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
+++ b/Documentation/devicetree/bindings/soc/cortina/cortina,cs7542-syscon.yaml
@@ -29,6 +29,10 @@ properties:
   "#clock-cells":
     const: 1
 
+  pcie-control:
+    type: object
+    $ref: /schemas/clock/cortina,cs7542-pcie-control.yaml#
+
   pinctrl:
     type: object
     $ref: /schemas/pinctrl/cortina,cs7542-pinctrl.yaml#

-- 
2.53.0

