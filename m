From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 03:57:58 +0100
Subject: [PATCH 1/3] ata: dwc_ahci: fall back to the PHY in the sata-port
 subnode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-rk3588-sata-fixes-v2027-01-v1-1-e54ca8e68f18@pardini.net>
References: <20261109-rk3588-sata-fixes-v2027-01-v1-0-e54ca8e68f18@pardini.net>
In-Reply-To: <20261109-rk3588-sata-fixes-v2027-01-v1-0-e54ca8e68f18@pardini.net>
To: u-boot@lists.u-boot-project.org, Simon Glass <sjg@chromium.org>, 
 Kever Yang <kever.yang@rock-chips.com>, Eugen Hristev <ehristev@kernel.org>, 
 Jon Lin <jon.lin@rock-chips.com>
Cc: Tom Rini <trini@konsulko.com>, Peng Fan <peng.fan@nxp.com>, 
 Ricardo Pardini <ricardo@pardini.net>, Quentin Schulz <u-boot@0leil.net>, 
 Jonas Karlman <jonas@kwiboo.se>, Heiko Stuebner <heiko@sntech.de>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2021; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=MaeLlyyV0DUNr5n18iGh2V4/rzNY16Gc/0SxdTgALc8=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8Ta2QFu+kMlaujlh6/ILQtN8GTlD9BXkRahpn
 LdtUN8+XEOJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavE2tgAKCRA7Xj/jnsft
 6X+/B/9Eb49J9eYxjoh3TTf7jju87NXs2+0/mHdxdGH63pu2XpcUN/2bmw1fVBi5obe4+MwolyG
 znD+sQDJ88egIFOXM9FD+LrSMK1KeeVbwk8hUqzF8SXq/K5pvwafbXboj1CMRDrAMhh/N0DrN6T
 cCkWhT0mu8/1x4KiINqm5AIt0N9PgMWjK7D6kHyjNyRXZsMx8Xp2yjKJlA8vmrJ7/tx9jY/VKAB
 ZYe/4inRUTwMQZ2AKORg4hMYuPNeL8SnuAzjDIxCpGXU20XmJdCy/SCUiZdXaZVJrqtFYflrPbw
 YVFR4qQvcWZC0qKS2gN8uBejtw2LzOnP/JczBjUgSBLCOnFL
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dwc_ahci_probe() only looks for a "sata-phy" PHY on the controller node.
The RK3588 device tree, as synced from Linux, describes the PHY in the
sata-port@0 subnode instead (the binding allows per-port PHYs, which is
how Linux's libahci_platform consumes them), so probing every RK3588
on-board SATA controller fails:

  => scsi scan
  scanning bus for devices...
  can't get the phy from DT

RK3566/RK3568 sata1 and sata2 have been affected the same way since the
v7.1 DT sync (d0a838bdc62), which brought in the Linux change "arm64:
dts: rockchip: Add port subnodes to RK356x SATA controllers" (linked
below). Only RK3568 sata0 still has the PHY on the controller node.

If the controller node has no "sata-phy" in phy-names, use the first PHY
of the first enabled subnode. A "sata-phy" that is declared but cannot
be resolved still fails the probe. Only one PHY is brought up, as
before; the RK3588 and RK356x controllers have a single port
(ports-implemented = <0x1>).

Only tested on RK3588.

Link: https://patch.msgid.link/20260201191804.41421-2-heiko@sntech.de
Cc: Jonas Karlman <jonas@kwiboo.se>
Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 drivers/ata/dwc_ahci.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/ata/dwc_ahci.c b/drivers/ata/dwc_ahci.c
index 0431d370716..8192d2f5f34 100644
--- a/drivers/ata/dwc_ahci.c
+++ b/drivers/ata/dwc_ahci.c
@@ -57,6 +57,19 @@ static int dwc_ahci_probe(struct udevice *dev)
 	struct phy phy;
 
 	ret = generic_phy_get_by_name(dev, "sata-phy", &phy);
+	if (ret && dev_read_stringlist_search(dev, "phy-names",
+					      "sata-phy") < 0) {
+		ofnode node;
+
+		/* e.g. RK35xx: the phy is in the sata-port@N subnode */
+		dev_for_each_subnode(node, dev) {
+			if (!ofnode_is_enabled(node))
+				continue;
+			ret = generic_phy_get_by_index_nodev(node, 0, &phy);
+			if (!ret)
+				break;
+		}
+	}
 	if (ret) {
 		pr_err("can't get the phy from DT\n");
 		return ret;

-- 
2.47.3

