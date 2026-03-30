From: Satish Kharat <satishkh@cisco.com>
Date: Sun, 29 Mar 2026 19:45:19 -0700
Subject: [PATCH net-next v3 3/6] enic: detect SR-IOV VF type from PCI
 capability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260329-enic-sriov-v2-prep-v3-3-19a477549ef6@cisco.com>
References: <20260329-enic-sriov-v2-prep-v3-0-19a477549ef6@cisco.com>
In-Reply-To: <20260329-enic-sriov-v2-prep-v3-0-19a477549ef6@cisco.com>
To: Satish Kharat <satishkh@cisco.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774838716; l=3365;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=EHjug9jFvuqtjK7rgKqTb+ZxcNgtnQ9ViaQc7HzlDNE=;
 b=D/BEZvPa4Gw73XjlMiux2p+psMbdfXBKO+bFLDb2zgnYNRMiYEzrsidmOV22123Sh+0aQ4/yR
 NbGp9/DcDOHBTIg9r9Vbv9aIPGHqok9tlu60xNPZ83uX7jIbCBKNFA8
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Read the VF device ID from the SR-IOV PCI capability at probe time to
determine whether the PF is configured for V1, USNIC, or V2 virtual
functions. Store the result in enic->vf_type for use by subsequent
SR-IOV operations.

The VF type is a firmware-configured property (set via UCSM, CIMC,
Intersight etc) that is immutable from the driver's perspective. Only
PFs are probed for this capability; VFs and dynamic vnics skip
detection.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic.h      |  8 +++++++
 drivers/net/ethernet/cisco/enic/enic_main.c | 37 +++++++++++++++++++++++++++++
 2 files changed, 45 insertions(+)

diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index 366c65d072fc..0fd9cd917132 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -225,6 +225,13 @@ struct enic_rq {
 	struct page_pool *pool;
 } ____cacheline_aligned;
 
+enum enic_vf_type {
+	ENIC_VF_TYPE_NONE,
+	ENIC_VF_TYPE_V1,
+	ENIC_VF_TYPE_USNIC,
+	ENIC_VF_TYPE_V2,
+};
+
 /* Per-instance private data structure */
 struct enic {
 	struct net_device *netdev;
@@ -252,6 +259,7 @@ struct enic {
 #ifdef CONFIG_PCI_IOV
 	u16 num_vfs;
 #endif
+	enum enic_vf_type vf_type;
 	spinlock_t enic_api_lock;
 	bool enic_api_busy;
 	struct enic_port_profile *pp;
diff --git a/drivers/net/ethernet/cisco/enic/enic_main.c b/drivers/net/ethernet/cisco/enic/enic_main.c
index e16dfbcd2c22..acd05350ec1a 100644
--- a/drivers/net/ethernet/cisco/enic/enic_main.c
+++ b/drivers/net/ethernet/cisco/enic/enic_main.c
@@ -67,6 +67,7 @@
 #define PCI_DEVICE_ID_CISCO_VIC_ENET_DYN     0x0044  /* enet dynamic vnic */
 #define PCI_DEVICE_ID_CISCO_VIC_ENET_VF      0x0071  /* enet SRIOV VF */
 #define PCI_DEVICE_ID_CISCO_VIC_ENET_VF_V2   0x02b7  /* enet SRIOV V2 VF */
+#define PCI_DEVICE_ID_CISCO_VIC_ENET_VF_USNIC 0x00cf /* enet USNIC VF */
 
 /* Supported devices */
 static const struct pci_device_id enic_id_table[] = {
@@ -2621,6 +2622,41 @@ static void enic_iounmap(struct enic *enic)
 			iounmap(enic->bar[i].vaddr);
 }
 
+#ifdef CONFIG_PCI_IOV
+static void enic_sriov_detect_vf_type(struct enic *enic)
+{
+	struct pci_dev *pdev = enic->pdev;
+	int pos;
+	u16 vf_dev_id;
+
+	if (enic_is_sriov_vf(enic) || enic_is_dynamic(enic))
+		return;
+
+	pos = pci_find_ext_capability(pdev, PCI_EXT_CAP_ID_SRIOV);
+	if (!pos) {
+		enic->vf_type = ENIC_VF_TYPE_NONE;
+		return;
+	}
+
+	pci_read_config_word(pdev, pos + PCI_SRIOV_VF_DID, &vf_dev_id);
+
+	switch (vf_dev_id) {
+	case PCI_DEVICE_ID_CISCO_VIC_ENET_VF:
+		enic->vf_type = ENIC_VF_TYPE_V1;
+		break;
+	case PCI_DEVICE_ID_CISCO_VIC_ENET_VF_USNIC:
+		enic->vf_type = ENIC_VF_TYPE_USNIC;
+		break;
+	case PCI_DEVICE_ID_CISCO_VIC_ENET_VF_V2:
+		enic->vf_type = ENIC_VF_TYPE_V2;
+		break;
+	default:
+		enic->vf_type = ENIC_VF_TYPE_NONE;
+		break;
+	}
+}
+#endif
+
 static int enic_probe(struct pci_dev *pdev, const struct pci_device_id *ent)
 {
 	struct device *dev = &pdev->dev;
@@ -2734,6 +2770,7 @@ static int enic_probe(struct pci_dev *pdev, const struct pci_device_id *ent)
 			num_pps = enic->num_vfs;
 		}
 	}
+	enic_sriov_detect_vf_type(enic);
 #endif
 
 	/* Allocate structure for port profiles */

-- 
2.43.0

