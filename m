From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:45 +0800
Subject: [PATCH 19/19] MAINTAINERS: add an entry for the Allwinner V861 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-19-eb71ec3ee523@iscas.ac.cn>
References: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
In-Reply-To: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guo Ren <guoren@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Han Gao <gaohan@iscas.ac.cn>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Maxime Ripard <mripard@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-csky@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=1064;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=39Ac8hJzpCiQ7XryhT1eADd1ddcM2ysT57oAlX6+9R8=;
 b=yImKJfL/SM0iJ5gXSR0G3a7zEwdVCFqOgmcRGrK1c0Yxaoy5YXunPhnCNkpFmotpUgaYwGgLk
 8PkUGkVB3+cATxKHXuU20wzYPDweSAZ53K3Q6ECQOIXJmC3LIl6Sb42
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add myself as maintainer for the V861 bindings, clock and pin control
drivers and device trees.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 MAINTAINERS | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 93abbb315065..dfc300dc1eb2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24031,6 +24031,18 @@ F:	drivers/irqchip/irq-riscv-intc.c
 F:	include/linux/irqchip/riscv-aplic.h
 F:	include/linux/irqchip/riscv-imsic.h
 
+RISC-V ALLWINNER V861 SoC SUPPORT
+M:	Han Gao <gaohan@iscas.ac.cn>
+L:	linux-riscv@lists.infradead.org
+L:	linux-sunxi@lists.linux.dev
+S:	Maintained
+F:	Documentation/devicetree/bindings/clock/allwinner,sun252i-v861-ccu.yaml
+F:	arch/riscv/boot/dts/allwinner/sun252i-v861*
+F:	drivers/clk/sunxi-ng/ccu-sun252i-v861*.c
+F:	drivers/pinctrl/sunxi/pinctrl-sun252i-v861*.c
+F:	include/dt-bindings/clock/sun252i-v861*.h
+F:	include/dt-bindings/reset/sun252i-v861*.h
+
 RISC-V ANDES SoC Support
 M:	Ben Zong-You Xie <ben717@andestech.com>
 S:	Maintained

-- 
2.55.0

