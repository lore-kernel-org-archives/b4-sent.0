From: Rob Bradford <rbradford@rivosinc.com>
Date: Thu, 23 Feb 2023 17:13:57 +0000
Subject: [PATCH] virtio-net: Fix probe of virtio-net on kvmtool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230223-virtio-net-kvmtool-v1-1-fc23d29b9d7a@rivosinc.com>
X-B4-Tracking: v=1; b=H4sIANSe92MC/22OwQrCMBBEf6Xs2YV0Q6n4K+IhqVu7qIlsQiiU/
 rur4M3LwGN4w2xQWIULnLoNlJsUycmgP3QwLSHdGOVqDOTIOyKPTbRKxsQV7+1Zc37gcZz9OPR
 DZCIwMYbCGDWkafmp6AgtZ1n/DHycl7KV3yPny76/AQAyPqCYAAAA
To: "Michael S. Tsirkin" <mst@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: virtualization@lists.linux-foundation.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rob Bradford <rbradford@rivosinc.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677172452; l=1694;
 i=rbradford@rivosinc.com; s=20230223; h=from:subject:message-id;
 bh=z4BoSYh1zWAdqXeZO03vzqGwuNOqVDWaqEjXIgKixEQ=;
 b=sG/nKDOFR38MMLity9ZDXFHvYN9SbTx8eCMH1h1jh/fv3AC+ZcaV5qNk+SkzIcizdScKvRc4B
 RhVLyHozFqaD3+B2TZTIjArEVoS4xdsMmCsqDmkkHd/1yM2EsnO0tNV
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
 drivers/net/virtio_net.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/drivers/net/virtio_net.c b/drivers/net/virtio_net.c
index 61e33e4dd0cd..59951e51fe76 100644
--- a/drivers/net/virtio_net.c
+++ b/drivers/net/virtio_net.c
@@ -3781,9 +3781,8 @@ static int virtnet_probe(struct virtio_device *vdev)
 	if (virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_CSUM))
 		dev->features |= NETIF_F_RXCSUM;
 	if (virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO4) ||
-	    virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO6))
-		dev->features |= NETIF_F_GRO_HW;
-	if (virtio_has_feature(vdev, VIRTIO_NET_F_CTRL_GUEST_OFFLOADS))
+	    virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO6) &&
+	    virtio_has_feature(vdev, VIRTIO_NET_F_CTRL_GUEST_OFFLOADS))
 		dev->hw_features |= NETIF_F_GRO_HW;
 
 	dev->vlan_features = dev->features;

---
base-commit: c39cea6f38eefe356d64d0bc1e1f2267e282cdd3
change-id: 20230223-virtio-net-kvmtool-87f37515be22

Best regards,
-- 
Rob Bradford <rbradford@rivosinc.com>

