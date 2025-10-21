From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 21 Oct 2025 18:12:31 +0800
Subject: [PATCH 2/2] clk: divider: improve the execution efficiency of
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-improve_efficiency_of_clk_divider-v1-2-e2bf7f625af6@amlogic.com>
References: <20251021-improve_efficiency_of_clk_divider-v1-0-e2bf7f625af6@amlogic.com>
In-Reply-To: <20251021-improve_efficiency_of_clk_divider-v1-0-e2bf7f625af6@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761041565; l=652;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=4yJ8TlYve5AF/Eq9UZTnZIGY2BOewY1lDoBVTOtUsrQ=;
 b=VxzxRsKA+iZOgpD1UJltY5o1FNELeaOzfb/BDwqRVvD76/IppmfZ9jTzZLKPqGAMOhcmHJAjj
 rl/nsdMNhmcCEN7UCfH8OZkpW8gduzzcOFoM8CGg2yw+nVCORYeyBAO
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is no need to evaluate further divider values once _is_best_div()
finds one that matches the target rate.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/clk-divider.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/clk/clk-divider.c b/drivers/clk/clk-divider.c
index 2601b6155afb..b92c4f800fa9 100644
--- a/drivers/clk/clk-divider.c
+++ b/drivers/clk/clk-divider.c
@@ -339,6 +339,9 @@ static int clk_divider_bestdiv(struct clk_hw *hw, struct clk_hw *parent,
 			best = now;
 			*best_parent_rate = parent_rate;
 		}
+
+		if (best == rate)
+			break;
 	}
 
 	if (!bestdiv) {

-- 
2.42.0

