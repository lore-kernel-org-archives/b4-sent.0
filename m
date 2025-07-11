From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Fri, 11 Jul 2025 23:56:45 +0200
Subject: [PATCH v5 1/2] dt-bindings: timer: mti,gcru
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250711-riscv-time-mmio-v5-1-9ed1f825ad5e@htecgroup.com>
References: <20250711-riscv-time-mmio-v5-0-9ed1f825ad5e@htecgroup.com>
In-Reply-To: <20250711-riscv-time-mmio-v5-0-9ed1f825ad5e@htecgroup.com>
To: Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752271040; l=1784;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=/RHTs/dV8mK/r/ATCMy9xGEu8RznHBlNizMjaxes10Y=;
 b=oI3VZOfvBk9iNRCP9pJILM0FDdGES1Zpw+I5p/t4/+vK/OLwUC9L6nIK4WxhmEhnYP6j6Z/7J
 RomrV/dRnyPCm87Fei9SDZn7Ne70mYLU6Yj+FVhd6baabG0pO6qyC7w
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add dt-bindings for the GCR.U memory mapped timer device for RISC-V
platforms. The GCR.U memory region contains shadow copies of the RISC-V
mtime register and the hrtime Global Configuration Register.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
---
 .../devicetree/bindings/timer/mti,gcru.yaml        | 38 ++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/Documentation/devicetree/bindings/timer/mti,gcru.yaml b/Documentation/devicetree/bindings/timer/mti,gcru.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..ceaf90bad5332b64f3c1f28bebdc28d78443898a
--- /dev/null
+++ b/Documentation/devicetree/bindings/timer/mti,gcru.yaml
@@ -0,0 +1,38 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/timer/mti,gcru.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: GCR.U timer device for RISC-V platforms
+
+maintainers:
+  - Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
+
+description:
+  The GCR.U memory region contains memory mapped shadow copies of
+  mtime and hrtime Global Configuration Registers,
+  which software can choose to make accessible from user mode.
+
+properties:
+  compatible:
+    const: mti,gcru
+
+  reg:
+    items:
+      - description: Read-only shadow copy of the RISC-V mtime register.
+      - description: Read-only shadow copy of the high resolution timer register.
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    timer@1617f000 {
+        compatible = "mti,gcru";
+        reg = <0x1617f050 0x8>,
+              <0x1617f090 0x8>;
+    };

-- 
2.34.1

