From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 27 Oct 2026 23:37:01 +0800
Subject: [PATCH RFC 10/18] dt-bindings: timer: add Zhihe A210 CLINT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-a210-scmi-v1-10-74d58ce85bd8@iscas.ac.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793115418; l=807;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=mOLkOh4/jpI+bhz73rcyph1kni8iu4RhyVF0Wak3gq4=;
 b=KeI1lFZVfnK0DXd8ETZZgB+ksVJayuij7OJj1hfsbtb1XteWB98ctRke9ZnIc7FXDmCk4+PVq
 /wpwjTFIHK9AdFBNUk034oWabJBv0PFrOe5o8bM35iqFLP0putZ2BR0
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the A210 CLINT compatible with the thead,c900-clint fallback.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 Documentation/devicetree/bindings/timer/sifive,clint.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/timer/sifive,clint.yaml b/Documentation/devicetree/bindings/timer/sifive,clint.yaml
index 3673836e14de..805262bb6cd3 100644
--- a/Documentation/devicetree/bindings/timer/sifive,clint.yaml
+++ b/Documentation/devicetree/bindings/timer/sifive,clint.yaml
@@ -56,6 +56,7 @@ properties:
               - sophgo,sg2000-clint
               - sophgo,sg2002-clint
               - thead,th1520-clint
+              - zhihe,a210-clint
           - const: thead,c900-clint
       - items:
           - const: sifive,clint0

-- 
2.55.0

