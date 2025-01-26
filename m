From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 26 Jan 2025 19:58:58 +0100
Subject: [PATCH 3/9] dt-bindings: crypto: Convert fsl,sec-2.0 binding to
 YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250126-ppcyaml-v1-3-50649f51c3dd@posteo.net>
References: <20250126-ppcyaml-v1-0-50649f51c3dd@posteo.net>
In-Reply-To: <20250126-ppcyaml-v1-0-50649f51c3dd@posteo.net>
To: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org
Cc: Scott Wood <oss@buserror.net>, 
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737917943; l=9001;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=VuKZobngmGKB8eeYhzOACw9r9WKNsafw5qCcGq+aZKI=;
 b=vN1jl9emxv1uwCj8Z5ZFgm0z0SMh3aUHRcOxQoz75+tAAAcYM4po+3r+Nh2GOXowbE+pwx4lI
 e/0jGLqgWhrAXhj8i6wxcVSPeamPzfC1etq1H1ixtWh9aYV7zjj4e4u
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert the Freescale security engine (crypto accelerator) binding from
text form to YAML. The list of compatible strings reflects what was
previously described in prose; not all combinations occur in existing
devicetrees.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 .../devicetree/bindings/crypto/fsl,sec2.0.yaml     | 139 +++++++++++++++++++++
 .../devicetree/bindings/crypto/fsl-sec2.txt        |  65 ----------
 2 files changed, 139 insertions(+), 65 deletions(-)

diff --git a/Documentation/devicetree/bindings/crypto/fsl,sec2.0.yaml b/Documentation/devicetree/bindings/crypto/fsl,sec2.0.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..5ae593e60987e175413c3a082c9466f09f642bc4
--- /dev/null
+++ b/Documentation/devicetree/bindings/crypto/fsl,sec2.0.yaml
@@ -0,0 +1,139 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/crypto/fsl,sec2.0.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale SoC SEC Security Engines versions 1.x-2.x-3.x
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net.
+
+properties:
+  compatible:
+    description: |
+      Should contain entries for this and backward compatible SEC versions,
+      high to low. Warning: SEC1 and SEC2 are mutually exclusive.
+    oneOf:
+      - items:
+          - const: fsl,sec3.3
+          - const: fsl,sec3.1
+          - const: fsl,sec3.0
+          - const: fsl,sec2.4
+          - const: fsl,sec2.2
+          - const: fsl,sec2.1
+          - const: fsl,sec2.0
+      - items:
+          - const: fsl,sec3.1
+          - const: fsl,sec3.0
+          - const: fsl,sec2.4
+          - const: fsl,sec2.2
+          - const: fsl,sec2.1
+          - const: fsl,sec2.0
+      - items:
+          - const: fsl,sec3.0
+          - const: fsl,sec2.4
+          - const: fsl,sec2.2
+          - const: fsl,sec2.1
+          - const: fsl,sec2.0
+      - items:
+          - const: fsl,sec2.4
+          - const: fsl,sec2.2
+          - const: fsl,sec2.1
+          - const: fsl,sec2.0
+      - items:
+          - const: fsl,sec2.2
+          - const: fsl,sec2.1
+          - const: fsl,sec2.0
+      - items:
+          - const: fsl,sec2.1
+          - const: fsl,sec2.0
+      - items:
+          - const: fsl,sec2.0
+      - items:
+          - const: fsl,sec1.2
+          - const: fsl,sec1.0
+      - items:
+          - const: fsl,sec1.0
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  fsl,num-channels:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: An integer representing the number of channels available.
+
+  fsl,channel-fifo-len:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: |
+      An integer representing the number of descriptor pointers each channel
+      fetch fifo can hold.
+
+  fsl,exec-units-mask:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: |
+      The bitmask representing what execution units (EUs) are available.
+      EU information should be encoded following the SEC's Descriptor Header
+      Dword EU_SEL0 field documentation, i.e. as follows:
+
+        bit 0  = reserved - should be 0
+        bit 1  = set if SEC has the ARC4 EU (AFEU)
+        bit 2  = set if SEC has the DES/3DES EU (DEU)
+        bit 3  = set if SEC has the message digest EU (MDEU/MDEU-A)
+        bit 4  = set if SEC has the random number generator EU (RNG)
+        bit 5  = set if SEC has the public key EU (PKEU)
+        bit 6  = set if SEC has the AES EU (AESU)
+        bit 7  = set if SEC has the Kasumi EU (KEU)
+        bit 8  = set if SEC has the CRC EU (CRCU)
+        bit 11 = set if SEC has the message digest EU extended alg set (MDEU-B)
+
+      remaining bits are reserved for future SEC EUs.
+
+  fsl,descriptor-types-mask:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: |
+      The bitmask representing what descriptors are available. Descriptor type
+      information should be encoded following the SEC's Descriptor Header Dword
+      DESC_TYPE field documentation, i.e. as follows:
+
+        bit 0  = set if SEC supports the aesu_ctr_nonsnoop desc. type
+        bit 1  = set if SEC supports the ipsec_esp descriptor type
+        bit 2  = set if SEC supports the common_nonsnoop desc. type
+        bit 3  = set if SEC supports the 802.11i AES ccmp desc. type
+        bit 4  = set if SEC supports the hmac_snoop_no_afeu desc. type
+        bit 5  = set if SEC supports the srtp descriptor type
+        bit 6  = set if SEC supports the non_hmac_snoop_no_afeu desc.type
+        bit 7  = set if SEC supports the pkeu_assemble descriptor type
+        bit 8  = set if SEC supports the aesu_key_expand_output desc.type
+        bit 9  = set if SEC supports the pkeu_ptmul descriptor type
+        bit 10 = set if SEC supports the common_nonsnoop_afeu desc. type
+        bit 11 = set if SEC supports the pkeu_ptadd_dbl descriptor type
+
+      ..and so on and so forth.
+
+required:
+  - compatible
+  - reg
+  - fsl,num-channels
+  - fsl,channel-fifo-len
+  - fsl,exec-units-mask
+  - fsl,descriptor-types-mask
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    /* MPC8548E */
+    crypto@30000 {
+        compatible = "fsl,sec2.1", "fsl,sec2.0";
+        reg = <0x30000 0x10000>;
+        interrupts = <29 2>;
+        interrupt-parent = <&mpic>;
+        fsl,num-channels = <4>;
+        fsl,channel-fifo-len = <24>;
+        fsl,exec-units-mask = <0xfe>;
+        fsl,descriptor-types-mask = <0x12b0ebf>;
+    };
diff --git a/Documentation/devicetree/bindings/crypto/fsl-sec2.txt b/Documentation/devicetree/bindings/crypto/fsl-sec2.txt
deleted file mode 100644
index 125f155d00d052eec7d5093b5c5076cbe720417f..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/crypto/fsl-sec2.txt
+++ /dev/null
@@ -1,65 +0,0 @@
-Freescale SoC SEC Security Engines versions 1.x-2.x-3.x
-
-Required properties:
-
-- compatible : Should contain entries for this and backward compatible
-  SEC versions, high to low, e.g., "fsl,sec2.1", "fsl,sec2.0" (SEC2/3)
-                             e.g., "fsl,sec1.2", "fsl,sec1.0" (SEC1)
-    warning: SEC1 and SEC2 are mutually exclusive
-- reg : Offset and length of the register set for the device
-- interrupts : the SEC's interrupt number
-- fsl,num-channels : An integer representing the number of channels
-  available.
-- fsl,channel-fifo-len : An integer representing the number of
-  descriptor pointers each channel fetch fifo can hold.
-- fsl,exec-units-mask : The bitmask representing what execution units
-  (EUs) are available. It's a single 32-bit cell. EU information
-  should be encoded following the SEC's Descriptor Header Dword
-  EU_SEL0 field documentation, i.e. as follows:
-
-	bit 0  = reserved - should be 0
-	bit 1  = set if SEC has the ARC4 EU (AFEU)
-	bit 2  = set if SEC has the DES/3DES EU (DEU)
-	bit 3  = set if SEC has the message digest EU (MDEU/MDEU-A)
-	bit 4  = set if SEC has the random number generator EU (RNG)
-	bit 5  = set if SEC has the public key EU (PKEU)
-	bit 6  = set if SEC has the AES EU (AESU)
-	bit 7  = set if SEC has the Kasumi EU (KEU)
-	bit 8  = set if SEC has the CRC EU (CRCU)
-	bit 11 = set if SEC has the message digest EU extended alg set (MDEU-B)
-
-remaining bits are reserved for future SEC EUs.
-
-- fsl,descriptor-types-mask : The bitmask representing what descriptors
-  are available. It's a single 32-bit cell. Descriptor type information
-  should be encoded following the SEC's Descriptor Header Dword DESC_TYPE
-  field documentation, i.e. as follows:
-
-	bit 0  = set if SEC supports the aesu_ctr_nonsnoop desc. type
-	bit 1  = set if SEC supports the ipsec_esp descriptor type
-	bit 2  = set if SEC supports the common_nonsnoop desc. type
-	bit 3  = set if SEC supports the 802.11i AES ccmp desc. type
-	bit 4  = set if SEC supports the hmac_snoop_no_afeu desc. type
-	bit 5  = set if SEC supports the srtp descriptor type
-	bit 6  = set if SEC supports the non_hmac_snoop_no_afeu desc.type
-	bit 7  = set if SEC supports the pkeu_assemble descriptor type
-	bit 8  = set if SEC supports the aesu_key_expand_output desc.type
-	bit 9  = set if SEC supports the pkeu_ptmul descriptor type
-	bit 10 = set if SEC supports the common_nonsnoop_afeu desc. type
-	bit 11 = set if SEC supports the pkeu_ptadd_dbl descriptor type
-
-  ..and so on and so forth.
-
-Example:
-
-	/* MPC8548E */
-	crypto@30000 {
-		compatible = "fsl,sec2.1", "fsl,sec2.0";
-		reg = <0x30000 0x10000>;
-		interrupts = <29 2>;
-		interrupt-parent = <&mpic>;
-		fsl,num-channels = <4>;
-		fsl,channel-fifo-len = <24>;
-		fsl,exec-units-mask = <0xfe>;
-		fsl,descriptor-types-mask = <0x12b0ebf>;
-	};

-- 
2.48.0.rc1.219.gb6b6757d772

