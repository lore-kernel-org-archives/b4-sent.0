From: Ciprian Regus <ciprian.regus@analog.com>
Date: Wed, 08 Jul 2026 01:33:37 +0300
Subject: [PATCH net-next v5 09/13] net: ethernet: oa_tc6: Add new register
 address defines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260708-adin1140-driver-v5-9-4aca7b51a58b@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783463678; l=1428;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=EB3VnhWgqf4dLA3gFeg1s1OOxPLFVIe16UjLMTG7z2A=;
 b=lyhBNQWt+DGs4orIM8oJH+38D29vo11L9sC0zvpN6/ka6YGu/VqxrsWbFyuuoa0iTMIKRiMQd
 KnW+4p3kwSDCDE34s0bjDouhsESWUiYQv6g7HoMOIXgVvvYFwd84ZnQ
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add macro defines for the CONFIG2 register and the MMS1 memory map.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>
---
v5 changelog:
 - no change
v4 changelog:
 - rename OA_TC6_VEND_MMS1 to OA_TC6_MAC_MMS1.
 - group the MMS1 entry with the other MMS values and update the comment
   describing that set of macros.
v3 changelog:
 - New patch
---
 include/linux/oa_tc6.h | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 701e8930d80d..27f652d4920b 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -25,6 +25,9 @@
 #define OA_TC6_CONFIG0_ZARFE_ENABLE		BIT(12)
 #define OA_TC6_CONFIG0_PROTE			BIT(5)
 
+/* Configuration Register #2 */
+#define OA_TC6_REG_CONFIG2			0x0006
+
 /* Status Register #0 */
 #define OA_TC6_REG_STATUS0			0x0008
 #define OA_TC6_STATUS0_RESETC			BIT(6)	/* Reset Complete */
@@ -51,9 +54,10 @@
 #define OA_TC6_PHY_STD_REG_ADDR_BASE		0xFF00
 #define OA_TC6_PHY_STD_REG_ADDR_MASK		0x1F
 
-/* PHY – Clause 45 registers memory map selector (MMS) as per table 6 in the
+/* Memory map selector (MMS) values as per table 6 in the
  * OPEN Alliance specification.
  */
+#define OA_TC6_MAC_MMS1				1
 #define OA_TC6_PHY_C45_PCS_MMS2			2	/* MMD 3 */
 #define OA_TC6_PHY_C45_PMA_PMD_MMS3		3	/* MMD 1 */
 #define OA_TC6_PHY_C45_VS_PLCA_MMS4		4	/* MMD 31 */

-- 
2.43.0

