From: Mark Amirkan <markdamirkan@gmail.com>
Date: Fri, 11 Sep 2026 16:11:21 -0700
Subject: [PATCH net 1/2] ipv6: rpl: fix loop detection for separated local
 addresses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-sympwn-rpl-send-v1-1-1753993bb584@gmail.com>
References: <20260911-sympwn-rpl-send-v1-0-1753993bb584@gmail.com>
In-Reply-To: <20260911-sympwn-rpl-send-v1-0-1753993bb584@gmail.com>
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Alexander Aring <alex.aring@gmail.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Mark Amirkan <markdamirkan@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789168285; l=1258;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=aPw9jW477MDGfTEdsqsF4etE2NWXHDQy5grI9KKty9c=;
 b=YqX2bnYQxH+iSnWmqhIOEi2GFKE5BpfSFR++uw5ePva+ZTbl5B0eukprht9tL0hIT8lF3kUaK
 XzcKL/7ThQQA5eXF4SrBhU8YoF71Y4ts3Oq938fD/L2peeOmj97d+ez
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RFC 6554 requires an RPL router to drop a packet when two or more
addresses assigned to the router are separated in the SRH by an address
not assigned to it.

ipv6_chk_rpl_srh_loop() checks found > 1 before counting the current
local address. For the shortest invalid sequence -- local, non-local,
local -- found is 1 at the second local address and the SRH is accepted.

Check whether a local address was seen before the separation instead.
The receive path calls this helper before forwarding an RPL SRH, and
RFC 6554 requires the check to mitigate bandwidth-exhaustion attacks.

Fixes: f37c60593634 ("addrconf: add functionality to check on rpl requirements")
Cc: stable@vger.kernel.org
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
Assisted-by: Symbolic
---
 net/ipv6/addrconf.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/ipv6/addrconf.c b/net/ipv6/addrconf.c
index 9d89be7e0544..f678fb7fa574 100644
--- a/net/ipv6/addrconf.c
+++ b/net/ipv6/addrconf.c
@@ -4621,7 +4621,7 @@ int ipv6_chk_rpl_srh_loop(struct net *net, const struct in6_addr *segs,
 		}
 
 		if (hash_found) {
-			if (found > 1 && separated) {
+			if (found && separated) {
 				ret = 1;
 				break;
 			}

-- 
2.43.0

