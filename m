From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Sat, 06 Sep 2025 10:33:31 +0800
Subject: [PATCH net-next v2] net: phy: marvell: Fix 88e1510 downshift
 counter errata
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250906-marvell_fix-v2-1-f6efb286937f@altera.com>
X-B4-Tracking: v=1; b=H4sIAHudu2gC/22NQQrDIBRErxL+uhY1TUO66j1KKL/6bQSjRUVSg
 nevZN3lzGPe7JAoWkpw63aIVGyywbcgTx2oBf2bmNUtg+Ry4BOXbMVYyLmnsRvrjcReD8SNQmi
 LT6RWH7YHeMrM05ZhbmSxKYf4PW6KOPhfYxFMsMm8cMSruIxa39FlinhWYYW51voDH7YhJLEAA
 AA=
X-Change-ID: 20250902-marvell_fix-3f2a3d5e0fca
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757126014; l=2972;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=F3FOWm0NbZN4sKFf4+eqpl1A14nM44VDQbAr1h+E1Bg=;
 b=unzfDhLUk4l296CnIJxfXm9dEr3kmLtzND7dWHQ6lCv6fJDgJR9lmfN192y2t+cZSYV28iRcC
 m7sr92qYlkIDmbhEkBJOo2XQztbk2t6/2+nHDuuYKCHDsvxlGjEOI/U
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The 88e1510 PHY has an erratum where the phy downshift counter is not
cleared after phy being suspended(BMCR_PDOWN set) and then later
resumed(BMCR_PDOWN cleared). This can cause the gigabit link to
intermittently downshift to a lower speed.

Disabling and re-enabling the downshift feature clears the counter,
allowing the PHY to retry gigabit link negotiation up to the programmed
retry count times before downshifting. This behavior has been observed
on copper links.

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
Reviewed-by: Andrew Lunn <andrew@lunn.ch>
---
Changes in v2:
- Updated commit message and function description.
- Link to v1: https://lore.kernel.org/r/20250902-marvell_fix-v1-1-9fba7a6147dd@altera.com
---
 drivers/net/phy/marvell.c | 39 ++++++++++++++++++++++++++++++++++++++-
 1 file changed, 38 insertions(+), 1 deletion(-)

diff --git a/drivers/net/phy/marvell.c b/drivers/net/phy/marvell.c
index 623292948fa706a2b0d8b98919ead8b609bbd949..0ea366c1217eb3a6ddc26a8333280c211bd9545c 100644
--- a/drivers/net/phy/marvell.c
+++ b/drivers/net/phy/marvell.c
@@ -1902,6 +1902,43 @@ static int marvell_resume(struct phy_device *phydev)
 	return err;
 }
 
+/* m88e1510_resume
+ *
+ * The 88e1510 PHY has an erratum where the phy downshift counter is not cleared
+ * after phy being suspended(BMCR_PDOWN set) and then later resumed(BMCR_PDOWN
+ * cleared). This can cause the link to intermittently downshift to a lower speed.
+ *
+ * Disabling and re-enabling the downshift feature clears the counter, allowing
+ * the PHY to retry gigabit link negotiation up to the programmed retry count
+ * before downshifting. This behavior has been observed on copper links.
+ */
+static int m88e1510_resume(struct phy_device *phydev)
+{
+	int err;
+	u8 cnt = 0;
+
+	err = marvell_resume(phydev);
+	if (err < 0)
+		return err;
+
+	/* read downshift counter value */
+	err = m88e1011_get_downshift(phydev, &cnt);
+	if (err < 0)
+		return err;
+
+	if (cnt) {
+		/* downshift disabled */
+		err = m88e1011_set_downshift(phydev, 0);
+		if (err < 0)
+			return err;
+
+		/* downshift enabled, with previous counter value */
+		err = m88e1011_set_downshift(phydev, cnt);
+	}
+
+	return err;
+}
+
 static int marvell_aneg_done(struct phy_device *phydev)
 {
 	int retval = phy_read(phydev, MII_M1011_PHY_STATUS);
@@ -3923,7 +3960,7 @@ static struct phy_driver marvell_drivers[] = {
 		.handle_interrupt = marvell_handle_interrupt,
 		.get_wol = m88e1318_get_wol,
 		.set_wol = m88e1318_set_wol,
-		.resume = marvell_resume,
+		.resume = m88e1510_resume,
 		.suspend = marvell_suspend,
 		.read_page = marvell_read_page,
 		.write_page = marvell_write_page,

---
base-commit: 2fd4161d0d2547650d9559d57fc67b4e0a26a9e3
change-id: 20250902-marvell_fix-3f2a3d5e0fca

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

