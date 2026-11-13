From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:27 +0800
Subject: [PATCH 01/19] riscv: sunxi: describe the wider Allwinner SoC
 family
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-1-eb71ec3ee523@iscas.ac.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=987;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=iIMXHW4ncH9rYCfV6gqeS1VFiDJbleuDtC++QacYRuM=;
 b=1qagKD3rCKA24HqW1EY7WOksbBJolj6tNk+/fSKplFvFfQFmuICjc/3HRPonNK6YXjTtHCQMd
 k+l2SiI9Az4DbHj5RDb1WJdE+MlgzAKOR89f9hwcRwjPTczallY0Cjt
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ARCH_SUNXI is about to cover the V861 as well. Update its prompt and
help text instead of adding another option.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/Kconfig.socs | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/riscv/Kconfig.socs b/arch/riscv/Kconfig.socs
index cecbce0c4983..4cf3b24467e8 100644
--- a/arch/riscv/Kconfig.socs
+++ b/arch/riscv/Kconfig.socs
@@ -61,13 +61,13 @@ config SOC_STARFIVE
 	  This enables support for StarFive SoC platform hardware.
 
 config ARCH_SUNXI
-	bool "Allwinner sun20i SoCs"
+	bool "Allwinner SoCs"
 	depends on MMU
 	select ERRATA_THEAD
 	select SUN4I_TIMER
 	help
-	  This enables support for Allwinner sun20i platform hardware,
-	  including boards based on the D1 and D1s SoCs.
+	  This enables support for Allwinner SoC platform hardware,
+	  including boards based on the D1, D1s and V861 SoCs.
 
 config ARCH_TENSTORRENT
 	bool "Tenstorrent SoCs"

-- 
2.55.0

