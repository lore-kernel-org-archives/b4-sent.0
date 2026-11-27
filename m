From: Ricardo Pardini <ricardo@pardini.net>
Date: Fri, 27 Nov 2026 14:12:59 +0100
Subject: [PATCH v2 2/4] ata: dwc_ahci: get the PHY from the sata-port
 subnodes if any
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-rk3588-sata-fixes-v2027-01-v2-2-dbdf7770972a@pardini.net>
References: <20261127-rk3588-sata-fixes-v2027-01-v2-0-dbdf7770972a@pardini.net>
In-Reply-To: <20261127-rk3588-sata-fixes-v2027-01-v2-0-dbdf7770972a@pardini.net>
To: u-boot@lists.u-boot-project.org, Simon Glass <sjg@chromium.org>, 
 Kever Yang <kever.yang@rock-chips.com>, Eugen Hristev <ehristev@kernel.org>, 
 Jon Lin <jon.lin@rock-chips.com>
Cc: Tom Rini <trini@konsulko.com>, Peng Fan <peng.fan@nxp.com>, 
 Ricardo Pardini <ricardo@pardini.net>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Heiko Stuebner <heiko@sntech.de>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1329; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=jMc4maRHATqvBOpmaGWwi0WL8TS7p4hi/1K0YzF8JMw=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBrCYIZr4XAedgn/zbutvGOIHKJStkEhdoInLmn+
 Hnyk8b0U/WJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCawmCGQAKCRA7Xj/jnsft
 6c7TB/4+K5mHIhzPlYF2pg5uasJmt1KFvbbnPSoXXW6foxl+Pr0AOYqXo3KEMcLaHkiZsH1SPbY
 KttVq8b8OFOHmIKTGl9q6WtkEYa/2PXFEtUIxz5RHRJA8lVzFVPKcgkqaG923dyPBjKOO8ek30N
 C5A+toyoTtQcXlhmz0Wu6zS9qG05toSRSIcuq2jYufIEiBiUm1i+8HTFUvCFtbb4S6awmUYjtQf
 McDnLoyjzxGGmgfGxVeTJ236+B81swez3kMhe3SA6itBBq8ZFSC8BNBR/iN+9aa9E1Zy80yDcjg
 bXqBguEkay8jf6GPKRTRDNiVo4a4GRpQvuzeMUSWj6iFU7+p
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the controller node has sata-port subnodes, take the PHY of the
first enabled one instead, like Linux's libahci_platform does.

This fixes probing on RK3588 and on RK356x sata1/sata2, whose DTs
have the PHY in sata-port@0.

Link: https://patch.msgid.link/20260201191804.41421-2-heiko@sntech.de
Cc: Jonas Karlman <jonas@kwiboo.se>
Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 drivers/ata/dwc_ahci.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/drivers/ata/dwc_ahci.c b/drivers/ata/dwc_ahci.c
index 138a025cb02..97315441950 100644
--- a/drivers/ata/dwc_ahci.c
+++ b/drivers/ata/dwc_ahci.c
@@ -55,8 +55,20 @@ static int dwc_ahci_probe(struct udevice *dev)
 	struct dwc_ahci_priv *priv = dev_get_priv(dev);
 	int ret;
 	struct phy phy;
-
-	ret = generic_phy_get_by_index(dev, 0, &phy);
+	ofnode node;
+
+	/* Like Linux: first enabled sata-port subnode, else the controller */
+	if (dev_get_child_count(dev)) {
+		ret = -ENODEV;
+		dev_for_each_subnode(node, dev) {
+			if (!ofnode_is_enabled(node))
+				continue;
+			ret = generic_phy_get_by_index_nodev(node, 0, &phy);
+			break;
+		}
+	} else {
+		ret = generic_phy_get_by_index(dev, 0, &phy);
+	}
 	if (ret) {
 		pr_err("can't get the phy from DT\n");
 		return ret;

-- 
2.47.3

