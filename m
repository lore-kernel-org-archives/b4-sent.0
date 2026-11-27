From: Ricardo Pardini <ricardo@pardini.net>
Date: Fri, 27 Nov 2026 14:12:58 +0100
Subject: [PATCH v2 1/4] ata: dwc_ahci: use the first PHY, ignoring
 phy-names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-rk3588-sata-fixes-v2027-01-v2-1-dbdf7770972a@pardini.net>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=787; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=wm01rhWtnsB77YGcacSw/rSmvhsvQkWhSu/IMB4QbQw=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBrCYIZDtEIDQ15EoFitiYMwgx7dgRicZQgmrW/9
 ULnuCTriL2JATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCawmCGQAKCRA7Xj/jnsft
 6auoCACTaao9NX2DHHM3wQEI6Xcz/nHbtygvFBH0QsV9PhRyegyDraDORpOR8oibkSaZ/09lqkX
 zlU480UvzJ6bhszBdZUbV5lXS/eQdfBv6rDgP0+RQDddigvmWfGFw7Kuhc06yF0IGFkIDHnuzhe
 7ypfdDPCw508SaLx20H2eAG3WRVl9YE16A5taodz6y14lmpzQCJHyuRB9Pyb5ZAZ60HD6J+0LWg
 gEyi/KUyRu1E4/DUyIWjnVxUV5xYVVZr6N0awhtfU4Hw2vew1nteUPn8yXOm19x/GfUetmIcvXY
 aItzsqI1zzdU366AhlsIyRLEp7CI+rLvxjNJpz4f6mOUckkI
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Take the first PHY of the controller node instead of looking it up
by the "sata-phy" name, like Linux's libahci_platform does. The
binding allows a single PHY and phy-names is optional.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 drivers/ata/dwc_ahci.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/ata/dwc_ahci.c b/drivers/ata/dwc_ahci.c
index 0431d370716..138a025cb02 100644
--- a/drivers/ata/dwc_ahci.c
+++ b/drivers/ata/dwc_ahci.c
@@ -56,7 +56,7 @@ static int dwc_ahci_probe(struct udevice *dev)
 	int ret;
 	struct phy phy;
 
-	ret = generic_phy_get_by_name(dev, "sata-phy", &phy);
+	ret = generic_phy_get_by_index(dev, 0, &phy);
 	if (ret) {
 		pr_err("can't get the phy from DT\n");
 		return ret;

-- 
2.47.3

