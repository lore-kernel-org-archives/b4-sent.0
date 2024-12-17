From: Hans-Frieder Vogt <hfdevel@gmx.net>
Date: Tue, 17 Dec 2024 22:07:33 +0100
Subject: [PATCH net-next v3 2/7] net: phy: aquantia: add probe function to
 aqr105 for firmware loading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241217-tn9510-v3a-v3-2-4d5ef6f686e0@gmx.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734469657; l=857;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=O5mlrVhtjAYbCCzI+ndsrKr3J5xvxej0+u1cLQwUG08=;
 b=NIUZiVfs8wwgDLkPxzZzdL/0qmz2uL9oWi6fZrjCH3Az8lkI41JKlfq4E/d+H0/1+sT/m1szY
 xV4e/tFK8w2DWm2z7N/SCVL+OQ9hDyFJdFWByGFZTctMxumzCEiysm4
X-Developer-Key: i=hfdevel@gmx.net; a=ed25519;
 pk=s3DJ3DFe6BJDRAcnd7VGvvwPXcLgV8mrfbpt8B9coRc=
X-Endpoint-Received: by B4 Relay for hfdevel@gmx.net/20240915 with auth_id=209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Re-use the AQR107 probe function to load the firmware on the AQR105 (and
to probe the HWMON).

Signed-off-by: Hans-Frieder Vogt <hfdevel@gmx.net>
---
 drivers/net/phy/aquantia/aquantia_main.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/phy/aquantia/aquantia_main.c b/drivers/net/phy/aquantia/aquantia_main.c
index bb56a66d2a48fab35eac87f75ad030a3ca6d9ec0..81eeee29ba3e6fb11a476a5b51a8a8be061ca8c3 100644
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
2.45.2

