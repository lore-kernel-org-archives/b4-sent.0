From: Xilin Wu <wuxilin123@gmail.com>
Date: Wed, 24 Apr 2024 23:29:06 +0800
Subject: [PATCH 01/10] dt-bindings: pwm: Add SI-EN SN3112 PWM support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240424-ayn-odin2-initial-v1-1-e0aa05c991fd@gmail.com>
References: <20240424-ayn-odin2-initial-v1-0-e0aa05c991fd@gmail.com>
In-Reply-To: <20240424-ayn-odin2-initial-v1-0-e0aa05c991fd@gmail.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Junhao Xie <bigfoot@classfun.cn>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, Sam Ravnborg <sam@ravnborg.org>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Tengfei Fan <quic_tengfan@quicinc.com>, 
 Molly Sophia <mollysophia379@gmail.com>, Junhao Xie <bigfoot@classfun.cn>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-arm-msm@vger.kernel.org, Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713972563; l=1687;
 i=wuxilin123@gmail.com; s=20240424; h=from:subject:message-id;
 bh=Sd6Ecnq5OawH+103xxOmJ3nKkBaj9Y2Zw5nnRbO/UF4=;
 b=eUTowkOmB04wln4zX+/5k93CvZLX7lo0igr5S4Ch5podI8Hk35rew+sRl3bcVm14W1QrSqnT3
 o1etBHkXd58C3DNUlIk2LarC5FzddpwfLuaYg8S82Fg6RCYkzg1QMsN
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=vPnxeJnlD/PfEbyQPZzaay5ezxI/lMrke7qXy31lSM8=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20240424 with auth_id=157
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Junhao Xie <bigfoot@classfun.cn>

Add a new driver for the SI-EN SN3112 12-channel 8-bit PWM LED controller.

Signed-off-by: Junhao Xie <bigfoot@classfun.cn>
---
 .../devicetree/bindings/pwm/si-en,sn3112-pwm.yaml  | 55 ++++++++++++++++++++++
 1 file changed, 55 insertions(+)

diff --git a/Documentation/devicetree/bindings/pwm/si-en,sn3112-pwm.yaml b/Documentation/devicetree/bindings/pwm/si-en,sn3112-pwm.yaml
new file mode 100644
index 000000000000..2ab229ac40ce
--- /dev/null
+++ b/Documentation/devicetree/bindings/pwm/si-en,sn3112-pwm.yaml
@@ -0,0 +1,55 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pwm/si-en,sn3112-pwm.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SI-EN SN3112 12-channel 8-bit PWM LED controller
+
+maintainers:
+  - Junhao Xie <bigfoot@classfun.cn>
+
+allOf:
+  - $ref: pwm.yaml#
+
+properties:
+  compatible:
+    const: si-en,sn3112-pwm
+
+  reg:
+    const: 0x54
+    description: I2C slave address
+
+  sdb-gpios:
+    maxItems: 1
+    description: GPIO pin to hardware shutdown the device.
+
+  vdd-supply:
+    description: Chip vdd supply
+
+  "#pwm-cells":
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - "#pwm-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    i2c {
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      pwm@54 {
+        compatible = "si-en,sn3112-pwm";
+        reg = <0x54>;
+        sdb-gpios = <&pio 1 1 GPIO_ACTIVE_LOW>; /* PA1 */
+        vdd-supply = <&reg_dcdc1>;
+        #pwm-cells = <1>;
+      };
+    };

-- 
2.44.0

