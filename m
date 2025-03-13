From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 13 Mar 2025 22:35:45 +0100
Subject: [PATCH v4 2/4] dt-bindings: memory-controllers: Add
 fsl,elbc-gpcm-uio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250313-ppcyaml-elbc-v4-2-55903722d9ea@posteo.net>
References: <20250313-ppcyaml-elbc-v4-0-55903722d9ea@posteo.net>
In-Reply-To: <20250313-ppcyaml-elbc-v4-0-55903722d9ea@posteo.net>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, Crystal Wood <oss@buserror.net>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>
Cc: Frank Li <Frank.Li@nxp.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-mtd@lists.infradead.org, 
 linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741901745; l=2466;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=GqmRkAlOewBuTl80Xuqu1vck/4Qgv6V5ggfAWvSwWKQ=;
 b=wZeK9XEU61C7ky528WxfxleojI3r9yrM8qUzgijGXLV4l9QQ4TjOLOv5yUDEA4CBKOtuWtlnT
 HTOsyhSE2xTBXvX8GopYmSWIBsRpEmgSPf795+QssgqqpNTNNRkl6Yq
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Formalize the binding already supported by the uio_fsl_elbc_gpcm.c
driver.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

V4:
- no changes

V3:
- add review tags

V2:
- split out from fsl,elbc patch
- add description
- remove "device_type" property
- move to bindings/memory-controllers
---
 .../memory-controllers/fsl,elbc-gpcm-uio.yaml      | 59 ++++++++++++++++++++++
 1 file changed, 59 insertions(+)

diff --git a/Documentation/devicetree/bindings/memory-controllers/fsl,elbc-gpcm-uio.yaml b/Documentation/devicetree/bindings/memory-controllers/fsl,elbc-gpcm-uio.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..381584b400a0ad98c6d9e0b38f2877d44603ed84
--- /dev/null
+++ b/Documentation/devicetree/bindings/memory-controllers/fsl,elbc-gpcm-uio.yaml
@@ -0,0 +1,59 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/memory-controllers/fsl,elbc-gpcm-uio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Userspace I/O interface for Freescale eLBC devices
+
+description:
+  The Freescale Enhanced Local Bus controller (eLBC) supports flexible access
+  to memory devices, through the General-Purpose Chip-select Machine (GPCM).
+  The purpose of this binding is to designate devices attached to eLBC/GPMC for
+  use by userspace.
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+properties:
+  compatible:
+    const: fsl,elbc-gpcm-uio
+
+  reg:
+    maxItems: 1
+
+  elbc-gpcm-br:
+    description: Base Register (BR) value to set
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  elbc-gpcm-or:
+    description: Option Register (OR) value to set
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  interrupts:
+    maxItems: 1
+
+  uio_name:
+    $ref: /schemas/types.yaml#/definitions/string
+
+required:
+  - compatible
+  - reg
+  - elbc-gpcm-br
+  - elbc-gpcm-or
+
+additionalProperties: false
+
+examples:
+  - |
+    localbus {
+        #address-cells = <2>;
+        #size-cells = <1>;
+
+        simple-periph@2,0 {
+            compatible = "fsl,elbc-gpcm-uio";
+            reg = <0x2 0x0 0x10000>;
+            elbc-gpcm-br = <0xfd810800>;
+            elbc-gpcm-or = <0xffff09f7>;
+        };
+    };

-- 
2.48.0.rc1.219.gb6b6757d772

