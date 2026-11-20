From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 21 Nov 2026 03:15:53 +0800
Subject: [PATCH v4 07/13] dt-bindings: serial: snps-dw-apb-uart: add Zhihe
 A210 UART
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-a210-scmi-v4-7-4a795a0a9fc9@iscas.ac.cn>
References: <20261121-a210-scmi-v4-0-4a795a0a9fc9@iscas.ac.cn>
In-Reply-To: <20261121-a210-scmi-v4-0-4a795a0a9fc9@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Michal Simek <michal.simek@amd.com>, 
 Drew Fustini <fustini@kernel.org>, Icenowy Zheng <uwu@icenowy.me>, 
 Inochi Amaoto <inochiama@gmail.com>, Vivian Wang <wangruikang@iscas.ac.cn>, 
 Yao Zi <me@ziyao.cc>, Jiaxun Yang <jiaxun.yang@flygoat.com>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 linux-serial@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795202181; l=1465;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=QLjwbL73GqPkQVnItJ73UGwGElc2NGvSKMH+o+6GPQk=;
 b=mvx9J3mV6IzcJmdPW+I0FhhSHOkmb5FqNp/FEIQMzB2AVPcuaZH8yoCfQNW8cEwOf8Ln1Pnuo
 mE9cgoKzdq3A/dpppN09Ibufz89fAH1Qpr2DbaAh9GxqdZTI2hsQuB9
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

