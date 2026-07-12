From: Esteban Urrutia <esteuwu@proton.me>
Date: Sat, 11 Jul 2026 23:10:37 -0400
Subject: [PATCH v2 3/3] clk: qcom: dispcc-sm8450: Keep pll types as is for
 SM8475
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-sm8450-qol-dispcc-v2-3-fc1a07ac5601@proton.me>
References: <20260711-sm8450-qol-dispcc-v2-0-fc1a07ac5601@proton.me>
In-Reply-To: <20260711-sm8450-qol-dispcc-v2-0-fc1a07ac5601@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, Danila Tikhonov <danila@jiaxyga.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783825891; l=1363;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=t+lNjNa2t6HZO8sfj5j22+PtdnnFFxNblbhbO/qadd0=;
 b=Bj9RlBDSAQxg8KVWCWBDlK+W6DILMgAvBoBCOjSG+SkJQ/cXRWofqsgfJAT3JPEDb+hlrE1ui
 eAx32OOZCQZAnrSdhZglC3MU5gEL+tXYESGra/ckMRRMsugNEG8+xWV
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While using an OLE PLL type is correct according to downstream code, this
results in the display flickering at boot for SM8475 because downstream
uses EVO type configurations for both clocks, while, for some reason,
upstream uses EVO type configurations for SM8450 and OLE type
configurations for SM8475.
So far, no regressions have been observed and the display no longer
flickers.

Fixes: 7c0e8764dc33 ("clk: qcom: dispcc-sm8450: Add SM8475 support")
Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 drivers/clk/qcom/dispcc-sm8450.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/drivers/clk/qcom/dispcc-sm8450.c b/drivers/clk/qcom/dispcc-sm8450.c
index 07f22b5b5ee5..2c0edc23eeb1 100644
--- a/drivers/clk/qcom/dispcc-sm8450.c
+++ b/drivers/clk/qcom/dispcc-sm8450.c
@@ -1833,11 +1833,9 @@ static int disp_cc_sm8450_probe(struct platform_device *pdev)
 
 	if (of_device_is_compatible(pdev->dev.of_node, "qcom,sm8475-dispcc")) {
 		/* Update DISPCC PLL0 */
-		disp_cc_pll0.regs = clk_alpha_pll_regs[CLK_ALPHA_PLL_TYPE_LUCID_OLE];
 		disp_cc_pll0.clkr.hw.init = &sm8475_disp_cc_pll0_init;
 
 		/* Update DISPCC PLL1 */
-		disp_cc_pll1.regs = clk_alpha_pll_regs[CLK_ALPHA_PLL_TYPE_LUCID_OLE];
 		disp_cc_pll1.clkr.hw.init = &sm8475_disp_cc_pll1_init;
 
 		disp_cc_pll0.config = &sm8475_disp_cc_pll0_config;

-- 
2.55.0

