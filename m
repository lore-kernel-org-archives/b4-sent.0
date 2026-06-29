From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 29 Jun 2026 10:23:31 -0700
Subject: [PATCH net-next v6 01/15] net: phy: Helper to read and write
 through C45 without lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260629-s2500-mac-phy-support-v6-1-18ce79500371@onsemi.com>
References: <20260629-s2500-mac-phy-support-v6-0-18ce79500371@onsemi.com>
In-Reply-To: <20260629-s2500-mac-phy-support-v6-0-18ce79500371@onsemi.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782753817; l=3753;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=PZskgc1fBKQfn8jSfkk+0wWBwzgT1bBdU+1HtSLOovs=;
 b=Cj2VMf7mwxYSYwzusgkpeSMdx9znSvY/VqBYa9e0Cu/5TAvQKcZnp9fNVba93tBY9iWme78AS
 z5SdcVSUNm6CDDZ716X0T7kv1ybPKjq/aNkiRG9RuaUryFjPo+CSKEA
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Generic helper function to initiate read and write through C45 bus
protocol without mdio bus lock. This will help PHYs to avoid indirect C22
API calls for C45 bus protocol which may not be supported by the PHY.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v6
  - No change
changes in v5
  - no change
changes in v4
  - lockdep_assert_held added to ensure correct calling convention
changes in v3
  - Added the genphy APIs to initiate Clause 45 register read/write
  - first patch
---
 drivers/net/phy/phy_device.c | 55 ++++++++++++++++++++++++++++++++++++++++++++
 include/linux/phy.h          |  4 ++++
 2 files changed, 59 insertions(+)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 0615228459ef..b82b99d08132 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -2787,6 +2787,61 @@ int genphy_write_mmd_unsupported(struct phy_device *phdev, int devnum,
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

