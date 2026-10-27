From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 27 Oct 2026 23:37:02 +0800
Subject: [PATCH RFC 11/18] dt-bindings: firmware: add A210 SCMI clock and
 reset IDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-a210-scmi-v1-11-74d58ce85bd8@iscas.ac.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793115418; l=1905;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=cHyzHGe6C3hGqmqu+74Uf23AwBzHigG0TJ40txxDzZQ=;
 b=E380Dv6zaJZQluLlzXLNBYuGUXD5AMN+wkU/OKBHqGlcCbNfmOk1GGvnTFt5OQcKfn489dj4/
 mo0jkwjU3KRDRTt+HmLpg7mYFznHabr2FUPq+S9y1Hrz1BHN2dwZ8Iu
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Define the SCMI clock and reset IDs for the A210 UARTs, pad controllers
and AON I2C1. Each UART has separate serial and APB reset lines, so
they get separate reset IDs, numbered like the matching clocks.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 include/dt-bindings/clock/zhihe,a210-scmi.h | 15 +++++++++++++++
 include/dt-bindings/reset/zhihe,a210-scmi.h | 13 +++++++++++++
 2 files changed, 28 insertions(+)

diff --git a/include/dt-bindings/clock/zhihe,a210-scmi.h b/include/dt-bindings/clock/zhihe,a210-scmi.h
new file mode 100644
index 000000000000..b8f6441ac650
--- /dev/null
+++ b/include/dt-bindings/clock/zhihe,a210-scmi.h
@@ -0,0 +1,15 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+#ifndef _DT_BINDINGS_CLOCK_ZHIHE_A210_SCMI_H_
+#define _DT_BINDINGS_CLOCK_ZHIHE_A210_SCMI_H_
+
+/* SCMI clock IDs; existing entries must not be renumbered. */
+#define A210_CLK_UART_SCLK(n) (n)
+#define A210_CLK_UART_PCLK(n) (10 + (n))
+#define A210_CLK_PERI1_PAD 20
+#define A210_CLK_PERI2_PAD 21
+#define A210_CLK_PERI3_PAD 22
+#define A210_CLK_AON_SYS 23
+#define A210_CLK_AON_I2C1_IC 24
+#define A210_CLK_AON_I2C1_PCLK 25
+
+#endif
diff --git a/include/dt-bindings/reset/zhihe,a210-scmi.h b/include/dt-bindings/reset/zhihe,a210-scmi.h
new file mode 100644
index 000000000000..53e108c15407
--- /dev/null
+++ b/include/dt-bindings/reset/zhihe,a210-scmi.h
@@ -0,0 +1,13 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+#ifndef _DT_BINDINGS_RESET_ZHIHE_A210_SCMI_H_
+#define _DT_BINDINGS_RESET_ZHIHE_A210_SCMI_H_
+
+/* SCMI reset IDs; existing entries must not be renumbered. */
+#define A210_RESET_UART_SRST(n) (n)
+#define A210_RESET_UART_PRST(n) (10 + (n))
+#define A210_RESET_PERI1_PAD 20
+#define A210_RESET_PERI2_PAD 21
+#define A210_RESET_PERI3_PAD 22
+#define A210_RESET_AON_I2C1 23
+
+#endif

-- 
2.55.0

