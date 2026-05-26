From: Ciprian Regus <ciprian.regus@analog.com>
Date: Wed, 27 May 2026 00:51:51 +0300
Subject: [PATCH net-next v2 06/10] net: ethernet: oa_tc6: Add MMS register
 formatting macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-adin1140-driver-v2-6-37e5c8d4e0a0@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779832338; l=1763;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=5HSxO/CCFrO2eIoVbKXw+TUIV7w+rmcLQuB9FhaUalo=;
 b=gAhgj0HuuVyFkkyVsoXiYsNNmhf059JmCkplHxS9/qQNqowACEYivJblAY0FDgN/MPrcOhAZ9
 Tbf0jXL4+GdCa1hPzqVzKEHCOZc5n1eI3gfDMULJqSTAeuYr3FhO9pw
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Open Alliance TC6 standard defines multiple memory maps for the
MAC-PHY's register space. These are used to separate standard, vendor
and PHY MMD specific registers. Add a macro to make it more clear which
memory map each register is part of and allow easier definition.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>

---
v2 changelog:
 - New patch
---
 drivers/net/ethernet/oa_tc6.c | 4 ++--
 include/linux/oa_tc6.h        | 3 +++
 2 files changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 904bd790159d..876891ca9859 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -471,7 +471,7 @@ int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
 	if (ret < 0)
 		return ret;
 
-	ret = oa_tc6_read_register(tc6, (ret << 16) | regnum, &regval);
+	ret = oa_tc6_read_register(tc6, OA_TC6_MMS_REG(ret, regnum), &regval);
 	if (ret)
 		return ret;
 
@@ -489,7 +489,7 @@ int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
 	if (ret < 0)
 		return ret;
 
-	return oa_tc6_write_register(tc6, (ret << 16) | regnum, val);
+	return oa_tc6_write_register(tc6, OA_TC6_MMS_REG(ret, regnum), val);
 }
 EXPORT_SYMBOL_GPL(oa_tc6_mdiobus_write_c45);
 
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index ad6f17218603..8b56a132c9e3 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -10,6 +10,9 @@
 #include <linux/etherdevice.h>
 #include <linux/spi/spi.h>
 
+#define OA_TC6_MMS_REG(mms, reg) \
+	((((mms) & GENMASK(3, 0)) << 16) | ((reg) & GENMASK(15, 0)))
+
 /* OPEN Alliance TC6 registers */
 
 #define OA_TC6_REG_PHYID			0x0001

-- 
2.43.0

