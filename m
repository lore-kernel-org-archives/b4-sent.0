From: Ciprian Regus <ciprian.regus@analog.com>
Date: Wed, 27 May 2026 00:51:49 +0300
Subject: [PATCH net-next v2 04/10] net: ethernet: oa_tc6: Export the C45
 access functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-adin1140-driver-v2-4-37e5c8d4e0a0@analog.com>
References: <20260527-adin1140-driver-v2-0-37e5c8d4e0a0@analog.com>
In-Reply-To: <20260527-adin1140-driver-v2-0-37e5c8d4e0a0@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779832338; l=2238;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=G2YKLlP+q7gpNa7VGIqaY6JB/wn+q0v7tTUGj7fc4Ig=;
 b=rXoEtqv1uWHPXPcoFBESGbR3Q5tVL3l15HQBWIwlJn83PG/06JuEZTrkdpI7sO6ZufvqNxuAG
 +xsByidfo8ECAxj++HQOMh/6/3lXG4A1QZPEgZr5tAPniZA+QwpJ7nU
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The C45 access functions can still be used by some Ethernet drivers
which set the OA_TC6_BROKEN_PHY flag. Export them.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>

---
v2 changelog:
 - New patch
---
 drivers/net/ethernet/oa_tc6.c | 10 ++++++----
 include/linux/oa_tc6.h        |  4 ++++
 2 files changed, 10 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 7ae3639beadd..4a1fd9fd75ab 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -499,8 +499,8 @@ static int oa_tc6_get_phy_c45_mms(int devnum)
 	}
 }
 
-static int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
-				   int regnum)
+int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
+			    int regnum)
 {
 	struct oa_tc6 *tc6 = bus->priv;
 	u32 regval;
@@ -516,9 +516,10 @@ static int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
 
 	return regval;
 }
+EXPORT_SYMBOL_GPL(oa_tc6_mdiobus_read_c45);
 
-static int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
-				    int regnum, u16 val)
+int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
+			     int regnum, u16 val)
 {
 	struct oa_tc6 *tc6 = bus->priv;
 	int ret;
@@ -529,6 +530,7 @@ static int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
 
 	return oa_tc6_write_register(tc6, (ret << 16) | regnum, val);
 }
+EXPORT_SYMBOL_GPL(oa_tc6_mdiobus_write_c45);
 
 static int oa_tc6_mdiobus_register(struct oa_tc6 *tc6)
 {
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 6c38bf49e2a7..95e041d7d77b 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -32,3 +32,7 @@ int oa_tc6_read_registers(struct oa_tc6 *tc6, u32 address, u32 value[],
 			  u8 length);
 netdev_tx_t oa_tc6_start_xmit(struct oa_tc6 *tc6, struct sk_buff *skb);
 int oa_tc6_zero_align_receive_frame_enable(struct oa_tc6 *tc6);
+int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
+			    int regnum);
+int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
+			     int regnum, u16 val);

-- 
2.43.0

