From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 23 Nov 2026 15:30:43 +0100
Subject: [PATCH net 1/2] ipv6: check the scope of the best source address
 candidate in a VRF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-for-upstream-ipv6-vrf-saddr-scope-v1-v1-1-f667ab150ade@free.fr>
References: <20261123-for-upstream-ipv6-vrf-saddr-scope-v1-v1-0-f667ab150ade@free.fr>
In-Reply-To: <20261123-for-upstream-ipv6-vrf-saddr-scope-v1-v1-0-f667ab150ade@free.fr>
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Willem de Bruijn <willemb@google.com>, Simon Horman <horms@kernel.org>, 
 Nicolas Dichtel <nicolas.dichtel@6wind.com>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795444251; l=2864;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=qAK+JiLvzEBuj4PJyiZhxLv+qsyTNP8cUsd3PTIFVWc=;
 b=DoNrMRJhpkn60MdAaMHqnBimsK6qsAE7VwJ7xzOfpQ4Ctqle+qhdlT3jDGtjUw2NbvaSBuZo0
 Z7xr8V0IESzDym2QwpvPhYX0/MHuNXVJgwzsgTcwd9paGMhzyTXMQl7
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a packet is sent through a device of a VRF, ipv6_dev_get_saddr()
first checks the addresses of that device and of the VRF device.
It stops there when the best of them has a scope that fits the
destination.

Since the commit abb9a68d2c64 ("ipv6: take care of scope when
choosing the src addr"), that is what the scopedist of the best
candidate is tested for.

scopedist is only written when the rule scope compares 2 candidates.
With a single candidate, the rules stop at the first one, which only
tells that there was no candidate yet, then scopedist is read without
having been written.

It is 0 with CONFIG_INIT_STACK_ALL_ZERO, which passes the test:
a device that only has an IPv6 link-local address sends to
global destinations with that link-local address,
although another device of the VRF has a global address.

  # ip link add site2 type vrf table 30
  # ip link set site2 up
  # ip link add dummy0 type dummy
  # ip link set dummy0 master site2 up
  # ip addr add fd00:91::1/64 dev dummy0 nodad
  # ip link add dummy1 type dummy
  # ip link set dummy1 master site2 up
  # ip -6 route add fd00:93::/64 vrf site2 dev dummy1
  # ip -6 route get fd00:93::1 vrf site2
  fd00:93::1 dev dummy1 table 30 src fe80::5cb7:13ff:fe96:87ac metric 1024 pref medium

When the scope rule does run, scopedist is negative, whether the scope
fits or not: the test fails, and the other devices of the VRF are
checked too. One of their addresses can then win on a later rule,
the longest matching prefix for instance, over the address of the VRF
device, which the first lookup is meant to prefer.

So let's compare the scope of the best candidate with the scope of the
destination instead.

This issue was found for a development of a UDP tunnel device with
IPv6 addresses in a VRF selecting an IPv6 link-local source
address for a global destination: then it was confirmed with the
fib_tests.sh case of the next commit, whose first two checks fail without
this fix on a CONFIG_INIT_STACK_ALL_ZERO=y kernel.

Fixes: abb9a68d2c64 ("ipv6: take care of scope when choosing the src addr")
Cc: stable@vger.kernel.org
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 net/ipv6/addrconf.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/net/ipv6/addrconf.c b/net/ipv6/addrconf.c
index d9d13e78bf13b..656bf1ea26da8 100644
--- a/net/ipv6/addrconf.c
+++ b/net/ipv6/addrconf.c
@@ -1902,8 +1902,10 @@ int ipv6_dev_get_saddr(struct net *net, const struct net_device *dst_dev,
 							    master, &dst,
 							    scores, hiscore_idx);
 
-			if (scores[hiscore_idx].ifa &&
-			    scores[hiscore_idx].scopedist >= 0)
+			hiscore = &scores[hiscore_idx];
+			if (hiscore->ifa &&
+			    __ipv6_addr_src_scope(hiscore->addr_type) >=
+			    dst.scope)
 				goto out;
 		}
 

-- 
2.43.0

