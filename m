From: Cedric Jehasse <cedric.jehasse@luminex.be>
Date: Wed, 10 Jun 2026 10:31:23 +0200
Subject: [PATCH RFC] net: bridge: mcast: don't clear L2 host_joined on port
 group deletion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-mdb_l2_host_joined_fix-v1-1-19746b0b8a5d@luminex.be>
X-B4-Tracking: v=1; b=H4sIANogKWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMwNL3dyUpPgco/iM/OKS+Kz8zLzUlPi0zArdtCSjlFQjQ1MLg2RzJaD
 mgqJUoDDY4GilIDdnpdjaWgDkt+kAbQAAAA==
X-Change-ID: 20260609-mdb_l2_host_joined_fix-fb2de21580c7
To: Nikolay Aleksandrov <razor@blackwall.org>, 
 Ido Schimmel <idosch@nvidia.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: bridge@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Cedric Jehasse <cedric.jehasse@gmail.com>, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781080287; l=4075;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=Nc7ftwi5FCk1zbALrXN+jcXd41GY2T6GIvI9xkrpbyI=;
 b=RibYAWjSHhDpRl4wwKOTGtVn2IwvM9Jw1n97jKA3elr9UsKpNIBvxLOjg/+skCn4QwVhywZJ3
 a/yHESXt1GWDh5keWxvxnazzZKzdVDZHT+KvQ9hrQixTHvJhFJFZwBV
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For a static L2 multicast group that has both a host entry and a port
entry, deleting the port entry also removes the host entry, and the
whole group then disappears from "bridge mdb show".

To reproduce:
  bridge mdb add dev br0 port br0  grp 01:02:03:04:05:06 permanent
  bridge mdb add dev br0 port swp1 grp 01:02:03:04:05:06 permanent
  bridge mdb del dev br0 port swp1 grp 01:02:03:04:05:06 permanent
  bridge mdb show # the "port br0" host entry is gone, too

br_multicast_del_pg() processes every non-(*,G) entry through the S,G
path, which removes the port group from br->sg_port_tbl and then calls
br_multicast_sg_del_exclude_ports(). L2 entries are stored in
sg_port_tbl as well, so they take this path too.

When the last port is removed in br_multicast_sg_del_exclude_ports it
sets "sgmp->host_joined = false", clearing the host membership directly
and bypassing br_multicast_host_leave(). With host_joined now false and
no ports left, br_multicast_del_pg() arms the group timer and
br_multicast_group_expired() tears down the whole mdb entry -- even
though the host membership was explicitly and permanently configured
from user space.

Keep removing L2 port groups from sg_port_tbl, but skip the S,G
EXCLUDE-mode handling for them. The host membership of an L2 group is
managed solely via br_multicast_host_join() / br_multicast_host_leave().

Signed-off-by: Cedric Jehasse <cedric.jehasse@luminex.be>
---
For a static L2 multicast group that has both a host entry and a port
entry, deleting the port entry also removes the host entry, and the
whole group then disappears from "bridge mdb show".

To reproduce:
  bridge mdb add dev br0 port br0  grp 01:02:03:04:05:06 permanent
  bridge mdb add dev br0 port swp1 grp 01:02:03:04:05:06 permanent
  bridge mdb del dev br0 port swp1 grp 01:02:03:04:05:06 permanent
  bridge mdb show # the "port br0" host entry is gone, too

br_multicast_del_pg() processes every non-(*,G) entry through the S,G
path, which removes the port group from br->sg_port_tbl and then calls
br_multicast_sg_del_exclude_ports(). L2 entries are stored in
sg_port_tbl as well, so they take this path too.

When the last port is removed in br_multicast_sg_del_exclude_ports it
sets "sgmp->host_joined = false", clearing the host membership directly
and bypassing br_multicast_host_leave(). With host_joined now false and
no ports left, br_multicast_del_pg() arms the group timer and
br_multicast_group_expired() tears down the whole mdb entry -- even
though the host membership was explicitly and permanently configured
from user space.

Keep removing L2 port groups from sg_port_tbl, but skip the S,G
EXCLUDE-mode handling for them. The host membership of an L2 group is
managed solely via br_multicast_host_join() / br_multicast_host_leave().

This fixes the issue, but i'd like a second opinion on if this is the
correct way to fix it.
---
 net/bridge/br_multicast.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/net/bridge/br_multicast.c b/net/bridge/br_multicast.c
index 881d866d687a..d718a6d1ddb1 100644
--- a/net/bridge/br_multicast.c
+++ b/net/bridge/br_multicast.c
@@ -816,7 +816,13 @@ void br_multicast_del_pg(struct net_bridge_mdb_entry *mp,
 	if (!br_multicast_is_star_g(&mp->addr)) {
 		rhashtable_remove_fast(&br->sg_port_tbl, &pg->rhnode,
 				       br_sg_port_rht_params);
-		br_multicast_sg_del_exclude_ports(mp);
+		/* L2 entries share sg_port_tbl with S,G entries but have no
+		 * *,G/S,G EXCLUDE-mode semantics; their host membership is
+		 * managed explicitly via br_multicast_host_join()/leave() and
+		 * must not be cleared here when the last port group is removed.
+		 */
+		if (!br_group_is_l2(&mp->addr))
+			br_multicast_sg_del_exclude_ports(mp);
 	} else {
 		br_multicast_star_g_handle_mode(pg, MCAST_INCLUDE);
 	}

---
base-commit: 022bdd9c0d036863c4bacd1688b73c6be3001cee
change-id: 20260609-mdb_l2_host_joined_fix-fb2de21580c7

Best regards,
-- 
Cedric Jehasse <cedric.jehasse@luminex.be>

