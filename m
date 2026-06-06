From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 05 Jun 2026 22:42:32 -0700
Subject: [PATCH net-next v4 01/16] net: phy: Helper to read and write
 through C45 without lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260605-s2500-mac-phy-support-v4-1-de0fbc13c6d8@onsemi.com>
References: <20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com>
In-Reply-To: <20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780724562; l=3459;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=JvvJXQtiELpn1FGIsjj4sr5oo2VlfTINRAZf1k5i42I=;
 b=y6DMdh9smhvvWef/6NBQQFDz0anPehbu1rQUl6u/PaXM+u/UUKbuu9HObang8430hF8xDin9w
 yS0GcRb19+qAIVJLzQr2yRfdG0nTHd44a0VfZijWHNbf1iCZ1+7mkuy
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Generic helper function to initiate read and write through C45 bus
protocol without mdio bus lock. This will help PHYs to avoid indirect C22
API calls for C45 bus protocol which may not be supported by the PHY.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
 drivers/net/phy/phy_device.c | 55 ++++++++++++++++++++++++++++++++++++++++++++
 include/linux/phy.h          |  4 ++++
 2 files changed, 59 insertions(+)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 3370eb822017..20c92fde4fbb 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -2781,6 +2781,61 @@ int genphy_write_mmd_unsupported(struct phy_device *phdev, int devnum,
 }
 EXPORT_SYMBOL(genphy_write_mmd_unsupported);
 
+/**
+ * genphy_phy_read_mmd - Helper for reading a register without lock
+ * from the given MMD and PHY.
+ * @phydev: The phy_device struct
+ * @devnum: The MMD to read from
+ * @regnum: The register on the MMD to read
+ *
+ * Description: PHYs can have both C22 and C45 registers space. Once PHY
+ * is discovered via C22 bus protocol, it uses C22 indirect access to
+ * access C45 registers. Some PHYs, like 10Base-T1S PHYs defined by OPEN
+ * Alliance 10BASE‑T1x, support only direct access.
+ *
+ * If PHY indicates C45 support through DTS entry, it avoid C22 APIs
+ * entirely and therefore generic MDIO registers are inaccessible.
+ *
+ * MDIO bus isn't locked here because when called through read_mmd
+ * callback of phy_driver, caller is expected to lock the bus as
+ * implemented in phy_read_mmd.
+ *
+ * Returns: Register value if successful, negative error code on failure.
+ */
+int genphy_phy_read_mmd(struct phy_device *phydev, int devnum,
+			u16 regnum)
+{
+	struct mii_bus *bus = phydev->mdio.bus;
+	int addr = phydev->mdio.addr;
+
+	lockdep_assert_held(&bus->mdio_lock);
+	return __mdiobus_c45_read(bus, addr, devnum, regnum);
+}
+EXPORT_SYMBOL(genphy_phy_read_mmd);
+
+/**
+ * genphy_phy_write_mmd - Helper for writing a register without lock
+ * to the given MMD and PHY.
+ * @phydev: The phy_device struct
+ * @devnum: The MMD to write to
+ * @regnum: The register on the MMD to write
+ * @val:    Value to write
+ *
+ * Description: Similar to genphy_phy_read_mmd
+ *
+ * Returns: 0 if successful, negative error code on failure.
+ */
+int genphy_phy_write_mmd(struct phy_device *phydev, int devnum,
+			 u16 regnum, u16 val)
+{
+	struct mii_bus *bus = phydev->mdio.bus;
+	int addr = phydev->mdio.addr;
+
+	lockdep_assert_held(&bus->mdio_lock);
+	return __mdiobus_c45_write(bus, addr, devnum, regnum, val);
+}
+EXPORT_SYMBOL(genphy_phy_write_mmd);
+
 int genphy_suspend(struct phy_device *phydev)
 {
 	return phy_set_bits(phydev, MII_BMCR, BMCR_PDOWN);
diff --git a/include/linux/phy.h b/include/linux/phy.h
index 199a7aaa341b..8266dd4a8dbe 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -2301,6 +2301,10 @@ int genphy_read_mmd_unsupported(struct phy_device *phdev, int devad,
 				u16 regnum);
 int genphy_write_mmd_unsupported(struct phy_device *phdev, int devnum,
 				 u16 regnum, u16 val);
+int genphy_phy_write_mmd(struct phy_device *phydev, int devnum,
+			 u16 regnum, u16 val);
+int genphy_phy_read_mmd(struct phy_device *phydev, int devnum,
+			u16 regnum);
 
 /* Clause 37 */
 int genphy_c37_config_aneg(struct phy_device *phydev);

-- 
2.43.0

