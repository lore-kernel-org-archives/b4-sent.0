From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 06 May 2025 13:36:59 -0500
Subject: [PATCH] spi: tegra114: Use value to check for invalid delays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250506-spi-tegra114-fixup-v1-1-136dc2f732f3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMtWGmgC/x2MQQ5AMBAAv9Ls2SbbohVfEQd0sReaFpGIv2scJ
 5OZBxJH4QSteiDyJUn2LYMuFEzrsC2M4jODIVNTTRZTEDx4iYPWFc5ynwH9OFtXkh+pcZDDEDm
 Lf9r17/sBsguP3GQAAAA=
X-Change-ID: 20250506-spi-tegra114-fixup-dbf6730db087
To: Laxman Dewangan <ldewangan@nvidia.com>, Mark Brown <broonie@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-spi@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746556624; l=1451;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Hw03YaXk/WZ6EX96VNFe6W5UJoy0p3RB6GhwI2lDOas=;
 b=CEGKjV7XRxmWJqtCmKGXcQ1HRrEygIotyDIVa2P8UldIcnnCCRRgM51WuUQ6TYSNQoHyZ0ZnP
 mzcTFoaFAUQCEtiHeb0NckUCgy8uofM8thOYzVHLVLhG2C2EQN9sG7r
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A delay unit of 0 is a valid entry, thus it is not valid to check for
unused delays. Instead, check the value field; if that is zero, the
given delay is unset.

Fixes: 4426e6b4ecf6 ("spi: tegra114: Don't fail set_cs_timing when delays are zero")
Cc: stable@vger.kernel.org
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/spi/spi-tegra114.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/spi/spi-tegra114.c b/drivers/spi/spi-tegra114.c
index 2a8bb798e95b954fe573f1c50445ed2e7fcbfd78..795a8482c2c700c3768bd50bf59971256893a486 100644
--- a/drivers/spi/spi-tegra114.c
+++ b/drivers/spi/spi-tegra114.c
@@ -728,9 +728,9 @@ static int tegra_spi_set_hw_cs_timing(struct spi_device *spi)
 	u32 inactive_cycles;
 	u8 cs_state;
 
-	if ((setup->unit && setup->unit != SPI_DELAY_UNIT_SCK) ||
-	    (hold->unit && hold->unit != SPI_DELAY_UNIT_SCK) ||
-	    (inactive->unit && inactive->unit != SPI_DELAY_UNIT_SCK)) {
+	if ((setup->value && setup->unit != SPI_DELAY_UNIT_SCK) ||
+	    (hold->value && hold->unit != SPI_DELAY_UNIT_SCK) ||
+	    (inactive->value && inactive->unit != SPI_DELAY_UNIT_SCK)) {
 		dev_err(&spi->dev,
 			"Invalid delay unit %d, should be SPI_DELAY_UNIT_SCK\n",
 			SPI_DELAY_UNIT_SCK);

---
base-commit: 0d8d44db295ccad20052d6301ef49ff01fb8ae2d
change-id: 20250506-spi-tegra114-fixup-dbf6730db087

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

