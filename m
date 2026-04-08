From: Satish Kharat <satishkh@cisco.com>
Date: Wed, 08 Apr 2026 08:08:19 -0700
Subject: [PATCH net-next v2 09/10] enic: wire V2 SR-IOV enable with admin
 channel and MBOX
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-enic-sriov-v2-admin-channel-v2-v2-9-d05dd3623fd3@cisco.com>
References: <20260408-enic-sriov-v2-admin-channel-v2-v2-0-d05dd3623fd3@cisco.com>
In-Reply-To: <20260408-enic-sriov-v2-admin-channel-v2-v2-0-d05dd3623fd3@cisco.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com, 
 Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775660895; l=6935;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=0Zp148iTdgKUk7HjYvB2gUm0XG1uGsH31sXpO9CD+ik=;
 b=quOaxKFxf+A3HUKuR/jfaHep3haE5vVowegc5xi9ApzAklmC+Q0yq743quNrQDpZ8xlbHjghc
 ILRAzm51K3eAWZzUhu5jdxo0ndhiJ/rfhHzzaR0uskQgmiPHeKUeyWE
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend enic_sriov_configure() to handle V2 SR-IOV VFs. When the PF
detects V2 VF device IDs, the enable path allocates per-VF MBOX state,
opens the admin channel, initializes the MBOX protocol, and then calls
pci_enable_sriov(). The admin channel must be ready before VFs are
created so that VF drivers can immediately begin the MBOX capability
and registration handshake during their probe.

The disable path reverses this order: pci_disable_sriov() first (so VF
drivers unregister via MBOX), then the admin channel is closed and
per-VF state is freed.

The existing V1/USNIC SR-IOV paths are unchanged.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic_main.c | 137 ++++++++++++++++++++++++++--
 drivers/net/ethernet/cisco/enic/enic_res.c  |   1 +
 drivers/net/ethernet/cisco/enic/vnic_enet.h |   4 +-
 3 files changed, 134 insertions(+), 8 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/enic_main.c b/drivers/net/ethernet/cisco/enic/enic_main.c
index 3a4afd6da41f..48c38347d6ce 100644
--- a/drivers/net/ethernet/cisco/enic/enic_main.c
+++ b/drivers/net/ethernet/cisco/enic/enic_main.c
@@ -60,6 +60,8 @@
 #include "enic_clsf.h"
 #include "enic_rq.h"
 #include "enic_wq.h"
+#include "enic_admin.h"
+#include "enic_mbox.h"
 
 #define ENIC_NOTIFY_TIMER_PERIOD	(2 * HZ)
 
@@ -2688,6 +2690,120 @@ static void enic_sriov_detect_vf_type(struct enic *enic)
 		}
 	}
 }
+
+static int __maybe_unused
+enic_sriov_v2_enable(struct enic *enic, int num_vfs)
+{
+	int err;
+
+	if (!enic->has_admin_channel) {
+		netdev_err(enic->netdev,
+			   "V2 SR-IOV requires admin channel resources\n");
+		return -EOPNOTSUPP;
+	}
+
+	enic->vf_state = kcalloc(num_vfs, sizeof(*enic->vf_state), GFP_KERNEL);
+	if (!enic->vf_state)
+		return -ENOMEM;
+
+	err = enic_admin_channel_open(enic);
+	if (err) {
+		netdev_err(enic->netdev,
+			   "Failed to open admin channel: %d\n", err);
+		goto free_vf_state;
+	}
+
+	enic_mbox_init(enic);
+
+	enic->num_vfs = num_vfs;
+
+	err = pci_enable_sriov(enic->pdev, num_vfs);
+	if (err) {
+		netdev_err(enic->netdev,
+			   "pci_enable_sriov failed: %d\n", err);
+		goto close_admin;
+	}
+
+	enic->priv_flags |= ENIC_SRIOV_ENABLED;
+	return num_vfs;
+
+close_admin:
+	enic->num_vfs = 0;
+	enic_admin_channel_close(enic);
+free_vf_state:
+	kfree(enic->vf_state);
+	enic->vf_state = NULL;
+	return err;
+}
+
+static void enic_sriov_v2_disable(struct enic *enic)
+{
+	pci_disable_sriov(enic->pdev);
+	enic_admin_channel_close(enic);
+	kfree(enic->vf_state);
+	enic->vf_state = NULL;
+	enic->num_vfs = 0;
+	enic->priv_flags &= ~ENIC_SRIOV_ENABLED;
+}
+
+static int __maybe_unused
+enic_sriov_configure(struct pci_dev *pdev, int num_vfs)
+{
+	struct net_device *netdev = pci_get_drvdata(pdev);
+	struct enic *enic = netdev_priv(netdev);
+	struct enic_port_profile *pp;
+	int err;
+
+	if (num_vfs > 0) {
+		if (enic->config.mq_subvnic_count) {
+			netdev_err(netdev,
+				   "SR-IOV not supported with multi-queue sub-vnics\n");
+			return -EOPNOTSUPP;
+		}
+
+		if (enic->vf_type == ENIC_VF_TYPE_NONE) {
+			netdev_err(netdev,
+				   "SR-IOV not supported on this firmware version\n");
+			return -EOPNOTSUPP;
+		}
+
+		if (enic->vf_type == ENIC_VF_TYPE_V2)
+			return enic_sriov_v2_enable(enic, num_vfs);
+
+		pp = kcalloc(num_vfs, sizeof(*pp), GFP_KERNEL);
+		if (!pp)
+			return -ENOMEM;
+
+		err = pci_enable_sriov(pdev, num_vfs);
+		if (err) {
+			kfree(pp);
+			return err;
+		}
+
+		kfree(enic->pp);
+		enic->pp = pp;
+		enic->num_vfs = num_vfs;
+		enic->priv_flags |= ENIC_SRIOV_ENABLED;
+		return num_vfs;
+	}
+
+	if (!enic_sriov_enabled(enic))
+		return 0;
+
+	if (enic->vf_type == ENIC_VF_TYPE_V2) {
+		enic_sriov_v2_disable(enic);
+		return 0;
+	}
+
+	pci_disable_sriov(pdev);
+	enic->num_vfs = 0;
+	enic->priv_flags &= ~ENIC_SRIOV_ENABLED;
+
+	kfree(enic->pp);
+	enic->pp = kzalloc(sizeof(*enic->pp), GFP_KERNEL);
+
+	return 0;
+}
 #endif
 
 static int enic_probe(struct pci_dev *pdev, const struct pci_device_id *ent)
@@ -2786,12 +2902,18 @@ static int enic_probe(struct pci_dev *pdev, const struct pci_device_id *ent)
 		goto err_out_vnic_unregister;
 
 #ifdef CONFIG_PCI_IOV
-	/* Get number of subvnics */
+	enic_sriov_detect_vf_type(enic);
+
+	/* Auto-enable SR-IOV if VFs were pre-configured (e.g. at boot).
+	 * V2 VFs require the admin channel, which is not yet set up at probe
+	 * time; use sysfs (enic_sriov_configure) to enable V2 SR-IOV instead.
+	 */
 	pos = pci_find_ext_capability(pdev, PCI_EXT_CAP_ID_SRIOV);
 	if (pos) {
 		pci_read_config_word(pdev, pos + PCI_SRIOV_TOTAL_VF,
 			&enic->num_vfs);
-		if (enic->num_vfs) {
+		if (enic->num_vfs &&
+		    enic->vf_type != ENIC_VF_TYPE_V2) {
 			err = pci_enable_sriov(pdev, enic->num_vfs);
 			if (err) {
 				dev_err(dev, "SRIOV enable failed, aborting."
@@ -2803,7 +2925,6 @@ static int enic_probe(struct pci_dev *pdev, const struct pci_device_id *ent)
 			num_pps = enic->num_vfs;
 		}
 	}
-	enic_sriov_detect_vf_type(enic);
 #endif
 
 	/* Allocate structure for port profiles */
@@ -3032,14 +3153,16 @@ static void enic_remove(struct pci_dev *pdev)
 		cancel_work_sync(&enic->reset);
 		cancel_work_sync(&enic->change_mtu_work);
 		unregister_netdev(netdev);
-		enic_dev_deinit(enic);
-		vnic_dev_close(enic->vdev);
 #ifdef CONFIG_PCI_IOV
 		if (enic_sriov_enabled(enic)) {
-			pci_disable_sriov(pdev);
-			enic->priv_flags &= ~ENIC_SRIOV_ENABLED;
+			if (enic->vf_type == ENIC_VF_TYPE_V2)
+				enic_sriov_v2_disable(enic);
+			else
+				pci_disable_sriov(pdev);
 		}
 #endif
+		enic_dev_deinit(enic);
+		vnic_dev_close(enic->vdev);
 		kfree(enic->pp);
 		vnic_dev_unregister(enic->vdev);
 		enic_iounmap(enic);
diff --git a/drivers/net/ethernet/cisco/enic/enic_res.c b/drivers/net/ethernet/cisco/enic/enic_res.c
index 2b7545d6a67f..436326ace049 100644
--- a/drivers/net/ethernet/cisco/enic/enic_res.c
+++ b/drivers/net/ethernet/cisco/enic/enic_res.c
@@ -59,6 +59,7 @@ int enic_get_vnic_config(struct enic *enic)
 	GET_CONFIG(intr_timer_usec);
 	GET_CONFIG(loop_tag);
 	GET_CONFIG(num_arfs);
+	GET_CONFIG(mq_subvnic_count);
 	GET_CONFIG(max_rq_ring);
 	GET_CONFIG(max_wq_ring);
 	GET_CONFIG(max_cq_ring);
diff --git a/drivers/net/ethernet/cisco/enic/vnic_enet.h b/drivers/net/ethernet/cisco/enic/vnic_enet.h
index 9e8e86262a3f..519d2969990b 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_enet.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_enet.h
@@ -21,7 +21,9 @@ struct vnic_enet_config {
 	u16 loop_tag;
 	u16 vf_rq_count;
 	u16 num_arfs;
-	u8 reserved[66];
+	u8 reserved1[32];
+	u16 mq_subvnic_count;
+	u8 reserved2[32];
 	u32 max_rq_ring;	// MAX RQ ring size
 	u32 max_wq_ring;	// MAX WQ ring size
 	u32 max_cq_ring;	// MAX CQ ring size

-- 
2.43.0

