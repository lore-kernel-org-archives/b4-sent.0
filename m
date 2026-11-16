From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 16 Nov 2026 12:55:09 +0100
Subject: [PATCH v3 2/8] dt-bindings: riscv: Add MIPS Boston board
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-p8700-dts-v3-2-ec5d4b7de39f@htecgroup.com>
References: <20261116-p8700-dts-v3-0-ec5d4b7de39f@htecgroup.com>
In-Reply-To: <20261116-p8700-dts-v3-0-ec5d4b7de39f@htecgroup.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Anup Patel <anup@brainfault.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Inochi Amaoto <inochiama@outlook.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Conor Dooley <conor@kernel.org>, linux-riscv@lists.infradead.org, 
 Vladimir Kondratiev <vladimir.kondratiev@mobileye.com>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Joel Stanley <joel@jms.id.au>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794830124; l=1692;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=5xVOseiOua96OFvJrDMkH+ySfMmO2vu4mBB4SPO9IZo=;
 b=CFEMhFviJqzLiCWV/idM/1CfSBhuzsjSnorw0V62mkGAPjmQbpm486MJVAKXrKB7Wv7rMNzA7
 Oov0uPhn1bdC8rr0d20Fzijr3aNlmdAlcC6SW4CawWXCWnGhQt73R9r
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the MIPS Boston board compatible with a P8700 bitfile.

Co-developed-by: Djordje Todorovic <djordje.todorovic@htecgroup.com>
Signed-off-by: Djordje Todorovic <djordje.todorovic@htecgroup.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 Documentation/devicetree/bindings/riscv/mips.yaml | 33 +++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/Documentation/devicetree/bindings/riscv/mips.yaml b/Documentation/devicetree/bindings/riscv/mips.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..bb251a7b1bcc762876fb94f0b636415774024183
--- /dev/null
+++ b/Documentation/devicetree/bindings/riscv/mips.yaml
@@ -0,0 +1,33 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/riscv/mips.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: MIPS SoC-based boards
+
+maintainers:
+  - Djordje Todorovic <djordje.todorovic@htecgroup.com>
+  - Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
+
+description:
+  MIPS SoC-based boards
+
+properties:
+  $nodename:
+    const: '/'
+  compatible:
+    oneOf:
+      - description: |
+          Boston FPGA development board with a MIPS P8700 bitfile
+
+          The Boston board carries a Xilinx XC7V2000T FPGA and fixed
+          peripherals: a Xilinx AXI PCIe root port, an Intel EG20T PCH,
+          a UART and an ASCII LCD.
+        items:
+          - const: mips,p8700-boston-rtl-5057225-202410011144
+          - const: mips,p8700-boston
+
+additionalProperties: true
+
+...

-- 
2.43.0

