From: Rob Bradford <rbradford@rivosinc.com>
Date: Thu, 23 Feb 2023 19:38:25 +0000
Subject: [PATCH v2] virtio-net: Fix probe of virtio-net on kvmtool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230223-virtio-net-kvmtool-v2-1-8ec93511e67f@rivosinc.com>
X-B4-Tracking: v=1; b=H4sIALDA92MC/32OwQrCMAxAf2X0bGRNGXOe/A/Zoe0yF3SttKUoY
 /9uN/AmXgIv4YW3iEiBKYpztYhAmSN7VwAPlbCTdjcCHgoLrFHViAoyh8QeHCW45zl5/4BTO6q
 2kY0hRFFEoyOBCdrZ6atCjVDmyK8fDzbnGagc95BrX3jimHx4711Zbtu/CVmChNGiGrAz3dDqS
 +DsIzt7tH4W/bquH/BJxl/rAAAA
To: "Michael S. Tsirkin" <mst@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: virtualization@lists.linux-foundation.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rob Bradford <rbradford@rivosinc.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677181108; l=1940;
 i=rbradford@rivosinc.com; s=20230223; h=from:subject:message-id;
 bh=VRhqKw5Ze722O7VxR9BzREUmJZpHoDBohCxS8RVhlls=;
 b=cFs6kjrwj/vcHdFLZkpxyr5YrACaF7Ip9rtA8yDfpIuWFLvfTLJDYeBYyR/Doso4g2Cm6+lVV
 KyVlZUK+bqnB6PyV8LOWqUsTFCsHnfateDZfGbOwk/2y8nCmOTg6jqN
X-Developer-Key: i=rbradford@rivosinc.com; a=ed25519;
 pk=LZhCh/kJ+nOqxgEGWkLfx2jKUM5LlyU0Jlip8qsjuA8=
X-Endpoint-Received: by B4 Relay for rbradford@rivosinc.com/20230223 with auth_id=34
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kvmtool does not support the VIRTIO_NET_F_CTRL_GUEST_OFFLOADS feature
but does advertise the VIRTIO_NET_F_GUEST_TSO{4,6} features. Check that
the VIRTIO_NET_F_CTRL_GUEST_OFFLOADS feature is present before setting
the NETIF_F_GRO_HW feature bit as otherwise an attempt will be made to
program the virtio-net device using the ctrl queue which will fail.

This resolves the following error when running on kvmtool:

[    1.865992] net eth0: Fail to set guest offload.
[    1.872491] virtio_net virtio2 eth0: set_features() failed (-22); wanted 0x0000000000134829, left 0x0080000000134829

Signed-off-by: Rob Bradford <rbradford@rivosinc.com>
---
Changes in v2:
- Use parentheses to group logical OR of features 
- Link to v1:
  https://lore.kernel.org/r/20230223-virtio-net-kvmtool-v1-1-fc23d29b9d7a@rivosinc.com
---
 drivers/net/virtio_net.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/drivers/net/virtio_net.c b/drivers/net/virtio_net.c
index 61e33e4dd0cd..f8341d1a4ccd 100644
--- a/drivers/net/virtio_net.c
+++ b/drivers/net/virtio_net.c
@@ -3780,10 +3780,9 @@ static int virtnet_probe(struct virtio_device *vdev)
 	}
 	if (virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_CSUM))
 		dev->features |= NETIF_F_RXCSUM;
-	if (virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO4) ||
-	    virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO6))
-		dev->features |= NETIF_F_GRO_HW;
-	if (virtio_has_feature(vdev, VIRTIO_NET_F_CTRL_GUEST_OFFLOADS))
+	if ((virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO4) ||
+	    virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO6)) &&
+	    virtio_has_feature(vdev, VIRTIO_NET_F_CTRL_GUEST_OFFLOADS))
 		dev->hw_features |= NETIF_F_GRO_HW;
 
 	dev->vlan_features = dev->features;

---
base-commit: c39cea6f38eefe356d64d0bc1e1f2267e282cdd3
change-id: 20230223-virtio-net-kvmtool-87f37515be22

Best regards,
-- 
Rob Bradford <rbradford@rivosinc.com>

