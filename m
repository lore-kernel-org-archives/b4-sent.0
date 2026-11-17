From: Suyuan Wang <shyckless@gmail.com>
Date: Tue, 17 Nov 2026 13:04:41 +0000
Subject: [PATCH net] vlan: require real device netns admin to change GVRP
 and MVRP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-vlan-gvrp-v1-1-53a6b0775953@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOhQ/GoC/yWMQQqDMBQFryJvbSBfQoteRVyY9Gt/KVESDULw7
 qZ2OcMwGZGDcERXZQROEmXxBaiu4N6jn1nJqzAa3TyI6KnSd/RqTmFVRreTc9YaTQalXwNPcty
 vHp43DH8Zd/tht/0uOM8LXl3gOnIAAAA=
X-Change-ID: 20261117-vlan-gvrp-409fccbb4014
To: netdev@vger.kernel.org
Cc: edumazet@kernel.org, kuba@kernel.org, davem@davemloft.net, 
 linux-kernel@vger.kernel.org, elb12345@hotmail.co.uk, horms@kernel.org, 
 pabeni@redhat.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920680; l=3616;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=aPzvkoJxrs75VGP9OVSKh7asGZOHTzpg2ld/W4/JnyU=;
 b=u+HsRqt9OQMihDiNfBrDajCA2N5gyWBMaRFjPlIP3o7lKFjNddQ6JGAnhDf/v75M/vSHp42S2
 RJNs7b+S9ryDsTgrn/IQMwKZTcgMRQ7XWC6cc/pvPYBtLmhPaLsBolW
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

A VLAN device can be moved to another network namespace while its real
device stays behind. CAP_NET_ADMIN in the VLAN's namespace is then
enough to change its flags, through IFLA_VLAN_FLAGS or the
SET_VLAN_FLAG_CMD ioctl. Two of those flags act on the real device
rather than on the VLAN:

    if (netif_running(dev) && (new_flags ^ old_flags) & VLAN_FLAG_GVRP) {
            if (new_flags & VLAN_FLAG_GVRP)
                    vlan_gvrp_request_join(dev);
            ...

vlan_gvrp_request_join() and vlan_mvrp_request_join() declare the VLAN's
own VID on real_dev's GARP/MRP applicant, so the real device starts
sending registrations for it on the wire, and the switch on the other
end may add the port to that VLAN. On a running VLAN, clearing the flag
withdraws the declaration the same way.

So an administrator of the VLAN's namespace, with no capability in the
real device's namespace, can make the real device emit GVRP/MVRP
registrations on the wire. Check CAP_NET_ADMIN in the real device's
namespace in vlan_dev_change_flags() when GVRP or MVRP changes, which
covers both the rtnetlink and the ioctl path. rtnl_dev_link_net_capable()
allows it right away when both devices are in the same namespace, so
nothing changes for that case. This matches macvlan and the changelink
series that gated the tunnel drivers and, recently, macsec.

rtnl_dev_link_net_capable() was added by commit 8165f7ff57d9 ("net:
ip_gre: require CAP_NET_ADMIN in the device netns for changelink"); a
stable tree without it needs that first.

Found with a static analysis tool and checked by hand.

Fixes: 70c03b49b80b ("vlan: Add GVRP support")
Fixes: 86fbe9bb599f ("net/8021q: Implement Multiple VLAN Registration Protocol (MVRP)")
Cc: stable+noautosel@kernel.org # local DoS by a userns admin; low severity
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested under QEMU with network namespaces (x86_64, GVRP and MVRP
enabled): an unprivileged user+net namespace admin can toggle GVRP and
MVRP on a VLAN whose real device stays in the init netns before this
patch, via both the SET_VLAN_FLAG_CMD ioctl and the rtnetlink
IFLA_VLAN_FLAGS path, and is denied with -EPERM after it, while a
same-netns privileged admin still can. W=1 and sparse show no new
warnings. I haven't run it against a real switch.

The same gap in macsec was fixed in commit ed502e485685 ("macsec:
require CAP_NET_ADMIN in the device netns for changelink"). Its author
described the identical VLAN case there and said a separate VLAN patch
would follow; I could not find one on netdev, so this is sent
independently.

Link: https://lore.kernel.org/netdev/AS8P251MB000190AAD82CD30EFBC57B4DC8B42@AS8P251MB0001.EURP251.PROD.OUTLOOK.COM/
---
 net/8021q/vlan_dev.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/net/8021q/vlan_dev.c b/net/8021q/vlan_dev.c
index bca0a3693636..44067b0ccf35 100644
--- a/net/8021q/vlan_dev.c
+++ b/net/8021q/vlan_dev.c
@@ -269,6 +269,12 @@ int vlan_dev_change_flags(const struct net_device *dev, u32 flags, u32 mask)
 		return -EINVAL;
 
 	new_flags = (old_flags & ~mask) | (flags & mask);
+
+	/* GVRP and MVRP act on the real device, which may be in another netns */
+	if (((new_flags ^ old_flags) & (VLAN_FLAG_GVRP | VLAN_FLAG_MVRP)) &&
+	    !rtnl_dev_link_net_capable(dev, dev_net(vlan->real_dev)))
+		return -EPERM;
+
 	WRITE_ONCE(vlan->flags, new_flags);
 
 	if (netif_running(dev) && (new_flags ^ old_flags) & VLAN_FLAG_GVRP) {



