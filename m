From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 03 Nov 2026 03:45:07 +0800
Subject: [PATCH RFC v3 04/17] dt-bindings: mailbox: add Zhihe A210 AP to
 E902 mailbox
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-a210-scmi-v3-4-ee6b31580808@iscas.ac.cn>
References: <20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn>
In-Reply-To: <20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn>
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>, 
 Michal Simek <michal.simek@amd.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 Icenowy Zheng <uwu@icenowy.me>, Inochi Amaoto <inochiama@gmail.com>, 
 Vivian Wang <wangruikang@iscas.ac.cn>, Yao Zi <me@ziyao.cc>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-gpio@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, linux-clk@vger.kernel.org, 
 linux-serial@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793648705; l=3069;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=1bSlRTbJH+ic/kKX/KZWwqkpU0t/w8ZHzrQrtqPAxps=;
 b=Mbtcx9ULN3M5M1BOVXKIfPa7Ysmpnzr8bxJu9gjIiuQ1do9EqmOCy8wBUewlfmylGO/UUQaq/
 l54pph/+wc9CjpX/G9HOZ8YL/V3ckKuglIBcUS/6Ezcani0vj4mFo1y
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Zhihe A210 has an E902 management core next to its application
processors. Each side owns a mailbox block and rings the other side by
writing to its slice of the other side's mailbox.

The application processors ring E902 through their slice of the E902
mailbox. E902 rings back through the application processor mailbox and
writes INFO0 or INFO1 there to say which of its two doorbells it rang.
The doorbells carry no data, and clients such as SCMI keep their
messages in shared memory.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 .../bindings/mailbox/zhihe,a210-ap-mailbox.yaml    | 67 ++++++++++++++++++++++
 1 file changed, 67 insertions(+)

diff --git a/Documentation/devicetree/bindings/mailbox/zhihe,a210-ap-mailbox.yaml b/Documentation/devicetree/bindings/mailbox/zhihe,a210-ap-mailbox.yaml
new file mode 100644
index 000000000000..7d7ab1c550a0
--- /dev/null
+++ b/Documentation/devicetree/bindings/mailbox/zhihe,a210-ap-mailbox.yaml
@@ -0,0 +1,67 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mailbox/zhihe,a210-ap-mailbox.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Zhihe A210 application processor to E902 mailbox
+
+maintainers:
+  - Han Gao <gaohan@iscas.ac.cn>
+
+description: |
+  The A210 application processors and the E902 always-on core each own a
+  mailbox. A core raises an interrupt on the other side by writing the
+  generate register of the other core's mailbox, and can leave a value in one
+  of the INFO registers there to identify the request. The application
+  processor side therefore needs its own mailbox, which holds the INFO
+  registers written by E902 and the interrupt status, clear and mask
+  registers, and the slice of the E902 mailbox assigned to it.
+
+  The E902 firmware keeps both mailboxes clocked and out of reset. Their
+  clocks and resets are not controlled from the application processors.
+
+properties:
+  compatible:
+    const: zhihe,a210-ap-mailbox
+
+  reg:
+    items:
+      - description: Application processor mailbox
+      - description: Application processor slice of the E902 mailbox
+
+  reg-names:
+    items:
+      - const: local
+      - const: remote
+
+  interrupts:
+    maxItems: 1
+
+  '#mbox-cells':
+    const: 1
+    description:
+      Doorbell index, 0 or 1. E902 writes INFO0 or INFO1 of the application
+      processor mailbox to tell which doorbell it rings. Only doorbell 0 can
+      also be rung by the application processor.
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - interrupts
+  - '#mbox-cells'
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    mailbox@320000 {
+        compatible = "zhihe,a210-ap-mailbox";
+        reg = <0x320000 0x2000>, <0x311000 0x1000>;
+        reg-names = "local", "remote";
+        interrupts = <336 IRQ_TYPE_LEVEL_HIGH>;
+        #mbox-cells = <1>;
+    };

-- 
2.55.0

