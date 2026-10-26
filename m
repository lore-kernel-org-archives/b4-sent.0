From: Esko Mobius <echoowall@gmail.com>
Date: Mon, 26 Oct 2026 15:23:08 +0800
Subject: [PATCH net 1/2] Revert "selftests: net: packetdrill: add tests for
 advertised MSS with PMTU exceptions"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-advmss-revert-v1-1-272fa4b7ecb6@gmail.com>
References: <20261026-advmss-revert-v1-0-272fa4b7ecb6@gmail.com>
In-Reply-To: <20261026-advmss-revert-v1-0-272fa4b7ecb6@gmail.com>
To: netdev@vger.kernel.org
Cc: Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Simon Horman <horms@kernel.org>, 
 David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, Shuah Khan <shuah@kernel.org>, 
 Thorsten Leemhuis <regressions@leemhuis.info>, regressions@lists.linux.dev, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Esko Mobius <echoowall@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792999388; l=5480;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=uFnONYx2E6brR0l6+uJjUZUsugs/bXfH+6zBoDLWc54=;
 b=ULddStXmSXwCyHaZ46Fz3sv7//3MUR2oEh/dcoU8rRoKUg6NFa32swzD10M6rBqiBLz6pxB/j
 8ErFryqgmZfDuAGhVRXuNpw3laLQd4RMH3tfo21TFP6t+nVr47rQerU
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit e5c8e301b497 ("selftests: net: packetdrill: add
tests for advertised MSS with PMTU exceptions").

These tests assert the behaviour introduced by commit 2640e6419594
("net: advertise TCP MSS from the configured MTU, not the learned
PMTU"), which is reverted in the next patch because it causes a
regression. Remove them first so the series stays bisectable.

Signed-off-by: Esko Mobius <echoowall@gmail.com>
---
 .../net/packetdrill/tcp_advmss_pmtu_ipv4.pkt       | 67 ----------------------
 .../net/packetdrill/tcp_advmss_pmtu_ipv6.pkt       | 67 ----------------------
 2 files changed, 134 deletions(-)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_advmss_pmtu_ipv4.pkt b/tools/testing/selftests/net/packetdrill/tcp_advmss_pmtu_ipv4.pkt
deleted file mode 100644
index f2ef931b7..000000000
--- a/tools/testing/selftests/net/packetdrill/tcp_advmss_pmtu_ipv4.pkt
+++ /dev/null
@@ -1,67 +0,0 @@
-// SPDX-License-Identifier: GPL-2.0
-//
-// Test that IPv4 advertised MSS in SYN-ACK is derived from the configured
-// interface MTU (1500 -> MSS 1460), not the ICMP-learned Path MTU.
-
---ip_version=ipv4
-
-`./defaults.sh
-ethtool -K tun0 tso off
-`
-
-//
-// Connection 1: Learn PMTU exception (MTU 1200 -> MSS 1160)
-//
-    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
-   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
-   +0 bind(3, ..., ...) = 0
-   +0 listen(3, 1) = 0
-
-   +0 < S 0:0(0) win 65535 <mss 1460,sackOK,nop,nop,nop,wscale 8>
-   +0 > S. 0:0(0) ack 1 <mss 1460,nop,nop,sackOK,nop,wscale 8>
-  +.1 < . 1:1(0) ack 1 win 257
-   +0 accept(3, ..., ...) = 4
-
-// Send a full 1460-byte segment
-   +0 write(4, ..., 1460) = 1460
-   +0 > P. 1:1461(1460) ack 1
-
-// ICMP Fragmentation Needed arrives indicating next-hop MTU 1200
-   +0 < icmp unreachable frag_needed mtu 1200 [1:1461(1460)]
-
-// Local host retransmits using the learned MTU 1200 (MSS = 1200 - 40 = 1160)
-   +0 > . 1:1161(1160) ack 1
-   +0 > P. 1161:1461(300) ack 1
-   +0 < R 1:1(0) ack 1461 win 0
-
-// Close connection 1 and listener
-   +0 close(4) = 0
-   +0 close(3) = 0
-
-//
-// Connection 2: New connection from the same peer
-//
-   +0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
-   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
-   +0 bind(3, ..., ...) = 0
-   +0 listen(3, 1) = 0
-
-   +0 < S 0:0(0) win 65535 <mss 1460,sackOK,nop,nop,nop,wscale 8>
-
-// Verify: SYN-ACK MUST advertise configured MSS 1460, NOT the learned PMTU MSS 1160
-   +0 > S. 0:0(0) ack 1 <mss 1460,nop,nop,sackOK,nop,wscale 8>
-   +0 < . 1:1(0) ack 1 win 257
-   +0 accept(3, ..., ...) = 4
-
-// Verify: Outgoing transmit MSS is still constrained by the learned PMTU 1200
-   +0 write(4, ..., 1460) = 1460
-   +0 > . 1:1161(1160) ack 1
-   +0 > P. 1161:1461(300) ack 1
-   +0 < . 1:1(0) ack 1461 win 257
-
-// Clean up
-   +0 close(4) = 0
-   +0 > F. 1461:1461(0) ack 1
-   +0 < F. 1:1(0) ack 1462 win 257
-   +0 > . 1462:1462(0) ack 2
-   +0 close(3) = 0
diff --git a/tools/testing/selftests/net/packetdrill/tcp_advmss_pmtu_ipv6.pkt b/tools/testing/selftests/net/packetdrill/tcp_advmss_pmtu_ipv6.pkt
deleted file mode 100644
index c7638b11a..000000000
--- a/tools/testing/selftests/net/packetdrill/tcp_advmss_pmtu_ipv6.pkt
+++ /dev/null
@@ -1,67 +0,0 @@
-// SPDX-License-Identifier: GPL-2.0
-//
-// Test that IPv6 advertised MSS in SYN-ACK is derived from the configured
-// interface MTU (1520 -> MSS 1460), not the ICMPv6-learned Path MTU.
-
---ip_version=ipv6
-
-`./defaults.sh
-ethtool -K tun0 tso off
-`
-
-//
-// Connection 1: Learn PMTU exception (MTU 1280 -> MSS 1220)
-//
-    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
-   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
-   +0 bind(3, ..., ...) = 0
-   +0 listen(3, 1) = 0
-
-   +0 < S 0:0(0) win 65535 <mss 1460,sackOK,nop,nop,nop,wscale 8>
-   +0 > S. 0:0(0) ack 1 <mss 1460,nop,nop,sackOK,nop,wscale 8>
-  +.1 < . 1:1(0) ack 1 win 257
-   +0 accept(3, ..., ...) = 4
-
-// Send a full 1460-byte segment
-   +0 write(4, ..., 1460) = 1460
-   +0 > P. 1:1461(1460) ack 1
-
-// ICMPv6 Packet Too Big arrives indicating next-hop MTU 1280
-   +0 < icmp packet_too_big mtu 1280 [1:1461(1460)]
-
-// Local host retransmits using the learned MTU 1280 (MSS = 1280 - 40 - 20 = 1220)
-   +0 > . 1:1221(1220) ack 1
-   +0 > P. 1221:1461(240) ack 1
-   +0 < R 1:1(0) ack 1461 win 0
-
-// Close connection 1 and listener
-   +0 close(4) = 0
-   +0 close(3) = 0
-
-//
-// Connection 2: New connection from the same peer
-//
-   +0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
-   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
-   +0 bind(3, ..., ...) = 0
-   +0 listen(3, 1) = 0
-
-   +0 < S 0:0(0) win 65535 <mss 1460,sackOK,nop,nop,nop,wscale 8>
-
-// Verify: SYN-ACK MUST advertise configured MSS 1460, NOT the learned PMTU MSS 1220
-   +0 > S. 0:0(0) ack 1 <mss 1460,nop,nop,sackOK,nop,wscale 8>
-   +0 < . 1:1(0) ack 1 win 257
-   +0 accept(3, ..., ...) = 4
-
-// Verify: Outgoing transmit MSS is still constrained by the learned PMTU 1280
-   +0 write(4, ..., 1460) = 1460
-   +0 > . 1:1221(1220) ack 1
-   +0 > P. 1221:1461(240) ack 1
-   +0 < . 1:1(0) ack 1461 win 257
-
-// Clean up
-   +0 close(4) = 0
-   +0 > F. 1461:1461(0) ack 1
-   +0 < F. 1:1(0) ack 1462 win 257
-   +0 > . 1462:1462(0) ack 2
-   +0 close(3) = 0

-- 
Git-157)

