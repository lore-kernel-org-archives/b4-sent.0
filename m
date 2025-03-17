From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 17 Mar 2025 08:48:34 +0100
Subject: [PATCH v2] net: phy: dp83822: fix transmit amplitude if
 CONFIG_OF_MDIO not defined
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250317-dp83822-fix-transceiver-mdio-v2-1-fb09454099a4@liebherr.com>
X-B4-Tracking: v=1; b=H4sIANHT12cC/33NTQrCMBCG4avIrB1JUvrnyntIF2kytQO2KZMSl
 NK7G4trl+/H8MwGkYQpwvW0gVDiyGHOYc4ncKOdH4Tsc4NRplSFqtEvTdEYgwO/cBU7R0ecSHD
 yHNCSqQfyjaraFjKxCOW7g793uUeOa5D38S3p7/qDtfkPJ40a675qtSpcaXt1ezL1I4lcXJig2
 /f9A/ihkyvLAAAA
X-Change-ID: 20250307-dp83822-fix-transceiver-mdio-ae27fed80699
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Gerhard Engleder <gerhard@engleder-embedded.com>, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742197722; l=1728;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=FhqMIOb8gc2Jav0LaFqqWUr8RHshzd6zjF1Tsp9SwHE=;
 b=ifMh5cTdVqfJsVw55g9MZH0HPHvMRRp5+iHIXIUZ/jcdHC6dyZVBGvJ9B5a5X41RZd4NGGkZe
 AzYUzbWKdTCC6/280VSUMVon22/UGMuBCGlB7wudQFvdpHIck4lur7p
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When CONFIG_OF_MDIO is not defined the index for selecting the transmit
amplitude voltage for 100BASE-TX is set to 0, but it should be -1, if there
is no need to modify the transmit amplitude voltage. Move initialization of
the index from dp83822_of_init to dp8382x_probe.

Fixes: 4f3735e82d8a ("net: phy: dp83822: Add support for changing the transmit amplitude voltage")
Reviewed-by: Gerhard Engleder <gerhard@engleder-embedded.com>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v2:
- Drop tx_amplitude_100base_tx_index_modify
- Init tx_amplitude_100base_tx_index in dp8382x_probe
- Link to v1: https://lore.kernel.org/r/20250312-dp83822-fix-transceiver-mdio-v1-1-7b69103c5ab0@liebherr.com
---
 drivers/net/phy/dp83822.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/phy/dp83822.c b/drivers/net/phy/dp83822.c
index 3662f3905d5ade8ad933608fcaeabb714a588418..14f36154963841dff98be5af4dfbd2760325c13d 100644
--- a/drivers/net/phy/dp83822.c
+++ b/drivers/net/phy/dp83822.c
@@ -833,7 +833,6 @@ static int dp83822_of_init(struct phy_device *phydev)
 		dp83822->set_gpio2_clk_out = true;
 	}
 
-	dp83822->tx_amplitude_100base_tx_index = -1;
 	ret = phy_get_tx_amplitude_gain(phydev, dev,
 					ETHTOOL_LINK_MODE_100baseT_Full_BIT,
 					&val);
@@ -931,6 +930,7 @@ static int dp8382x_probe(struct phy_device *phydev)
 	if (!dp83822)
 		return -ENOMEM;
 
+	dp83822->tx_amplitude_100base_tx_index = -1;
 	phydev->priv = dp83822;
 
 	return 0;

---
base-commit: bfc6c67ec2d64d0ca4e5cc3e1ac84298a10b8d62
change-id: 20250307-dp83822-fix-transceiver-mdio-ae27fed80699

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

