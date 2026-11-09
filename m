From: Yongjian Wang <echoowall@gmail.com>
Date: Tue, 10 Nov 2026 00:44:37 +0800
Subject: [PATCH net-next v3 3/4] selftests/net: packetdrill: add TCP black
 hole detection test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-mtu-probing-series-v3-3-dedfab25d641@gmail.com>
References: <20261110-mtu-probing-series-v3-0-dedfab25d641@gmail.com>
In-Reply-To: <20261110-mtu-probing-series-v3-0-dedfab25d641@gmail.com>
To: davem@davemloft.net, edumazet@kernel.org, pabeni@redhat.com, 
 shuah@kernel.org, kuniyu@google.com, horms@kernel.org, ncardwell@google.com, 
 kuba@kernel.org
Cc: netdev@vger.kernel.org, panweiping3@gmail.com, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794242675; l=2277;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=DlEcv6f+Cg8yca5bPvzEty87MvxA44OfQo4Nhelyigg=;
 b=b6IakWvTGhE9iFUrmoVJExBBuUp3WgBj6VBPI1QvZZxGs/n1mKHat+wB/r0KC3Cy8+Pg2TGyi
 2C6detkgoESASbiz3ieI2o7B9sN3LuK1dIqZZeEU821Qp8EEUNLwbsf
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Black hole detection (net.ipv4.tcp_mtu_probing=1) has no selftest
coverage.

Add a test where a full-sized segment keeps timing out without any ICMP
feedback. Check that the MSS drops to tcp_base_mss once tcp_retries1 is
exceeded, and that the smaller MSS is also used for new data after the
retransmission is acknowledged.

Set tcp_retries1 to 1 to keep the test short, and disable TLP so that
every retransmission comes from the RTO timer, which is what
tcp_write_timeout() counts.

Signed-off-by: Yongjian Wang <echoowall@gmail.com>
---
 .../net/packetdrill/tcp_mtu_probing_blackhole.pkt  | 37 ++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole.pkt b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole.pkt
new file mode 100644
index 000000000000..f10dbb36dd2d
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole.pkt
@@ -0,0 +1,37 @@
+// SPDX-License-Identifier: GPL-2.0
+// Test black hole detection with tcp_mtu_probing=1: when full-sized segments
+// keep timing out and no ICMP arrives, TCP falls back to tcp_base_mss.
+
+`./defaults.sh
+sysctl -q net.ipv4.tcp_mtu_probing=1
+sysctl -q net.ipv4.tcp_base_mss=1024
+sysctl -q net.ipv4.tcp_retries1=1
+sysctl -q net.ipv4.tcp_early_retrans=0`
+
+    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 65535 <mss 1460,nop,nop,sackOK>
+   +0 > S. 0:0(0) ack 1 <mss 1460,nop,nop,sackOK>
+  +.1 < . 1:1(0) ack 1 win 65535
+   +0 accept(3, ..., ...) = 4
+
+   +0 write(4, ..., 1460) = 1460
+   +0 > P. 1:1461(1460) ack 1
+
+// The first retransmission keeps the full size.
+  +.3 > P. 1:1461(1460) ack 1
+
+// Once tcp_retries1 is exceeded the MSS drops to tcp_base_mss.
+  +.6 > . 1:1025(1024) ack 1
+  +.1 < . 1:1(0) ack 1025 win 65535
+   +0 > P. 1025:1461(436) ack 1
+  +.1 < . 1:1(0) ack 1461 win 65535
+
+// New data keeps using the smaller MSS.
+   +0 write(4, ..., 1460) = 1460
+   +0 > . 1461:2485(1024) ack 1
+   +0 > P. 2485:2921(436) ack 1
+  +.1 < . 1:1(0) ack 2921 win 65535

-- 
Git-157)

