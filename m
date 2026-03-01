From: Simon Baatz <gmbnomis@gmail.com>
Date: Sun, 01 Mar 2026 09:41:33 +0100
Subject: [PATCH] selftests/net: packetdrill: restore tcp_rcv_big_endseq.pkt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-tcp_rcv_big_endseq-v1-1-86ab7415ab58@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avIrBNSor+rRIjpaLMx05AgunvS8
 lu890DGRJhhZg8kLJTpCBWiYWB2HTxystUgW9m3Uo78MlElU9RGXmGwGU9uRidwmESnBws1jAk
 d3f90Wd/3AzlIkn9kAAAA
X-Change-ID: 20260228-tcp_rcv_big_endseq-c8f1e7914a7d
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772354501; l=2571;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=y5Qga6QOLux9usDOxXwZ0c1UWnBSsfdcWFsVJAvrhHI=;
 b=o5FudX9jHGh+XH4xjuB9TRyfPib3PPUV14pl2IJlNizXNWR68+AE0ZA5cQNh2KDpZiUPNUAj7
 hISaYNu4DUhDqv4NtAg/77TOI+mb7VHW+0Ra/aVGtPHIWTTmk3GALw2
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 1cc93c48b5d7 ("selftests/net: packetdrill: remove tests for
tcp_rcv_*big") removed the test for the reverted commit 1d2fbaad7cd8
("tcp: stronger sk_rcvbuf checks") but also the one for commit
9ca48d616ed7 ("tcp: do not accept packets beyond window").

Restore the test with the necessary adaptation: expect a delayed ACK
instead of an immediate one, since tcp_can_ingest() does not fail
anymore for the last data packet.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../net/packetdrill/tcp_rcv_big_endseq.pkt         | 44 ++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_big_endseq.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_big_endseq.pkt
new file mode 100644
index 0000000000000000000000000000000000000000..6c0f32c40f19be2a750fc9d69bbf64250cd7b525
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_big_endseq.pkt
@@ -0,0 +1,44 @@
+// SPDX-License-Identifier: GPL-2.0
+
+--mss=1000
+
+`./defaults.sh`
+
+    0 `nstat -n`
+
+// Establish a connection.
+   +0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 setsockopt(3, SOL_SOCKET, SO_RCVBUF, [10000], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 32792 <mss 1000,nop,wscale 7>
+   +0 > S. 0:0(0) ack 1 <mss 1460,nop,wscale 0>
+  +.1 < . 1:1(0) ack 1 win 257
+
+  +0 accept(3, ..., ...) = 4
+
+  +0 < P. 1:4001(4000) ack 1 win 257
+  +0 > .  1:1(0) ack 4001 win 5000
+
+// packet in sequence : SKB_DROP_REASON_TCP_INVALID_END_SEQUENCE / LINUX_MIB_BEYOND_WINDOW
+  +0 < P. 4001:54001(50000) ack 1 win 257
+  +0 > .  1:1(0) ack 4001 win 5000
+
+// ooo packet. : SKB_DROP_REASON_TCP_INVALID_END_SEQUENCE / LINUX_MIB_BEYOND_WINDOW
+  +1 < P. 5001:55001(50000) ack 1 win 257
+  +0 > .  1:1(0) ack 4001 win 5000
+
+// SKB_DROP_REASON_TCP_INVALID_SEQUENCE / LINUX_MIB_BEYOND_WINDOW
+  +0 < P. 70001:80001(10000) ack 1 win 257
+  +0 > .  1:1(0) ack 4001 win 5000
+
+  +0 read(4, ..., 100000) = 4000
+
+// If queue is empty, accept a packet even if its end_seq is above wup + rcv_wnd
+  +0 < P. 4001:54001(50000) ack 1 win 257
+   * > .  1:1(0) ack 54001 win 0
+
+// Check LINUX_MIB_BEYOND_WINDOW has been incremented 3 times.
++0 `nstat | grep TcpExtBeyondWindow | grep -q " 3 "`

---
base-commit: 9439a661c2e80485406ce2c90b107ca17858382d
change-id: 20260228-tcp_rcv_big_endseq-c8f1e7914a7d

Best regards,
-- 
Simon Baatz <gmbnomis@gmail.com>

