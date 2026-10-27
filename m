From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 27 Oct 2026 23:36:55 +0800
Subject: [PATCH RFC 04/18] dt-bindings: mailbox: add the A210 AP to E902
 doorbell
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-a210-scmi-v1-4-74d58ce85bd8@iscas.ac.cn>
References: <20261027-a210-scmi-v1-0-74d58ce85bd8@iscas.ac.cn>
In-Reply-To: <20261027-a210-scmi-v1-0-74d58ce85bd8@iscas.ac.cn>
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Linus Walleij <linusw@kernel.org>, 
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
 linux-serial@vger.kernel.org, Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793115418; l=3071;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=Aa03o52/q7r5yl/oQj7tvURMaxh2zbyMjEEfFVs/Mx0=;
 b=9x5MRu5wx8RqE0wf2ApXCODP19BTZv0c73fMy5djuOOqlLT+r+AZHvIggIAKsqbM2e6z5K8ZF
 dzXeFbZybVjD7bIKfS+XUJrF4bXbLFldE77YjSDtNMqOr8tgvu5mgUl
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the AP doorbell and optional endpoint clocks. Firmware may keep
the clocks enabled before the SCMI transport is available. An optional
E902 to AP data bank identifies a second, receive-only notification
channel sharing the doorbell interrupt.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 .../bindings/mailbox/zhihe,a210-ap-mailbox.yaml    | 76 ++++++++++++++++++++++
 1 file changed, 76 insertions(+)

diff --git a/Documentation/devicetree/bindings/mailbox/zhihe,a210-ap-mailbox.yaml b/Documentation/devicetree/bindings/mailbox/zhihe,a210-ap-mailbox.yaml
new file mode 100644
index 000000000000..4541750223eb
--- /dev/null
+++ b/Documentation/devicetree/bindings/mailbox/zhihe,a210-ap-mailbox.yaml
@@ -0,0 +1,76 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mailbox/zhihe,a210-ap-mailbox.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Zhihe A210 application processor to E902 doorbell
+
+maintainers:
+  - Han Gao <gaohan@iscas.ac.cn>
+
+description: |
+  The A210 exposes a bidirectional notification channel between the
+  application processors and E902 firmware. Payloads and transaction
+  completion are managed by the client using shared memory. The firmware
+  initializes the remote endpoint before the application processor binds.
+  When firmware manages the endpoint clocks and keeps them running, omit
+  clocks and clock-names to avoid a dependency on services using this mailbox.
+
+properties:
+  compatible:
+    const: zhihe,a210-ap-mailbox
+  reg:
+    minItems: 2
+    items:
+      - description: Application processor interrupt status and control
+      - description: Remote E902 notification channel
+      - description:
+          E902 to application processor channel data, which identifies the
+          channel that raised the shared interrupt
+  reg-names:
+    minItems: 2
+    items:
+      - const: interrupt
+      - const: tx
+      - const: rx
+  interrupts:
+    maxItems: 1
+  clocks:
+    items:
+      - description: Application processor mailbox clock
+      - description: E902 mailbox clock
+  clock-names:
+    items:
+      - const: local
+      - const: remote
+  '#mbox-cells':
+    const: 1
+    description: |
+      Channel index. Channel 0 carries requests to E902 and their completion.
+      Channel 1 receives E902 notifications and requires the rx region.
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
+dependentRequired:
+  clocks: [clock-names]
+  clock-names: [clocks]
+
+examples:
+  - |
+    mailbox@321000 {
+        compatible = "zhihe,a210-ap-mailbox";
+        reg = <0x321000 0x1000>, <0x311000 0x1000>, <0x320000 0x1000>;
+        reg-names = "interrupt", "tx", "rx";
+        clocks = <&clk 0>, <&clk 1>;
+        clock-names = "local", "remote";
+        #mbox-cells = <1>;
+        interrupts = <336 4>;
+    };

-- 
2.55.0

