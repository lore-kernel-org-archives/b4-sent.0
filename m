From: Satish Kharat <satishkh@cisco.com>
Date: Sat, 21 Feb 2026 10:17:00 -0800
Subject: [PATCH 2/2] net:ethernet:enic: map ethtool link modes by VIC type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260221-enic-cscwi36355-v1-2-5a01a6046d5e@cisco.com>
References: <20260221-enic-cscwi36355-v1-0-5a01a6046d5e@cisco.com>
In-Reply-To: <20260221-enic-cscwi36355-v1-0-5a01a6046d5e@cisco.com>
To: netdev@vger.kernel.org
Cc: Satish Kharat <satishkh@cisco.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771697893; l=10825;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=N8+kx2iBxqmrLKDZNVdwcLIsgoMssw7v9dyzc2PHkug=;
 b=64KvIvj7jOG4a//DsBtTdWjXE8su0jbhjaYA+eiALn4FaECFd14f4M18MH9bAnnkgLCxARptm
 ohthWDszQfRC4t5iDJhuhvA2r2ehcMOofR/mxdXEjxFiltxjj0T2i9C
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Report supported and advertised media types based on the VIC subsystem
ID so ethtool reflects the hardware capabilities.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic_ethtool.c | 229 ++++++++++++++++++++++++-
 1 file changed, 222 insertions(+), 7 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/enic_ethtool.c b/drivers/net/ethernet/cisco/enic/enic_ethtool.c
index 471613899..80fbbb7ef 100644
--- a/drivers/net/ethernet/cisco/enic/enic_ethtool.c
+++ b/drivers/net/ethernet/cisco/enic/enic_ethtool.c
@@ -126,19 +126,234 @@ static void enic_intr_coal_set_rx(struct enic *enic, u32 timer)
 	}
 }
 
+static void enic_get_supp_adv_media_type(struct net_device *netdev,
+					 struct ethtool_link_ksettings *ecmd)
+{
+	struct enic *enic = netdev_priv(netdev);
+	struct ethtool_link_settings *base = &ecmd->base;
+	u16 sub_dev_id = 0;
+
+	base->port = PORT_OTHER;
+
+	if (enic->pdev)
+		sub_dev_id = enic->pdev->subsystem_device;
+
+	switch (sub_dev_id) {
+	case PCI_SUBDEV_ID_CISCO_VIC_1225:
+	case PCI_SUBDEV_ID_CISCO_VIC_1227:
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     10000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     10000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported, FIBRE);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising, FIBRE);
+		base->port = PORT_FIBRE;
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_1285:
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported, FIBRE);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising, FIBRE);
+		base->port = PORT_FIBRE;
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_1225T:
+	case PCI_SUBDEV_ID_CISCO_VIC_1227T:
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     10000baseT_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     10000baseT_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported, FIBRE);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising, FIBRE);
+		base->port = PORT_FIBRE;
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_1385:
+	case PCI_SUBDEV_ID_CISCO_VIC_1387:
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     10000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     10000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     10000baseLR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     10000baseLR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseLR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseLR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported, FIBRE);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising, FIBRE);
+		base->port = PORT_FIBRE;
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_1477:
+	case PCI_SUBDEV_ID_CISCO_VIC_1485:
+	case PCI_SUBDEV_ID_CISCO_VIC_1487:
+	case PCI_SUBDEV_ID_CISCO_VIC_1495:
+	case PCI_SUBDEV_ID_CISCO_VIC_1497:
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseCR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseCR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseLR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseLR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     100000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     100000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     100000baseCR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     100000baseCR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported, FIBRE);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising, FIBRE);
+		base->port = PORT_FIBRE;
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_15235:
+	case PCI_SUBDEV_ID_CISCO_VIC_15237:
+	case PCI_SUBDEV_ID_CISCO_VIC_15238:
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseCR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseCR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseLR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseLR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     100000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     100000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     100000baseCR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     100000baseCR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     200000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     200000baseSR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     200000baseDR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     200000baseDR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     200000baseLR4_ER4_FR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     200000baseLR4_ER4_FR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported, FIBRE);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising, FIBRE);
+		base->port = PORT_FIBRE;
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_1455:
+	case PCI_SUBDEV_ID_CISCO_VIC_1457:
+	case PCI_SUBDEV_ID_CISCO_VIC_1467:
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     10000baseT_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     10000baseT_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     25000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     25000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported, FIBRE);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising, FIBRE);
+		base->port = PORT_FIBRE;
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_15428:
+	case PCI_SUBDEV_ID_CISCO_VIC_15427:
+	case PCI_SUBDEV_ID_CISCO_VIC_15425:
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     10000baseT_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     10000baseT_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     25000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     25000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     50000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     50000baseSR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported, FIBRE);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising, FIBRE);
+		base->port = PORT_FIBRE;
+		break;
+	/* Do not mention port type as FIBRE for blade VICs */
+	case PCI_SUBDEV_ID_CISCO_VIC_1240:
+	case PCI_SUBDEV_ID_CISCO_VIC_1280:
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     10000baseKR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     10000baseKR_Full);
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_1340:
+	case PCI_SUBDEV_ID_CISCO_VIC_1380:
+	case PCI_SUBDEV_ID_CISCO_VIC_1440: /* 10G/40G KR */
+	case PCI_SUBDEV_ID_CISCO_VIC_1480: /* 10G/40G KR */
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     10000baseKR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     10000baseKR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     40000baseKR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     40000baseKR4_Full);
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_14425: /* 25G KR */
+	case PCI_SUBDEV_ID_CISCO_VIC_14825: /* 25G KR */
+	case PCI_SUBDEV_ID_CISCO_VIC_15420: /* 25G KR */
+	case PCI_SUBDEV_ID_CISCO_VIC_15422: /* 25G KR */
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     25000baseKR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     25000baseKR_Full);
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_15411: /* 10G KR */
+	case PCI_SUBDEV_ID_CISCO_VIC_15412: /* 10G KR */
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     10000baseKR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     10000baseKR_Full);
+		break;
+	case PCI_SUBDEV_ID_CISCO_VIC_15231: /* 25G/100G/200G KR */
+	case PCI_SUBDEV_ID_CISCO_VIC_15230: /* 25G/100G/200G KR */
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     25000baseKR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     25000baseKR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     100000baseKR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     100000baseKR_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, supported,
+						     200000baseKR4_Full);
+		ethtool_link_ksettings_add_link_mode(ecmd, advertising,
+						     200000baseKR4_Full);
+		break;
+	}
+}
+
 static int enic_get_ksettings(struct net_device *netdev,
 			      struct ethtool_link_ksettings *ecmd)
 {
 	struct enic *enic = netdev_priv(netdev);
 	struct ethtool_link_settings *base = &ecmd->base;
 
-	ethtool_link_ksettings_add_link_mode(ecmd, supported,
-					     10000baseT_Full);
-	ethtool_link_ksettings_add_link_mode(ecmd, supported, FIBRE);
-	ethtool_link_ksettings_add_link_mode(ecmd, advertising,
-					     10000baseT_Full);
-	ethtool_link_ksettings_add_link_mode(ecmd, advertising, FIBRE);
-	base->port = PORT_FIBRE;
+	enic_get_supp_adv_media_type(netdev, ecmd);
 
 	if (netif_carrier_ok(netdev)) {
 		base->speed = vnic_dev_port_speed(enic->vdev);

-- 
2.43.0

