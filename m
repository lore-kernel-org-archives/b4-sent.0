From: Yongjian Wang <echoowall@gmail.com>
Date: Sun, 08 Nov 2026 22:39:54 +0800
Subject: [PATCH net-next v2 4/4] selftests/net: packetdrill: add TCP MTU
 probing test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-mtu-probing-series-v2-4-355d6490c3db@gmail.com>
References: <20261108-mtu-probing-series-v2-0-355d6490c3db@gmail.com>
In-Reply-To: <20261108-mtu-probing-series-v2-0-355d6490c3db@gmail.com>
To: davem@davemloft.net, pabeni@redhat.com, ncardwell@google.com, 
 horms@kernel.org, kuba@kernel.org, kuniyu@google.com, shuah@kernel.org, 
 edumazet@kernel.org
Cc: linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 panweiping3@gmail.com, netdev@vger.kernel.org, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794148792; l=2709;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=6H7bHmrcx+NwgR2BDbVgQR3Zh+5FGAud6AanMriiUKs=;
 b=IF0QrQGeatzU48wsrF47IdTLRTtNbPESsNSiji6pEnMO9xs+BhemHYRsXBPLlLRKzTLxq/A5h
 QUJQ+geU4HNCmoO2RS4SjHRTLidrr4T5DuThSdH0TGSIDiO94RX0bAD
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Packetization layer path MTU discovery (net.ipv4.tcp_mtu_probing=2) has
no selftest coverage.

Add a test for an active connection. Check that it starts at
tcp_base_mss, that it sends the first probe half way between
tcp_base_mss and the peer's MSS once cwnd allows it, and that an
acknowledged probe raises the MSS and leads to a larger probe.

Disable TCP timestamps since the MTU search range is computed before the
timestamp option is negotiated, which would otherwise make the MSS
depend on the header length at connect time.

Signed-off-by: Yongjian Wang <echoowall@gmail.com>
---
 .../net/packetdrill/tcp_mtu_probing_search.pkt     | 43 ++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_search.pkt b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_search.pkt
new file mode 100644
index 000000000..65e466fbf
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_search.pkt
@@ -0,0 +1,43 @@
+// SPDX-License-Identifier: GPL-2.0
+// Test packetization layer path MTU discovery with tcp_mtu_probing=2: an
+// active connection starts at tcp_base_mss and raises its MSS by binary search
+// as probes are acknowledged.
+
+`./defaults.sh
+sysctl -q net.ipv4.tcp_mtu_probing=2
+sysctl -q net.ipv4.tcp_base_mss=1024
+sysctl -q net.ipv4.tcp_timestamps=0`
+
+    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 fcntl(3, F_SETFL, O_RDWR|O_NONBLOCK) = 0
+   +0 connect(3, ..., ...) = -1 EINPROGRESS (Operation is now in progress)
+   +0 > S 0:0(0) <...>
+  +.1 < S. 0:0(0) ack 1 win 65535 <mss 1460,nop,nop,sackOK>
+   +0 > . 1:1(0) ack 1
+   +0 fcntl(3, F_SETFL, O_RDWR) = 0
+
+// The initial window is sent with tcp_base_mss. No probe yet, cwnd is below 11.
+   +0 write(3, ..., 40000) = 40000
+   +0 > P. 1:2049(2048) ack 1
+   +0 > P. 2049:4097(2048) ack 1
+   +0 > P. 4097:6145(2048) ack 1
+   +0 > P. 6145:8193(2048) ack 1
+   +0 > P. 8193:10241(2048) ack 1
+
+// The first probe is half way between tcp_base_mss and the peer's MSS.
+  +.1 < . 1:1(0) ack 10241 win 65535
+   +0 > . 10241:11483(1242) ack 1
+   +0 > P. 11483:13531(2048) ack 1
+   +0 > P. 13531:15579(2048) ack 1
+   +0 > P. 15579:17627(2048) ack 1
+   +0 > P. 17627:19675(2048) ack 1
+   +0 > P. 19675:21723(2048) ack 1
+   +0 > P. 21723:23771(2048) ack 1
+   +0 > P. 23771:25819(2048) ack 1
+   +0 > P. 25819:27867(2048) ack 1
+   +0 > P. 27867:29915(2048) ack 1
+
+// Acknowledging the probe raises the MSS, and the next probe is larger.
+  +.1 < . 1:1(0) ack 29915 win 65535
+   +0 > . 29915:31266(1351) ack 1
+   +0 > P. 31266:33750(2484) ack 1

-- 
Git-157)

