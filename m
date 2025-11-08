From: Dang Huynh <dang.huynh@mainlining.org>
Date: Sat, 08 Nov 2025 12:38:08 +0700
Subject: [PATCH v6 12/12] clk: rockchip: rk3568: Use assigned VPLL clock
 when possible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251108-vop2-pt2-v6-12-d04c699262fb@mainlining.org>
References: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
In-Reply-To: <20251108-vop2-pt2-v6-0-d04c699262fb@mainlining.org>
To: u-boot@lists.denx.de
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Simon Glass <sjg@chromium.org>, Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, Tom Rini <trini@konsulko.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, Alexander Graf <agraf@csgraf.de>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 Ion Agorria <ion@agorria.com>, 
 Dario Binacchi <dario.binacchi@amarulasolutions.com>, 
 Dragan Simic <dsimic@manjaro.org>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Piotr Zalewski <pZ010001011111@proton.me>, 
 Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762580305; l=1072;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=YxEY3Xma9RY2BCcT6VkDypXiPdcF8vPSl/CwSJeinL4=;
 b=W70RC/N8SgwCL5Xlm+lVkcU2Rn1XqJfcc63smqC92VDuvC7AWCe1+Wi5Y0Pc0f7m0cO1SkBpa
 qsXn0LFbVNZAGXTCny6GG7OTIr1gvWWRs9yPP5He8VgXFvW8WT7NrIN
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This matches how VPLL is configured under Linux and avoid weird
behaviors when VPLL is reconfigured under Linux.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 drivers/clk/rockchip/clk_rk3568.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/rockchip/clk_rk3568.c b/drivers/clk/rockchip/clk_rk3568.c
index 533031caead..cd0e24d77dc 100644
--- a/drivers/clk/rockchip/clk_rk3568.c
+++ b/drivers/clk/rockchip/clk_rk3568.c
@@ -1820,7 +1820,11 @@ static ulong rk3568_dclk_vop_set_clk(struct rk3568_clk_priv *priv,
 			     ((div - 1) << DCLK0_VOP_DIV_SHIFT));
 		rk3568_pmu_pll_set_rate(priv, HPLL, div * rate);
 	} else if (sel == DCLK_VOP_SEL_VPLL) {
-		div = DIV_ROUND_UP(RK3568_VOP_PLL_LIMIT_FREQ, rate);
+		if (priv->vpll_hz)
+			div = DIV_ROUND_UP(priv->vpll_hz, rate);
+		else
+			div = DIV_ROUND_UP(RK3568_VOP_PLL_LIMIT_FREQ, rate);
+
 		rk_clrsetreg(&cru->clksel_con[conid],
 			     DCLK0_VOP_DIV_MASK | DCLK0_VOP_SEL_MASK,
 			     (DCLK_VOP_SEL_VPLL << DCLK0_VOP_SEL_SHIFT) |

-- 
2.51.2

