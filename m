From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 11 Oct 2026 21:35:44 +0200
Subject: [PATCH v2 2/9] clk: rockchip: rk3399: add the clocks the DSI and
 VOP paths need
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-b4-pinephone-pro-defconfig-v2-2-6b7be35fbee7@protonmail.com>
References: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
In-Reply-To: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Peter Robinson <pbrobinson@gmail.com>, David Heidelberg <david@ixit.cz>, 
 Ondrej Jirman <megi@xff.cz>, Tom Rini <trini@konsulko.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, Simon Glass <sjg@chromium.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Lukasz Majewski <lukma@denx.de>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791747347; l=2340;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=WGZarjKqFfQaJpAXbo2NZOkBnnapWO5KF62gMGVIbbU=;
 b=n7Xhs7hPa1UA/OQrwfRiW3rvwDkz7H7SkkcJHWwD+rujvRi2rcw8RPYI06tX37y7+8EOfY9Xb
 4nTmcLc6AHhD8SVPo3nesBXJJh9BXFHQlP8Z4/QzKuUWR5J0T/N9QmN
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Handle SCLK_DPHY_PLL (fixed 24MHz), set_rate for ACLK_VOP0 and
HCLK_VOP0. Add enable/disable for SCLK_DPHY_TX0_CFG and
PCLK_VIO_GRF.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/clk/rockchip/clk_rk3399.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/drivers/clk/rockchip/clk_rk3399.c b/drivers/clk/rockchip/clk_rk3399.c
index 6e87db18be0..0ddd1f20176 100644
--- a/drivers/clk/rockchip/clk_rk3399.c
+++ b/drivers/clk/rockchip/clk_rk3399.c
@@ -1001,6 +1001,8 @@ static ulong rk3399_clk_get_rate(struct clk *clk)
 	case PCLK_WDT:
 		rate = rk3399_alive_get_clk(priv->cru);
 		break;
+	case SCLK_DPHY_PLL:
+		return 24000000;
 	default:
 		log_debug("Unknown clock %lu\n", clk->id);
 		return -ENOENT;
@@ -1064,6 +1066,8 @@ static ulong rk3399_clk_set_rate(struct clk *clk, ulong rate)
 	case DCLK_VOP1:
 		ret = rk3399_vop_set_clk(priv->cru, clk->id, rate);
 		break;
+	case ACLK_VOP0:
+	case HCLK_VOP0:
 	case ACLK_VOP1:
 	case HCLK_VOP1:
 	case HCLK_SD:
@@ -1168,6 +1172,11 @@ static int __maybe_unused rk3399_clk_set_parent(struct clk *clk,
 		return rk3399_gmac_set_parent(clk, parent);
 	case SCLK_PCIEPHY_REF:
 		return rk3399_pciephy_set_parent(clk, parent);
+	case DCLK_VOP1_DIV:
+	case DCLK_VOP0_DIV:
+	case DCLK_VOP1:
+	case DCLK_VOP0:
+		return 0;
 	}
 
 	debug("%s: unsupported clk %ld\n", __func__, clk->id);
@@ -1261,6 +1270,12 @@ static int rk3399_clk_enable(struct clk *clk)
 		if (readl(&priv->cru->clksel_con[18]) & BIT(10))
 			rk_clrreg(&priv->cru->clkgate_con[12], BIT(6));
 		break;
+	case SCLK_DPHY_TX0_CFG:
+		rk_clrreg(&priv->cru->clkgate_con[21], BIT(1));
+		break;
+	case PCLK_VIO_GRF:
+		rk_clrreg(&priv->cru->clkgate_con[29], BIT(12));
+		break;
 	default:
 		debug("%s: unsupported clk %ld\n", __func__, clk->id);
 		return -ENOENT;
@@ -1356,6 +1371,12 @@ static int rk3399_clk_disable(struct clk *clk)
 		if (readl(&priv->cru->clksel_con[18]) & BIT(10))
 			rk_setreg(&priv->cru->clkgate_con[12], BIT(6));
 		break;
+	case SCLK_DPHY_TX0_CFG:
+		rk_setreg(&priv->cru->clkgate_con[21], BIT(1));
+		break;
+	case PCLK_VIO_GRF:
+		rk_setreg(&priv->cru->clkgate_con[29], BIT(12));
+		break;
 	default:
 		debug("%s: unsupported clk %ld\n", __func__, clk->id);
 		return -ENOENT;

-- 
2.55.0

