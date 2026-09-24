From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Date: Thu, 24 Sep 2026 12:48:18 +0200
Subject: [PATCH net-next v2] net: phy: mxl-gpy: add 2.5G for MXL86211C
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-mainline-rouven-mxl2g5-v2-1-fc8367a4c3ad@linaro.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WOQQ6DIBREr2L+ujTwDVq76j0aF6hfpVFoAImN8
 e5Fe4AuJzNvZjbw5DR5uGcbOIraa2uSwEsG7ajMQEx3SQNyLHiFyGalzaQNMWeXSIbN64SDZCU
 2rRQd3qqSQ4Lfjnq9nsVPMBSYoTVA/XP80ryoDUfvkR21D9Z9zg9RnMS/uSiYYIpTJ/MiF0r2j
 xRSzl6tG6De9/0LFfjFg9kAAAA=
X-Change-ID: 20260922-mainline-rouven-mxl2g5-72bc51d28970
To: Xu Liang <lxu@maxlinear.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Daniel Golle <daniel@makrotopia.org>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790246899; l=1635;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=pedhSXhCXKROiJuybTwA78NJnL4APYoFo51G1JpeoQo=;
 b=cmQqF/rb11o7qo13y20RyMgHjULPMyxDxiVftIoo7m1LhqkubyIySVl3QbD7rnu4cuDOV222w
 2ggwoUnUR4zBriij6Wy5+NnrDe4lhGd6wt2Un88nLTHUq/F42xyn8FH
X-Developer-Key: i=rouven.czerwinski@linaro.org; a=ed25519;
 pk=/5pmUK/XIAIIo8JA0axgfy1k8NRhRTQkxVwZYa1ga7U=
X-Endpoint-Received: by B4 Relay for rouven.czerwinski@linaro.org/20260126 with auth_id=616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MXL86211C also supports 2.5G via 2500BASEX, switch the config init
to indicate support for that mode. Datasheet checks indicate that the
2.5G speed indication is the same between GPY211 & MXL86211C.

The same should be true for MXL86252 & MXL86282, those are not modified
for a lack of testing hardware.

With this change 2.5G negotiates correctly with a Mikrotik
CRS310-8G+2S+IN.

Fixes: 9d844da693d6 ("net: phy: mxl-gpy: add support for MxL86211C")
Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Rouven Czerwinski <rouven.czerwinski@linaro.org>
---
Changes in v2:
- Fix typos: Fix Typo swaps of *68*211 to *86211*
- add Fixes: trailer
both suggested by Sashiko
- Link to v1: https://patch.msgid.link/20260922-mainline-rouven-mxl2g5-v1-1-a0ed53631a5f@linaro.org
---
 drivers/net/phy/mxl-gpy.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/phy/mxl-gpy.c b/drivers/net/phy/mxl-gpy.c
index 0da2d4e9d8548..089a1a9e5bc61 100644
--- a/drivers/net/phy/mxl-gpy.c
+++ b/drivers/net/phy/mxl-gpy.c
@@ -1405,7 +1405,7 @@ static struct phy_driver gpy_drivers[] = {
 		PHY_ID_MATCH_MODEL(PHY_ID_MXL86211C),
 		.name		= "Maxlinear Ethernet MxL86211C",
 		.get_features	= genphy_c45_pma_read_abilities,
-		.config_init	= gpy_config_init,
+		.config_init	= gpy21x_config_init,
 		.probe		= gpy_probe,
 		.inband_caps	= gpy_inband_caps,
 		.config_inband	= gpy_config_inband,

---
base-commit: 2d7341a020a57b30c1826db38f81bbc257ae3bbc
change-id: 20260922-mainline-rouven-mxl2g5-72bc51d28970

Best regards,
--  
Rouven Czerwinski <rouven.czerwinski@linaro.org>

