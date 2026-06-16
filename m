From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Tue, 16 Jun 2026 18:03:37 +0200
Subject: [PATCH v9 1/3] dt-bindings: timer: mips,p8700-gcru
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-riscv-time-mmio-v9-1-03af7bc8f2d8@htecgroup.com>
References: <20260616-riscv-time-mmio-v9-0-03af7bc8f2d8@htecgroup.com>
In-Reply-To: <20260616-riscv-time-mmio-v9-0-03af7bc8f2d8@htecgroup.com>
To: Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Paul Walmsley <pjw@kernel.org>, 
 John Stultz <jstultz@google.com>, Stephen Boyd <sboyd@kernel.org>, 
 Vivian Wang <wangruikang@iscas.ac.cn>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Chao-ying Fu <cfu@mips.com>, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781625819; l=1839;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=3ID8Av8rSUgllKXPW8NF381c9MC7TR+0AZClpf5xwBU=;
 b=VCQiNxZXqb9FlMdtl4eIz/ets/STHbyYu7uYtL+o9NCje20gp+5RR4DMiFx4gvdOkDCXQ+FXK
 PWgzEXk0RZGAteFLOvf5X/5cVWSk+0PaH9z+Ny0fVfgXdb+ZbdQQjwO
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add dt-bindings for the GCR.U memory mapped timer device for RISC-V
platforms. The GCR.U memory region contains shadow copies of the RISC-V
mtime register and the hrtime Global Configuration Register.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
---
 .../devicetree/bindings/timer/mips,p8700-gcru.yaml | 38 ++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/Documentation/devicetree/bindings/timer/mips,p8700-gcru.yaml b/Documentation/devicetree/bindings/timer/mips,p8700-gcru.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..e6f25e769f461d58c87194fba3540eee13cb322b
--- /dev/null
+++ b/Documentation/devicetree/bindings/timer/mips,p8700-gcru.yaml
@@ -0,0 +1,38 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/timer/mips,p8700-gcru.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: GCR.U timer device for the MIPS P8700 platform
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
+    const: mips,p8700-gcru
+
+  reg:
+    items:
+      - description: Read-only shadow copy of the RISC-V mtime register.
+      - description: Read-only shadow copy of the P8700 high resolution timer register.
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    timer@1617f050 {
+        compatible = "mips,p8700-gcru";
+        reg = <0x1617f050 0x8>,
+              <0x1617f090 0x8>;
+    };

-- 
2.43.0

