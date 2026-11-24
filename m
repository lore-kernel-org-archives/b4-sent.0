From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Tue, 24 Nov 2026 14:10:00 -0800
Subject: [PATCH net-next v12 12/15] net: phy: Add helper to modify only the
 PHY loopback bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-s2500-mac-phy-support-v12-12-3575855d99f9@onsemi.com>
References: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
In-Reply-To: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795558193; l=3213;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=qV7xFmEYUdRBeaDELW+xZTB76dySkY5uubXFY2kgNgo=;
 b=je32yGTAdeWuvcRUxea7rOuAK9EOFz/eep29Ick+pctsREz9GJ1H4L/q1ECuakmCoIO0tsqOn
 gGkzb+jpUaxDLErRKw1ZWN/YWImzXux0TGjIX0Vcac8pgkzQ7UN/wpq
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a generic helper function, genphy_loopback_no_speed(), to modify
the loopback bit of the PHY only, without setting the speed. This will
help the PHY drivers, like 10BASE-T1S or any other PHYs that want to
handle the loopback bit only.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v12
  - No change
changes in v11
  - Made the changes to phy core into a separate patch. Previously
    changes were in a patch that also had vendor code changes.
  - Documentation in the comments section is made accurate.
changes in v10
  - No change
changes in v9
  - replaced "fixed_speed" with "no_speed" for the API.
  - Improved the comments to be specific about not setting the
    speed.
changes in v8
  - No code change. Changes were in two different patches.
    Merged into one.
changes in v7
  - No change
changes in v6
  - No change
changes in v5
  - No change
changes in v4
  - Moved the onsemi implementation to a new, genphy API to
    make it vendor agnostic.
changes in v3
  - Added loopback functionality for onsemi's PHY driver
  - First patch
---
 drivers/net/phy/phy_device.c | 24 ++++++++++++++++++++++++
 include/linux/phy.h          |  2 ++
 2 files changed, 26 insertions(+)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index b39e945cebd7..80d93bb43312 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -2923,6 +2923,30 @@ int genphy_resume(struct phy_device *phydev)
 }
 EXPORT_SYMBOL(genphy_resume);
 
+/**
+ * genphy_loopback_no_speed - Enable or disable PHY loopback, speed unchanged
+ * @phydev: The phy_device struct
+ * @enable: Flag to enable or disable the PHY level loopback.
+ * @speed: Speed setting. Not supported: -EOPNOTSUPP is returned if it is
+ *         non-zero when enabling loopback. Ignored when disabling.
+ *
+ * Description: Only BMCR_LOOPBACK is modified. It fails with -EOPNOTSUPP if
+ * @speed is non-zero when enabling loopback, or with the error from the
+ * BMCR access.
+ *
+ * Returns: 0 if successful, negative error code on failure.
+ */
+int genphy_loopback_no_speed(struct phy_device *phydev, bool enable,
+			     int speed)
+{
+	if (enable && speed)
+		return -EOPNOTSUPP;
+
+	return phy_modify(phydev, MII_BMCR, BMCR_LOOPBACK,
+			  enable ? BMCR_LOOPBACK : 0);
+}
+EXPORT_SYMBOL(genphy_loopback_no_speed);
+
 int genphy_loopback(struct phy_device *phydev, bool enable, int speed)
 {
 	if (enable) {
diff --git a/include/linux/phy.h b/include/linux/phy.h
index f1b1ad1dd82f..38a60ad4f68e 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -2318,6 +2318,8 @@ int genphy_read_status(struct phy_device *phydev);
 int genphy_read_master_slave(struct phy_device *phydev);
 int genphy_suspend(struct phy_device *phydev);
 int genphy_resume(struct phy_device *phydev);
+int genphy_loopback_no_speed(struct phy_device *phydev, bool enable,
+			     int speed);
 int genphy_loopback(struct phy_device *phydev, bool enable, int speed);
 int genphy_soft_reset(struct phy_device *phydev);
 irqreturn_t genphy_handle_interrupt_no_ack(struct phy_device *phydev);

-- 
2.43.0

