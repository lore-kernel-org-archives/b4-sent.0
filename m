From: Satish Kharat <satishkh@cisco.com>
Date: Wed, 08 Apr 2026 08:08:11 -0700
Subject: [PATCH net-next v2 01/10] enic: verify firmware supports V2 SR-IOV
 at probe time
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-enic-sriov-v2-admin-channel-v2-v2-1-d05dd3623fd3@cisco.com>
References: <20260408-enic-sriov-v2-admin-channel-v2-v2-0-d05dd3623fd3@cisco.com>
In-Reply-To: <20260408-enic-sriov-v2-admin-channel-v2-v2-0-d05dd3623fd3@cisco.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com, 
 Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775660895; l=2487;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=U+7cccRNUL3xFmQmWMuuDwvDAzXNoaVbS53PO5MaWOY=;
 b=ojjFXX+8n9Aw4jr53KnkCsqac532vT1wOzk33bGXlcNYEGU2tPDvt87Ojzu1jlEWE57o8vMPX
 1Zi6f7c3Kq/CpzKg3MOh13YRehULRGYi/DqyYJvHA9vY5H+7D2gXLMr
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During PF probe, query the firmware get-supported-feature interface
to verify that the running firmware supports V2 SR-IOV. Firmware
version 5.3(4.72) and later report VIC_FEATURE_SRIOV via
CMD_GET_SUPP_FEATURE_VER. If the firmware does not support the
feature, set vf_type to ENIC_VF_TYPE_NONE and log a warning so the
admin knows a firmware upgrade is needed.

The VIC_FEATURE_SRIOV enum value (4) matches the firmware ABI. A
placeholder entry (VIC_FEATURE_PTP at position 3) is added to keep
the enum in sync with firmware's feature numbering.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic_main.c   | 18 ++++++++++++++++++
 drivers/net/ethernet/cisco/enic/vnic_devcmd.h |  2 ++
 2 files changed, 20 insertions(+)

diff --git a/drivers/net/ethernet/cisco/enic/enic_main.c b/drivers/net/ethernet/cisco/enic/enic_main.c
index e7125b818087..3a4afd6da41f 100644
--- a/drivers/net/ethernet/cisco/enic/enic_main.c
+++ b/drivers/net/ethernet/cisco/enic/enic_main.c
@@ -2641,8 +2641,10 @@ static void enic_iounmap(struct enic *enic)
 static void enic_sriov_detect_vf_type(struct enic *enic)
 {
 	struct pci_dev *pdev = enic->pdev;
+	u64 supported_versions, a1 = 0;
 	int pos;
 	u16 vf_dev_id;
+	int err;
 
 	if (enic_is_sriov_vf(enic) || enic_is_dynamic(enic))
 		return;
@@ -2669,6 +2671,22 @@ static void enic_sriov_detect_vf_type(struct enic *enic)
 		enic->vf_type = ENIC_VF_TYPE_NONE;
 		break;
 	}
+
+	if (enic->vf_type == ENIC_VF_TYPE_V2) {
+		/* A successful command means firmware recognizes
+		 * VIC_FEATURE_SRIOV; supported_versions is available
+		 * for sub-feature versioning in the future.
+		 */
+		err = vnic_dev_get_supported_feature_ver(enic->vdev,
+							 VIC_FEATURE_SRIOV,
+							 &supported_versions,
+							 &a1);
+		if (err) {
+			dev_warn(&pdev->dev,
+				 "SR-IOV V2 not supported by current firmware. Upgrade to VIC FW 5.3(4.72) or higher.\n");
+			enic->vf_type = ENIC_VF_TYPE_NONE;
+		}
+	}
 }
 #endif
 
diff --git a/drivers/net/ethernet/cisco/enic/vnic_devcmd.h b/drivers/net/ethernet/cisco/enic/vnic_devcmd.h
index 605ef17f967e..7a4bce736105 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_devcmd.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_devcmd.h
@@ -734,6 +734,8 @@ enum vic_feature_t {
 	VIC_FEATURE_VXLAN,
 	VIC_FEATURE_RDMA,
 	VIC_FEATURE_VXLAN_PATCH,
+	VIC_FEATURE_PTP,
+	VIC_FEATURE_SRIOV,
 	VIC_FEATURE_MAX,
 };
 

-- 
2.43.0

