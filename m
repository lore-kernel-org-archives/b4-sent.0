From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Fri, 19 Apr 2024 13:09:24 +0300
Subject: [PATCH net-next 01/13] net: dsa: mt7530: disable EEE abilities on
 failure on MT7531 and MT7988
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240419-for-netnext-mt7530-improvements-4-v1-1-6d852ca79b1d@arinc9.com>
References: <20240419-for-netnext-mt7530-improvements-4-v1-0-6d852ca79b1d@arinc9.com>
In-Reply-To: <20240419-for-netnext-mt7530-improvements-4-v1-0-6d852ca79b1d@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713521374; l=3406;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=1dA5Tqo1oiLbTJdCrnbheqEyfiDY3WFrwARn+Ftc72o=;
 b=UO3hPYTxBJo1mK0GV+DML+3WC507lLVCAZaSDKCUa50HDDTamo4u6Lug3dOxyYxfuxU7+S0nj
 JyMPdPBjZ7ZDNOx2QVMov1G6N7F5CIQ2nMMXrw5qavBN57Jh1EiFU3l
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MT7531_FORCE_EEE1G and MT7531_FORCE_EEE100 bits let the
PMCR_FORCE_EEE1G and PMCR_FORCE_EEE100 bits determine the 1G/100 EEE
abilities of the MAC. If MT7531_FORCE_EEE1G and MT7531_FORCE_EEE100 are
unset, the abilities are left to be determined by PHY auto polling.

The commit 40b5d2f15c09 ("net: dsa: mt7530: Add support for EEE features")
made it so that the PMCR_FORCE_EEE1G and PMCR_FORCE_EEE100 bits are set on
mt753x_phylink_mac_link_up(). But it did not set the MT7531_FORCE_EEE1G and
MT7531_FORCE_EEE100 bits. Because of this, the EEE abilities will be
determined by PHY auto polling, regardless of the result of phy_init_eee().

Define these bits and add them to the MT7531_FORCE_MODE mask which is set
in mt7531_setup_common(). With this, there won't be any EEE abilities set
when phy_init_eee() returns a negative value.

Thanks to Russell for explaining when phy_init_eee() could return a
negative value below.

Looking at phy_init_eee(), it could return a negative value when:

1. phydev->drv is NULL
2. if genphy_c45_eee_is_active() returns negative
3. if genphy_c45_eee_is_active() returns zero, it returns -EPROTONOSUPPORT
4. if phy_set_bits_mmd() fails (e.g. communication error with the PHY)

If we then look at genphy_c45_eee_is_active(), then:

genphy_c45_read_eee_adv() and genphy_c45_read_eee_lpa() propagate their
non-zero return values, otherwise this function returns zero or positive
integer.

If we then look at genphy_c45_read_eee_adv(), then a failure of
phy_read_mmd() would cause a negative value to be returned.

Looking at genphy_c45_read_eee_lpa(), the same is true.

So, it can be summarised as:

- phydev->drv is NULL
- there is a communication error accessing the PHY
- EEE is not active

otherwise, it returns zero on success.

If one wishes to determine whether an error occurred vs EEE not being
supported through negotiation for the negotiated speed, if it returns
-EPROTONOSUPPORT in the latter case. Other error codes mean either the
driver has been unloaded or communication error.

In conclusion, determining the EEE abilities by PHY auto polling shouldn't
result in having any EEE abilities enabled, when one of the last two
situations in the summary happens. And it seems that if phydev->drv is
NULL, there would be bigger problems with the device than a broken link. So
this is not a bugfix.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.h | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/net/dsa/mt7530.h b/drivers/net/dsa/mt7530.h
index 94932c3dbde9..f7c5355c1642 100644
--- a/drivers/net/dsa/mt7530.h
+++ b/drivers/net/dsa/mt7530.h
@@ -328,11 +328,15 @@ enum mt7530_vlan_port_acc_frm {
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

