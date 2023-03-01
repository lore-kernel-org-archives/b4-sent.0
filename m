From: Rob Bradford <rbradford@rivosinc.com>
Date: Wed, 01 Mar 2023 13:59:52 +0000
Subject: [PATCH v3] virtio-net: Fix probe of virtio-net on kvmtool
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230223-virtio-net-kvmtool-v3-1-e038660624de@rivosinc.com>
X-B4-Tracking: v=1; b=H4sIAFda/2MC/4WOQQrCMBBFr1KydqSZUNO68h7iok0ndlATSUpQS
 u9uWnAjopuBN5//+JOIFJii2BeTCJQ4sncZ1KYQZmjdmYD7zAJLVCWigsRhZA+ORrik2+j9FWp
 tla5k1RGiyMWujQRdaJ0Z3lUoEfK1/PgiWDr3QDlchxxPmQeOow/PdVeSy/fnhCRBgjWoemy6p
 tftIXDykZ3ZGn8TizHhfwtmS02mUZWUtNP2wzLP8wtIA04KMQEAAA==
To: "Michael S. Tsirkin" <mst@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: virtualization@lists.linux-foundation.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rob Bradford <rbradford@rivosinc.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677679192; l=3604;
 i=rbradford@rivosinc.com; s=20230223; h=from:subject:message-id;
 bh=uAe/SKwsHTpefY9V/DL39NAvpPxAdiRm85ilJO0Tds4=;
 b=k3aNNNHOyZhbPNqhoQd4/ZrfM9IEXIi8pClhR7JYzeZ1xW0xniVNY7ktwc8A5oqTs9584QUIF
 jJQ1lPRhD6cDPKufx8BQoSk+9x7invBgdec+Om5UZGc3Nmdvwv95leh
X-Developer-Key: i=rbradford@rivosinc.com; a=ed25519;
 pk=LZhCh/kJ+nOqxgEGWkLfx2jKUM5LlyU0Jlip8qsjuA8=
X-Endpoint-Received: by B4 Relay for rbradford@rivosinc.com/20230223 with auth_id=34
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the following commit virtio-net on kvmtool has printed a warning
during the probe:

commit dbcf24d153884439dad30484a0e3f02350692e4c
Author: Jason Wang <jasowang@redhat.com>
Date:   Tue Aug 17 16:06:59 2021 +0800

    virtio-net: use NETIF_F_GRO_HW instead of NETIF_F_LRO

[    1.865992] net eth0: Fail to set guest offload.
[    1.872491] virtio_net virtio2 eth0: set_features() failed (-22); wanted 0x0000000000134829, left 0x0080000000134829

This is because during the probing the underlying netdev device has
identified that the netdev features on the device has changed and
attempts to update the virtio-net offloads through the virtio-net
control queue. kvmtool however does not have a control queue that supports
offload changing (VIRTIO_NET_F_CTRL_GUEST_OFFLOADS is not advertised)

The netdev features have changed due to validation checks in
netdev_fix_features():

if (!(features & NETIF_F_RXCSUM)) {
	/* NETIF_F_GRO_HW implies doing RXCSUM since every packet
	 * successfully merged by hardware must also have the
	 * checksum verified by hardware.  If the user does not
	 * want to enable RXCSUM, logically, we should disable GRO_HW.
	 */
	if (features & NETIF_F_GRO_HW) {
		netdev_dbg(dev, "Dropping NETIF_F_GRO_HW since no RXCSUM feature.\n");
		features &= ~NETIF_F_GRO_HW;
	}
}

Since kvmtool does not advertise the VIRTIO_NET_F_GUEST_CSUM feature the
NETIF_F_RXCSUM bit is not present and so the NETIF_F_GRO_HW bit is
cleared. This results in the netdev features changing, which triggers
the attempt to reprogram the virtio-net offloads which then fails.

This commit prevents that set of netdev features from changing by
preemptively applying the same validation and only setting
NETIF_F_GRO_HW if NETIF_F_RXCSUM is set because the device supports both
VIRTIO_NET_F_GUEST_CSUM and VIRTIO_NET_F_GUEST_TSO{4,6}

Signed-off-by: Rob Bradford <rbradford@rivosinc.com>
---
Changes in v3:
- Identified root-cause of feature bit changing and updated conditions
  check
- Link to v2: https://lore.kernel.org/r/20230223-virtio-net-kvmtool-v2-1-8ec93511e67f@rivosinc.com

Changes in v2:
- Use parentheses to group logical OR of features 
- Link to v1:
  https://lore.kernel.org/r/20230223-virtio-net-kvmtool-v1-1-fc23d29b9d7a@rivosinc.com
---
 drivers/net/virtio_net.c | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/drivers/net/virtio_net.c b/drivers/net/virtio_net.c
index 61e33e4dd0cd..2e7705142ca5 100644
--- a/drivers/net/virtio_net.c
+++ b/drivers/net/virtio_net.c
@@ -3778,11 +3778,13 @@ static int virtnet_probe(struct virtio_device *vdev)
 			dev->features |= dev->hw_features & NETIF_F_ALL_TSO;
 		/* (!csum && gso) case will be fixed by register_netdev() */
 	}
-	if (virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_CSUM))
+	if (virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_CSUM)) {
 		dev->features |= NETIF_F_RXCSUM;
-	if (virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO4) ||
-	    virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO6))
-		dev->features |= NETIF_F_GRO_HW;
+		/* This dependency is enforced by netdev_fix_features */
+		if (virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO4) ||
+		    virtio_has_feature(vdev, VIRTIO_NET_F_GUEST_TSO6))
+			dev->features |= NETIF_F_GRO_HW;
+	}
 	if (virtio_has_feature(vdev, VIRTIO_NET_F_CTRL_GUEST_OFFLOADS))
 		dev->hw_features |= NETIF_F_GRO_HW;
 

---
base-commit: c39cea6f38eefe356d64d0bc1e1f2267e282cdd3
change-id: 20230223-virtio-net-kvmtool-87f37515be22

Best regards,
-- 
Rob Bradford <rbradford@rivosinc.com>

