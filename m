From: Ciprian Regus <ciprian.regus@analog.com>
Date: Wed, 08 Jul 2026 01:33:36 +0300
Subject: [PATCH net-next v5 08/13] net: ethernet: oa_tc6: Use the
 read_mms/write_mms functions for C45
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-adin1140-driver-v5-8-4aca7b51a58b@analog.com>
References: <20260708-adin1140-driver-v5-0-4aca7b51a58b@analog.com>
In-Reply-To: <20260708-adin1140-driver-v5-0-4aca7b51a58b@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783463678; l=1900;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=4ee8cdHLlKW3pjbGukxiV3V1VUwrIJXWsR2neQk5fUA=;
 b=yIKf6ITo+yGidI+2uGF9WgjVu6Gpui9yQ2EbTgAwSylrDiRgTUFUjYWVdXasznz/1oW8a05K1
 ajAXv7KEKmFCX2S7luWEExLilv67maroYm9CHXMAdL30zWtthE2wmJb
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Accessing PHY MMD devices requires control transactions to registers in
a memory map other than 0. Replace the current formatting of the
register addresses with the oa_tc6_{read,write}_register_mms()
functions. While we're here, introduce the mms variable to store the
memory map returned by oa_tc6_get_phy_c45_mms() instead of ret, in order
to improve the code readability.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>
---
v5 changelog:
 - no change
v4 changelog:
 - no change
v3 changelog:
 - New patch
---
 drivers/net/ethernet/oa_tc6.c | 19 ++++++++++---------
 1 file changed, 10 insertions(+), 9 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 955148d3cefc..417c15d1ff42 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -499,13 +499,14 @@ int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
 {
 	struct oa_tc6 *tc6 = bus->priv;
 	u32 regval;
+	int mms;
 	int ret;
 
-	ret = oa_tc6_get_phy_c45_mms(devnum);
-	if (ret < 0)
-		return ret;
+	mms = oa_tc6_get_phy_c45_mms(devnum);
+	if (mms < 0)
+		return mms;
 
-	ret = oa_tc6_read_register(tc6, (ret << 16) | regnum, &regval);
+	ret = oa_tc6_read_register_mms(tc6, mms, regnum, &regval);
 	if (ret)
 		return ret;
 
@@ -517,13 +518,13 @@ int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
 			     int regnum, u16 val)
 {
 	struct oa_tc6 *tc6 = bus->priv;
-	int ret;
+	int mms;
 
-	ret = oa_tc6_get_phy_c45_mms(devnum);
-	if (ret < 0)
-		return ret;
+	mms = oa_tc6_get_phy_c45_mms(devnum);
+	if (mms < 0)
+		return mms;
 
-	return oa_tc6_write_register(tc6, (ret << 16) | regnum, val);
+	return oa_tc6_write_register_mms(tc6, mms, regnum, val);
 }
 EXPORT_SYMBOL_GPL(oa_tc6_mdiobus_write_c45);
 

-- 
2.43.0

