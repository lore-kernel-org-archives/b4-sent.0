From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 03:58:00 +0100
Subject: [PATCH 3/3] phy: rockchip: naneng-combphy: fix RK3588 SATA
 pipe_con1 register offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-rk3588-sata-fixes-v2027-01-v1-3-e54ca8e68f18@pardini.net>
References: <20261109-rk3588-sata-fixes-v2027-01-v1-0-e54ca8e68f18@pardini.net>
In-Reply-To: <20261109-rk3588-sata-fixes-v2027-01-v1-0-e54ca8e68f18@pardini.net>
To: u-boot@lists.u-boot-project.org, Simon Glass <sjg@chromium.org>, 
 Kever Yang <kever.yang@rock-chips.com>, Eugen Hristev <ehristev@kernel.org>, 
 Jon Lin <jon.lin@rock-chips.com>
Cc: Tom Rini <trini@konsulko.com>, Peng Fan <peng.fan@nxp.com>, 
 Ricardo Pardini <ricardo@pardini.net>, Quentin Schulz <u-boot@0leil.net>, 
 Jonas Karlman <jonas@kwiboo.se>, Heiko Stuebner <heiko@sntech.de>, 
 Yifeng Zhao <yifeng.zhao@rock-chips.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2126; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=Q3Cve4zvVjlX4+VTW+xM72LErIs4mz3VhCpxoPE6y/4=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8Ta3M7L0/Nl8Tc5vBtggHZLTrmXK/So4jVgWX
 mdPhxH+Ac2JATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavE2twAKCRA7Xj/jnsft
 6bEyB/4sTpXpmQEwMi8gaXfvQf53SrWReltxgZ7peZ+wKfSXW7YtOlVnuRLRPTP2a2otGDI/oQP
 Uf1GMjuDwAmt19N/7r22Uz89D4gs1BLNIpwXfm4TFZt9DDkXlSgnbCYbu4c06t5aaAjgz2N+1sd
 smbzYfCjncXzl2rNwPo6xk3PBOB8YmkfY2H1NjWu75QBh4JyXqqjB9mhvqViHfo2zW3sGDJ2xD1
 JxtEiXVDNSMEAL+H5CGskw9ESLwQ7842ce+LJEnU95vDrAtHunkLe0nz9olfNZFViYH6p/i8CaI
 zGK/U4uYhTjho6tVAXxMHL2TDlNwPUCHbRunCPkiAM+ZdG6i
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On RK3588, the sata2 PHY speed is selected by sata2_phy_spdmode in
PHP_GRF_PHP_CON1[1:0] (offset 0x0004), with sata2_phy_rx_err in bit 2.
rk3588_combphy_grfcfgs has pipe_con1_for_sata at offset 0x0000 though,
so the value 0x2 (6.0 Gb/s, rx_err cleared) ends up in PHP_GRF_PHP_CON0
and CON1 is never written.

This leaves sata2 at its 1.5 Gb/s reset value, so the link only trains
at 1.5 Gb/s, even with a 6 Gb/s capable disk. sata0 and sata1 are not
affected: their speed fields are in PHP_GRF_PHP_CON0 and are set by
pipe_con0_for_sata.

The register layout is described in the RK3588 TRM V1.0 Part1, section
6.17 "PHP_GRF Register Description". Rockchip fixed this in their BSP
kernel in 2022 by moving pipe_con1_for_sata to offset 0x0004; the same
fix was sent for Linux.

Tested with an mSATA SSD on sata2 (combphy2_psu): PxSSTS (0xfe230128)
reads 0x113 (1.5 Gb/s) before and 0x133 (6.0 Gb/s) after.

Fixes: c5b4a012bca8 ("phy: rockchip: naneng-combphy: Support rk3588")
Link: https://github.com/rockchip-linux/kernel/commit/2f5fe2c0bbd4fa95102aadd60da1100989103aa0
Link: https://patch.msgid.link/20261109-rk3588-combphy-sata2-6g-v1-1-e9135c91de6a@pardini.net
Cc: Yifeng Zhao <yifeng.zhao@rock-chips.com>
Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 drivers/phy/rockchip/phy-rockchip-naneng-combphy.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c b/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c
index 82353ae7678..675401e085f 100644
--- a/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c
+++ b/drivers/phy/rockchip/phy-rockchip-naneng-combphy.c
@@ -727,7 +727,7 @@ static const struct rockchip_combphy_grfcfg rk3588_combphy_grfcfgs = {
 	.con3_for_sata		= { 0x000c, 15, 0, 0x00, 0x0407 },
 	/* pipe-grf */
 	.pipe_con0_for_sata	= { 0x0000, 11, 5, 0x00, 0x22 },
-	.pipe_con1_for_sata	= { 0x0000, 2, 0, 0x00, 0x2 },
+	.pipe_con1_for_sata	= { 0x0004, 2, 0, 0x00, 0x2 },
 	.pipe_pcie1l0_sel	= { 0x0100, 0, 0, 0x01, 0x0 },
 	.pipe_pcie1l1_sel	= { 0x0100, 1, 1, 0x01, 0x0 },
 };

-- 
2.47.3

