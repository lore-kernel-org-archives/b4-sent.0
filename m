From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Thu, 10 Jul 2025 00:21:44 +0200
Subject: [PATCH v3 1/2] dt-bindings: gpu: Add Apple SoC GPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250710-sgx-dt-v3-1-299bb3a65109@gmail.com>
References: <20250710-sgx-dt-v3-0-299bb3a65109@gmail.com>
In-Reply-To: <20250710-sgx-dt-v3-0-299bb3a65109@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752099708; l=4053;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=ueufFqm5JgZMrOUFrDIeyDT9kbQhcJKg9fq4FWQiRKE=;
 b=+EwYGwIf1NLULyxb8K2xiug6EM5dpNzuQx4Jaj/shI8W4CfRAdYUWDxgWPFq7k1d9J1USpyN4
 ts+svCeFOh2AiWYPs60IxGgg/m1AD6VFlD61HbJbdTdvtRh9QXg1ke3
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the GPU present in Apple SoCs

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Reviewed-by: Sven Peter <sven@kernel.org>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 Documentation/devicetree/bindings/gpu/apple,agx.yaml | 94 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 MAINTAINERS                                          |  1 +
 2 files changed, 95 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpu/apple,agx.yaml b/Documentation/devicetree/bindings/gpu/apple,agx.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..51629b3833b0a8c296eaccdfd6d9eeef02a5bc63
--- /dev/null
+++ b/Documentation/devicetree/bindings/gpu/apple,agx.yaml
@@ -0,0 +1,94 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/gpu/apple,agx.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple SoC GPU
+
+maintainers:
+  - Sasha Finkelstein <fnkl.kernel@gmail.com>
+
+properties:
+  compatible:
+    oneOf:
+      - enum:
+          - apple,agx-g13g
+          - apple,agx-g13s
+          - apple,agx-g14g
+      - items:
+          - enum:
+              - apple,agx-g13c
+              - apple,agx-g13d
+          - const: apple,agx-g13s
+
+  reg:
+    items:
+      - description: GPU coprocessor control registers
+      - description: GPU block MMIO registers
+
+  reg-names:
+    items:
+      - const: asc
+      - const: sgx
+
+  power-domains:
+    maxItems: 1
+
+  mboxes:
+    maxItems: 1
+
+  memory-region:
+    items:
+      - description: Region containing GPU MMU TTBs
+      - description: Region containing GPU MMU page tables
+      - description:
+          Region containing a shared handoff structure for VM
+          management coordination
+      - description: Calibration blob. Mostly power-related configuration
+      - description: Calibration blob. Mostly GPU-related configuration
+      - description: Shared global variables with GPU firmware
+
+  memory-region-names:
+    items:
+      - const: ttbs
+      - const: pagetables
+      - const: handoff
+      - const: hw-cal-a
+      - const: hw-cal-b
+      - const: globals
+
+  apple,firmware-abi:
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 3
+    description:
+      macOS version the current firmware is paired with, used to pick
+      the version of firmware ABI to be used.
+      Bootloader will overwrite this
+
+required:
+  - compatible
+  - reg
+  - mboxes
+  - memory-region
+  - apple,firmware-abi
+
+additionalProperties: false
+
+examples:
+  - |
+    gpu@6400000 {
+        compatible = "apple,agx-g13g";
+        reg = <0x6400000 0x40000>,
+              <0x4000000 0x1000000>;
+        reg-names = "asc", "sgx";
+        mboxes = <&agx_mbox>;
+        power-domains = <&ps_gfx>;
+        memory-region = <&uat_ttbs>, <&uat_pagetables>, <&uat_handoff>,
+                        <&gpu_hw_cal_a>, <&gpu_hw_cal_b>, <&gpu_globals>;
+        memory-region-names = "ttbs", "pagetables", "handoff",
+                              "hw-cal-a", "hw-cal-b", "globals";
+
+        apple,firmware-abi = <0 0 0>;
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index a92290fffa163f9fe8fe3f04bf66426f9a894409..2a32c9c4ee355a1109a3e2031ea3663c39cc8c68 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2331,6 +2331,7 @@ F:	Documentation/devicetree/bindings/arm/apple/*
 F:	Documentation/devicetree/bindings/clock/apple,nco.yaml
 F:	Documentation/devicetree/bindings/cpufreq/apple,cluster-cpufreq.yaml
 F:	Documentation/devicetree/bindings/dma/apple,admac.yaml
+F:	Documentation/devicetree/bindings/gpu/apple,agx.yaml
 F:	Documentation/devicetree/bindings/i2c/apple,i2c.yaml
 F:	Documentation/devicetree/bindings/input/touchscreen/apple,z2-multitouch.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/apple,*

-- 
2.50.1

