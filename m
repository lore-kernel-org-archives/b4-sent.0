From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Mon, 11 Mar 2024 14:46:38 +0300
Subject: [PATCH net 1/2] net: dsa: mt7530: fix link-local frames that
 ingress vlan filtering ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240311-b4-for-net-mt7530-fix-link-local-vlan-v1-1-d67e6cc31af2@arinc9.com>
References: <20240311-b4-for-net-mt7530-fix-link-local-vlan-v1-0-d67e6cc31af2@arinc9.com>
In-Reply-To: <20240311-b4-for-net-mt7530-fix-link-local-vlan-v1-0-d67e6cc31af2@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: =?utf-8?q?Alvin_=C5=A0ipraga?= <ALSI@bang-olufsen.dk>, 
 Frank Wunderlich <frank-w@public-files.de>, 
 Bartel Eerdekens <bartel.eerdekens@constell8.be>, mithat.guner@xeront.com, 
 erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710157606; l=7136;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=K75hAu2dsFq9nTLqW4EpsuZ+WvDXtzzGUuh2+IG83rE=;
 b=G0SWuF5iJjU2Re/OK7NrmKcAAFLPFWF7ImnJg6XyOZdJqq2XCPLtc0wRxzkExnhAZHhqGKnMD
 0UCDinMFdt2BQeVkacR56I872H2WJclDLjlhCNBYZUfQmjVieRv/dGv
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Whether VLAN-aware or not, on every VID VLAN table entry that has the CPU
port as a member of it, frames are set to egress the CPU port with the VLAN
tag stacked. This is so that VLAN tags can be appended after hardware
special tag (called DSA tag in the context of Linux drivers).

For user ports on a VLAN-unaware bridge, frame ingressing the user port
egresses CPU port with only the special tag.

For user ports on a VLAN-aware bridge, frame ingressing the user port
egresses CPU port with the special tag and the VLAN tag.

This causes issues with link-local frames, specifically BPDUs, because the
software expects to receive them VLAN-untagged.

There are two options to make link-local frames egress untagged. Setting
CONSISTENT or UNTAGGED on the EG_TAG bits on the relevant register.
CONSISTENT means frames egress exactly as they ingress. That means
egressing with the VLAN tag they had at ingress or egressing untagged if
they ingressed untagged. Although link-local frames are not supposed to be
transmitted VLAN-tagged, if they are done so, when egressing through a CPU
port, the special tag field will be broken.

BPDU egresses CPU port with VLAN tag egressing stacked, received on
software:

00:01:25.104821 AF Unknown (382365846), length 106:
                                     | STAG  | | VLAN  |
        0x0000:  0000 6c27 614d 4143 0001 0000 8100 0001  ..l'aMAC........
        0x0010:  0026 4242 0300 0000 0000 0000 6c27 614d  .&BB........l'aM
        0x0020:  4143 0000 0000 0000 6c27 614d 4143 0000  AC......l'aMAC..
        0x0030:  0000 1400 0200 0f00 0000 0000 0000 0000  ................

BPDU egresses CPU port with VLAN tag egressing untagged, received on
software:

00:23:56.628708 AF Unknown (25215488), length 64:
                                     | STAG  |
        0x0000:  0000 6c27 614d 4143 0001 0000 0026 4242  ..l'aMAC.....&BB
        0x0010:  0300 0000 0000 0000 6c27 614d 4143 0000  ........l'aMAC..
        0x0020:  0000 0000 6c27 614d 4143 0000 0000 1400  ....l'aMAC......
        0x0030:  0200 0f00 0000 0000 0000 0000            ............

BPDU egresses CPU port with VLAN tag egressing tagged, received on
software:

00:01:34.311963 AF Unknown (25215488), length 64:
                                     | Mess  |
        0x0000:  0000 6c27 614d 4143 0001 0001 0026 4242  ..l'aMAC.....&BB
        0x0010:  0300 0000 0000 0000 6c27 614d 4143 0000  ........l'aMAC..
        0x0020:  0000 0000 6c27 614d 4143 0000 0000 1400  ....l'aMAC......
        0x0030:  0200 0f00 0000 0000 0000 0000            ............

To prevent confusing the software, force the frame to egress UNTAGGED
instead of CONSISTENT. This way, frames can't possibly be received TAGGED
by software which would have the special tag field broken.

VLAN Tag Egress Procedure

   For all frames, one of these options set the earliest in this order will
   apply to the frame:

   - EG_TAG in certain registers for certain frames.
     This will apply to frame with matching MAC DA or EtherType.

   - EG_TAG in the address table.
     This will apply to frame at its incoming port.

   - EG_TAG in the PVC register.
     This will apply to frame at its incoming port.

   - EG_CON and [EG_TAG per port] in the VLAN table.
     This will apply to frame at its outgoing port.

   - EG_TAG in the PCR register.
     This will apply to frame at its outgoing port.

   EG_TAG in certain registers for certain frames:

   PPPoE Discovery_ARP/RARP: PPP_EG_TAG and ARP_EG_TAG in the APC register.
   IGMP_MLD: IGMP_EG_TAG and MLD_EG_TAG in the IMC register.
   BPDU and PAE: BPDU_EG_TAG and PAE_EG_TAG in the BPC register.
   REV_01 and REV_02: R01_EG_TAG and R02_EG_TAG in the RGAC1 register.
   REV_03 and REV_0E: R03_EG_TAG and R0E_EG_TAG in the RGAC2 register.
   REV_10 and REV_20: R10_EG_TAG and R20_EG_TAG in the RGAC3 register.
   REV_21 and REV_UN: R21_EG_TAG and RUN_EG_TAG in the RGAC4 register.

With this change, it can be observed that a bridge interface with stp_state
and vlan_filtering enabled will properly block ports now.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 23 +++++++++++++++--------
 drivers/net/dsa/mt7530.h |  9 ++++++++-
 2 files changed, 23 insertions(+), 9 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 3c1f657593a8..beef5bc38b88 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -1001,16 +1001,23 @@ static void mt7530_setup_port5(struct dsa_switch *ds, phy_interface_t interface)
 static void
 mt753x_trap_frames(struct mt7530_priv *priv)
 {
-	/* Trap BPDUs to the CPU port(s) */
-	mt7530_rmw(priv, MT753X_BPC, MT753X_BPDU_PORT_FW_MASK,
+	/* Trap 802.1X PAE frames and BPDUs to the CPU port(s) and egress them
+	 * VLAN-untagged.
+	 */
+	mt7530_rmw(priv, MT753X_BPC, MT753X_PAE_EG_TAG_MASK |
+		   MT753X_PAE_PORT_FW_MASK | MT753X_BPDU_EG_TAG_MASK |
+		   MT753X_BPDU_PORT_FW_MASK,
+		   MT753X_PAE_EG_TAG(MT7530_VLAN_EG_UNTAGGED) |
+		   MT753X_PAE_PORT_FW(MT753X_BPDU_CPU_ONLY) |
+		   MT753X_BPDU_EG_TAG(MT7530_VLAN_EG_UNTAGGED) |
 		   MT753X_BPDU_CPU_ONLY);
 
-	/* Trap 802.1X PAE frames to the CPU port(s) */
-	mt7530_rmw(priv, MT753X_BPC, MT753X_PAE_PORT_FW_MASK,
-		   MT753X_PAE_PORT_FW(MT753X_BPDU_CPU_ONLY));
-
-	/* Trap LLDP frames with :0E MAC DA to the CPU port(s) */
-	mt7530_rmw(priv, MT753X_RGAC2, MT753X_R0E_PORT_FW_MASK,
+	/* Trap LLDP frames with :0E MAC DA to the CPU port(s) and egress them
+	 * VLAN-untagged.
+	 */
+	mt7530_rmw(priv, MT753X_RGAC2, MT753X_R0E_EG_TAG_MASK |
+		   MT753X_R0E_PORT_FW_MASK,
+		   MT753X_R0E_EG_TAG(MT7530_VLAN_EG_UNTAGGED) |
 		   MT753X_R0E_PORT_FW(MT753X_BPDU_CPU_ONLY));
 }
 
diff --git a/drivers/net/dsa/mt7530.h b/drivers/net/dsa/mt7530.h
index 17e42d30fff4..cef2af3f24d5 100644
--- a/drivers/net/dsa/mt7530.h
+++ b/drivers/net/dsa/mt7530.h
@@ -65,12 +65,18 @@ enum mt753x_id {
 
 /* Registers for BPDU and PAE frame control*/
 #define MT753X_BPC			0x24
-#define  MT753X_BPDU_PORT_FW_MASK	GENMASK(2, 0)
+#define  MT753X_PAE_EG_TAG_MASK		GENMASK(24, 22)
+#define  MT753X_PAE_EG_TAG(x)		FIELD_PREP(MT753X_PAE_EG_TAG_MASK, x)
 #define  MT753X_PAE_PORT_FW_MASK	GENMASK(18, 16)
 #define  MT753X_PAE_PORT_FW(x)		FIELD_PREP(MT753X_PAE_PORT_FW_MASK, x)
+#define  MT753X_BPDU_EG_TAG_MASK	GENMASK(8, 6)
+#define  MT753X_BPDU_EG_TAG(x)		FIELD_PREP(MT753X_BPDU_EG_TAG_MASK, x)
+#define  MT753X_BPDU_PORT_FW_MASK	GENMASK(2, 0)
 
 /* Register for :03 and :0E MAC DA frame control */
 #define MT753X_RGAC2			0x2c
+#define  MT753X_R0E_EG_TAG_MASK		GENMASK(24, 22)
+#define  MT753X_R0E_EG_TAG(x)		FIELD_PREP(MT753X_R0E_EG_TAG_MASK, x)
 #define  MT753X_R0E_PORT_FW_MASK	GENMASK(18, 16)
 #define  MT753X_R0E_PORT_FW(x)		FIELD_PREP(MT753X_R0E_PORT_FW_MASK, x)
 
@@ -253,6 +259,7 @@ enum mt7530_port_mode {
 enum mt7530_vlan_port_eg_tag {
 	MT7530_VLAN_EG_DISABLED = 0,
 	MT7530_VLAN_EG_CONSISTENT = 1,
+	MT7530_VLAN_EG_UNTAGGED = 4,
 };
 
 enum mt7530_vlan_port_attr {

-- 
2.40.1

