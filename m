From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] clk: sunxi-ng: h616: PLL output gate and GPU
 notifier order
Date: Mon, 16 Nov 2026 08:45:06 +0000
Message-Id: <20261116-h616-pll-output-gate-v2-0-a418026ffae6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBBFr0Jm7RgKtRFX3sOwKNMBaoCSthAN4
 e4Cxp3Ll/z/3gKBveUAt2QBz7MN1g0bZKcEqNVDw2jNxpClmRJCSGyVUDh2HbopjlPERkdGKkx
 upJZpwQVs19FzbV+H9lF+OUzVkynurn3R2hCdfx/dWey7X+LyPzELFCipymuSRpG83pte2+5Mr
 odyXdcPKIhKecoAAAA=
X-Change-ID: 20261114-h616-pll-output-gate-c9d3d4a409e9
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794818707; l=1465;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=+gIGBxaGYrzlHRjrte48rjzJCH2FF1p8PLkVsm41dBE=;
 b=rVKKVnQpSRBwsSYWhSWt6F6Q9Vx2Sm9DefvBeZXvuKHQs5alkTfrfR2ty28MhZHTJumt9NjX/
 Jcfe2OMOMbeDgNtTPV1vs1lomIrwci6DsP8VvhzqKi84dy1EDxPKkNV
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 gates the H616 PLLs with their output enable bit instead of
powering them down. Patch 2 registers the GPU PLL notifier before the
mux notifier, as Ilya Titov's 0ec5e7572ddc did for the CPU.

No Cc: stable: the patch 1 crash needs out-of-tree H616 HDMI, and the
old GPU notifier order never failed here.

Tested on an Orange Pi Zero2 (7.3.4 with HDMI patches): v1 survived the
failing mode set 40 times. v2 was not re-run against the crash (our HDMI
no longer leaves pll-video0); it is a regression check: expected PLL
bits, 1434 random CPU and GPU OPP changes under load. Idle power not
measured.

Developed with Claude (Anthropic); I reviewed it.

---
Changes in v2:
- Patch 1: power up the PLLs in the existing loop and stop forcing bit
  27 there, instead of a second loop (Chen-Yu Tsai, Sashiko)
- New patch 2 (Sashiko)
- Rebased on sunxi/clk-for-7.5
- Link to v1: https://patch.msgid.link/20261115-h616-pll-output-gate-v1-1-4cb3fc4d6c48@gmail.com

---
Arun Iyengar (2):
      clk: sunxi-ng: h616: Gate the PLLs with their output enable bit
      clk: sunxi-ng: h616: Register GPU PLL notifier before mux notifier

 drivers/clk/sunxi-ng/ccu-sun50i-h616.c | 37 ++++++++++++++++++----------------
 1 file changed, 20 insertions(+), 17 deletions(-)
---
base-commit: 63a29fbb4ecdadbaccd2693864616918698e1e58
change-id: 20261114-h616-pll-output-gate-c9d3d4a409e9

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

