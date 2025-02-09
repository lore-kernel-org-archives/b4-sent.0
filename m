From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 09 Feb 2025 22:51:57 +0100
Subject: [PATCH v3 1/2] dt-bindings: media: i2c: Add DW9719 and DW9761 VCM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250209-dw9761dts-v3-1-14d3f00f0585@apitzsch.eu>
References: <20250209-dw9761dts-v3-0-14d3f00f0585@apitzsch.eu>
In-Reply-To: <20250209-dw9761dts-v3-0-14d3f00f0585@apitzsch.eu>
To: Daniel Scally <djrscally@gmail.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739137936; l=1650;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=VMCqVc24c9S5LJtNjPFsXe/GrcCNw3hzuYoj92Rfr3Y=;
 b=0ThCYlAuDhrGQ10YOxPYdp0nNASxxTKs4qP4uq+GUh8ksDVdew/NEv8VR7yZ8JVep7D5+nFdJ
 DNxu9OmClHdDQiVgp2oIazWRuJz7qo6gx8lmz0RiosuwVgCsT2vzvqi
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document Dongwoon DW9719 and DW9761 VCM devicetree bindings.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 .../bindings/media/i2c/dongwoon,dw9719.yaml        | 45 ++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9719.yaml b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9719.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..b38d22bf09713a7999e1f9ce6553de7587dbe5d2
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9719.yaml
@@ -0,0 +1,45 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/i2c/dongwoon,dw9719.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Dongwoon Anatech DW9719 Voice Coil Motor (VCM) Controller
+
+maintainers:
+  - devicetree@vger.kernel.org
+
+description:
+  The Dongwoon DW9719 is a 10-bit digital-to-analog (DAC) converter. The DAC
+  is controlled via a 2-wire (I2C-compatible) serial interface.
+
+properties:
+  compatible:
+    enum:
+      - dongwoon,dw9719
+      - dongwoon,dw9761
+
+  reg:
+    maxItems: 1
+
+  vdd-supply:
+    description: Regulator providing power to the "VDD" pin.
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
+        camera-lens@c {
+            compatible = "dongwoon,dw9761";
+            reg = <0x0c>;
+            vdd-supply = <&pm8916_l10>;
+        };
+    };

-- 
2.48.1

