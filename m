From: Fabricio Akio <fabricioakio@gmail.com>
Date: Mon, 28 Sep 2026 14:41:44 -0300
Subject: [PATCH 2/2] clk: qcom: mmcc-sdm660: set num_parents on
 mdss_axi_clk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-sdm660-clk-fixes-v1-2-5d5bb84e3258@gmail.com>
References: <20260928-sdm660-clk-fixes-v1-0-5d5bb84e3258@gmail.com>
In-Reply-To: <20260928-sdm660-clk-fixes-v1-0-5d5bb84e3258@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@somainline.org>, 
 Martin Botka <martin.botka@somainline.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790617365; l=1035;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=E76jx8Xg+uatx7H1ZWR6OZh0it0AFLP8sb6gWPX154o=;
 b=omde6j8vrZlLSsRLdN9YtMrwk04vNyCekaKnMzoJplH7evhVL7piwyAvXhzLdBd2uO5h01x0s
 GPCyItcDNskCq5B4KiHhMV9hoMhGuV+U5LzB7fMr381sGsJREgLxS3R
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mdss_axi_clk names axi_clk_src in parent_hws but leaves num_parents at
zero, so the array is never read and the branch registers as a root
clock -- no rate of its own, and no reference on its parent:

  axi_clk_src   en=0 rate=384000000
  mdss_axi_clk  en=1 rate=0

It is the only branch in this driver missing the field.

Fixes: 5db3ae8b33de ("clk: qcom: Add SDM660 Multimedia Clock Controller (MMCC) driver")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 drivers/clk/qcom/mmcc-sdm660.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/clk/qcom/mmcc-sdm660.c b/drivers/clk/qcom/mmcc-sdm660.c
index 9f8b8e29fa0f..433f5954eb91 100644
--- a/drivers/clk/qcom/mmcc-sdm660.c
+++ b/drivers/clk/qcom/mmcc-sdm660.c
@@ -2064,6 +2064,7 @@ static struct clk_branch mdss_axi_clk = {
 		.hw.init = &(struct clk_init_data){
 			.name = "mdss_axi_clk",
 			.parent_hws = (const struct clk_hw *[]){ &axi_clk_src.clkr.hw },
+			.num_parents = 1,
 			.ops = &clk_branch2_ops,
 		},
 	},

-- 
2.55.0

