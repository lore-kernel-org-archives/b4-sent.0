From: Ciprian Regus <ciprian.regus@analog.com>
Date: Thu, 04 Jun 2026 19:32:55 +0300
Subject: [PATCH net-next v3 10/13] net: phy: add generic helpers for direct
 C45 MMD access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-adin1140-driver-v3-10-5debdb3173c4@analog.com>
References: <20260604-adin1140-driver-v3-0-5debdb3173c4@analog.com>
In-Reply-To: <20260604-adin1140-driver-v3-0-5debdb3173c4@analog.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, devicetree@vger.kernel.org, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780590775; l=2682;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=KEFIsY+nz2k4HZCe7o0fb2JTtI08zuGJ0BttX6Nj+lE=;
 b=nQJkHUs+QsBvezjO+21nfGJcNE8zwp5E65EP5hXQ/FO0/zsBT/iOZOy+k0+8l3adH6PTWmvTG
 F86AIruqA1rAzQFImNJ5mjzGfe5tYCh5zSZDDX317cNic1v1r5uyOVe
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some PHYs support direct C45 register access but not C22 indirect MMD
access (registers 0xD and 0xE). When discovered via C22, phylib routes
MMD access through the indirect path, which won't work on these
devices.

Add genphy_read_mmd_c45() and genphy_write_mmd_c45() as read_mmd/
write_mmd callbacks that bypass the C22 indirect path and use the bus
C45 accessors directly.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>
---
v3 changelog:
 - no change
v2 changelog:
 - New patch
---
 drivers/net/phy/phy_device.c | 25 +++++++++++++++++++++++++
 include/linux/phy.h          |  3 +++
 2 files changed, 28 insertions(+)

diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 3370eb822017..d33d096e700d 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -2764,6 +2764,31 @@ int genphy_read_abilities(struct phy_device *phydev)
 }
 EXPORT_SYMBOL(genphy_read_abilities);
 
+/* Some PHYs support direct C45 register access but not C22 indirect
+ * MMD access (registers 13 and 14). When discovered via C22, phylib
+ * routes MMD access through the indirect path, which won't work on
+ * these devices. These helpers bypass indirect access and use the bus
+ * C45 accessors directly.
+ */
+int genphy_read_mmd_c45(struct phy_device *phydev, int devnum, u16 regnum)
+{
+	struct mii_bus *bus = phydev->mdio.bus;
+	int addr = phydev->mdio.addr;
+
+	return __mdiobus_c45_read(bus, addr, devnum, regnum);
+}
+EXPORT_SYMBOL(genphy_read_mmd_c45);
+
+int genphy_write_mmd_c45(struct phy_device *phydev, int devnum, u16 regnum,
+			 u16 val)
+{
+	struct mii_bus *bus = phydev->mdio.bus;
+	int addr = phydev->mdio.addr;
+
+	return __mdiobus_c45_write(bus, addr, devnum, regnum, val);
+}
+EXPORT_SYMBOL(genphy_write_mmd_c45);
+
 /* This is used for the phy device which doesn't support the MMD extended
  * register access, but it does have side effect when we are trying to access
  * the MMD register via indirect method.
diff --git a/include/linux/phy.h b/include/linux/phy.h
index 199a7aaa341b..432d44188dbc 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -2297,6 +2297,9 @@ static inline int genphy_no_config_intr(struct phy_device *phydev)
 {
 	return 0;
 }
+int genphy_read_mmd_c45(struct phy_device *phydev, int devnum, u16 regnum);
+int genphy_write_mmd_c45(struct phy_device *phydev, int devnum, u16 regnum,
+			 u16 val);
 int genphy_read_mmd_unsupported(struct phy_device *phdev, int devad,
 				u16 regnum);
 int genphy_write_mmd_unsupported(struct phy_device *phdev, int devnum,

-- 
2.43.0

