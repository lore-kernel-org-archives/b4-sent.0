From: Hans-Frieder Vogt <hfdevel@gmx.net>
Date: Tue, 17 Dec 2024 22:07:37 +0100
Subject: [PATCH net-next v3 6/7] net: tn40xx: prepare tn40xx driver to find
 phy of the TN9510 card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241217-tn9510-v3a-v3-6-4d5ef6f686e0@gmx.net>
References: <20241217-tn9510-v3a-v3-0-4d5ef6f686e0@gmx.net>
In-Reply-To: <20241217-tn9510-v3a-v3-0-4d5ef6f686e0@gmx.net>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, Hans-Frieder Vogt <hfdevel@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734469657; l=1416;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=rESsj+vd7KGKfozt3aHW3N4Wnw4DdcDrscsB4sUdilI=;
 b=xf0hdxtZyuXoEfg78h7+uWKrxqCrXtjcIE1fYmrVWHkjXeNAkCbLsnoun5jW49gku5zbj3SOZ
 zfwcEafc4TrDdBF7T5PN34qqNyG7DfiqjHoV47qzdAQrYELwyLXnZow
X-Developer-Key: i=hfdevel@gmx.net; a=ed25519;
 pk=s3DJ3DFe6BJDRAcnd7VGvvwPXcLgV8mrfbpt8B9coRc=
X-Endpoint-Received: by B4 Relay for hfdevel@gmx.net/20240915 with auth_id=209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Prepare the tn40xx driver to load for Tehuti TN9510 cards, which require
bit 3 in the register TN40_REG_MDIO_CMD_STAT to be set. The function of bit
3 is unclear, but may have something to do with the length of the preamble
in the MDIO communication. If bit 3 is not set, the PHY will not be found
when performing a scan for PHYs. Use the available tn40_mdio_set_speed
function which includes setting bit 3. Just move the function to before the
devm_mdio_register function, which scans the mdio bus for PHYs.

Signed-off-by: Hans-Frieder Vogt <hfdevel@gmx.net>
---
 drivers/net/ethernet/tehuti/tn40_mdio.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/tehuti/tn40_mdio.c b/drivers/net/ethernet/tehuti/tn40_mdio.c
index b8ee553f60d1beadeda828584adfea670f0d4ca8..993458cc49322de3466c604385dca64d4c3b949f 100644
--- a/drivers/net/ethernet/tehuti/tn40_mdio.c
+++ b/drivers/net/ethernet/tehuti/tn40_mdio.c
@@ -185,13 +185,13 @@ int tn40_mdiobus_init(struct tn40_priv *priv)
 			ret);
 	}
 
+	tn40_mdio_set_speed(priv, TN40_MDIO_SPEED_6MHZ);
 	ret = devm_mdiobus_register(&pdev->dev, bus);
 	if (ret) {
 		dev_err(&pdev->dev, "failed to register mdiobus %d %u %u\n",
 			ret, bus->state, MDIOBUS_UNREGISTERED);
 		goto err_swnodes_unregister;
 	}
-	tn40_mdio_set_speed(priv, TN40_MDIO_SPEED_6MHZ);
 	priv->mdio = bus;
 	return 0;
 

-- 
2.45.2

