From: Niall Leonard <nl250060@ncr.com>
Date: Tue, 31 Jan 2023 13:49:37 +0000
Subject: [PATCH v2 1/2] dt-bindings: improve wb,mbl-gpio binding
 documentation.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230126-gpio-mmio-fix-v2-1-38397aace340@ncr.com>
References: <20230126-gpio-mmio-fix-v2-0-38397aace340@ncr.com>
In-Reply-To: <20230126-gpio-mmio-fix-v2-0-38397aace340@ncr.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Niall Leonard <nl250060@ncr.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3862; i=nl250060@ncr.com;
 h=from:subject:message-id; bh=142m7Aqg9vw0k6ow9nta9rhrZ0z5xj3jNyxgUalZmSE=;
 b=owEBbQKS/ZANAwAKAVGiIrYFD2P/AcsmYgBj2Rxz/48ADK4QFJhVsMMPjq97FYf9+GU+yxYhz3oB
 Ru8fQjOJAjMEAAEKAB0WIQSha1EPjh6hUqdtwZNRoiK2BQ9j/wUCY9kccwAKCRBRoiK2BQ9j/wfqD/
 9MfkaSMi+fNT85L55YvriK0JaptFrIHxrzlFJkfh1nGjioTNPmW5mT742ULSkzx0ZJjzvYh1ay8Hvo
 iBV2bG3RkqCZmS8mCD7kY6nm729bvgLoj968DNt2UQNHiFlZ9w2Ftl7eOYCOKLAVLq5THkCE3FGlu9
 qVR95vc3ZIQfWIBF6K92t8c/nigXW31IfBnNEZJAU4JflHT091gaHq0fzgsnUb+4rDXfN8fUhBUPYU
 DD8A9mGV16pxJ3UxzgtPmn/ax5FTYxMe2daeKsU0II1SiJSQgWqAd17zkuWwnm5VtK6T5HUz0fI0R1
 ojpLc6fvAAvMR/UT87sjoXPwY6KiSYUSCRzpga3Iifq5XrxObXEWbZqjqAJ8KiuzWxSH2xkp0x/tHu
 /RNTfLvOFLHFZ4N5BAzFEFSjdH1+xjBo7SkA/zG1GmmhwyAujGu4n2vn0zNcpGTJ/4/75YRlOx53V9
 LPmTS7pvTer4BmzxJdW2WqV6K1JSRHwi8o9zxNyocMMkhdPxZzbbhpZt8AWMNqgrsc7/wt7r6SVkvU
 tVHtW0CRFyWF+JB+ezrD4cBLX3I5Hd5SAVbAAtplpqD+8dIjE6YzGOYImUqGMyMWBj6Rhu8odA2r9H
 m7SJgWML6WQbWU8eiGZ8CHPMsT8HH7fKIDMf51D0mQsw12JF5ymFL8punxGw==
X-Developer-Key: i=nl250060@ncr.com; a=openpgp;
 fpr=A16B510F8E1EA152A76DC19351A222B6050F63FF
X-Endpoint-Received: by B4 Submission Endpoint for nl250060@ncr.com/default with auth_id=26
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Convert existing wd,mbl-gpio binding documentation to YAML and add
new optional propery "no-input".

Signed-off-by: Niall Leonard <nl250060@ncr.com>
---
 .../devicetree/bindings/gpio/wd,mbl-gpio.txt       | 38 -----------
 .../devicetree/bindings/gpio/wd,mbl-gpio.yaml      | 78 ++++++++++++++++++++++
 2 files changed, 78 insertions(+), 38 deletions(-)

diff --git a/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.txt b/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.txt
deleted file mode 100644
index 038c3a6a1f4d..000000000000
--- a/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.txt
+++ /dev/null
@@ -1,38 +0,0 @@
-Bindings for the Western Digital's MyBook Live memory-mapped GPIO controllers.
-
-The Western Digital MyBook Live has two memory-mapped GPIO controllers.
-Both GPIO controller only have a single 8-bit data register, where GPIO
-state can be read and/or written.
-
-Required properties:
-	- compatible: should be "wd,mbl-gpio"
-	- reg-names: must contain
-		"dat" - data register
-	- reg: address + size pairs describing the GPIO register sets;
-		order must correspond with the order of entries in reg-names
-	- #gpio-cells: must be set to 2. The first cell is the pin number and
-			the second cell is used to specify the gpio polarity:
-			0 = active high
-			1 = active low
-	- gpio-controller: Marks the device node as a gpio controller.
-
-Optional properties:
-	- no-output: GPIOs are read-only.
-
-Examples:
-	gpio0: gpio0@e0000000 {
-		compatible = "wd,mbl-gpio";
-		reg-names = "dat";
-		reg = <0xe0000000 0x1>;
-		#gpio-cells = <2>;
-		gpio-controller;
-	};
-
-	gpio1: gpio1@e0100000 {
-		compatible = "wd,mbl-gpio";
-		reg-names = "dat";
-		reg = <0xe0100000 0x1>;
-		#gpio-cells = <2>;
-		gpio-controller;
-		no-output;
-	};
diff --git a/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.yaml b/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.yaml
new file mode 100644
index 000000000000..d1c72a42c5bc
--- /dev/null
+++ b/Documentation/devicetree/bindings/gpio/wd,mbl-gpio.yaml
@@ -0,0 +1,78 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/gpio/wd,mbl-gpio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Western Digital's MyBook Live memory-mapped GPIO controllers.
+
+maintainers:
+  - Niall Leonard <nl250060@ncr.com>
+
+description: |+
+  Bindings for the Western Digital's MyBook Live memory-mapped GPIO controllers.
+
+  The Western Digital MyBook Live has two memory-mapped GPIO controllers.
+  Both GPIO controller only have a single 8-bit data register, where GPIO
+  state can be read and/or written.
+
+properties:
+  compatible:
+    enum:
+      - wd,mbl-gpio
+
+  reg-names:
+    items:
+      - const: dat
+
+  reg:
+    maxItems: 1
+
+  "#gpio-cells":
+    const: 2
+
+  gpio-controller: true
+
+  no-output:
+    description: GPIOs are read-only.
+
+  no-input:
+    description: GPIOs are write-only.
+
+required:
+  - compatible
+  - reg-names
+  - reg
+  - '#gpio-cells'
+  - gpio-controller
+
+additionalProperties: false
+
+examples:
+  - |
+    gpio0: gpio0@e0000000 {
+        compatible = "wd,mbl-gpio";
+        reg-names = "dat";
+        reg = <0xe0000000 0x1>;
+        #gpio-cells = <2>;
+        gpio-controller;
+    };
+
+    gpio1: gpio1@e0100000 {
+        compatible = "wd,mbl-gpio";
+        reg-names = "dat";
+        reg = <0xe0100000 0x1>;
+        #gpio-cells = <2>;
+        gpio-controller;
+        no-output;
+    };
+
+    gpio2: gpio1@e0200000 {
+        compatible = "wd,mbl-gpio";
+        reg-names = "dat";
+        reg = <0xe0200000 0x1>;
+        #gpio-cells = <2>;
+        gpio-controller;
+        no-input;
+    };
+

-- 
2.34.1

