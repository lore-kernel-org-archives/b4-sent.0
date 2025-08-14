From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 14 Aug 2025 11:52:27 +0100
Subject: [PATCH 5/6] dt-binbings: gpio: Add bindings for the LTC4283 Swap
 Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250814-ltc4283-support-v1-5-88b2cef773f2@analog.com>
References: <20250814-ltc4283-support-v1-0-88b2cef773f2@analog.com>
In-Reply-To: <20250814-ltc4283-support-v1-0-88b2cef773f2@analog.com>
To: linux-hwmon@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755168753; l=1989;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Mi+0w4C770q9JTWbgxwKL384Ye5xiUh9QjGwMTrZ6Xs=;
 b=QLTCDnUrhQy1nxd3vzBpXvjXbpC1vLZCvqc0K7r7lTNC42scTylXuXsFZvLH4YtgHM4jB1kh7
 t68Q1yWWCI1Apgec7jBBIpTgcV+bsyyGRNhhiAsbx5ajVbTTDqopUTX
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the bindings for the GPIO controller functions of the
LTC4283 Hot Swap Controller.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 .../devicetree/bindings/gpio/adi,ltc4283.yaml      | 33 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 34 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/adi,ltc4283.yaml b/Documentation/devicetree/bindings/gpio/adi,ltc4283.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..39ca59c53519ea3a761c75c394c56de885d63fea
--- /dev/null
+++ b/Documentation/devicetree/bindings/gpio/adi,ltc4283.yaml
@@ -0,0 +1,33 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/gpio/adi,ltc4283.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: GPIO LTC4283 Negative Voltage Hot Swap Controller
+
+maintainers:
+  - Nuno Sá <nuno.sa@analog.com>
+
+description: |
+  This module is part of the LTC4283 MFD device.
+  See Documentation/devicetree/bindings/mfd/adi,ltc4283.yaml
+  This implements the GPIO bindings for the LTC4283 negative voltage hot swap
+  controller.
+
+properties:
+  compatible:
+    enum:
+      - adi,ltc4283-gpio
+
+  gpio-controller: true
+
+  '#gpio-cells':
+    const: 2
+
+required:
+  - compatible
+  - gpio-controller
+  - '#gpio-cells'
+
+additionalProperties: false
diff --git a/MAINTAINERS b/MAINTAINERS
index d5d3018b5424f403e7396f0470a12ce8c94a5e49..e492e75833564bd9065fe2422e86479553ea59dd 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -14505,6 +14505,7 @@ M:	Nuno Sá <nuno.sa@analog.com>
 L:	linux-hwmon@vger.kernel.org
 L:	linux-gpio@vger.kernel.org
 S:	Supported
+F:	Documentation/devicetree/bindings/gpio/adi,ltc4283.yaml
 F:	Documentation/devicetree/bindings/hwmon/adi,ltc4283.yaml
 F:	Documentation/devicetree/bindings/mfd/adi,ltc4283.yaml
 F:	drivers/hwmon/ltc4283-hwmon.c

-- 
2.50.1

