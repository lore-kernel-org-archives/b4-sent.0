From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 06:03:01 +0000
Subject: [PATCH 2/2] clk: sunxi-ng: h616: Let the S/PDIF clock set the
 audio PLL rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-h616-clk-emac-spdif-v1-2-e5e36e8963e4@gmail.com>
References: <20261110-h616-clk-emac-spdif-v1-0-e5e36e8963e4@gmail.com>
In-Reply-To: <20261110-h616-clk-emac-spdif-v1-0-e5e36e8963e4@gmail.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-clk@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794290580; l=1435;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=uVt5p9JtVDMkgUlUZbZagSzjVS3EEVHXWn6aQwkqLrw=;
 b=kyMvMV20BqetCpzD8DhhjOaPMNYBc6IvDDTj5ZZGpdi3HSJMYV5oXMWuEqnn44dsbYCkeVEBP
 oquoJsXrKj8Dp4E5xE8a1X/8YjlP2M+IRWPHyU1Gt919aOwQnKRLddx
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sun4i-spdif asks for 22.5792 or 24.576 MHz on the S/PDIF (OWA) module
clock, depending on the sample rate family. The spdif clock has no
CLK_SET_RATE_PARENT, so it can only divide down the rate pll-audio
already runs at. Unless another audio device has already set the PLL for
the right family, the power-of-two divider rounds down and the request
succeeds at a wrong rate: about 12.3 MHz from the reset PLL value, so
48 kHz content is sent at about 24 kHz.

Propagate rate changes to the parent, like the audio codec clocks
already do. This is the same change as the one just applied for the H6
[1].

Link: https://lore.kernel.org/all/20261104185027.883011-1-jernej.skrabec@gmail.com/ [1]
Fixes: 88dde5e23da1 ("clk: sunxi-ng: Add support for the Allwinner H616 CCU")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/clk/sunxi-ng/ccu-sun50i-h616.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/sunxi-ng/ccu-sun50i-h616.c b/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
index d2625fec651a..f703d690a563 100644
--- a/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
+++ b/drivers/clk/sunxi-ng/ccu-sun50i-h616.c
@@ -529,7 +529,7 @@ static struct ccu_div spdif_clk = {
 		.hw.init	= CLK_HW_INIT_PARENTS("spdif",
 						      audio_parents,
 						      &ccu_div_ops,
-						      0),
+						      CLK_SET_RATE_PARENT),
 	},
 };
 

-- 
2.55.0

