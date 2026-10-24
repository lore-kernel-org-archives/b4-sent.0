From: Demos Ra <demosthenes.ra@gmail.com>
Date: Sun, 25 Oct 2026 00:13:56 +0700
Subject: [PATCH net 2/2] tools: ynl: generate code for rt-nexthop bucket
 notifications
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-ynl-ntf-bucket-v1-2-65aef308d62c@gmail.com>
References: <20261025-ynl-ntf-bucket-v1-0-65aef308d62c@gmail.com>
In-Reply-To: <20261025-ynl-ntf-bucket-v1-0-65aef308d62c@gmail.com>
To: Donald Hunter <donald.hunter@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Simon Horman <horms@kernel.org>, David Ahern <dsahern@kernel.org>, 
 Ido Schimmel <idosch@nvidia.com>, netdev@vger.kernel.org, 
 Sashiko <sashiko-bot@kernel.org>, Demos Ra <demosthenes.ra@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792862112; l=2406;
 i=demosthenes.ra@gmail.com; s=20261019; h=from:subject:message-id;
 bh=f9ZeZy+zDvDO+mRHxxqISmOxmWt4JRL0xxqUpwYYolE=;
 b=l1WcbvkG7HReRqUj4ESOIOZ0uD7zLVaEkRfCWkaD+a+ClbLZwSMqP3eNuiKF+BP4N1IiOPKxa
 U62kgpzh9vjBBeSNQx1vzvjHNxyUQc7t4vF6SXh8Njtgtn3aAV5otOV
X-Developer-Key: i=demosthenes.ra@gmail.com; a=ed25519;
 pk=sDKS9AI9zxhWgOqkhc9EOIo6cky+anqccB3VGtDvzCc=
X-Endpoint-Received: by B4 Relay for demosthenes.ra@gmail.com/20261019 with auth_id=1235
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The kernel sends RTM_NEWNEXTHOPBUCKET to RTNLGRP_NEXTHOP when the
upkeep of a resilient nexthop group migrates a bucket. With
newnexthopbucket-ntf excluded from the code generation, the
notification table of the generated rt-nexthop code ends at
RTM_DELNEXTHOP. On a socket subscribed to the group, ynl_ntf_parse()
rejects the bucket notification without setting an error message, so
ynl_ntf_check() fails, and so does a request in flight when the
notification arrives, as ynl_check_alien() passes it to
ynl_ntf_parse() too.

ynl-gen can now generate the notification, so drop the exclusion.

Reproduced in a network namespace, with traffic through a resilient
group so that a weight change defers the bucket migrations to the
upkeep work:

  ip link add dummy0 type dummy && ip link set dummy0 up
  ip addr add 192.0.2.1/24 dev dummy0
  ip nexthop add id 1 via 192.0.2.2 dev dummy0
  ip nexthop add id 2 via 192.0.2.3 dev dummy0
  ip nexthop add id 10 group 1/2 type resilient buckets 8 idle_timer 1
  ip route add 198.51.100.0/24 nhid 10
  for i in $(seq 64); do echo > /dev/udp/198.51.100.$i/9; done
  ip nexthop replace id 10 group 1,3/2 type resilient

A C program that joins RTNLGRP_NEXTHOP by hand and then calls
ynl_ntf_check() or rt_nexthop_getnexthop() fails with an empty error
message before this patch, and parses the two bucket notifications
after it. The program is available on request. Reproducing it needed
no kernel changes. Tested on 7.0 with the reproducer and the YNL
selftests, which all pass.

Fixes: 457dc9fefe9a ("netlink: specs: Add a spec for nexthops in rtnetlink")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20261019-rt-nexthop-spec-v1-1-9c586edf86ab%40gmail.com
Signed-off-by: Demos Ra <demosthenes.ra@gmail.com>
---
 tools/net/ynl/generated/Makefile | 1 -
 1 file changed, 1 deletion(-)

diff --git a/tools/net/ynl/generated/Makefile b/tools/net/ynl/generated/Makefile
index d76d4ca94629..5a186349b5a8 100644
--- a/tools/net/ynl/generated/Makefile
+++ b/tools/net/ynl/generated/Makefile
@@ -18,7 +18,6 @@ include ../Makefile.deps
 
 YNL_GEN_ARG_ethtool:=--user-header linux/ethtool_netlink.h \
 	--exclude-op stats-get
-YNL_GEN_ARG_rt-nexthop:=--exclude-op newnexthopbucket-ntf
 
 TOOL:=../pyynl/ynl_gen_c.py
 TOOL_RST:=../pyynl/ynl_gen_rst.py

-- 
2.53.0

