From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 12 Mar 2025 18:23:32 +0100
Subject: [PATCH] net: phy: dp83822: fix transmit amplitude if
 CONFIG_OF_MDIO not defined
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250312-dp83822-fix-transceiver-mdio-v1-1-7b69103c5ab0@liebherr.com>
X-B4-Tracking: v=1; b=H4sIABPD0WcC/x3MQQqDMBBG4avIrB1IJ6ixV5EugvnVWTTKpEhBv
 HtDlx883kUFpij0bC4ynFp0zxWPtqF5i3kFa6omcdI57wZOR/BBhBf98sdiLjP0hPE76c4RMix
 IwfXjSHVxGGr330+v+/4Bv2o46W4AAAA=
X-Change-ID: 20250307-dp83822-fix-transceiver-mdio-ae27fed80699
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741800212; l=1832;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=mTFreHX34pBc+oU2pNBg+ke78ROdzLxTH0hZJ0yVXyw=;
 b=E2EFw8PtEHMY2cU2EAObFNnLPVJSmYdJUHq4B1GKMusIPHWH28S+jC1WuDKZDUqDG8IEnSYiD
 b5VmYCuMFNbBaB+pnQkyQHGHSVBtAjeCgfanKaHVq5O9lZLUOwCHkG+
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When CONFIG_OF_MDIO is not defined the index for selecting the transmit
amplitude voltage for 100BASE-TX is set to 0, but it should be -1, if there
is no need to modify the transmit amplitude voltage. Add a flag to make
sure there is a need to modify it.

Fixes: 4f3735e82d8a ("net: phy: dp83822: Add support for changing the transmit amplitude voltage")
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/net/phy/dp83822.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/net/phy/dp83822.c b/drivers/net/phy/dp83822.c
index 3662f3905d5ade8ad933608fcaeabb714a588418..d69000cb0ceff28e8288ba24e0af1c960ea9cc97 100644
--- a/drivers/net/phy/dp83822.c
+++ b/drivers/net/phy/dp83822.c
@@ -201,6 +201,7 @@ struct dp83822_private {
 	bool set_gpio2_clk_out;
 	u32 gpio2_clk_out;
 	bool led_pin_enable[DP83822_MAX_LED_PINS];
+	bool tx_amplitude_100base_tx_modify;
 	int tx_amplitude_100base_tx_index;
 };
 
@@ -527,7 +528,7 @@ static int dp83822_config_init(struct phy_device *phydev)
 			       FIELD_PREP(DP83822_IOCTRL2_GPIO2_CLK_SRC,
 					  dp83822->gpio2_clk_out));
 
-	if (dp83822->tx_amplitude_100base_tx_index >= 0)
+	if (dp83822->tx_amplitude_100base_tx_modify)
 		phy_modify_mmd(phydev, MDIO_MMD_VEND2, MII_DP83822_LDCTRL,
 			       DP83822_100BASE_TX_LINE_DRIVER_SWING,
 			       FIELD_PREP(DP83822_100BASE_TX_LINE_DRIVER_SWING,
@@ -851,6 +852,8 @@ static int dp83822_of_init(struct phy_device *phydev)
 				   val);
 			return -EINVAL;
 		}
+
+		dp83822->tx_amplitude_100base_tx_modify = true;
 	}
 
 	return dp83822_of_init_leds(phydev);

---
base-commit: c62e6f056ea308d6382450c1cb32e41727375885
change-id: 20250307-dp83822-fix-transceiver-mdio-ae27fed80699

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

