From: Suyuan Wang <shyckless@gmail.com>
Date: Tue, 24 Nov 2026 04:28:02 +0000
Subject: [PATCH net] qede: Don't advertise XDP features on VFs without XDP
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-qede-vf-xdp-v1-1-6fd99227d178@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFESBWsC/yWMQQrCMBQFr1Le2g9JiCJeRVxo/qt+F7EmbSmU3
 t2oyxmYWVFZjBWnbkXhbNVeuYHfdUiPa75TTBsjuHDwPkR5UylzL4sO4pz6/TGlGJVoxVDY2/K
 7nZE54vKXdbo9mcbvB9v2AU/A5ad0AAAA
X-Change-ID: 20261124-qede-vf-xdp-00d158cc44de
To: john.fastabend@gmail.com, pabeni@redhat.com, davem@davemloft.net, 
 daniel@iogearbox.net, andrew+netdev@lunn.ch, edumazet@kernel.org, 
 hawk@kernel.org, ast@kernel.org, kuba@kernel.org
Cc: netdev@vger.kernel.org, lorenzo@kernel.org, bpf@vger.kernel.org, 
 linux-kernel@vger.kernel.org, sdf@fomichev.me
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795494482; l=2042;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=vQr3uhj8nir4mygw+a8Vo5cg0xdsW+ekBDQFJzRYxlk=;
 b=lccUFniknjtEaGIRnCUPoKnsqeDfSk0tVWSy5f0m4CGQE4Oz8pusaHVqxEGqoy/LrGLkyA2eW
 4S5jj63+juYCBCK/B/NDKcq+RWol+4WGDCd1krEANM9AFA2l9E5c7Mq
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

A VF without XDP support gets qede_netdev_vf_ops, which has neither
.ndo_bpf nor .ndo_xdp_xmit, but qede_init_ndev() still sets

	ndev->xdp_features = NETDEV_XDP_ACT_BASIC | NETDEV_XDP_ACT_REDIRECT |
			     NETDEV_XDP_ACT_NDO_XMIT;

for every device. The devmap code only allocates dev->xdp_bulkq when
the device has .ndo_xdp_xmit, but the XDP redirect paths use
NETDEV_XDP_ACT_NDO_XMIT to decide whether they can call bq_enqueue(),
which dereferences dev->xdp_bulkq. So an XDP program running on another
device can redirect a frame to such a VF, through a devmap or
bpf_redirect(), and bq_enqueue() then dereferences a NULL xdp_bulkq.

Only set the XDP features when the device uses ops with XDP support,
that is on a PF or on a VF with xdp_supported.

Found with a static analysis tool and checked by hand.

Fixes: 66c0e13ad236 ("drivers: net: turn on XDP features")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on x86_64 (W=1, no new warnings). I don't have qede
hardware.
---
 drivers/net/ethernet/qlogic/qede/qede_main.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/qlogic/qede/qede_main.c b/drivers/net/ethernet/qlogic/qede/qede_main.c
index 7ed17faced54..19d13ef27d10 100644
--- a/drivers/net/ethernet/qlogic/qede/qede_main.c
+++ b/drivers/net/ethernet/qlogic/qede/qede_main.c
@@ -890,8 +890,11 @@ static void qede_init_ndev(struct qede_dev *edev)
 
 	ndev->hw_features = hw_features;
 
-	ndev->xdp_features = NETDEV_XDP_ACT_BASIC | NETDEV_XDP_ACT_REDIRECT |
-			     NETDEV_XDP_ACT_NDO_XMIT;
+	/* qede_netdev_vf_ops has no XDP callbacks */
+	if (!IS_VF(edev) || edev->dev_info.xdp_supported)
+		ndev->xdp_features = NETDEV_XDP_ACT_BASIC |
+				     NETDEV_XDP_ACT_REDIRECT |
+				     NETDEV_XDP_ACT_NDO_XMIT;
 
 	/* MTU range: 46 - 9600 */
 	ndev->min_mtu = ETH_ZLEN - ETH_HLEN;



