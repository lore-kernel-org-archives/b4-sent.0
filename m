From: Ciprian Regus <ciprian.regus@analog.com>
Date: Tue, 09 Jun 2026 18:28:03 +0300
Subject: [PATCH net-next v4 04/13] net: ethernet: oa_tc6: Export the C45
 access functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260609-adin1140-driver-v4-4-0753e28ee004@analog.com>
References: <20260609-adin1140-driver-v4-0-0753e28ee004@analog.com>
In-Reply-To: <20260609-adin1140-driver-v4-0-0753e28ee004@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781018886; l=2337;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=PXhiTLN/eJwzSVDtbuD8NyXEgUV3FNkSSabnshSdzNo=;
 b=A7PKiH/bxz6XS2HkdmifsqnrdQ66IhRJOHb8lUtrlDBMGMV5pbcEkHxqT992Fd7P5aqQ//mWJ
 kYB2vm9d9L1Cqi0Jhb+ThrLT6A5g+wtx9ZXfHeJihcnK2WVhfrpChcl
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The C45 access functions can still be used by some Ethernet drivers
which set the OA_TC6_BROKEN_PHY flag. Export them.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>
---
v4 changelog:
 - no change
v3 changelog:
 - no change
v2 changelog:
 - New patch
---
 drivers/net/ethernet/oa_tc6.c | 10 ++++++----
 include/linux/oa_tc6.h        |  4 ++++
 2 files changed, 10 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 2a72f0c4b009..b37e398e30e3 100644
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
index 62e3d89f80ed..2660eefa3504 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -31,3 +31,7 @@ int oa_tc6_read_registers(struct oa_tc6 *tc6, u32 address, u32 value[],
 			  u8 length);
 netdev_tx_t oa_tc6_start_xmit(struct oa_tc6 *tc6, struct sk_buff *skb);
 int oa_tc6_zero_align_receive_frame_enable(struct oa_tc6 *tc6);
+int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
+			    int regnum);
+int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
+			     int regnum, u16 val);

-- 
2.43.0

