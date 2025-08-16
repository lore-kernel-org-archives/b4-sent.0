From: Christoph Paasch <cpaasch@openai.com>
Subject: [PATCH net-next v2 0/2] net: Speedup some nexthop handling when
 having A LOT of nexthops
Date: Sat, 16 Aug 2025 16:12:47 -0700
Message-Id: <20250816-nexthop_dump-v2-0-491da3462118@openai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG8QoWgC/22NywrDIBREfyXcdS3RvKCr/kcIJeq1uYuoqA0pw
 X+vuO5yODNnLogYCCM8mgsCHhTJ2RLErQG1rfaNjHTJIFoxtJPomcUzbc6/9Gf3zIyqE/0kpNI
 GysQHNHRW3QwWU23DUshGMbnwrT8Hr/y/8uCMs1H2nTFGD3JVT+fRrnRXbocl5/wDZKxDo7MAA
 AA=
X-Change-ID: 20250724-nexthop_dump-f6c32472bcdf
To: David Ahern <dsahern@kernel.org>, 
 Nikolay Aleksandrov <razor@blackwall.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Ido Schimmel <idosch@idosch.org>
Cc: netdev@vger.kernel.org, Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755385987; l=1201;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=6oq/r2Duv8TUJtLlhHnfA58qlBeaNbRXlhksPZnzC4w=;
 b=g8diLrmD17CmCr2q08HjVmvpTapBE/z+gcgdw+hgV8J2E7Qjp2+DGqmWfEYkPjfbBy/k8R1KR
 ScpZCndKkbBC2pnFdEARxR/9uBbYVXZwnxsK9cZbhDX0AOAOU1Fr/7C
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Configuring a very large number of nexthops is fairly possible within a
reasonable time-frame. But, certain netlink commands can become
extremely slow.

This series addresses some of these, namely dumping and removing
nexthops.

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
Changes in v2:
- Added another improvement to the series "net: When removing nexthops,
  don't call synchronize_net if it is not necessary"
- Fixed typos, made comments within 80-character limit and unified
  comment-style. (Ido Schimmel)
- Removed if (nh->id < s_idx) in the for-loop as it is no more needed.
  (Ido Schimmel)
- Link to v1: https://lore.kernel.org/r/20250724-nexthop_dump-v1-1-6b43fffd5bac@openai.com

---
Christoph Paasch (2):
      net: Make nexthop-dumps scale linearly with the number of nexthops
      net: When removing nexthops, don't call synchronize_net if it is not necessary

 net/ipv4/nexthop.c | 42 +++++++++++++++++++++++++++++++++++++++---
 1 file changed, 39 insertions(+), 3 deletions(-)
---
base-commit: bab3ce404553de56242d7b09ad7ea5b70441ea41
change-id: 20250724-nexthop_dump-f6c32472bcdf

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

