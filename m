From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 09 Oct 2026 10:12:29 -0700
Subject: [PATCH net-next v9 09/11] onsemi: s2500: Added selftest support to
 onsemi's S2500 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-s2500-mac-phy-support-v9-9-dcefe1d0bf0d@onsemi.com>
References: <20261009-s2500-mac-phy-support-v9-0-dcefe1d0bf0d@onsemi.com>
In-Reply-To: <20261009-s2500-mac-phy-support-v9-0-dcefe1d0bf0d@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791565943; l=1779;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=0s8jXlqiuPiEwP153abb8OuiPHKo4VvluMNFFTW261I=;
 b=qF7plycfdK+m6YWv7lNIvyKxtYPWEXgVZq6pIhIay3JHOMohGn0Cu7i7G92dI+8VjhGCxkuLY
 Kzm26IsWw+6CIrqL/TH9r4hEhGR3AzCkEQ1YjrA5gmsJDT1oPqXjfuo
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds selftest support for onsemi S2500 MAC-PHY. Added as a separate
patch for the ease of review.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v9
  - Added net_selftest entry to the ethtool_ops in the correct patch
changes in v8
  - No change
changes in v7
  - No change
changes in v6
  - Moved the signed off information to the correct place.
changes in v5
  - No change
changes in v4:
  - Added a selftest as a separate patch
  - First patch
---
 drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c b/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
index 062cab9460dc..12e59e8d44a6 100644
--- a/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
@@ -5,6 +5,7 @@
  */
 
 #include <linux/ethtool.h>
+#include <net/selftests.h>
 #include <linux/phy.h>
 
 #include "s2500_hw_def.h"
@@ -201,6 +202,8 @@ static int s2500_get_sset_count(struct net_device *ndev, int sset)
 	switch (sset) {
 	case ETH_SS_STATS:
 		return S2500_MAC_STATS_LEN;
+	case ETH_SS_TEST:
+		return net_selftest_get_count();
 	default:
 		return -EOPNOTSUPP;
 	}
@@ -214,6 +217,9 @@ static void s2500_get_strings(struct net_device *ndev, u32 stringset,
 		memcpy(buf, s2500_mac_stat_strings,
 		       S2500_MAC_STATS_LEN * ETH_GSTRING_LEN);
 		break;
+	case ETH_SS_TEST:
+		net_selftest_get_strings(buf);
+		break;
 	}
 }
 
@@ -372,5 +378,6 @@ const struct ethtool_ops s2500_ethtool_ops = {
 	.get_ts_info = s2500_get_ts_info,
 	.get_regs_len = s2500_get_regs_len,
 	.get_regs = s2500_get_regs,
+	.self_test = net_selftest,
 };
 

-- 
2.43.0

