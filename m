From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 06:03:00 +0000
Subject: [PATCH 1/2] clk: sunxi-ng: h616: Fix the EMAC 25 MHz clock parent
 and divider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-h616-clk-emac-spdif-v1-1-e5e36e8963e4@gmail.com>
References: <20261110-h616-clk-emac-spdif-v1-0-e5e36e8963e4@gmail.com>
In-Reply-To: <20261110-h616-clk-emac-spdif-v1-0-e5e36e8963e4@gmail.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-clk@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794290580; l=2089;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=3R8NOHaq8WoHe/ITqSr7/Mvs3yLBB/Q5F/fqBEKvzFI=;
 b=jzSAMX5MGax6j/Mgiufd6pZI7rdjq+ZZuAkF5zVH/+HvL4wamDRRPeN1VUPK/621DM58gISNj
 SyCW5lxUvqJBU2BHhv0egJCBCxYqLjGQzir3oElj7XrOaxwf9M6FO3a
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H616 user manual (v1.0, 3.3.5.86 EPHY_25M_CLK_REG, 0x0970) gives the
EPHY 25 MHz clock as PLL_PERI0(1X) / 24, with bit 31 gating the output
and bit 30 gating the PLL_PERI0 input. The driver models it as a plain
gate below ahb3, so the clock framework reports the AHB3 rate (200 MHz)
for a clock that runs at 25 MHz, and the clock tree does not show that
the PHY clock depends on pll-periph0 rather than on the AHB3 bus.

Model it like the D1 driver does: a gate with a fixed /24 pre-divider
below pll-periph0. The register writes do not change, only the parent
and the reported rate do. On an Orange Pi Zero2, emac-25m now reads
25000000 with pll-periph0 (600 MHz) as its parent.

Fixes: 88dde5e23da1 ("clk: sunxi-ng: Add support for the Allwinner H616 CCU")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/clk/sunxi-ng/ccu-sun50i-h616.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/sunxi-ng/ccu-sun50i-h616.c b/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
index 955c614830fa..d2625fec651a 100644
--- a/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
+++ b/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
@@ -489,8 +489,17 @@ static SUNXI_CCU_MP_WITH_MUX_GATE(spi1_clk, "spi1", nand_spi_parents, 0x944,
 static SUNXI_CCU_GATE(bus_spi0_clk, "bus-spi0", "ahb3", 0x96c, BIT(0), 0);
 static SUNXI_CCU_GATE(bus_spi1_clk, "bus-spi1", "ahb3", 0x96c, BIT(1), 0);
 
-static SUNXI_CCU_GATE(emac_25m_clk, "emac-25m", "ahb3", 0x970,
-		      BIT(31) | BIT(30), 0);
+/*
+ * The EPHY 25 MHz clock is PLL_PERI0(1X) / 24, gated by both the special
+ * clock gate (bit 31) and the PLL_PERI0 input gate (bit 30).
+ */
+static const struct clk_hw *emac_25m_parents[] = {
+	&pll_periph0_clk.common.hw
+};
+
+static SUNXI_CCU_GATE_HWS_WITH_PREDIV(emac_25m_clk, "emac-25m",
+				      emac_25m_parents, 0x970,
+				      BIT(31) | BIT(30), 24, 0);
 
 static SUNXI_CCU_GATE(bus_emac0_clk, "bus-emac0", "ahb3", 0x97c, BIT(0), 0);
 static SUNXI_CCU_GATE(bus_emac1_clk, "bus-emac1", "ahb3", 0x97c, BIT(1), 0);

-- 
2.55.0

