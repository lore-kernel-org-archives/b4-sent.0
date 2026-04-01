From: Satish Kharat <satishkh@cisco.com>
Date: Wed, 01 Apr 2026 08:31:14 -0700
Subject: [PATCH net-next v4 4/6] enic: make enic_dev_enable/disable
 ref-counted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-enic-sriov-v2-prep-v4-4-d5834b2ef1b9@cisco.com>
References: <20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com>
In-Reply-To: <20260401-enic-sriov-v2-prep-v4-0-d5834b2ef1b9@cisco.com>
To: Satish Kharat <satishkh@cisco.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775057474; l=4130;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=zvvdRfwq8gsBZZOSKyc4TXaUkVuYP93HpEGc0xRpx0k=;
 b=faHAjZwd4ltGsy3HOtd2pkMIBkRUiT6vgD8Is0FcEb0Nuo6GQ8M0JUPbQJqeWzqgpF+JeJS8D
 BL7reGlC7dsA4Bf8oRCLz4HoX1h8IbD9W8dsp6ls/VslCAPqOMu2uJf
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both the data path (ndo_open/ndo_stop) and the upcoming admin channel
need to enable and disable the vNIC device independently. Without
reference counting, closing the admin channel while the netdev is up
would inadvertently disable the entire device.

Add an enable_count to struct enic, protected by the existing
devcmd_lock. enic_dev_enable() issues CMD_ENABLE_WAIT only on the
first caller (0 -> 1 transition), and enic_dev_disable() issues
CMD_DISABLE only when the last caller releases (1 -> 0 transition).

Also check the return value of enic_dev_enable() in enic_open() and
fail the open if the firmware enable command fails. Without this check,
a failed enable leaves enable_count at zero while the interface appears
up, which can cause a later admin channel enable/disable cycle to
incorrectly disable the hardware under the active data path.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic.h      |  1 +
 drivers/net/ethernet/cisco/enic/enic_dev.c  | 17 +++++++++++++----
 drivers/net/ethernet/cisco/enic/enic_main.c | 17 ++++++++++++++++-
 3 files changed, 30 insertions(+), 5 deletions(-)

diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index 0fd9cd917132..67fd780b1fa1 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -260,6 +260,7 @@ struct enic {
 	u16 num_vfs;
 #endif
 	enum enic_vf_type vf_type;
+	unsigned int enable_count;
 	spinlock_t enic_api_lock;
 	bool enic_api_busy;
 	struct enic_port_profile *pp;
diff --git a/drivers/net/ethernet/cisco/enic/enic_dev.c b/drivers/net/ethernet/cisco/enic/enic_dev.c
index 2cbae7c6cc3d..659787f73cf1 100644
--- a/drivers/net/ethernet/cisco/enic/enic_dev.c
+++ b/drivers/net/ethernet/cisco/enic/enic_dev.c
@@ -131,10 +131,13 @@ int enic_dev_set_ig_vlan_rewrite_mode(struct enic *enic)
 
 int enic_dev_enable(struct enic *enic)
 {
-	int err;
+	int err = 0;
 
 	spin_lock_bh(&enic->devcmd_lock);
-	err = vnic_dev_enable_wait(enic->vdev);
+	if (enic->enable_count == 0)
+		err = vnic_dev_enable_wait(enic->vdev);
+	if (!err)
+		enic->enable_count++;
 	spin_unlock_bh(&enic->devcmd_lock);
 
 	return err;
@@ -142,10 +145,16 @@ int enic_dev_enable(struct enic *enic)
 
 int enic_dev_disable(struct enic *enic)
 {
-	int err;
+	int err = 0;
 
 	spin_lock_bh(&enic->devcmd_lock);
-	err = vnic_dev_disable(enic->vdev);
+	if (enic->enable_count == 0) {
+		spin_unlock_bh(&enic->devcmd_lock);
+		return 0;
+	}
+	enic->enable_count--;
+	if (enic->enable_count == 0)
+		err = vnic_dev_disable(enic->vdev);
 	spin_unlock_bh(&enic->devcmd_lock);
 
 	return err;
diff --git a/drivers/net/ethernet/cisco/enic/enic_main.c b/drivers/net/ethernet/cisco/enic/enic_main.c
index acd05350ec1a..e7125b818087 100644
--- a/drivers/net/ethernet/cisco/enic/enic_main.c
+++ b/drivers/net/ethernet/cisco/enic/enic_main.c
@@ -1750,7 +1750,11 @@ static int enic_open(struct net_device *netdev)
 	if (vnic_dev_get_intr_mode(enic->vdev) == VNIC_DEV_INTR_MODE_MSIX)
 		for (i = 0; i < enic->wq_count; i++)
 			napi_enable(&enic->napi[enic_cq_wq(enic, i)]);
-	enic_dev_enable(enic);
+	err = enic_dev_enable(enic);
+	if (err) {
+		netdev_err(netdev, "Failed to enable device: %d\n", err);
+		goto err_out_dev_enable;
+	}
 
 	for (i = 0; i < enic->intr_count; i++)
 		vnic_intr_unmask(&enic->intr[i]);
@@ -1760,6 +1764,17 @@ static int enic_open(struct net_device *netdev)
 
 	return 0;
 
+err_out_dev_enable:
+	for (i = 0; i < enic->rq_count; i++)
+		napi_disable(&enic->napi[i]);
+	if (vnic_dev_get_intr_mode(enic->vdev) == VNIC_DEV_INTR_MODE_MSIX)
+		for (i = 0; i < enic->wq_count; i++)
+			napi_disable(&enic->napi[enic_cq_wq(enic, i)]);
+	netif_tx_disable(netdev);
+	if (!enic_is_dynamic(enic) && !enic_is_sriov_vf(enic))
+		enic_dev_del_station_addr(enic);
+	for (i = 0; i < enic->wq_count; i++)
+		vnic_wq_disable(&enic->wq[i].vwq);
 err_out_free_rq:
 	for (i = 0; i < enic->rq_count; i++) {
 		ret = vnic_rq_disable(&enic->rq[i].vrq);

-- 
2.43.0

