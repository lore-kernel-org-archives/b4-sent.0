From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 22 Oct 2026 03:53:24 +0800
Subject: [PATCH 04/18] dt-bindings: clock: add Zhihe A210 AON clock
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-a210-init-v1-4-5e438f972d24@iscas.ac.cn>
References: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
In-Reply-To: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Icenowy Zheng <uwu@icenowy.me>, 
 Drew Fustini <fustini@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792612403; l=2509;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=+6t0kWAwiSZdwyxaiMeac4DxjPKd5CpUhqWGEpuz3PM=;
 b=ouvK5Z74x8Z1T4L8JHl1Qsx7OfQKVEiK4Jxx2iSo70XsTpMNh93ZcZcAFDX+UWJWbcvsDYeWU
 EOnc7YXUQ2gDMvH0OEqoi8aHJiSIeWKNlkX0ts+GL8fJyqSDijOWN2x
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the A210 AON clock controller, including input clocks,
the system clock and I2C1 gates.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 .../bindings/clock/zhihe,a210-aon-clk.yaml         | 58 ++++++++++++++++++++++
 include/dt-bindings/clock/zhihe,a210-aon-clk.h     |  9 ++++
 2 files changed, 67 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/zhihe,a210-aon-clk.yaml b/Documentation/devicetree/bindings/clock/zhihe,a210-aon-clk.yaml
new file mode 100644
index 000000000000..bc1587e3fa81
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/zhihe,a210-aon-clk.yaml
@@ -0,0 +1,58 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/zhihe,a210-aon-clk.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Zhihe A210 always-on peripheral clock controller
+
+maintainers:
+  - Han Gao <gaohan@iscas.ac.cn>
+
+description: |
+  The AON clock controller provides a system clock multiplexer and
+  divider, along with peripheral clock gates.
+
+properties:
+  compatible:
+    const: zhihe,a210-aon-clk
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    items:
+      - description: High-speed AON reference
+      - description: External oscillator
+      - description: Internal RC oscillator
+      - description: RTC oscillator
+
+  clock-names:
+    items:
+      - const: high
+      - const: osc
+      - const: rc
+      - const: rtc
+
+  '#clock-cells':
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - '#clock-cells'
+
+additionalProperties: false
+
+examples:
+  - |
+    clock-controller@30844000 {
+        compatible = "zhihe,a210-aon-clk";
+        reg = <0x30844000 0x1c>;
+        #clock-cells = <1>;
+        clocks = <&aon_high>, <&osc24m>, <&rc26m>, <&rtc32k>;
+        clock-names = "high", "osc", "rc", "rtc";
+    };
+...
diff --git a/include/dt-bindings/clock/zhihe,a210-aon-clk.h b/include/dt-bindings/clock/zhihe,a210-aon-clk.h
new file mode 100644
index 000000000000..29d7e9183adf
--- /dev/null
+++ b/include/dt-bindings/clock/zhihe,a210-aon-clk.h
@@ -0,0 +1,9 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+#ifndef _DT_BINDINGS_CLOCK_ZHIHE_A210_AON_H
+#define _DT_BINDINGS_CLOCK_ZHIHE_A210_AON_H
+
+#define A210_AON_SYS_CLK		0
+#define A210_AON_I2C1_IC_CLK	1
+#define A210_AON_I2C1_PCLK	2
+
+#endif

-- 
2.55.0

