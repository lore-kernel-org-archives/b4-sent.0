From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/2] clk: fix corner case of
 clk_mux_determine_rate_flags()
Date: Tue, 25 Apr 2023 15:46:38 +0800
Message-Id: <20230421-clk-v2-0-74c6cc2214d1@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF6FR2QC/1WNzQ6DIBCEX8XsuTSyWA899T0aD7AulfhDA0jaG
 N+96K3Hb+bLzAaRg+MI92qDwNlF55cCeKmABr28WLi+MGCNqm5QCppG0TbUmpZRUm+gmEZHFib
 ohYbDnXVMHI7iHdi6zzn/7AoPLiYfvudblkf6P5ylkMKYW60sWiSrHn5Nk/fjlfwM3b7vPyEk9
 IqxAAAA
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1682408804; l=665;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=P4ik3YtZtaRc6Wh+178aYQgH3s7csdz7KIDFbHZ86mc=;
 b=kPLo/ER7VoJpG3MfRFJptHn3wXFBaCAJuBu6nHGpJwTDK2tJ/Y2FQ+ccTtTcM2GCZfGnVYhNM
 LTV8aVVH1yvB1fLPFfFRuVJRN/tzmuF9UNdu3c3aaBpauMzJ9GMkX9U
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- Add a unit test to clk_test.c
- Link to v1: https://lore.kernel.org/r/20230421-clk-v1-1-bb503f2f2cf3@outlook.com

---
Yang Xiwen (2):
      clk: use ULONG_MAX as the initial value for the iteration in clk_mux_determine_rate_flags()
      clk: tests: Add missing test case for mux determine_rate

 drivers/clk/clk.c      | 5 ++++-
 drivers/clk/clk_test.c | 9 +++++++++
 2 files changed, 13 insertions(+), 1 deletion(-)
---
base-commit: 76f598ba7d8e2bfb4855b5298caedd5af0c374a8
change-id: 20230421-clk-64c6b6e21cdb

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

