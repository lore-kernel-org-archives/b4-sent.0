From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 29 Jun 2026 10:23:43 -0700
Subject: [PATCH net-next v6 13/15] onsemi: s2500: Added selftest support to
 onsemi's S2500 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-s2500-mac-phy-support-v6-13-18ce79500371@onsemi.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782753817; l=2141;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=xAh4QdUPM7M3PmJFMlwFYJNUCquBDeDkO1wtN+J0YbU=;
 b=+A8gde5WdF34H6/DxTt35y69ewrY5xKvkPimmHCcnYspVH3cyTIcH5ehJhesnN67psXCZbLeT
 ovOA+RK+EljDvAeRea4PEMDuOiZjkSFTFTCl6l8HJKee/irTMsoLRwi
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds selftest support for onsemi S2500 MAC-PHY. Added as a separate
patch for the ease of review.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v6
  - Moved the signed off information to the correct place.
changes in v5
  - No change
changes in v4:
  - Added a selftest as a separate patch
  - First patch
---
 drivers/net/ethernet/onsemi/s2500/Kconfig         | 1 +
 drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c | 7 +++++++
 2 files changed, 8 insertions(+)

diff --git a/drivers/net/ethernet/onsemi/s2500/Kconfig b/drivers/net/ethernet/onsemi/s2500/Kconfig
index f2e8d5d1429d..7bb4b413d5f9 100644
--- a/drivers/net/ethernet/onsemi/s2500/Kconfig
+++ b/drivers/net/ethernet/onsemi/s2500/Kconfig
@@ -8,6 +8,7 @@ if NET_VENDOR_ONSEMI
 config S2500_MACPHY
 	tristate "S2500 support"
 	depends on SPI
+	imply NET_SELFTESTS
 	select NCN26000_PHY
 	select OA_TC6
 	help
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c b/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
index 7760cec57849..b149cb72ed77 100644
--- a/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
@@ -5,6 +5,7 @@
  */
 
 #include <linux/ethtool.h>
+#include <net/selftests.h>
 #include <linux/phy.h>
 
 #include "s2500_hw_def.h"
@@ -229,6 +230,8 @@ static int s2500_get_sset_count(struct net_device *ndev, int sset)
 	switch (sset) {
 	case ETH_SS_STATS:
 		return S2500_MAC_STATS_LEN;
+	case ETH_SS_TEST:
+		return net_selftest_get_count();
 	default:
 		return -EOPNOTSUPP;
 	}
@@ -242,6 +245,9 @@ static void s2500_get_strings(struct net_device *ndev, u32 stringset,
 		memcpy(buf, s2500_mac_stat_strings,
 		       S2500_MAC_STATS_LEN * ETH_GSTRING_LEN);
 		break;
+	case ETH_SS_TEST:
+		net_selftest_get_strings(buf);
+		break;
 	}
 }
 
@@ -349,5 +355,6 @@ const struct ethtool_ops s2500_ethtool_ops = {
 	.get_ts_info        = s2500_get_ts_info,
 	.get_regs_len       = s2500_get_regs_len,
 	.get_regs           = s2500_get_regs,
+	.self_test          = net_selftest,
 };
 

-- 
2.43.0

