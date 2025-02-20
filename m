From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 20 Feb 2025 12:57:35 +0100
Subject: [PATCH v3] dt-bindings: crypto: Convert fsl,sec-2.0 to YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250220-ppcyaml-crypto-v3-1-99eedece4821@posteo.net>
X-B4-Tracking: v=1; b=H4sIAK4Yt2cC/x3MQQqAIBBA0avIrBNkMoSuEi1MpxqoFI0owrsnL
 d/i/xcyJaYMvXgh0cWZw1HRNgLcao+FJPtqQIWdQlQyRvfYfZMuPfEM0hpCbCftTaehRjHRzPc
 /HMZSPjfRTBlgAAAA
X-Change-ID: 20250220-ppcyaml-crypto-a7e223b4d754
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.li@nxp.com>
Cc: linux-crypto@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Frank Li <Frank.Li@nxp.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740052674; l=9885;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=VQI1SwSdvA5Go+l/EHI4sUuSgV2LauJEg+kWzJK6GOw=;
 b=x3IasRC/Ho9CRrJKeqYk7FLqIMfkqwc6vSHwJfIsuy9gTm8wLozpB5f2oGxAq6KLN7tkePAaJ
 HXVkxn9Z2CHDHxygNco7hk+nDLohsFq5ls8j4UTmx1+mGxLcVYzcq1/
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert the Freescale security engine (crypto accelerator) binding from
text form to YAML. The list of compatible strings reflects what was
previously described in prose; not all combinations occur in existing
devicetrees.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
V3:
- split out as a single patch
- Add Frank Li's R-b tag
- fix typo in email address syntax
- normalize spelling of "descriptor type", and reformat the description
  of fsl,descriptor-types-mask for readability
- add missing end-of-document marker (...)

V2:
- part of series [PATCH v2 00/12] YAML conversion of several Freescale/PowerPC DT bindings
  Link: https://lore.kernel.org/lkml/20250207-ppcyaml-v2-3-8137b0c42526@posteo.net/
- several improvements suggested by Rob Herring:
  - remove unnecessary multiline markers
  - constrain fsl,num-channels to enum: [1,4]
  - constrain fsl,channel-fifo-len to plausible limits
  - constrain fsl,exec-units-mask to maximum=0xfff
- trim subject line (remove "binding")
---
 .../devicetree/bindings/crypto/fsl,sec2.0.yaml     | 144 +++++++++++++++++++++
 .../devicetree/bindings/crypto/fsl-sec2.txt        |  65 ----------
 2 files changed, 144 insertions(+), 65 deletions(-)

diff --git a/Documentation/devicetree/bindings/crypto/fsl,sec2.0.yaml b/Documentation/devicetree/bindings/crypto/fsl,sec2.0.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..2091b89bb726b1bb8437916550810e925a345067
--- /dev/null
+++ b/Documentation/devicetree/bindings/crypto/fsl,sec2.0.yaml
@@ -0,0 +1,144 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/crypto/fsl,sec2.0.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Freescale SoC SEC Security Engines versions 1.x-2.x-3.x
+
+maintainers:
+  - J. Neuschäfer <j.ne@posteo.net>
+
+properties:
+  compatible:
+    description:
+      Should contain entries for this and backward compatible SEC versions,
+      high to low. Warning - SEC1 and SEC2 are mutually exclusive.
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
+    enum: [ 1, 4 ]
+    description: An integer representing the number of channels available.
+
+  fsl,channel-fifo-len:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    maximum: 100
+    description:
+      An integer representing the number of descriptor pointers each channel
+      fetch fifo can hold.
+
+  fsl,exec-units-mask:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    maximum: 0xfff
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
+        bit 0  = SEC supports descriptor type aesu_ctr_nonsnoop
+        bit 1  = SEC supports descriptor type ipsec_esp
+        bit 2  = SEC supports descriptor type common_nonsnoop
+        bit 3  = SEC supports descriptor type 802.11i AES ccmp
+        bit 4  = SEC supports descriptor type hmac_snoop_no_afeu
+        bit 5  = SEC supports descriptor type srtp
+        bit 6  = SEC supports descriptor type non_hmac_snoop_no_afeu
+        bit 7  = SEC supports descriptor type pkeu_assemble
+        bit 8  = SEC supports descriptor type aesu_key_expand_output
+        bit 9  = SEC supports descriptor type pkeu_ptmul
+        bit 10 = SEC supports descriptor type common_nonsnoop_afeu
+        bit 11 = SEC supports descriptor type pkeu_ptadd_dbl
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
+
+...
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

---
base-commit: 2014c95afecee3e76ca4a56956a936e23283f05b
change-id: 20250220-ppcyaml-crypto-a7e223b4d754

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

