From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 0/2] clk: improve the execution efficiency of
 determine_rate()
Date: Tue, 21 Oct 2025 18:12:29 +0800
Message-Id: <20251021-improve_efficiency_of_clk_divider-v1-0-e2bf7f625af6@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI1c92gC/x3N0QoCIRBG4VdZ5jpBjU3oVSKk9J8aKl1GkGLZd
 1/p8rs5Z6UGFTQ6TyspujSpZcAdJkrPW3nASB4mb/3srLdGPovWjghmSYKSfrFyTO9XzNIlQ83
 p6DjhHmwIgUZnUbB8/4/Lddt2fo1+E3MAAAA=
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761041565; l=770;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=XaFkDnIxFuwdKpw/5slO8Fg7rQXH3UlmWMTwwbD+760=;
 b=3ub3SZ+eS4ugMlITxvskq26g3XdQ/H+pdxTAON9nKGIhZGB9nxyJasrHX+yWKiE2ZN8DA1V81
 xFZLIjo5rloAmjP4mtI4dpQju04ScYobUvnvcI6JRt9bkrPcNzSbDcF
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series aims to reduce the execution time of
determine_rate() for mux and divider clocks.

Although the core logic of _is_best_div() and mux_is_better_rate() is
similar, they are submitted as two separate patches to minimize
maintenance risk.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (2):
      clk: mux: improve the execution efficiency of determine_rate()
      clk: divider: improve the execution efficiency of determine_rate()

 drivers/clk/clk-divider.c | 3 +++
 drivers/clk/clk.c         | 3 +++
 2 files changed, 6 insertions(+)
---
base-commit: 606da5bb165594c052ee11de79bf05bc38bc1aa6
change-id: 20251020-improve_efficiency_of_clk_divider-631fceb70777

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

