From: Daniel Braunwarth <daniel.braunwarth@kuka.com>
Date: Tue, 24 Jun 2025 16:17:33 +0200
Subject: [PATCH net-next] net: phy: realtek: add error handling to
 rtl8211f_get_wol
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-realtek_fixes-v1-1-02a0b7c369bc@kuka.com>
X-B4-Tracking: v=1; b=H4sIAHyzWmgC/x3L4QpAMBSG4VvR+W3FCeFWJK35xolG25KSe7f8f
 Hp7HwrwgkB99pDHJUEOl1DmGZlVuwVK5mTiguui4Up56D1im6zcCKqtLXdsrCl1Rek5Pf6QloE
 conK4I43v+wGPmEg6aQAAAA==
X-Change-ID: 20250624-realtek_fixes-85f292cfc1a4
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Jon Hunter <jonathanh@nvidia.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daniel Braunwarth <daniel.braunwarth@kuka.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750774665; l=1492;
 i=daniel.braunwarth@kuka.com; s=20250425; h=from:subject:message-id;
 bh=OKIaJlj0nrfTAYstQqag45KapLdQ8tvdEWLzdWiNk5s=;
 b=7mNj/l+AW+0zCELuRDjTpfWfouZu6Wbewt+QQyclvcPC1asqXnBlDWqj8uWlZ3xrwwHxkyl6X
 715ddpihqjzCJzZ2pU7DE+OnVKEePScwM2ToCPlTdccU66o9FwZwQOW
X-Developer-Key: i=daniel.braunwarth@kuka.com; a=ed25519;
 pk=fTSYKvKU5SCGGLHVz5NaznQ2MbXNWUZzdqPihgCfYms=
X-Endpoint-Received: by B4 Relay for daniel.braunwarth@kuka.com/20250425 with auth_id=388
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We should check if the WOL settings was successfully read from the PHY.

In case this fails we cannot just use the error code and proceed.

Signed-off-by: Daniel Braunwarth <daniel.braunwarth@kuka.com>
Reported-by: Jon Hunter <jonathanh@nvidia.com>
Closes: https://lore.kernel.org/baaa083b-9a69-460f-ab35-2a7cb3246ffd@nvidia.com
---
 drivers/net/phy/realtek/realtek_main.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/net/phy/realtek/realtek_main.c b/drivers/net/phy/realtek/realtek_main.c
index c3dcb62574303374666b46a454cd4e10de455d24..dd0d675149ad7f9730f04ba1aea82e02b15dfb2c 100644
--- a/drivers/net/phy/realtek/realtek_main.c
+++ b/drivers/net/phy/realtek/realtek_main.c
@@ -436,9 +436,15 @@ static irqreturn_t rtl8211f_handle_interrupt(struct phy_device *phydev)
 
 static void rtl8211f_get_wol(struct phy_device *dev, struct ethtool_wolinfo *wol)
 {
+	int wol_events;
+
 	wol->supported = WAKE_MAGIC;
-	if (phy_read_paged(dev, RTL8211F_WOL_SETTINGS_PAGE, RTL8211F_WOL_SETTINGS_EVENTS)
-	    & RTL8211F_WOL_EVENT_MAGIC)
+
+	wol_events = phy_read_paged(dev, RTL8211F_WOL_SETTINGS_PAGE, RTL8211F_WOL_SETTINGS_EVENTS);
+	if (wol_events < 0)
+		return;
+
+	if (wol_events & RTL8211F_WOL_EVENT_MAGIC)
 		wol->wolopts = WAKE_MAGIC;
 }
 

---
base-commit: f817b6dd2b62d921a6cdc0a3ac599cd1851f343c
change-id: 20250624-realtek_fixes-85f292cfc1a4

Best regards,
-- 
Daniel Braunwarth <daniel.braunwarth@kuka.com>

