From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 21 Oct 2025 18:12:30 +0800
Subject: [PATCH 1/2] clk: mux: improve the execution efficiency of
 determine_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-improve_efficiency_of_clk_divider-v1-1-e2bf7f625af6@amlogic.com>
References: <20251021-improve_efficiency_of_clk_divider-v1-0-e2bf7f625af6@amlogic.com>
In-Reply-To: <20251021-improve_efficiency_of_clk_divider-v1-0-e2bf7f625af6@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761041565; l=769;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=kpI7sJGuBtaGiKOaRn1dUBDRcck1TQit3fBKO0ju8fc=;
 b=au5lQ/hQp014GAb+uq9d8JpGOxZ1QHU8sRX0kgqHJ87EH7/z089DXLBqHOs+j6CwD3RoB+IMw
 7xFQgHArwbaCq/uYirA8Ci/LC8HuFVN07WZfJ7raLs0czwoi20uxO1m
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the current logic of mux_is_better_rate(), even if a
parent clock matching req->rate is found again in the current loop,
it will not be selected.

Exit the loop once the best-matching parent clock is found to avoid
unnecessary function calls and reduce execution time.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/clk.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 85d2f2481acf..925e4768e3ad 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -758,6 +758,9 @@ int clk_mux_determine_rate_flags(struct clk_hw *hw,
 			best_parent = parent;
 			best = parent_rate;
 		}
+
+		if (best == req->rate)
+			break;
 	}
 
 	if (!best_parent)

-- 
2.42.0

