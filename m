From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sun, 14 Apr 2024 00:08:13 +0300
Subject: [PATCH net-next] net: phy: mediatek-ge: do not disable EEE
 advertisement
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240414-for-netnext-mediatek-ge-do-not-disable-eee-adv-v1-1-2fefd63c990b@arinc9.com>
X-B4-Tracking: v=1; b=H4sIADz0GmYC/x3N2wrCMBCE4Vcpe+1CE4unV5FepNmJLmoiSSiF0
 nc39fKH4ZuVCrKi0K1bKWPWoim2MIeO/NPFB1ilNdneDv3RGg4pc0SNWCp/IOoqXtxmkjimyqL
 FTW8wAHYy83Q6S/A+XC/GUEO/GUGX/+GdmsM7ROO2/QBWJbCvigAAAA==
To: Daniel Golle <daniel@makrotopia.org>, Qingfang Deng <dqfext@gmail.com>, 
 SkyLake Huang <SkyLake.Huang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: mithat.guner@xeront.com, erkin.bozoglu@xeront.com, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713042497; l=1262;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=3+tGyLYc9tR5wwy3EghRPXT4LZ9a92aLjvNesVkpu9o=;
 b=W1Dn4HFVHIUCOJTQtcShYgKgcG7Ck+OXjRDh/mAj+PHLqe0nx8zL743Qod1CUINXYtPSl+N4t
 1RNaO8X4jOcCOCKSeamjbRPXGI3W7B8FkPtIlDoQG0kl4AFu1DlEgDG
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mediatek-ge PHY driver already disables EEE advertisement on the switch
PHYs but my testing [1] shows that it is somehow enabled afterwards.
Disabling EEE advertisement before the PHY driver initialises keeps it off.
Therefore, remove disabling EEE advertisement here as it's useless.

Link: https://lore.kernel.org/netdev/d286ea27-e911-4dcb-9037-b75f22b437b8@arinc9.com/ [1]
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/phy/mediatek-ge.c | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/drivers/net/phy/mediatek-ge.c b/drivers/net/phy/mediatek-ge.c
index a493ae01b267..54ea64a37ab3 100644
--- a/drivers/net/phy/mediatek-ge.c
+++ b/drivers/net/phy/mediatek-ge.c
@@ -23,9 +23,6 @@ static int mtk_gephy_write_page(struct phy_device *phydev, int page)
 
 static void mtk_gephy_config_init(struct phy_device *phydev)
 {
-	/* Disable EEE */
-	phy_write_mmd(phydev, MDIO_MMD_AN, MDIO_AN_EEE_ADV, 0);
-
 	/* Enable HW auto downshift */
 	phy_modify_paged(phydev, MTK_PHY_PAGE_EXTENDED, 0x14, 0, BIT(4));
 

---
base-commit: 32affa5578f0e6b9abef3623d3976395afbd265c
change-id: 20240321-for-netnext-mediatek-ge-do-not-disable-eee-adv-b67dfccf9811

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

