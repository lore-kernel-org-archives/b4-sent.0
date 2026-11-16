From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Mon, 16 Nov 2026 08:45:08 +0000
Subject: [PATCH v2 2/2] clk: sunxi-ng: h616: Register GPU PLL notifier
 before mux notifier
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-h616-pll-output-gate-v2-2-a418026ffae6@gmail.com>
References: <20261116-h616-pll-output-gate-v2-0-a418026ffae6@gmail.com>
In-Reply-To: <20261116-h616-pll-output-gate-v2-0-a418026ffae6@gmail.com>
To: Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>
Cc: Andre Przywara <andre.przywara@arm.com>, 
 Maxime Ripard <mripard@kernel.org>, 
 Philippe Simons <simons.philippe@gmail.com>, 
 Ilya Titov <ilya.titov@wirenboard.com>, linux-clk@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794818707; l=1471;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=QL/weaZ6VGxEBkGAwe9yYKN6VnO0kkiDcNvaqnoXQSE=;
 b=77W17WrT9nFCzC+g6lJHQ5hR7OvFqbPOm6VA8sd65vxexQQJGeaCX4IXRt/PSOBZ0yJZ8Jt5Q
 ZJfHeM/omhGBwPsMy926W+02bT/vUWgreFPRf7oIuJYzzYK6vuEvh8w
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register the GPU PLL notifier first, so the GPU goes back to the PLL
only after it has re-locked, as required by commit 02ae2bc6febd
("clk: sunxi-ng: Add clk notifier to gate then ungate PLL clocks").
Commit 0ec5e7572ddc ("clk: sunxi-ng: h616: register CPU PLL notifier
before mux notifier") did this for the CPU.

Fixes: eb963d7948ce ("clk: sunxi-ng: h616: Reparent GPU clock during frequency changes")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/clk/sunxi-ng/ccu-sun50i-h616.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/clk/sunxi-ng/ccu-sun50i-h616.c b/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
index 4037c5f022a8..8f53605eaafa 100644
--- a/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
+++ b/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
@@ -1254,13 +1254,16 @@ static int sun50i_h616_ccu_probe(struct platform_device *pdev)
 	ccu_mux_notifier_register(pll_cpux_clk.common.hw.clk,
 				  &sun50i_h616_cpu_nb);
 
+	/*
+	 * Re-lock the GPU PLL after any rate changes. Must be registered
+	 * before the mux notifier, so GPU goes back to a locked PLL.
+	 */
+	ccu_pll_notifier_register(&sun50i_h616_pll_gpu_nb);
+
 	/* Reparent GPU during GPU PLL rate changes */
 	ccu_mux_notifier_register(pll_gpu_clk.common.hw.clk,
 				  &sun50i_h616_gpu_nb);
 
-	/* Re-lock the GPU PLL after any rate changes */
-	ccu_pll_notifier_register(&sun50i_h616_pll_gpu_nb);
-
 	return 0;
 }
 

-- 
2.55.0

