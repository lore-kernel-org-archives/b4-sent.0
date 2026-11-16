From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Mon, 16 Nov 2026 05:55:26 +0000
Subject: [PATCH v2 2/2] spi: sun6i: Add dual read support for the H616
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-spi-sun6i-h616-dual-read-v2-2-e0c66eb71e20@gmail.com>
References: <20261116-spi-sun6i-h616-dual-read-v2-0-e0c66eb71e20@gmail.com>
In-Reply-To: <20261116-spi-sun6i-h616-dual-read-v2-0-e0c66eb71e20@gmail.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794808525; l=1884;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=/aYd9VQyOFWGonPeySJDcD8WiJeGpg8qKpxGGrt1DFM=;
 b=VnJoB2BxeoaDrHHyJpU9gow+SGuG52MelLJnvbcmmd25ti+CsGbKWlTGYpu6cp6l2+nOOGvqc
 bd8DYfK6z6RAiTrzstYMoO1rzEKA/P65tCY1CIYDy4BfP7ceYhHH1qZ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H616 SPI controllers bind through the "allwinner,sun8i-h3-spi"
fallback, which advertises no dual or quad modes, although the H616
manual documents the dual read (DRM, SPI_BCC bit 28) and quad (Quad_EN,
bit 29) controls that the driver already programs for the R329.

Match "allwinner,sun50i-h616-spi" with the H3 clock control and dual
reads. Dual writes and quad mode are left out: untested on the H616.

Tested on an Orange Pi Zero2 (2 MiB Macronix SPI NOR, flash node with
spi-rx-bus-width = <2>): 1-1-2 reads (opcode 0x3b), the whole flash in
0.30 s instead of 0.52 s, repeated reads identical.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/spi/spi-sun6i.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/spi/spi-sun6i.c b/drivers/spi/spi-sun6i.c
index 6b7a05dd0de8..3a77ade87fbe 100644
--- a/drivers/spi/spi-sun6i.c
+++ b/drivers/spi/spi-sun6i.c
@@ -778,6 +778,12 @@ static const struct sun6i_spi_cfg sun8i_h3_spi_cfg = {
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
@@ -786,6 +792,7 @@ static const struct sun6i_spi_cfg sun50i_r329_spi_cfg = {
 static const struct of_device_id sun6i_spi_match[] = {
 	{ .compatible = "allwinner,sun6i-a31-spi", .data = &sun6i_a31_spi_cfg },
 	{ .compatible = "allwinner,sun8i-h3-spi",  .data = &sun8i_h3_spi_cfg },
+	{ .compatible = "allwinner,sun50i-h616-spi", .data = &sun50i_h616_spi_cfg },
 	{ .compatible = "allwinner,sun50i-r329-spi", .data = &sun50i_r329_spi_cfg },
 	/*
 	 * A523's SPI controller has a combined RX buffer + FIFO counter

-- 
2.55.0

