From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] clk: sunxi-ng: h616: Fix the EMAC 25 MHz and S/PDIF
 clocks
Date: Tue, 10 Nov 2026 06:02:59 +0000
Message-Id: <20261110-h616-clk-emac-spdif-v1-0-e5e36e8963e4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMAyA4VeRnBcwRQr6KrKDpumMOifNNgbFd
 7fbjt/h/zOYJBWDrsqQ5K2mj62ALhXwNGw3QQ3F4GrniajGyZNHXheU+8Boe9CIDRG3PsQxiIN
 S7kmifn7X/vq3vcZZ+PldwXGc14sRa3cAAAA=
X-Change-ID: 20261110-h616-clk-emac-spdif-411c96dfbde2
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-clk@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794290580; l=1811;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=IFyI7JJ8fJLP5Ef3+9F0FXrHqe21a7ZPZU1S9cQpPE0=;
 b=7owWMhF0E+ULMOrWbnsnk0mKjC9hdboYHaGDF3wJNwiCdTE7p9ICpEEDXmeEk4EgPmnUT4xre
 P2q6cD2d5QxDg5AHxmameUabWmzoFT/46s8Ummp7LZinICao/MP2pvL
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two small fixes for the H616 CCU, found while checking the clock tree of
an Orange Pi Zero2 against the H616 user manual.

Patch 1 models the EPHY 25 MHz clock as PLL_PERI0 / 24, as the manual
describes it. Only the parent and the reported rate change; the register
writes are the same.

Patch 2 lets the S/PDIF clock change the audio PLL rate, so the 44.1 kHz
and 48 kHz families both get the right module clock. It is the H616
counterpart of the H6 patch that was just applied [1].

Tested on an Orange Pi Zero2 (H616) with a 7.3 kernel carrying both
patches:
- clk_summary shows emac-25m at 25000000 with pll-periph0 (600 MHz) as
  its parent (200000000 below ahb3 before). The Zero2 uses an external
  RGMII PHY on EMAC0, so nothing on this board consumes the clock; only
  the clock tree was checked.
- With the S/PDIF output enabled, the spdif clock is 24576000 Hz under
  aplay at 48 kHz and 22579200 Hz at 44.1 kHz. I have no S/PDIF receiver,
  so the output itself was not checked on the wire.

These patches were developed with Claude (Anthropic) as a coding
assistant. It investigated the problem and wrote the code and the commit
messages; I reviewed them, and they were tested on an Orange Pi Zero2
(H616) as described above.

[1] https://lore.kernel.org/all/20261104185027.883011-1-jernej.skrabec@gmail.com/

---
Arun Iyengar (2):
      clk: sunxi-ng: h616: Fix the EMAC 25 MHz clock parent and divider
      clk: sunxi-ng: h616: Let the S/PDIF clock set the audio PLL rate

 drivers/clk/sunxi-ng/ccu-sun50i-h616.c | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)
---
base-commit: 280af24c860569000b375edda6436ba8e3ee4b3a
change-id: 20261110-h616-clk-emac-spdif-411c96dfbde2

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

