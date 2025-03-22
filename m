From: Hans-Frieder Vogt <hfdevel@gmx.net>
Date: Sat, 22 Mar 2025 11:45:53 +0100
Subject: [PATCH net-next v7 2/7] net: phy: aquantia: add probe function to
 aqr105 for firmware loading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-tn9510-v3a-v7-2-672a9a3d8628@gmx.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742640367; l=900;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=vEeavGZyiKSDFemLfNRy5gMMBOs/2nb7oTqi4HS4XIQ=;
 b=NrBz3etyWZ8DkFcMAlVhUSvqUGbeYUtAKAjnx9by5Hve6YA0Nt0I9itwtk9xMmfGuewQHOJjm
 A76ERMrz8R0Ae5cIcH7RWbuQHAlYZNA0+qjTCmvjrKyk1Om6WkrCBmZ
X-Developer-Key: i=hfdevel@gmx.net; a=ed25519;
 pk=s3DJ3DFe6BJDRAcnd7VGvvwPXcLgV8mrfbpt8B9coRc=
X-Endpoint-Received: by B4 Relay for hfdevel@gmx.net/20240915 with auth_id=209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Re-use the AQR107 probe function to load the firmware on the AQR105 (and
to probe the HWMON).

Signed-off-by: Hans-Frieder Vogt <hfdevel@gmx.net>
Reviewed-by: Andrew Lunn <andrew@lunn.ch>
---
 drivers/net/phy/aquantia/aquantia_main.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/phy/aquantia/aquantia_main.c b/drivers/net/phy/aquantia/aquantia_main.c
index e42ace4e682aacf56199b7fdb9613d20f240fa27..86b0e63de5d88fa1050919a8826bdbec4bbcf8ba 100644
--- a/drivers/net/phy/aquantia/aquantia_main.c
+++ b/drivers/net/phy/aquantia/aquantia_main.c
@@ -912,6 +912,7 @@ static struct phy_driver aqr_driver[] = {
 	PHY_ID_MATCH_MODEL(PHY_ID_AQR105),
 	.name		= "Aquantia AQR105",
 	.config_aneg    = aqr_config_aneg,
+	.probe		= aqr107_probe,
 	.config_intr	= aqr_config_intr,
 	.handle_interrupt = aqr_handle_interrupt,
 	.read_status	= aqr_read_status,

-- 
2.47.2

