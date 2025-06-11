From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 11 Jun 2025 11:42:09 +0200
Subject: [PATCH v2] dt-bindings: interrupt-controller: Convert fsl,mpic-msi
 to YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250611-msipic-yaml-v2-1-f2e174c48802@posteo.net>
X-B4-Tracking: v=1; b=H4sIAHBPSWgC/1XMQQ7CIBCF4as0sxYDFIpx1XuYLmod7CS2ECDEp
 uHuYl25/F/yvh0iBsII12aHgJkiubWGPDUwzeP6REaP2iC51FzKji2RPE1sG5cXMx22lvO71Yh
 QHz6gpfeh3YbaM8XkwnbgWXzXn6N4++dkwQSzSqqLMtoIZXvvYkJ3XjHBUEr5ANtsRX6nAAAA
X-Change-ID: 20250226-msipic-yaml-76e3f00bf5ee
To: Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Crystal Wood <oss@buserror.net>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749634936; l=12697;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=93Rhmig5L5zB9a0kXFywVlymV8E3tuGkGjN+qrmRYXs=;
 b=WgwFZpfj419E3pvGAJeIH8mxbS4ecOCGH3SgnDGBj44TW4SzTp907y0qLD83/fZkKKKaNUNmr
 J7Lmzs7OPXrCALZKQ8P2bp7XWx5T3tO6Cy3cigQCAajIn8OpCX8Pr6Y
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As part of a larger effort to bring various PowerPC-related bindings
into the YAML world, this patch converts msi-pic.txt to YAML and moves
it into the bindings/interrupt-controller/ directory. The conversion may
necessarily be a bit hard to read because the binding is quite verbose.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Rebase on v6.16-rc1
- Address Conor Dooley's review comments:
  - Add multiline marker (|) to preserve formatting
  - Split 'reg' list in second example
  - Rewrite version dependent information as an if/else schema

Link to v1: https://lore.kernel.org/r/20250403-msipic-yaml-v1-1-f4248475714f@posteo.net
---
---
 .../interrupt-controller/fsl,mpic-msi.yaml         | 161 +++++++++++++++++++++
 .../devicetree/bindings/powerpc/fsl/msi-pic.txt    | 111 --------------
 2 files changed, 161 insertions(+), 111 deletions(-)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/fsl,mpic-msi.yaml b/Documentation/devicetree/bindings/interrupt-controller/fsl,mpic-msi.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..89db7742c28b3650207b361bfa6fbaf4e69ccc45
--- /dev/null
+++ b/Documentation/devicetree/bindings/interrupt-controller/fsl,mpic-msi.yaml
@@ -0,0 +1,161 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/interrupt-controller/fsl,mpic-msi.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale MSI interrupt controller
+
+description: |
+  The Freescale hypervisor and msi-address-64
+  -------------------------------------------
+
+  Normally, PCI devices have access to all of CCSR via an ATMU mapping.  The
+  Freescale MSI driver calculates the address of MSIIR (in the MSI register
+  block) and sets that address as the MSI message address.
+
+  In a virtualized environment, the hypervisor may need to create an IOMMU
+  mapping for MSIIR.  The Freescale ePAPR hypervisor has this requirement
+  because of hardware limitations of the Peripheral Access Management Unit
+  (PAMU), which is currently the only IOMMU that the hypervisor supports.
+  The ATMU is programmed with the guest physical address, and the PAMU
+  intercepts transactions and reroutes them to the true physical address.
+
+  In the PAMU, each PCI controller is given only one primary window.  The
+  PAMU restricts DMA operations so that they can only occur within a window.
+  Because PCI devices must be able to DMA to memory, the primary window must
+  be used to cover all of the guest's memory space.
+
+  PAMU primary windows can be divided into 256 subwindows, and each
+  subwindow can have its own address mapping ("guest physical" to "true
+  physical").  However, each subwindow has to have the same alignment, which
+  means they cannot be located at just any address.  Because of these
+  restrictions, it is usually impossible to create a 4KB subwindow that
+  covers MSIIR where it's normally located.
+
+  Therefore, the hypervisor has to create a subwindow inside the same
+  primary window used for memory, but mapped to the MSIR block (where MSIIR
+  lives).  The first subwindow after the end of guest memory is used for
+  this.  The address specified in the msi-address-64 property is the PCI
+  address of MSIIR.  The hypervisor configures the PAMU to map that address to
+  the true physical address of MSIIR.
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+properties:
+  compatible:
+    oneOf:
+      - enum:
+          - fsl,mpic-msi
+          - fsl,mpic-msi-v4.3
+          - fsl,ipic-msi
+          - fsl,vmpic-msi
+          - fsl,vmpic-msi-v4.3
+      - items:
+          - enum:
+              - fsl,mpc8572-msi
+              - fsl,mpc8610-msi
+              - fsl,mpc8641-msi
+          - const: fsl,mpic-msi
+
+  reg:
+    minItems: 1
+    items:
+      - description: Address and length of the shared message interrupt
+          register set
+      - description: Address of aliased MSIIR or MSIIR1 register for platforms
+          that have such an alias. If using MSIIR1, the second region must be
+          added because different MSI group has different MSIIR1 offset.
+
+  interrupts:
+    minItems: 1
+    maxItems: 16
+    description:
+      Each one of the interrupts here is one entry per 32 MSIs, and routed to
+      the host interrupt controller. The interrupts should be set as edge
+      sensitive. If msi-available-ranges is present, only the interrupts that
+      correspond to available ranges shall be present.
+
+  msi-available-ranges:
+    $ref: /schemas/types.yaml#/definitions/uint32-matrix
+    items:
+      items:
+        - description: First MSI interrupt in this range
+        - description: Number of MSI interrupts in this range
+    description:
+      Define which MSI interrupt can be used in the 256 MSI interrupts.
+      If not specified, all the MSI interrupts can be used.
+      Each available range must begin and end on a multiple of 32 (i.e. no
+      splitting an individual MSI register or the associated PIC interrupt).
+
+  msi-address-64:
+    $ref: /schemas/types.yaml#/definitions/uint64
+    description:
+      64-bit PCI address of the MSIIR register. The MSIIR register is used for
+      MSI messaging.  The address of MSIIR in PCI address space is the MSI
+      message address.
+
+      This property may be used in virtualized environments where the hypervisor
+      has created an alternate mapping for the MSIR block.  See the top-level
+      description for an explanation.
+
+required:
+  - compatible
+  - reg
+  - interrupts
+
+anyOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - fsl,mpic-msi-v4.3
+              - fsl,vmpic-msi-v4.3
+    then:
+      properties:
+        interrupts:
+          maxItems: 16
+          description:
+            Version 4.3 implies that there are 16 shared interrupts, and they
+            are configured through MSIIR1.
+
+        # MPIC v4.3 does not support this property because the 32 interrupts of
+        # an individual register are not continuous when using MSIIR1.
+        msi-available-ranges: false
+
+        reg:
+          minItems: 2
+
+    else:
+      properties:
+        interrupts:
+          maxItems: 8
+          description:
+            In versions before 4.3, only 8 shared interrupts are available, and
+            they are configured through MSIIR.
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    msi@41600 {
+            compatible = "fsl,mpc8610-msi", "fsl,mpic-msi";
+            reg = <0x41600 0x80>;
+            msi-available-ranges = <0 0x100>;
+            interrupts = <0xe0 0>, <0xe1 0>, <0xe2 0>, <0xe3 0>,
+                         <0xe4 0>, <0xe5 0>, <0xe6 0>, <0xe7 0>;
+    };
+
+  - |
+    msi@41600 {
+            compatible = "fsl,mpic-msi-v4.3";
+            reg = <0x41600 0x200>, <0x44148 4>;
+            interrupts = <0xe0 0 0 0>, <0xe1 0 0 0>, <0xe2 0 0 0>, <0xe3 0 0 0>,
+                         <0xe4 0 0 0>, <0xe5 0 0 0>, <0xe6 0 0 0>, <0xe7 0 0 0>,
+                         <0x100 0 0 0>, <0x101 0 0 0>, <0x102 0 0 0>, <0x103 0 0 0>,
+                         <0x104 0 0 0>, <0x105 0 0 0>, <0x106 0 0 0>, <0x107 0 0 0>;
+    };
+
+...
diff --git a/Documentation/devicetree/bindings/powerpc/fsl/msi-pic.txt b/Documentation/devicetree/bindings/powerpc/fsl/msi-pic.txt
deleted file mode 100644
index f8d2b7fe06d695971d48ba21ab67e5b72a212fe9..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/powerpc/fsl/msi-pic.txt
+++ /dev/null
@@ -1,111 +0,0 @@
-* Freescale MSI interrupt controller
-
-Required properties:
-- compatible : compatible list, may contain one or two entries
-  The first is "fsl,CHIP-msi", where CHIP is the processor(mpc8610, mpc8572,
-  etc.) and the second is "fsl,mpic-msi" or "fsl,ipic-msi" or
-  "fsl,mpic-msi-v4.3" depending on the parent type and version. If mpic
-  version is 4.3, the number of MSI registers is increased to 16, MSIIR1 is
-  provided to access these 16 registers, and compatible "fsl,mpic-msi-v4.3"
-  should be used. The first entry is optional; the second entry is
-  required.
-
-- reg : It may contain one or two regions. The first region should contain
-  the address and the length of the shared message interrupt register set.
-  The second region should contain the address of aliased MSIIR or MSIIR1
-  register for platforms that have such an alias, if using MSIIR1, the second
-  region must be added because different MSI group has different MSIIR1 offset.
-
-- interrupts : each one of the interrupts here is one entry per 32 MSIs,
-  and routed to the host interrupt controller. the interrupts should
-  be set as edge sensitive.  If msi-available-ranges is present, only
-  the interrupts that correspond to available ranges shall be present.
-
-Optional properties:
-- msi-available-ranges: use <start count> style section to define which
-  msi interrupt can be used in the 256 msi interrupts. This property is
-  optional, without this, all the MSI interrupts can be used.
-  Each available range must begin and end on a multiple of 32 (i.e.
-  no splitting an individual MSI register or the associated PIC interrupt).
-  MPIC v4.3 does not support this property because the 32 interrupts of an
-  individual register are not continuous when using MSIIR1.
-
-- msi-address-64: 64-bit PCI address of the MSIIR register. The MSIIR register
-  is used for MSI messaging.  The address of MSIIR in PCI address space is
-  the MSI message address.
-
-  This property may be used in virtualized environments where the hypervisor
-  has created an alternate mapping for the MSIR block.  See below for an
-  explanation.
-
-
-Example:
-	msi@41600 {
-		compatible = "fsl,mpc8610-msi", "fsl,mpic-msi";
-		reg = <0x41600 0x80>;
-		msi-available-ranges = <0 0x100>;
-		interrupts = <
-			0xe0 0
-			0xe1 0
-			0xe2 0
-			0xe3 0
-			0xe4 0
-			0xe5 0
-			0xe6 0
-			0xe7 0>;
-		interrupt-parent = <&mpic>;
-	};
-
-	msi@41600 {
-		compatible = "fsl,mpic-msi-v4.3";
-		reg = <0x41600 0x200 0x44148 4>;
-		interrupts = <
-			0xe0 0 0 0
-			0xe1 0 0 0
-			0xe2 0 0 0
-			0xe3 0 0 0
-			0xe4 0 0 0
-			0xe5 0 0 0
-			0xe6 0 0 0
-			0xe7 0 0 0
-			0x100 0 0 0
-			0x101 0 0 0
-			0x102 0 0 0
-			0x103 0 0 0
-			0x104 0 0 0
-			0x105 0 0 0
-			0x106 0 0 0
-			0x107 0 0 0>;
-	};
-
-The Freescale hypervisor and msi-address-64
--------------------------------------------
-Normally, PCI devices have access to all of CCSR via an ATMU mapping.  The
-Freescale MSI driver calculates the address of MSIIR (in the MSI register
-block) and sets that address as the MSI message address.
-
-In a virtualized environment, the hypervisor may need to create an IOMMU
-mapping for MSIIR.  The Freescale ePAPR hypervisor has this requirement
-because of hardware limitations of the Peripheral Access Management Unit
-(PAMU), which is currently the only IOMMU that the hypervisor supports.
-The ATMU is programmed with the guest physical address, and the PAMU
-intercepts transactions and reroutes them to the true physical address.
-
-In the PAMU, each PCI controller is given only one primary window.  The
-PAMU restricts DMA operations so that they can only occur within a window.
-Because PCI devices must be able to DMA to memory, the primary window must
-be used to cover all of the guest's memory space.
-
-PAMU primary windows can be divided into 256 subwindows, and each
-subwindow can have its own address mapping ("guest physical" to "true
-physical").  However, each subwindow has to have the same alignment, which
-means they cannot be located at just any address.  Because of these
-restrictions, it is usually impossible to create a 4KB subwindow that
-covers MSIIR where it's normally located.
-
-Therefore, the hypervisor has to create a subwindow inside the same
-primary window used for memory, but mapped to the MSIR block (where MSIIR
-lives).  The first subwindow after the end of guest memory is used for
-this.  The address specified in the msi-address-64 property is the PCI
-address of MSIIR.  The hypervisor configures the PAMU to map that address to
-the true physical address of MSIIR.

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250226-msipic-yaml-76e3f00bf5ee

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

