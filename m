From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 22 Jun 2026 22:55:38 -0700
Subject: [PATCH 2/3] dt-bindings: hwmon: pmbus: Support for onsemi's FD5121
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-support-fd5121-from-onsemi-v1-2-b31767689c65@onsemi.com>
References: <20260622-support-fd5121-from-onsemi-v1-0-b31767689c65@onsemi.com>
In-Reply-To: <20260622-support-fd5121-from-onsemi-v1-0-b31767689c65@onsemi.com>
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782194144; l=1429;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=Zw1KdNLpVYL6UZplq8A+h3jDYYOHRawnuaZFGAXmcFg=;
 b=5LwwDnJZbiIpKvcgN54cRezHu4qz681+0HrvqBMRvst7oLKuB54J8cRxlp0EyDzKDr9brEFXz
 r8spVsYORlJAjyxA4sFeFKc7xyY2n8ljxvfke9MxCY9eZUiyx0shcx1
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree schema for onsemi FD5121, FD5123, and
FD5125 dual rail, multi-phase digital controllers.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
 .../bindings/hwmon/pmbus/onnn,fd5121.yaml          | 41 ++++++++++++++++++++++
 1 file changed, 41 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/pmbus/onnn,fd5121.yaml b/Documentation/devicetree/bindings/hwmon/pmbus/onnn,fd5121.yaml
new file mode 100644
index 000000000000..b0453b0634f0
--- /dev/null
+++ b/Documentation/devicetree/bindings/hwmon/pmbus/onnn,fd5121.yaml
@@ -0,0 +1,41 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/hwmon/pmbus/onnn,fd5121.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: onsemi's multi-phase digital controllers
+
+maintainers:
+  - Selvamani Rajagopal <selvamani.rajagopal@onsemi.com>
+
+description:
+  onsemi multi-phase digital controllers with PMBus.
+
+properties:
+  compatible:
+    enum:
+      - onnn,fd5121
+      - onnn,fd5123
+      - onnn,fd5125
+
+  reg:
+    maxItems: 1
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
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      fd5121@50 {
+        compatible = "onnn,fd5121";
+        reg = <0x50>;
+      };
+    };

-- 
2.43.0

