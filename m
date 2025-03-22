From: Hans-Frieder Vogt <hfdevel@gmx.net>
Date: Sat, 22 Mar 2025 11:45:57 +0100
Subject: [PATCH net-next v7 6/7] net: tn40xx: prepare tn40xx driver to find
 phy of the TN9510 card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-tn9510-v3a-v7-6-672a9a3d8628@gmx.net>
References: <20250322-tn9510-v3a-v7-0-672a9a3d8628@gmx.net>
In-Reply-To: <20250322-tn9510-v3a-v7-0-672a9a3d8628@gmx.net>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hans-Frieder Vogt <hfdevel@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742640367; l=1514;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=FHzhMDcYn0WJzfuyGOmQtKpwwoxyjDmyIphfAS+vBhs=;
 b=uQlQ8T5Hbx7d/6MmwN7+kijl2U1ZplgP0Ix453kZ3ck22Exwb2uSxqye1AQ/iR4p3qmBK4/nv
 xf5gH6Iw3AeDNco0sJqm5h/4IqjcWAALHkBQThKwFssRU1kAWis0GD1
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
Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Reviewed-by: FUJITA Tomonori <fujita.tomonori@gmail.com>
---
 drivers/net/ethernet/tehuti/tn40_mdio.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/tehuti/tn40_mdio.c b/drivers/net/ethernet/tehuti/tn40_mdio.c
index 5bb0cbc87d064e3f697a88f5b96bc9a38a2ffd12..fb1a4a2e4dbc552a90934ab92300fcd98ef903c4 100644
--- a/drivers/net/ethernet/tehuti/tn40_mdio.c
+++ b/drivers/net/ethernet/tehuti/tn40_mdio.c
@@ -200,13 +200,13 @@ int tn40_mdiobus_init(struct tn40_priv *priv)
 		}
 	}
 
+	tn40_mdio_set_speed(priv, TN40_MDIO_SPEED_6MHZ);
 	ret = devm_mdiobus_register(&pdev->dev, bus);
 	if (ret) {
 		dev_err(&pdev->dev, "failed to register mdiobus %d %u %u\n",
 			ret, bus->state, MDIOBUS_UNREGISTERED);
 		goto err_swnodes_cleanup;
 	}
-	tn40_mdio_set_speed(priv, TN40_MDIO_SPEED_6MHZ);
 	return 0;
 
 err_swnodes_unregister:

-- 
2.47.2

