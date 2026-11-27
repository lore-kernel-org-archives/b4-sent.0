From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 02:10:12 +0000
Subject: [PATCH 5.15.y] ipvlan: inherit needed_headroom and needed_tailroom
 from phy_dev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so4-ipvlan-515-v1-1-b8cbc7c7d37a@certik.com>
X-B4-Tracking: v=1; b=H4sIAIPmCGsC/1WNwQ6CMBBEf4Xs2UVaXUV/xXhoyyo1pCVdJBrCv
 9vqyeO8zLxZQDh5FjhXCySevfgYclCbClxvwp3RdzmDbvRBKX1EiXv04zyYgKQIdyey1DYtMRP
 k0Zj45l9f4QWoVlS/4frj8rQPdlOxlaY1wmiTCa4vSDh0U4wDFr79f4F1/QAd4xrXqQAAAA==
X-Change-ID: 20261127-so4-ipvlan-515-395b58085ee5
To: stable@vger.kernel.org
Cc: Eric Dumazet <edumazet@google.com>, Hangbin Liu <liuhangbin@kylinos.cn>, 
 netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795745411; l=3601;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=GYY8CNKD4Vhjb/fIaxt5s/tjtVosIUaiFaM2oQ7VzIM=;
 b=tKTy0AN2eUJGg5vBTnjHo9d7J41zM8UTuKCppWpapAux50zL7AuTf2NqqYmepuRgw43zLAoub
 xkutM8LIvBlDA7iq0r7J9W8N2ruEfEVnMXgCmpOmTE2v2csNyCxfJrl
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Eric Dumazet <edumazet@google.com>

commit e16e960d55a40d36bd7c2494cc005e757dc9a1ef upstream.

ipvlan devices inherit hard_header_len from phy_dev during ipvlan_init(),
but leave needed_headroom and needed_tailroom set to 0.

When the underlying phy_dev (or stacked lower device) requires extra headroom
or tailroom for headers/trailers (e.g. macsec, ipsec, wireguard, tunnels, or
veth with rx headroom), upper layers calculating packet headroom and tailroom
fail to reserve sufficient space.

This can result in reallocation overhead, skb headroom underflows, or KASAN
slab-use-after-free crashes when dev_hard_header() / ipvlan_hard_header()
prepends header data or when lower devices append tailroom.

Fix this by:
1. Inheriting needed_headroom and needed_tailroom from phy_dev in ipvlan_init().
2. Propagating needed_headroom and needed_tailroom updates to attached ipvlans
   in ipvlan_device_event() when receiving NETDEV_FEAT_CHANGE events.

Fixes: 2ad7bf363841 ("ipvlan: Initial check-in of the IPVLAN driver.")
Reported-by: syzbot+1f9fd0f4b601cf88d6e6@syzkaller.appspotmail.com
Closes: https://lore.kernel.org/netdev/6a720a21.40259c87.584f4.04bb.GAE@google.com/T/#u
Reported-by: Tangxin Xie <xietangxin@h-partners.com>
Closes: https://lore.kernel.org/netdev/CANn89i+1EW-sFNK8xoq98gMbPCeLS7e=+rs9gHfLg5Wj+4x0sw@mail.gmail.com/T/#mcc6307f115e500df23ea2980d5669fe95f20b6b4
Signed-off-by: Eric Dumazet <edumazet@google.com>
Reviewed-by: Hangbin Liu <liuhangbin@kylinos.cn>
Link: https://patch.msgid.link/20260806103857.115541-1-edumazet@google.com
Signed-off-by: Jakub Kicinski <kuba@kernel.org>
[ adapted to 5.15.y: keep this branch's direct GSO limit assignments ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.1.y and newer already have this fix. 5.15.y sets gso_max_size and
gso_max_segs directly instead of calling netif_inherit_tso_max(), so
the two new assignments sit next to those lines; the added lines are
the same as upstream.

Tested on v5.15.226:
- x86_64 allmodconfig W=1 build of drivers/net/ipvlan/ipvlan_main.o,
  base vs patched, no new warnings
- booted the patched kernel under QEMU/KVM. I didn't run a test that
  stacks ipvlan on a device needing extra headroom.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/net/ipvlan/ipvlan_main.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/ipvlan/ipvlan_main.c b/drivers/net/ipvlan/ipvlan_main.c
index fe4399af8eea..ca97d1de6a9a 100644
--- a/drivers/net/ipvlan/ipvlan_main.c
+++ b/drivers/net/ipvlan/ipvlan_main.c
@@ -144,6 +144,8 @@ static int ipvlan_init(struct net_device *dev)
 	dev->gso_max_size = phy_dev->gso_max_size;
 	dev->gso_max_segs = phy_dev->gso_max_segs;
 	dev->hard_header_len = phy_dev->hard_header_len;
+	dev->needed_headroom = phy_dev->needed_headroom;
+	dev->needed_tailroom = phy_dev->needed_tailroom;
 
 	netdev_lockdep_set_classes(dev);
 
@@ -768,6 +770,8 @@ static int ipvlan_device_event(struct notifier_block *unused,
 		list_for_each_entry(ipvlan, &port->ipvlans, pnode) {
 			ipvlan->dev->gso_max_size = dev->gso_max_size;
 			ipvlan->dev->gso_max_segs = dev->gso_max_segs;
+			ipvlan->dev->needed_headroom = dev->needed_headroom;
+			ipvlan->dev->needed_tailroom = dev->needed_tailroom;
 			netdev_update_features(ipvlan->dev);
 		}
 		break;

---
base-commit: 4f2df9a01754521fbba3493e8ad91ef65515e68c
change-id: 20261127-so4-ipvlan-515-395b58085ee5

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

