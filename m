From: Suyuan Wang <shyckless@gmail.com>
Date: Fri, 20 Nov 2026 08:51:13 +0000
Subject: [PATCH net] l2tp: require CAP_NET_ADMIN to join the l2tp multicast
 group
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-l2tp-mcast-perm-v1-1-22dbffa88655@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAKAGsC/yWMwQrCMBAFf6Xs2YUmQsX+SvGQpK+6YmPIpkUo/
 fdGPc7AzEaKLFDqm40yVlF5xwrm1FB4uHgHy1iZbGs7Y2zLL1sSz8Fp4YQ8s790cOE8wrsr1Sp
 lTPL5HQeKKHT7S138E6F8X7TvBxXVuZ54AAAA
X-Change-ID: 20261120-l2tp-mcast-perm-b76eac3deba9
To: davem@davemloft.net, edumazet@kernel.org, kuba@kernel.org, 
 pabeni@redhat.com
Cc: stephen@networkplumber.org, linux-kernel@vger.kernel.org, 
 maoyixie.tju@gmail.com, netdev@vger.kernel.org, horms@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795164672; l=2848;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=QYL5ERiD0rSoT6Kdzd/1Vi1hg5wYDxhdVPE3t1Z9Y9s=;
 b=/Egw0ayNzFvVWWOtDuOcExSGyss8K0jQOh1ad6zGfq1b5fOJ/5JqirMhiR2tEPNh0XdBYhN9R
 Ftjyjx8iaT3AOSZLEaxtcmaHOfN7pSFwGvxzOQznLpgYuBVe0gC/yn3
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

The l2tp generic netlink family sends a notification on its "l2tp"
multicast group whenever a tunnel or session is created, modified or
deleted. The message is built by the same l2tp_nl_tunnel_send() and
l2tp_nl_session_send() helpers as the replies to TUNNEL_GET and
SESSION_GET, so it carries the tunnel and session IDs, the addresses
and ports, the statistics and, for L2TPv3 sessions with cookies
configured, the local and peer cookies.

The tunnel and session commands, including the GET commands, need
CAP_NET_ADMIN in the user namespace owning the network namespace
(GENL_UNS_ADMIN_PERM), but generic netlink lets any user join a
multicast group by default. So an unprivileged user in the same network
namespace can read all of this by joining the group. Configured cookies
help an L2TPv3 endpoint reject blindly injected packets, and leaking
them weakens that.

Commit ed267f783c0c ("l2tp: send netlink notifications in the tunnel's
net namespace") already noted that a listener needs no privilege, but
only stopped the notifications from reaching other network namespaces.
This patch handles listeners in the tunnel's own namespace.

Mark the group with GENL_MCAST_CAP_NET_ADMIN, as was done for gtp in
commit db627e71b6da ("gtp: Require 'CAP_NET_ADMIN' when joining the gtp
multicast group"). genl_bind() then requires CAP_NET_ADMIN in the user
namespace owning the network namespace, the same capability and
namespace as the tunnel and session commands.

Found with a static analysis tool and checked by hand.

Fixes: 33f72e6f0c67 ("l2tp : multicast notification to the registered listeners")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested in QEMU (x86_64): three listeners join the "l2tp" group, then
root creates an L2TPv3 tunnel and a session with a cookie.

Before:
  root: joined, gets TUNNEL_CREATE and SESSION_CREATE (with the cookie)
  root without CAP_NET_ADMIN: same
  nobody: same

After:
  root: joined, gets both notifications
  root without CAP_NET_ADMIN: EPERM
  nobody: EPERM

This covers joining the registered group. Joining a group ID before any
family owns it is a separate genetlink issue, handled by "genetlink:
Reject joining multicast groups no family owns".
---
 net/l2tp/l2tp_netlink.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/net/l2tp/l2tp_netlink.c b/net/l2tp/l2tp_netlink.c
index 89ef04c78787..98290cc956fe 100644
--- a/net/l2tp/l2tp_netlink.c
+++ b/net/l2tp/l2tp_netlink.c
@@ -31,6 +31,7 @@ static struct genl_family l2tp_nl_family;
 static const struct genl_multicast_group l2tp_multicast_group[] = {
 	{
 		.name = L2TP_GENL_MCGROUP,
+		.flags = GENL_MCAST_CAP_NET_ADMIN,
 	},
 };
 



