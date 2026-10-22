From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Thu, 22 Oct 2026 23:52:40 +0200
Subject: [PATCH 2/4] clk: meson: g12a: fix swapped VID_PLL and VID_PLL_DIV
 clock ids
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-fix-g12a-clk-v1-2-e2bd8f3f1afa@aliel.fr>
References: <20261022-fix-g12a-clk-v1-0-e2bd8f3f1afa@aliel.fr>
In-Reply-To: <20261022-fix-g12a-clk-v1-0-e2bd8f3f1afa@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jian Hu <jian.hu@amlogic.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1162;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=YR8frSm+6sxxqFo9ANrOruNDwaVVFJ61khzljz/qP2U=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9at1r126fz2QibRosEiwl19TzbEnL0cZaFv9YPZIpPtQ
 rjnp2cdpSwMYlwMsmKKLP1zLU+8u3z0zNc96ikwc1iZQIYwcHEKwET4uBn+Z0duUVv/Tn3z8+uX
 5AXCJN88WR9lpW5jOMtwcufHhayS8xn+u984/vPqXeXVJXz22w8bP9rb+6stTvxEyWrXFbdteNJ
 fsAAA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In g12a onecell data table CLKID_VID_PLL points to g12a_vid_pll_div
and CLKID_VID_PLL_DIV points to g12a_vid_pll. So the ids are swapped.

Swap the ids back to their right entries.

Fixes: 085a4ea93d54 ("clk: meson: g12a: add peripheral clock controller")
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/clk/meson/g12a.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/meson/g12a.c b/drivers/clk/meson/g12a.c
index 4ec5f15daf98..07105b2089c3 100644
--- a/drivers/clk/meson/g12a.c
+++ b/drivers/clk/meson/g12a.c
@@ -4622,9 +4622,9 @@ static struct clk_hw *g12a_hw_clks[] = {
 	[CLKID_HDMI_PLL_OD]		= &g12a_hdmi_pll_od.hw,
 	[CLKID_HDMI_PLL_OD2]		= &g12a_hdmi_pll_od2.hw,
 	[CLKID_HDMI_PLL]		= &g12a_hdmi_pll.hw,
-	[CLKID_VID_PLL]			= &g12a_vid_pll_div.hw,
+	[CLKID_VID_PLL]			= &g12a_vid_pll.hw,
 	[CLKID_VID_PLL_SEL]		= &g12a_vid_pll_sel.hw,
-	[CLKID_VID_PLL_DIV]		= &g12a_vid_pll.hw,
+	[CLKID_VID_PLL_DIV]		= &g12a_vid_pll_div.hw,
 	[CLKID_VCLK_SEL]		= &g12a_vclk_sel.hw,
 	[CLKID_VCLK2_SEL]		= &g12a_vclk2_sel.hw,
 	[CLKID_VCLK_INPUT]		= &g12a_vclk_input.hw,

-- 
2.43.0

