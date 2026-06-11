From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Thu, 11 Jun 2026 14:55:39 -0700
Subject: [PATCH net v5 2/4] net: ethernet: oa_tc6: mdiobus->parent
 initialized with NULL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260611-level-trigger-v5-2-4533a9e85ce2@onsemi.com>
References: <20260611-level-trigger-v5-0-4533a9e85ce2@onsemi.com>
In-Reply-To: <20260611-level-trigger-v5-0-4533a9e85ce2@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>
Cc: Andrew Lunn <andrew@lunn.ch>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 devicetree@vger.kernel.org, 
 Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781214947; l=1364;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=t+dmUxmhz+NSvTxVN33pXrsCLCkCj0A5Bx5yqncn/ig=;
 b=SkapaNnxGJcsM1J0VF4hAwiBSRzQVsHp2MRugT+VyfsnajInTDc6CHmD91efGhifz9rwphcyU
 OqMNQogUT66BNFLmw8wD9e4B5NjEBaK2lLeP+tQYDBPaEKoo81bJrON
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As "dev" pointer in oa_tc6 structure is never initialized,
mbiobus->parent was initialized with NULL.  This change
fixes it by initializing it with device pointer of spi.

Fixes: 8f9bf857e43b ("net: ethernet: oa_tc6: implement internal PHY initialization")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v5:
  Changed Fixes: commit ID to accurately reflect where issue originated
changes in v4:
   new patch
---
 drivers/net/ethernet/oa_tc6.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index f3ac2875adfb..477ceefde2c5 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -110,7 +110,6 @@
 
 /* Internal structure for MAC-PHY drivers */
 struct oa_tc6 {
-	struct device *dev;
 	struct net_device *netdev;
 	struct phy_device *phydev;
 	struct mii_bus *mdiobus;
@@ -520,7 +519,7 @@ static int oa_tc6_mdiobus_register(struct oa_tc6 *tc6)
 	tc6->mdiobus->read_c45 = oa_tc6_mdiobus_read_c45;
 	tc6->mdiobus->write_c45 = oa_tc6_mdiobus_write_c45;
 	tc6->mdiobus->name = "oa-tc6-mdiobus";
-	tc6->mdiobus->parent = tc6->dev;
+	tc6->mdiobus->parent = &tc6->spi->dev;
 
 	snprintf(tc6->mdiobus->id, ARRAY_SIZE(tc6->mdiobus->id), "%s",
 		 dev_name(&tc6->spi->dev));

-- 
2.43.0

