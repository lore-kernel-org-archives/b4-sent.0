From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 24 May 2024 14:35:09 +0800
Subject: [PATCH] spi: meson-spicc: set SPI clock flag CLK_SET_RATE_PARENT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240524-spi_pclk_setparent-v1-1-99e0ce70b66f@amlogic.com>
X-B4-Tracking: v=1; b=H4sIABw1UGYC/x3MQQqAIBBA0avErBNyyqCuEhFiUw2FiRMRSHdPW
 r7F/wmEIpNAXySIdLPw6TN0WYDbrF9J8ZwNWGFTGWyUBJ6CO/ZJ6Ao2kr9UO1vsajRO6xpyGCI
 t/PzTYXzfD52+YXpkAAAA
To: Mark Brown <broonie@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-spi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, Sunny Luo <sunny.luo@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716532532; l=1803;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=i2kf4hjt27aFCniu/cvi7M+Wdce80gPI7LhS2KX7ULY=;
 b=ehUpQ96FcIL43Duzap4N1C5TOSDRp6ZTDXvwx0+NTo1ezJmCXPgZdeqeFOUDsub3YptIpzR9q
 oATZyZAAqSYC18IypOtnO7eSAWfPzir+KMzfpkM//iyvrIIRc6AhJXK
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SPI clock flag CLK_SET_RATE_PARENT for using pclk as parent clock.
This gives SPI more flexibility in frequency selection.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Sunny Luo <sunny.luo@amlogic.com>
---
 drivers/spi/spi-meson-spicc.c | 16 ++++++++++------
 1 file changed, 10 insertions(+), 6 deletions(-)

diff --git a/drivers/spi/spi-meson-spicc.c b/drivers/spi/spi-meson-spicc.c
index fc75492e50ff..8a4a8ba9dfed 100644
--- a/drivers/spi/spi-meson-spicc.c
+++ b/drivers/spi/spi-meson-spicc.c
@@ -644,11 +644,13 @@ static int meson_spicc_pow2_clk_init(struct meson_spicc_device *spicc)
 	snprintf(name, sizeof(name), "%s#pow2_fixed_div", dev_name(dev));
 	init.name = name;
 	init.ops = &clk_fixed_factor_ops;
-	init.flags = 0;
-	if (spicc->data->has_pclk)
+	if (spicc->data->has_pclk) {
+		init.flags = CLK_SET_RATE_PARENT;
 		parent_data[0].hw = __clk_get_hw(spicc->pclk);
-	else
+	} else {
+		init.flags = 0;
 		parent_data[0].hw = __clk_get_hw(spicc->core);
+	}
 	init.num_parents = 1;
 
 	pow2_fixed_div->mult = 1,
@@ -708,11 +710,13 @@ static int meson_spicc_enh_clk_init(struct meson_spicc_device *spicc)
 	snprintf(name, sizeof(name), "%s#enh_fixed_div", dev_name(dev));
 	init.name = name;
 	init.ops = &clk_fixed_factor_ops;
-	init.flags = 0;
-	if (spicc->data->has_pclk)
+	if (spicc->data->has_pclk) {
+		init.flags = CLK_SET_RATE_PARENT;
 		parent_data[0].hw = __clk_get_hw(spicc->pclk);
-	else
+	} else {
+		init.flags = 0;
 		parent_data[0].hw = __clk_get_hw(spicc->core);
+	}
 	init.num_parents = 1;
 
 	enh_fixed_div->mult = 1,

---
base-commit: 3aac9f4885922ad0fc01b86f85903768219475a3
change-id: 20240524-spi_pclk_setparent-6da29325c113

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

