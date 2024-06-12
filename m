From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 12 Jun 2024 17:44:50 +0800
Subject: [PATCH] spi: meson-spicc: add spicc loopback mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240612-spi_lbc-v1-1-d52e8c8011bd@amlogic.com>
X-B4-Tracking: v=1; b=H4sIABFuaWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDM0ND3eKCzPicpGRdAwtTy+TUpGRTC4NUJaDqgqLUtMwKsEnRsbW1AOo
 n511ZAAAA
To: Mark Brown <broonie@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-spi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sunny Luo <sunny.luo@amlogic.com>, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718185490; l=1402;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=b+Ry5KyDug4yW2aXOoBaVaLUbknmRYKeqBgQWvQYE0Q=;
 b=scoKl7griElcwsQYJ5MkTT9KMG5KoHWGW0pBIMKlZcXQ0qwTcMxpVklWONNq0cdQQ62ieUpzt
 RN+ICCezNmlD8L7HkC0Z/Dqe3qZrHGu2q7QJievDZcWACky1WpdqNLI
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add spicc loopback mode for debugging convenience.

Signed-off-by: Sunny Luo <sunny.luo@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/spi/spi-meson-spicc.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/spi/spi-meson-spicc.c b/drivers/spi/spi-meson-spicc.c
index 8a4a8ba9dfed..8838a98b04c2 100644
--- a/drivers/spi/spi-meson-spicc.c
+++ b/drivers/spi/spi-meson-spicc.c
@@ -514,7 +514,9 @@ static int meson_spicc_prepare_message(struct spi_controller *host,
 	/* Setup no wait cycles by default */
 	writel_relaxed(0, spicc->base + SPICC_PERIODREG);
 
-	writel_bits_relaxed(SPICC_LBC_W1, 0, spicc->base + SPICC_TESTREG);
+	writel_bits_relaxed(SPICC_LBC_W1,
+			    spi->mode & SPI_LOOP ? SPICC_LBC_W1 : 0,
+			    spicc->base + SPICC_TESTREG);
 
 	return 0;
 }
@@ -850,7 +852,7 @@ static int meson_spicc_probe(struct platform_device *pdev)
 
 	host->num_chipselect = 4;
 	host->dev.of_node = pdev->dev.of_node;
-	host->mode_bits = SPI_CPHA | SPI_CPOL | SPI_CS_HIGH;
+	host->mode_bits = SPI_CPHA | SPI_CPOL | SPI_CS_HIGH | SPI_LOOP;
 	host->bits_per_word_mask = SPI_BPW_MASK(32) |
 				   SPI_BPW_MASK(24) |
 				   SPI_BPW_MASK(16) |

---
base-commit: ec0d19f2b59699e2e148091debaa0d9d6af5800a
change-id: 20240611-spi_lbc-0859cebc580e

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

