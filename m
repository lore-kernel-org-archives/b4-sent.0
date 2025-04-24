From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 23 Apr 2025 21:03:03 -0500
Subject: [PATCH] spi: tegra114: Don't fail set_cs_timing when delays are
 zero
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250423-spi-tegra114-v1-1-2d608bcc12f9@gmail.com>
X-B4-Tracking: v=1; b=H4sIANabCWgC/x3MTQqAIBBA4avIrBP8Bekq0cJstNmYaEQg3T1p+
 S3e69CwEjaYWYeKNzU684CcGITD54Sc9mFQQllhlOatEL8wVS+l4ZtzTrlgg4gaRlIqRnr+3bK
 +7wfRnhCvXgAAAA==
X-Change-ID: 20250423-spi-tegra114-b88828c5c0f3
To: Laxman Dewangan <ldewangan@nvidia.com>, Mark Brown <broonie@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Mason Zhang <Mason.Zhang@mediatek.com>
Cc: linux-spi@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745460211; l=1447;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=6Ntl3heYOtSRo+SbZlaWWlJ/8sphcbur4awnUfzmiKk=;
 b=UngeTiHC4/irfiREWVxaOQlDY8BZIa8YqVXnNAGy9+5094zQFFqJTZfL0x7LsHsqt4Xzi66Qi
 /gjS63hepyMAYsfBK0t3ZXzr3Aqn7BW9OywpDOqR/OVYdI1zkQ1Jluu
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original code would skip null delay pointers, but when the pointers
were converted to point within the spi_device struct, the check was not
updated to skip delays of zero. Hence all spi devices that didn't set
delays would fail to probe.

Fixes: 04e6bb0d6bb1 ("spi: modify set_cs_timing parameter")
Cc: stable@vger.kernel.org
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/spi/spi-tegra114.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/spi/spi-tegra114.c b/drivers/spi/spi-tegra114.c
index 3822d7c8d8edb9730e937df50d1c75e095dd18ec..2a8bb798e95b954fe573f1c50445ed2e7fcbfd78 100644
--- a/drivers/spi/spi-tegra114.c
+++ b/drivers/spi/spi-tegra114.c
@@ -728,9 +728,9 @@ static int tegra_spi_set_hw_cs_timing(struct spi_device *spi)
 	u32 inactive_cycles;
 	u8 cs_state;
 
-	if (setup->unit != SPI_DELAY_UNIT_SCK ||
-	    hold->unit != SPI_DELAY_UNIT_SCK ||
-	    inactive->unit != SPI_DELAY_UNIT_SCK) {
+	if ((setup->unit && setup->unit != SPI_DELAY_UNIT_SCK) ||
+	    (hold->unit && hold->unit != SPI_DELAY_UNIT_SCK) ||
+	    (inactive->unit && inactive->unit != SPI_DELAY_UNIT_SCK)) {
 		dev_err(&spi->dev,
 			"Invalid delay unit %d, should be SPI_DELAY_UNIT_SCK\n",
 			SPI_DELAY_UNIT_SCK);

---
base-commit: a79be02bba5c31f967885c7f3bf3a756d77d11d9
change-id: 20250423-spi-tegra114-b88828c5c0f3

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

