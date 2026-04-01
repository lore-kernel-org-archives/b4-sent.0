From: Satish Kharat <satishkh@cisco.com>
Date: Wed, 01 Apr 2026 08:31:11 -0700
Subject: [PATCH net-next v4 1/6] enic: extend resource discovery for SR-IOV
 admin channel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-enic-sriov-v2-prep-v4-1-d5834b2ef1b9@cisco.com>
References: <20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com>
In-Reply-To: <20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com>
To: Satish Kharat <satishkh@cisco.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775057474; l=3356;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=y0pGwL9wW5ULZUwdK19OUJqESwm7dxXUYk9R9IIroV8=;
 b=ZP9Adj0tYDtyKk8NvLNaGcW7dIiyFFcr0tbrBPONiWiuehFPYidDcpH6qC7pmXcqmXfbajRdE
 0FnBEGKIU2pDQEMzhIZh4oo313Rk0QtzRildB1suTNEcikpT5Phf8Ds
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

VIC firmware exposes admin channel resources (WQ, RQ, CQ) for PF-VF
communication when SR-IOV is active. Add the corresponding resource
type definitions and teach the discovery and access functions to
handle them.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic.h          |  2 ++
 drivers/net/ethernet/cisco/enic/vnic_dev.c      | 10 ++++++++++
 drivers/net/ethernet/cisco/enic/vnic_resource.h |  4 ++++
 3 files changed, 16 insertions(+)

diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index 6959e85ab516..366c65d072fc 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -297,6 +297,8 @@ static inline struct net_device *vnic_get_netdev(struct vnic_dev *vdev)
 	dev_warn(&(vdev)->pdev->dev, fmt, ##__VA_ARGS__)
 #define vdev_info(vdev, fmt, ...)					\
 	dev_info(&(vdev)->pdev->dev, fmt, ##__VA_ARGS__)
+#define vdev_dbg(vdev, fmt, ...)					\
+	dev_dbg(&(vdev)->pdev->dev, fmt, ##__VA_ARGS__)
 
 #define vdev_neterr(vdev, fmt, ...)					\
 	netdev_err(vnic_get_netdev(vdev), fmt, ##__VA_ARGS__)
diff --git a/drivers/net/ethernet/cisco/enic/vnic_dev.c b/drivers/net/ethernet/cisco/enic/vnic_dev.c
index c72452749f5e..c8d657e97094 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_dev.c
+++ b/drivers/net/ethernet/cisco/enic/vnic_dev.c
@@ -77,6 +77,9 @@ static int vnic_dev_discover_res(struct vnic_dev *vdev,
 		u32 count = ioread32(&r->count);
 		u32 len;
 
+		vdev_dbg(vdev, "res type %u bar %u offset 0x%x count %u\n",
+			 type, bar_num, bar_offset, count);
+
 		r++;
 
 		if (bar_num >= num_bars)
@@ -90,6 +93,9 @@ static int vnic_dev_discover_res(struct vnic_dev *vdev,
 		case RES_TYPE_RQ:
 		case RES_TYPE_CQ:
 		case RES_TYPE_INTR_CTRL:
+		case RES_TYPE_ADMIN_WQ:
+		case RES_TYPE_ADMIN_RQ:
+		case RES_TYPE_ADMIN_CQ:
 			/* each count is stride bytes long */
 			len = count * VNIC_RES_STRIDE;
 			if (len + bar_offset > bar[bar_num].len) {
@@ -102,6 +108,7 @@ static int vnic_dev_discover_res(struct vnic_dev *vdev,
 		case RES_TYPE_INTR_PBA_LEGACY:
 		case RES_TYPE_DEVCMD:
 		case RES_TYPE_DEVCMD2:
+		case RES_TYPE_SRIOV_INTR:
 			len = count;
 			break;
 		default:
@@ -135,6 +142,9 @@ void __iomem *vnic_dev_get_res(struct vnic_dev *vdev, enum vnic_res_type type,
 	case RES_TYPE_RQ:
 	case RES_TYPE_CQ:
 	case RES_TYPE_INTR_CTRL:
+	case RES_TYPE_ADMIN_WQ:
+	case RES_TYPE_ADMIN_RQ:
+	case RES_TYPE_ADMIN_CQ:
 		return (char __iomem *)vdev->res[type].vaddr +
 			index * VNIC_RES_STRIDE;
 	default:
diff --git a/drivers/net/ethernet/cisco/enic/vnic_resource.h b/drivers/net/ethernet/cisco/enic/vnic_resource.h
index b4776e334d63..d327821fa9b9 100644
--- a/drivers/net/ethernet/cisco/enic/vnic_resource.h
+++ b/drivers/net/ethernet/cisco/enic/vnic_resource.h
@@ -42,6 +42,10 @@ enum vnic_res_type {
 	RES_TYPE_DEPRECATED1,		/* Old version of devcmd 2 */
 	RES_TYPE_DEPRECATED2,		/* Old version of devcmd 2 */
 	RES_TYPE_DEVCMD2,		/* Device control region */
+	RES_TYPE_SRIOV_INTR = 45,	/* SR-IOV VF interrupt */
+	RES_TYPE_ADMIN_WQ = 49,	/* Admin channel WQ */
+	RES_TYPE_ADMIN_RQ,		/* Admin channel RQ */
+	RES_TYPE_ADMIN_CQ,		/* Admin channel CQ */
 
 	RES_TYPE_MAX,			/* Count of resource types */
 };

-- 
2.43.0

