From: Andy Chung <Andy.Chung@amd.com>
Date: Tue, 21 Jul 2026 14:31:33 +0800
Subject: [PATCH v3 2/4] dt-bindings: hwmon: Add Kandou KB9002
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260721-kb9002-upstream-v3-2-70563922be8d@amd.com>
References: <20260721-kb9002-upstream-v3-0-70563922be8d@amd.com>
In-Reply-To: <20260721-kb9002-upstream-v3-0-70563922be8d@amd.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Chung <andy.chung@amd.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784615506; l=1702;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=aa6Ba0HXZ1SFh9Lr9jRG/ZUTYEiDVeuZYixRpDGrB3E=;
 b=plFEds/yrtTdxmmSuAPgU078J8bnqzroBLMJlZu7LeXHHimp6tUU9Z1KAAysKoT9StIWshhQE
 2cftKEaUG/qBm1TqloP0ypl4PpkuG5ilzggJMdVjlaJpYGZVR5t6Ko4
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree bindings for the Kandou KB9002 PCIe 5.0 retimer, an
SMBus target that exposes an aggregated die temperature.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
---
 .../devicetree/bindings/hwmon/kandou,kb9002.yaml   | 46 ++++++++++++++++++++++
 1 file changed, 46 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/kandou,kb9002.yaml b/Documentation/devicetree/bindings/hwmon/kandou,kb9002.yaml
new file mode 100644
index 000000000000..0d939c8aa734
--- /dev/null
+++ b/Documentation/devicetree/bindings/hwmon/kandou,kb9002.yaml
@@ -0,0 +1,46 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/hwmon/kandou,kb9002.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Kandou KB9002 PCIe 5.0 retimer
+
+maintainers:
+  - Andy Chung <andy.chung@amd.com>
+
+description: |
+  The Kandou KB9002 is an 8-lane PCIe 5.0 retimer that exposes a
+  firmware-controlled SMBus 3.0 target on its sideband interface.
+  The host can query the aggregated maximum die temperature and the
+  running firmware version through that target.
+
+  The 7-bit SMBus address is selected by three SMB_ADDR straps and
+  ranges from 0x20 to 0x27.
+
+properties:
+  compatible:
+    const: kandou,kb9002
+
+  reg:
+    items:
+      - minimum: 0x20
+        maximum: 0x27
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        retimer@20 {
+            compatible = "kandou,kb9002";
+            reg = <0x20>;
+        };
+    };

-- 
2.34.1

