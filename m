From: Ricardo Pardini <ricardo@pardini.net>
Date: Sun, 15 Nov 2026 16:48:11 +0100
Subject: [PATCH v2] phy: rockchip: naneng-combphy: fix RK3588 SATA
 pipe_con1 register offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-rk3588-combphy-sata2-6g-v2-1-778e0e8011fe@pardini.net>
X-B4-Tracking: v=1; b=H4sIADrU+WoC/3WNyw6CMBBFf4V07ZhOawm48j8MixZGGI2FtJVIC
 P8uj7XLk9x7ziwiBaYortksAo0cufcrqFMm6s76loCblYWSKkepLhBe2hQF1P3bDd0E0SarIG9
 Baue0RIPGKLG+h0AP/u7me3Vw/Lgn1WnTbYuOY+rDtKdH3HZHBWX5tzIiIFCJ2tQlNpTb22BDw
 57PnpKolmX5AZz+eZnSAAAA
X-Change-ID: 20261024-rk3588-combphy-sata2-6g-03bb30151552
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Lucas Tanure <tanure@linux.com>, linux-phy@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Yifeng Zhao <yifeng.zhao@rock-chips.com>, 
 stable@vger.kernel.org, Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3245; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=7C3z50HF4YPPhxfojWOPHlWST5mhlOANTFSCF0BvMLE=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq+dQ8Q7AOEqBEaJ40Qr8v90oLDQJ4qH6b6aZGN
 Rxv5wgYhS2JATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavnUPAAKCRA7Xj/jnsft
 6Qu5B/43ii5B5vLp7uePCdS2Y60DAhqinh6J/QWpePpP4kNJVbE3YWpuHFy9lFKwgX7VaIRTNjq
 b3b06t7skss2elc97aE6opCrKTCog4udVuaUFgbXajh63e/nJBZgr91p9dSespZKw1RkNg9fsj7
 XEnFvSfys82kKhyK3Ap7g9qvhyukWwo6XsSCbUjnTRP0WBBNPJBM2LQ6cjEwia06jlipE5LZIxQ
 Hv49ZX2NnMZ3ba4y3Q+Dwh1U/KGFw2UuOjpo23r+4MFQFYEetjNqPKQxVkFdseeyz9GHGYtgCpV
 lJdsS2jc6D6do+YxNpwORkbkyNwgrK9fifExcH/RUeVuGsK4
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Yifeng Zhao <yifeng.zhao@rock-chips.com>

On RK3588, the sata2 PHY speed is selected by sata2_phy_spdmode in
PHP_GRF_PHP_CON1[1:0] (offset 0x0004), with sata2_phy_rx_err in bit 2.
rk3588_combphy_grfcfgs has pipe_con1_for_sata at offset 0x0000 though,
so the value 0x2 (6.0 Gb/s, rx_err cleared) ends up in PHP_GRF_PHP_CON0
and CON1 is never written.

This leaves sata2 at its 1.5 Gb/s reset value, so the link only trains
at 1.5 Gb/s, even with a 6 Gb/s capable disk and no SControl speed
limit. sata0 and sata1 are not affected: their speed fields are in
PHP_GRF_PHP_CON0 and are set by pipe_con0_for_sata.

The misplaced write also lands in PHP_GRF_PHP_CON0[2:0], which are the
PCIe link reset grant bits, and turns on the one for pcie3x2 whenever a
combphy is put in SATA mode. No effect from that is known, but this
stops it too.

The register layout is described in the RK3588 TRM V1.0 Part1, section
6.17 "PHP_GRF Register Description".

Tested with an mSATA SSD on sata2 (combphy2_psu). Before:

  ata2: SATA link up 1.5 Gbps (SStatus 113 SControl 300)
  Timing O_DIRECT disk reads: 374 MB in 3.01 seconds = 124.45 MB/sec

After:

  ata2: SATA link up 6.0 Gbps (SStatus 133 SControl 300)
  Timing O_DIRECT disk reads: 1266 MB in 3.00 seconds = 421.78 MB/sec

Fixes: a03c44277253 ("phy: rockchip: Add naneng combo phy support for RK3588")
Cc: stable@vger.kernel.org
Signed-off-by: Yifeng Zhao <yifeng.zhao@rock-chips.com>
[rewrite commit message]
Reviewed-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
Only sata2 was tested. U-Boot has the same table and the same problem;
the fix was sent there in [1].

[1] https://patch.msgid.link/20261109-rk3588-sata-fixes-v2027-01-v1-0-e54ca8e68f18@pardini.net
---
Changes in v2:
- Author is now Yifeng Zhao, who wrote the fix in the Rockchip BSP
  kernel; add his Signed-off-by (Sebastian)
- Move the PCIe link reset grant note into the commit message (Sebastian)
- Drop the BSP history sentence, the BSP Link: and the Cc (Sebastian)
- Trim the notes below the fold (Sebastian)
- Collect Sebastian's Reviewed-by
- Link to v1: https://patch.msgid.link/20261109-rk3588-combphy-sata2-6g-v1-1-e9135c91de6a@pardini.net
---
 drivers/phy/rockchip/phy-rockchip-naneng-combphy.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c b/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c
index 3102a99128f6..c469222dba8b 100644
--- a/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c
+++ b/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c
@@ -1395,7 +1395,7 @@ static const struct rockchip_combphy_grfcfg rk3588_combphy_grfcfgs = {
 	.con3_for_sata		= { 0x000c, 15, 0, 0x00, 0x0407 },
 	/* pipe-grf */
 	.pipe_con0_for_sata	= { 0x0000, 11, 5, 0x00, 0x22 },
-	.pipe_con1_for_sata	= { 0x0000, 2, 0, 0x00, 0x2 },
+	.pipe_con1_for_sata	= { 0x0004, 2, 0, 0x00, 0x2 },
 	.pipe_pcie1l0_sel	= { 0x0100, 0, 0, 0x01, 0x0 },
 	.pipe_pcie1l1_sel	= { 0x0100, 1, 1, 0x01, 0x0 },
 };

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261024-rk3588-combphy-sata2-6g-03bb30151552

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

