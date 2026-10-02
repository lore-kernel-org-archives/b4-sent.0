From: Fabricio Akio <fabricioakio@gmail.com>
Date: Fri, 02 Oct 2026 13:46:24 -0300
Subject: [PATCH v2] clk: qcom: mmcc-sdm660: enable the parents of the pixel
 clock sources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-sdm660-pclk0-parent-enable-v2-1-b07f6c33e96f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBBFr0K6dkxbSS2uuIdhUdoBRqGQFomGc
 HcLXsDNT17y897KIgbCyG7ZygIuFGn0CeQpY7YzvkUgl5hJLpXgXEJ0g1IcJts/05qAfgb0pu4
 RtJAXWxh7FU6zJJgCNvQ+5Pfqx/FVP9DOu3F/dBTnMXyO+iL231+hRYAAp5pG60LkOeZlOxjqz
 3YcWLVt2xcB8Ktl1gAAAA==
X-Change-ID: 20261002-sdm660-pclk0-parent-enable-8123c9ac71d8
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@somainline.org>, 
 Martin Botka <martin.botka@somainline.org>
Cc: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790959583; l=2766;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=kzflGE+GMBXQHBY1TxBvdSXGEj0HNva0A5hK970gsxc=;
 b=ECK3P/V4x7sPrl9k06Vf1H+RcCFyHC7n6CRe9OlexbcWZOBxAMKBQW6jtvmStk7uOi43lfn2i
 aabiJIUzT12CSU0CUeLW4/0ogpT+kyqFrQ25qt6zr3IztmDPudDAT/D
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pclk0_clk_src and pclk1_clk_src are fed by the DSI PHY PLLs, which
dsi_pll_14nm_vco_set_rate() resets and only clk_prepare() restarts. The
DSI host sets the link rates before it prepares the PLL, so the RCG is
updated against a stopped source, and if it is enabled at that point
the update times out:

  pclk0_clk_src: rcg didn't update its configuration.

Seen on a board whose simple-framebuffer node lists the pixel clock:
the RCG then reads enabled at msm's first modeset.

Set CLK_OPS_PARENT_ENABLE on both so the core prepares the PLL around
the rate change, as dispcc-sm8250 does for its pixel clock sources since
commit acf7a91d0b0e ("clk: qcom: dispcc-sm8250: Enable parents for pixel
clocks").

Fixes: 5db3ae8b33de ("clk: qcom: Add SDM660 Multimedia Clock Controller (MMCC) driver")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Tested on the Motorola Moto X4 (SDM630, payton) with the sdm660-mainline
7.2.y tree, sdm660_defconfig, DRM_MSM=m: without the flag the
pclk0_clk_src warning fires in most boots, with it never. At the stall
the RCG reads root-on and the PLL stopped. pclk1_clk_src is not
exercised here, nothing on this board drives DSI1. With the display
built in, clk_disable_unused() also prepares the PLL under this flag,
and some boots then log "DSI PLL lock failed".
---
Changes in v2:
- Set the flag on pclk1_clk_src as well, as Dmitry asked. v1 left it
  out because this board has nothing on DSI1 to test it with.
- Link to v1: https://patch.msgid.link/20261002-sdm660-pclk0-parent-enable-v1-1-d6ff889144e4@gmail.com
---
 drivers/clk/qcom/mmcc-sdm660.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/qcom/mmcc-sdm660.c b/drivers/clk/qcom/mmcc-sdm660.c
index 9f8b8e29fa0f..827741229dd7 100644
--- a/drivers/clk/qcom/mmcc-sdm660.c
+++ b/drivers/clk/qcom/mmcc-sdm660.c
@@ -984,7 +984,8 @@ static struct clk_rcg2 pclk0_clk_src = {
 		.parent_data = mmcc_xo_dsi0pll_dsi1pll,
 		.num_parents = ARRAY_SIZE(mmcc_xo_dsi0pll_dsi1pll),
 		.ops = &clk_pixel_ops,
-		.flags = CLK_SET_RATE_PARENT | CLK_GET_RATE_NOCACHE,
+		.flags = CLK_SET_RATE_PARENT | CLK_GET_RATE_NOCACHE |
+			 CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -998,7 +999,8 @@ static struct clk_rcg2 pclk1_clk_src = {
 		.parent_data = mmcc_xo_dsi0pll_dsi1pll,
 		.num_parents = ARRAY_SIZE(mmcc_xo_dsi0pll_dsi1pll),
 		.ops = &clk_pixel_ops,
-		.flags = CLK_SET_RATE_PARENT | CLK_GET_RATE_NOCACHE,
+		.flags = CLK_SET_RATE_PARENT | CLK_GET_RATE_NOCACHE |
+			 CLK_OPS_PARENT_ENABLE,
 	},
 };
 

---
base-commit: 9f24d789f03b22941b905ded43cb5ff8eea9ce62
change-id: 20261002-sdm660-pclk0-parent-enable-8123c9ac71d8

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

