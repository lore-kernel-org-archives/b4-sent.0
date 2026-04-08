From: Simon Baatz <gmbnomis@gmail.com>
Date: Wed, 08 Apr 2026 23:50:03 +0200
Subject: [PATCH net-next 2/7] selftests/net: packetdrill: verify non-scaled
 rcv_wnd initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-2-76a6f212e153@gmail.com>
References: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-0-76a6f212e153@gmail.com>
In-Reply-To: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-0-76a6f212e153@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775685040; l=5710;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=vE5ahbPUORfc7BXPMMFoPZPw044dM5vYwM0HDuTK/k4=;
 b=g2mREI0J5JAwtc0Uy++tUoZhnp4evlRNHBw95JOmA8wSCOH1ed8mNvJ+QdUpTZTumvqA0jX9R
 R4myNc3ACMSDjFW35m0xNAIQ6Ffwdr2qybRQ1//UU+fRysdEBlAzil+
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If we or our peer do not support window scaling in an active or
passive open, we must restrict rcv_wnd to 65535.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../packetdrill/tcp_rcv_wnd_active_no_scaling.pkt  | 27 +++++++++++++++++++
 .../tcp_rcv_wnd_active_peer_no_scaling.pkt         | 26 +++++++++++++++++++
 .../packetdrill/tcp_rcv_wnd_passive_no_scaling.pkt | 30 ++++++++++++++++++++++
 .../tcp_rcv_wnd_passive_peer_no_scaling.pkt        | 29 +++++++++++++++++++++
 4 files changed, 112 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_active_no_scaling.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_active_no_scaling.pkt
new file mode 100644
index 0000000000000..d39f834299fec
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_active_no_scaling.pkt
@@ -0,0 +1,27 @@
+// SPDX-License-Identifier: GPL-2.0
+//
+// If we do not support window scaling in an active open, we must
+// restrict rcv_wnd to 65535.
+
+`./defaults.sh
+sysctl -q net.ipv4.tcp_window_scaling=0`
+
+    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 4
+   +0 setsockopt(4, SOL_SOCKET, SO_RCVBUF, [256000], 4) = 0
+
+   +0...0 connect(4, ..., ...) = 0
+   +0 > S 0:0(0) win 65535 <mss 1460,sackOK,TS val 0 ecr 0>
+   +0 < S. 0:0(0) ack 1 win 65535
+   +0 > . 1:1(0) ack 1
+
+   +0 send(4, ..., 1000, 0) = 1000
+   +0 > P. 1:1001(1000) ack 1
+// Beyond window ACK is dropped, causing an immediate ACK
+   +0 < . 65537:65537(0) ack 1001 win 65535
+   +0 > . 1001:1001(0) ack 1
+
+  +.1 %{ assert tcpi_bytes_acked == 1, tcpi_bytes_acked; }%
+
+// In window ACK is accepted
+   +0 < . 65536:65536(0) ack 1001 win 65535
+  +.1 %{ assert tcpi_bytes_acked == 1001, tcpi_bytes_acked; }%
diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_active_peer_no_scaling.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_active_peer_no_scaling.pkt
new file mode 100644
index 0000000000000..a212945996e85
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_active_peer_no_scaling.pkt
@@ -0,0 +1,26 @@
+// SPDX-License-Identifier: GPL-2.0
+//
+// If the peer does not support window scaling in an active open, we must
+// restrict rcv_wnd to 65535.
+
+`./defaults.sh`
+
+    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 4
+   +0 setsockopt(4, SOL_SOCKET, SO_RCVBUF, [256000], 4) = 0
+
+   +0...0 connect(4, ..., ...) = 0
+   +0 > S 0:0(0) win 65535 <mss 1460,sackOK,TS val 0 ecr 0,nop,wscale 2>
+   +0 < S. 0:0(0) ack 1 win 65535
+   +0 > . 1:1(0) ack 1
+
+   +0 send(4, ..., 1000, 0) = 1000
+   +0 > P. 1:1001(1000) ack 1
+// Beyond window ACK is dropped, causing an immediate ACK
+   +0 < . 65537:65537(0) ack 1001 win 65535
+   +0 > . 1001:1001(0) ack 1
+
+  +.1 %{ assert tcpi_bytes_acked == 1, tcpi_bytes_acked; }%
+
+// In window ACK is accepted
+   +0 < . 65536:65536(0) ack 1001 win 65535
+  +.1 %{ assert tcpi_bytes_acked == 1001, tcpi_bytes_acked; }%
diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_passive_no_scaling.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_passive_no_scaling.pkt
new file mode 100644
index 0000000000000..907d452afc311
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_passive_no_scaling.pkt
@@ -0,0 +1,30 @@
+// SPDX-License-Identifier: GPL-2.0
+//
+// If we do not support window scaling in a passive open, we must
+// restrict rcv_wnd to 65535.
+
+`./defaults.sh
+sysctl -q net.ipv4.tcp_window_scaling=0`
+
+    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 setsockopt(3, SOL_SOCKET, SO_RCVBUF, [256000], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 32792 <mss 1000,nop,wscale 7>
+   +0 > S. 0:0(0) ack 1 win 65535 <mss 1460>
+   +0 < . 1:1(0) ack 1 win 32792
+
+   +0 accept(3, ..., ...) = 4
+   +0 send(4, ..., 1000, 0) = 1000
+   +0 > P. 1:1001(1000) ack 1
+// Beyond window ACK is dropped, causing an immediate ACK
+   +0 < . 65537:65537(0) ack 1001 win 32792
+   +0 > . 1001:1001(0) ack 1
+
+  +.1 %{ assert tcpi_bytes_acked == 0, tcpi_bytes_acked; }%
+
+// In window ACK is accepted
+   +0 < . 65536:65536(0) ack 1001 win 32792
+  +.1 %{ assert tcpi_bytes_acked == 1000, tcpi_bytes_acked; }%
diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_passive_peer_no_scaling.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_passive_peer_no_scaling.pkt
new file mode 100644
index 0000000000000..df88dd9b6f83e
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_passive_peer_no_scaling.pkt
@@ -0,0 +1,29 @@
+// SPDX-License-Identifier: GPL-2.0
+//
+// If the peer does not support window scaling in a passive open, we must
+// restrict rcv_wnd to 65535.
+
+`./defaults.sh`
+
+    0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 setsockopt(3, SOL_SOCKET, SO_RCVBUF, [256000], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 32792 <mss 1000>
+   +0 > S. 0:0(0) ack 1 win 65535 <mss 1460>
+   +0 < . 1:1(0) ack 1 win 32792
+
+   +0 accept(3, ..., ...) = 4
+   +0 send(4, ..., 1000, 0) = 1000
+   +0 > P. 1:1001(1000) ack 1
+// Beyond window ACK is dropped, causing an immediate ACK
+   +0 < . 65537:65537(0) ack 1001 win 32792
+   +0 > . 1001:1001(0) ack 1
+
+  +.1 %{ assert tcpi_bytes_acked == 0, tcpi_bytes_acked; }%
+
+// In window ACK is accepted
+   +0 < . 65536:65536(0) ack 1001 win 32792
+  +.1 %{ assert tcpi_bytes_acked == 1000, tcpi_bytes_acked; }%

-- 
2.53.0

