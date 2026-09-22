From: Vincent Jardin <vjardin@free.fr>
Date: Tue, 22 Sep 2026 21:40:33 +0200
Subject: [PATCH net-next v2] net: pcs: lynx: add support for 25GBASE-R
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260922-for-upstream-lynx-25gbaser-v1-v2-1-1e6cf79c7b52@free.fr>
X-B4-Tracking: v=1; b=H4sIALDZsmoC/42NQQqDMBBFryKz7pQkrY3pqvcoLqyZaKBNZJKKI
 t69wRMU/ubx4P0NErGnBPdqA6bZJx9DAXWqoB+7MBB6WxiUUDfRqBpdZPxOKTN1H3yvYUFVD6+
 uZHCWeBHCaGuEscJAaUxMzi9H/wmBMgZaMrTFjD7lyOtxPMvD//lRJtFZLftGXLU2zcMx0dkxt
 Pu+/wBOo3+Q0gAAAA==
To: Ioana Ciornei <ioana.ciornei@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790106068; l=3594;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=bmf6B3F6ohB69HA6ZyITfXa57iK/cRlvOW+wygkEdRw=;
 b=ezUeCvdgVgzuSEY24djbVTGKsQyeB2ZhpUeAe4SYXcES261DGvI5h1+9nh3ozxA5sXv2A3fWa
 MfS04tacPR0CdceNxpv9IrYnMaJt0hF2JLuWYKEWuCxEKdCfzvOdUiR
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Lynx PCS never supported 25GBASE-R. Add it, so that a 25G DPMAC on
LX2160A can be driven by phylink.

The SerDes side had the mode since the commit
  1cab8fba5073 ("phy: lynx-28g: add support for 25GBASER")
and dpaa2-mac maps DPMAC_ETH_IF_CAUI to PHY_INTERFACE_MODE_25GBASER,
but the PCS never handled it, so phylink_validate() failed with the
interface.

25GBASE-R is a serial mode without clause-37 in-band autonegotiation,
exactly like 10GBASE-R: it does not needs any configuration, its state
is read with phylink_mii_c45_pcs_get_state(), and it reports
LINK_INBAND_DISABLE.

phylink_mii_c45_pcs_get_state() is extended in the same patch because
without it the link comes up reporting Unknown/Unknown.

Suggested-by: Ioana Ciornei <ioana.ciornei@nxp.com>
Co-developed-by: Ioana Ciornei <ioana.ciornei@nxp.com>
Signed-off-by: Ioana Ciornei <ioana.ciornei@nxp.com>
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Repost of the RFC now that net-next has reopened, rebased on net-next.
---
Changes in v2:
- Reword: this adds 25GBASE-R support, it does not fix a regression
  (Ioana Ciornei)
- Squash in the phylink_mii_c45_pcs_get_state() 25GBASER case, without
  which the link comes up as Unknown/Unknown (Ioana Ciornei)
- Link to v1: https://lore.kernel.org/r/20260825-for-upstream-lynx-25gbaser-v1-v1-1-fd71c8047798@free.fr
---
 drivers/net/pcs/pcs-lynx.c | 6 +++++-
 drivers/net/phy/phylink.c  | 5 +++++
 2 files changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/net/pcs/pcs-lynx.c b/drivers/net/pcs/pcs-lynx.c
index a92081560e641..da4f99059eef7 100644
--- a/drivers/net/pcs/pcs-lynx.c
+++ b/drivers/net/pcs/pcs-lynx.c
@@ -46,6 +46,7 @@ static unsigned int lynx_pcs_inband_caps(struct phylink_pcs *pcs,
 		return LINK_INBAND_DISABLE | LINK_INBAND_ENABLE;
 
 	case PHY_INTERFACE_MODE_10GBASER:
+	case PHY_INTERFACE_MODE_25GBASER:
 		return LINK_INBAND_DISABLE;
 
 	case PHY_INTERFACE_MODE_USXGMII:
@@ -97,6 +98,7 @@ static void lynx_pcs_get_state(struct phylink_pcs *pcs, unsigned int neg_mode,
 		lynx_pcs_get_state_usxgmii(lynx->mdio, state);
 		break;
 	case PHY_INTERFACE_MODE_10GBASER:
+	case PHY_INTERFACE_MODE_25GBASER:
 		phylink_mii_c45_pcs_get_state(lynx->mdio, state);
 		break;
 	default:
@@ -188,7 +190,8 @@ static int lynx_pcs_config(struct phylink_pcs *pcs, unsigned int neg_mode,
 		return lynx_pcs_config_usxgmii(lynx->mdio, ifmode, advertising,
 					       neg_mode);
 	case PHY_INTERFACE_MODE_10GBASER:
-		/* Nothing to do here for 10GBASER */
+	case PHY_INTERFACE_MODE_25GBASER:
+		/* Nothing to do here for 10GBASER and 25GBASER */
 		break;
 	default:
 		return -EOPNOTSUPP;
@@ -279,6 +282,7 @@ static const phy_interface_t lynx_interfaces[] = {
 	PHY_INTERFACE_MODE_1000BASEX,
 	PHY_INTERFACE_MODE_2500BASEX,
 	PHY_INTERFACE_MODE_10GBASER,
+	PHY_INTERFACE_MODE_25GBASER,
 	PHY_INTERFACE_MODE_USXGMII,
 	PHY_INTERFACE_MODE_10G_QXGMII,
 };
diff --git a/drivers/net/phy/phylink.c b/drivers/net/phy/phylink.c
index 3ec3bb4391095..ff4375f1e9108 100644
--- a/drivers/net/phy/phylink.c
+++ b/drivers/net/phy/phylink.c
@@ -4360,6 +4360,11 @@ void phylink_mii_c45_pcs_get_state(struct mdio_device *pcs,
 		state->duplex = DUPLEX_FULL;
 		break;
 
+	case PHY_INTERFACE_MODE_25GBASER:
+		state->speed = SPEED_25000;
+		state->duplex = DUPLEX_FULL;
+		break;
+
 	default:
 		break;
 	}

---
base-commit: c8ea08ba34f2a2e9bfb18ff3d69eb2d69b324f49
change-id: 20260825-for-upstream-lynx-25gbaser-v1-30097d909d09

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

