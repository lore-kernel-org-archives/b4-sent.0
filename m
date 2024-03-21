From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Thu, 21 Mar 2024 19:29:14 +0300
Subject: [PATCH net v2 2/2] net: dsa: mt7530: fix disabling EEE on failure
 on MT7531 and MT7988
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240321-for-net-mt7530-fix-eee-for-mt7531-mt7988-v2-2-9af9d5041bfe@arinc9.com>
References: <20240321-for-net-mt7530-fix-eee-for-mt7531-mt7988-v2-0-9af9d5041bfe@arinc9.com>
In-Reply-To: <20240321-for-net-mt7530-fix-eee-for-mt7531-mt7988-v2-0-9af9d5041bfe@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 =?utf-8?q?Ren=C3=A9_van_Dorst?= <opensource@vdorst.com>, 
 Russell King <linux@armlinux.org.uk>, 
 SkyLake Huang <SkyLake.Huang@mediatek.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711038558; l=1925;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=DsZ4XshfmuCrCshjsgaop6WdjUbPqTHmbY230mILEL4=;
 b=G2zxEWZRPd7T5UKeb3EAgsPQG9cW8YK9hK0H++LcTnAJNjhhJgyhrSeiqfRJhNLEsGOYGv3YL
 Xz5cm9hMjd9D4wjOKTWIi8jOtYCQjRFlvYMfzdA2Qu+EhTkWIamreOF
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MT7531_FORCE_EEE1G and MT7531_FORCE_EEE100 bits let the
PMCR_FORCE_EEE1G and PMCR_FORCE_EEE100 bits determine the 1G/100 EEE
abilities of the MAC. If MT7531_FORCE_EEE1G and MT7531_FORCE_EEE100 are
unset, the abilities are left to be determined by PHY auto polling.

The commit 40b5d2f15c09 ("net: dsa: mt7530: Add support for EEE features")
made it so that the PMCR_FORCE_EEE1G and PMCR_FORCE_EEE100 bits are set on
mt753x_phylink_mac_link_up(). But it did not set the MT7531_FORCE_EEE1G and
MT7531_FORCE_EEE100 bits. Because of this, EEE will be enabled on the
switch MACs by polling the PHY, regardless of the result of phy_init_eee().

Define these bits and add them to MT7531_FORCE_MODE which is being used by
the subdriver. With this, EEE will be prevented from being enabled on the
switch MACs when phy_init_eee() fails.

Fixes: 40b5d2f15c09 ("net: dsa: mt7530: Add support for EEE features")
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.h | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/net/dsa/mt7530.h b/drivers/net/dsa/mt7530.h
index 509ed5362236..5b99aeca34b4 100644
--- a/drivers/net/dsa/mt7530.h
+++ b/drivers/net/dsa/mt7530.h
@@ -299,11 +299,15 @@ enum mt7530_vlan_port_acc_frm {
 #define  MT7531_FORCE_DPX		BIT(29)
 #define  MT7531_FORCE_RX_FC		BIT(28)
 #define  MT7531_FORCE_TX_FC		BIT(27)
+#define  MT7531_FORCE_EEE100		BIT(26)
+#define  MT7531_FORCE_EEE1G		BIT(25)
 #define  MT7531_FORCE_MODE		(MT7531_FORCE_LNK | \
 					 MT7531_FORCE_SPD | \
 					 MT7531_FORCE_DPX | \
 					 MT7531_FORCE_RX_FC | \
-					 MT7531_FORCE_TX_FC)
+					 MT7531_FORCE_TX_FC | \
+					 MT7531_FORCE_EEE100 | \
+					 MT7531_FORCE_EEE1G)
 #define  PMCR_LINK_SETTINGS_MASK	(PMCR_TX_EN | PMCR_FORCE_SPEED_1000 | \
 					 PMCR_RX_EN | PMCR_FORCE_SPEED_100 | \
 					 PMCR_TX_FC_EN | PMCR_RX_FC_EN | \

-- 
2.40.1

