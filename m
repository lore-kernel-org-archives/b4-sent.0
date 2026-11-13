From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 13 Nov 2026 08:59:33 -0800
Subject: [PATCH net-next v11 14/14] net: phy: dp83867: Use
 genphy_loopback_no_speed()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-s2500-mac-phy-support-v11-14-7a186141952c@onsemi.com>
References: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
In-Reply-To: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794589162; l=1372;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=87SU+XRFLyfHxWdkx39h3CNz/aAI9UytC7bQUseGhEI=;
 b=RwrVKWKMpM+IGE/WwBKcUeSKSSg29YqAKc2KsjnbELQcB0Ggn550Azc8Mce/HagQPEMb2oCkX
 snNK35YnaauDn2k0IPp1TGSJomMr51xqWiRaPeZ+e5QnuiioS+tKSDd
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace dp83867_loopback() with genphy_loopback_no_speed(), which
does the same. No functional change.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v11
  - Moved the vendor changes into its own patch.
  - New patch in v11.
---
 drivers/net/phy/dp83867.c | 11 +----------
 1 file changed, 1 insertion(+), 10 deletions(-)

diff --git a/drivers/net/phy/dp83867.c b/drivers/net/phy/dp83867.c
index b4b4931c6f8c..dc00484c6c7a 100644
--- a/drivers/net/phy/dp83867.c
+++ b/drivers/net/phy/dp83867.c
@@ -1057,15 +1057,6 @@ static void dp83867_link_change_notify(struct phy_device *phydev)
 	}
 }
 
-static int dp83867_loopback(struct phy_device *phydev, bool enable, int speed)
-{
-	if (enable && speed)
-		return -EOPNOTSUPP;
-
-	return phy_modify(phydev, MII_BMCR, BMCR_LOOPBACK,
-			  enable ? BMCR_LOOPBACK : 0);
-}
-
 static int
 dp83867_led_brightness_set(struct phy_device *phydev,
 			   u8 index, enum led_brightness brightness)
@@ -1291,7 +1282,7 @@ static struct phy_driver dp83867_driver[] = {
 		.resume		= dp83867_resume,
 
 		.link_change_notify = dp83867_link_change_notify,
-		.set_loopback	= dp83867_loopback,
+		.set_loopback	= genphy_loopback_no_speed,
 
 		.led_brightness_set = dp83867_led_brightness_set,
 		.led_hw_is_supported = dp83867_led_hw_is_supported,

-- 
2.43.0

