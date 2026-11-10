From: Yongjian Wang <echoowall@gmail.com>
Date: Wed, 11 Nov 2026 00:45:57 +0800
Subject: [PATCH net-next v4 3/4] selftests/net: packetdrill: add TCP black
 hole detection tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-mtu-probing-series-v4-3-6f2e484ca8ea@gmail.com>
References: <20261111-mtu-probing-series-v4-0-6f2e484ca8ea@gmail.com>
In-Reply-To: <20261111-mtu-probing-series-v4-0-6f2e484ca8ea@gmail.com>
To: pabeni@redhat.com, kuba@kernel.org, shuah@kernel.org, 
 edumazet@kernel.org, horms@kernel.org, kuniyu@google.com, 
 ncardwell@google.com, davem@davemloft.net
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 netdev@vger.kernel.org, panweiping3@gmail.com, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794329156; l=4124;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=+yXa+nBg9+47003kOzkfKLT4ELxoq9V9aPGcdqcFMpM=;
 b=IQkfUZhuhzXRnrmF05eHjVxDMIzJsZaDAOHq9rsSFqa4TCE0LrqaQmnruR2Al7Or3YM+Irc/7
 Tk6PnTL2fbFATQ8eAVy41bIpcCtAHGUB7lJ+AEx3+jLGFFTKb2MFswl
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Black hole detection (net.ipv4.tcp_mtu_probing=1) has no selftest
coverage.

Add a test that only sets tcp_mtu_probing=1 on top of the default
settings. A full-sized segment keeps timing out without any ICMP
feedback. Check that the MSS drops to tcp_base_mss once tcp_retries1
is exceeded, and that the smaller MSS is also used for new data after
the retransmission is acknowledged.

Add a shorter variant with tcp_retries1=1 and TLP disabled, so that
every retransmission comes from the RTO timer, which is what
tcp_write_timeout() counts.

Signed-off-by: Yongjian Wang <echoowall@gmail.com>
---
 .../net/packetdrill/tcp_mtu_probing_blackhole.pkt  | 38 ++++++++++++++++++++++
 ..._mtu_probing_blackhole_no_tlp_retries1_is_1.pkt | 38 ++++++++++++++++++++++
 2 files changed, 76 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole.pkt b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole.pkt
new file mode 100644
index 000000000000..95309cb4d872
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole.pkt
@@ -0,0 +1,38 @@
+// SPDX-License-Identifier: GPL-2.0
+// Test black hole detection with default settings and tcp_mtu_probing=1: when
+// full-sized segments keep timing out and no ICMP arrives, TCP falls back to
+// tcp_base_mss.
+
+`./defaults.sh
+sysctl -q net.ipv4.tcp_mtu_probing=1`
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
+// TLP and the first RTO retransmissions keep the full size.
+  +.3 > P. 1:1461(1460) ack 1
+  +.3 > P. 1:1461(1460) ack 1
+  +.6 > P. 1:1461(1460) ack 1
+ +1.2 > P. 1:1461(1460) ack 1
+
+// Once tcp_retries1 is exceeded the MSS drops to tcp_base_mss.
+ +2.4 > . 1:1025(1024) ack 1
+  +.1 < . 1:1(0) ack 1025 win 65535
+   +0 > P. 1025:1461(436) ack 1
+  +.1 < . 1:1(0) ack 1461 win 65535
+
+// New data keeps using the smaller MSS.
+   +0 write(4, ..., 1460) = 1460
+   +0 > . 1461:2485(1024) ack 1
+   +0 > P. 2485:2921(436) ack 1
+  +.1 < . 1:1(0) ack 2921 win 65535
diff --git a/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole_no_tlp_retries1_is_1.pkt b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole_no_tlp_retries1_is_1.pkt
new file mode 100644
index 000000000000..0421458fba45
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_mtu_probing_blackhole_no_tlp_retries1_is_1.pkt
@@ -0,0 +1,38 @@
+// SPDX-License-Identifier: GPL-2.0
+// Test black hole detection with tcp_mtu_probing=1, tcp_retries1=1 and TLP
+// disabled: when full-sized segments keep timing out and no ICMP arrives, TCP
+// falls back to tcp_base_mss.
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

