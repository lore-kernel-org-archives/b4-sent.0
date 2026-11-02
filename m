From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 03 Nov 2026 03:45:14 +0800
Subject: [PATCH RFC v3 11/17] dt-bindings: serial: snps-dw-apb-uart: add
 Zhihe A210 UART
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-a210-scmi-v3-11-ee6b31580808@iscas.ac.cn>
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
 Han Gao <gaohan@iscas.ac.cn>, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793648705; l=1465;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=QLjwbL73GqPkQVnItJ73UGwGElc2NGvSKMH+o+6GPQk=;
 b=GwTMVWufbQ3apHJbtkCx8hlRQnr+EZ3B6ni/R6Ct6tj8GjQaIdyxcUFNA6jzCIbaIHbScNRAo
 NxteGYBNi8CCG2wb3dxhMiBYvRAuuXZM8hNZ8O6SDJT8ZST/KoSAtkO
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Zhihe A210 UARTs have separate APB and serial clock domain resets.
Add an SoC-specific compatible that, like the StarFive JH7110 one,
allows both resets.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml b/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml
index e2ca126d58ba..a46a87e100bf 100644
--- a/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml
+++ b/Documentation/devicetree/bindings/serial/snps-dw-apb-uart.yaml
@@ -29,7 +29,9 @@ allOf:
       properties:
         compatible:
           contains:
-            const: starfive,jh7110-uart
+            enum:
+              - starfive,jh7110-uart
+              - zhihe,a210-uart
     then:
       properties:
         resets:
@@ -43,6 +45,7 @@ allOf:
               enum:
                 - starfive,jh7110-uart
                 - syna,sl2610-uart
+                - zhihe,a210-uart
     then:
       properties:
         resets:
@@ -92,6 +95,7 @@ properties:
               - syna,sl2610-uart
               - ti,tda54-uart
               - ultrarisc,dp1000-uart
+              - zhihe,a210-uart
           - const: snps,dw-apb-uart
       - const: snps,dw-apb-uart
 

-- 
2.55.0

