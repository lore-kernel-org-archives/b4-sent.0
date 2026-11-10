From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 05:34:25 +0000
Subject: [PATCH] spi: sun6i: Add dual read support for the H616
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-spi-sun6i-h616-dual-read-v1-1-59bea5a897d4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORto6oziq4iHro0uInU0qwhj7
 76qx+/w/wuYFBWDc7dAkbeavnID7TqIY8h3QU3N4J1nInJok6LVzIojE2Oq4YlFQsID+1O/H6J
 36Qgtn4rc9PNbX65/Wx0eEufvD9Z1A3MFpoh8AAAA
X-Change-ID: 20261110-spi-sun6i-h616-dual-read-562843bc20d7
To: Mark Brown <broonie@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: linux-spi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794288866; l=2702;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=tZGT7ZjHdId9r6BpMj+RA8BeDisXnRX+tnPmmh0C0Bc=;
 b=JQoe49yHNtyNnSQIFDzWoChjblFpYLtLOMljJsURSgpAJkp/VHvmdUU3GdI2MtVLx950u7Sv5
 CUuT5ewN6PRCOmrX6+9aL9hk09MET/uGHpH3so2UnyRvdoLds2y82kP
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H616 SPI controllers are bound through the "allwinner,sun8i-h3-spi"
fallback, whose configuration advertises no dual or quad modes. The
H616 user manual (v1.0, SPI_BCC register at 0x38) documents the same
dual read (DRM, bit 28) and quad (Quad_EN, bit 29) controls that the
driver already programs for the R329, while the controller keeps the
H3-style clock control register (SPI_CCR at 0x24).

Add an H616 configuration that combines the H3 clock control with dual
reads, matched on the existing "allwinner,sun50i-h616-spi" compatible,
so SPI NOR flashes can use 1-1-2 reads where the board wires both data
lines. Only dual reads are advertised: dual writes and quad mode use the
same register bits but have not been tested on the H616.

Tested on an Orange Pi Zero2 with its 2 MiB Macronix SPI NOR and
spi-rx-bus-width = <2> on the flash node: spi-nor reads with 1S-1S-2S
(opcode 0x3b), reading the whole flash takes 0.30 s instead of 0.52 s,
and repeated reads return identical data with a valid boot0 header.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
This patch was developed with Claude (Anthropic) as a coding assistant:
it investigated the problem, wrote the code and the commit message. I
reviewed it, and it was tested on an Orange Pi Zero2 (H616) as described
above.
---
 drivers/spi/spi-sun6i.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/spi/spi-sun6i.c b/drivers/spi/spi-sun6i.c
index e9fce8618299..2798b9c198c6 100644
--- a/drivers/spi/spi-sun6i.c
+++ b/drivers/spi/spi-sun6i.c
@@ -777,6 +777,12 @@ static const struct sun6i_spi_cfg sun8i_h3_spi_cfg = {
 	.has_clk_ctl	= true,
 };
 
+static const struct sun6i_spi_cfg sun50i_h616_spi_cfg = {
+	.fifo_depth	= SUN8I_FIFO_DEPTH,
+	.has_clk_ctl	= true,
+	.mode_bits	= SPI_RX_DUAL,
+};
+
 static const struct sun6i_spi_cfg sun50i_r329_spi_cfg = {
 	.fifo_depth	= SUN8I_FIFO_DEPTH,
 	.mode_bits	= SPI_RX_DUAL | SPI_TX_DUAL | SPI_RX_QUAD | SPI_TX_QUAD,
@@ -785,6 +791,7 @@ static const struct sun6i_spi_cfg sun50i_r329_spi_cfg = {
 static const struct of_device_id sun6i_spi_match[] = {
 	{ .compatible = "allwinner,sun6i-a31-spi", .data = &sun6i_a31_spi_cfg },
 	{ .compatible = "allwinner,sun8i-h3-spi",  .data = &sun8i_h3_spi_cfg },
+	{ .compatible = "allwinner,sun50i-h616-spi", .data = &sun50i_h616_spi_cfg },
 	{ .compatible = "allwinner,sun50i-r329-spi", .data = &sun50i_r329_spi_cfg },
 	/*
 	 * A523's SPI controller has a combined RX buffer + FIFO counter

---
base-commit: 429c9a10b3811ca2581f88c05a58bb1fd23229a7
change-id: 20261110-spi-sun6i-h616-dual-read-562843bc20d7

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

