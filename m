From: Simon Baatz <gmbnomis@gmail.com>
Date: Thu, 26 Feb 2026 01:49:09 +0100
Subject: [PATCH RFC net-next v2 3/5] selftests/net: packetdrill: add
 tcp_rcv_wnd_shrink_nomem.pkt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-3-aa3f8f9cc639@gmail.com>
References: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-0-aa3f8f9cc639@gmail.com>
In-Reply-To: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-0-aa3f8f9cc639@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 David Ahern <dsahern@kernel.org>, Stefano Brivio <sbrivio@redhat.com>, 
 Jon Maloy <jmaloy@redhat.com>, Jason Xing <kerneljasonxing@gmail.com>, 
 mfreemon@cloudflare.com, Shuah Khan <shuah@kernel.org>, 
 Stefano Brivio <sbrivio@redhat.com>
Cc: Christian Ebner <c.ebner@proxmox.com>, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772066964; l=7103;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=srbpCOkGkyiCgA3m8CsvVIdQ91JloySYJEtphyneQ6k=;
 b=oawNhURjKMYSDqzEVviXqSd5vevOvSPvsdubEDUYf6H1MqPAZK39DOvUg+cCNurHoLDxVqmkc
 0YSwWChN6AiCNlWLp2xM00KJTCwwDnZsjFL6fJTmeaaQPeyZkSKHbFA
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This test verifies
- the sequence number checks using the maximum advertised window
  sequence number and
- the logic for handling received data in tcp_data_queue()

for the cases:

1. The window is reduced to zero because of memory

2. The window grows again but still does not reach the originally
   advertised window

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt   | 141 +++++++++++++++++++++
 1 file changed, 141 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt
new file mode 100644
index 0000000000000000000000000000000000000000..8c30e231d7c82705f522f0e7bcdaffb9fb825974
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt
@@ -0,0 +1,141 @@
+// SPDX-License-Identifier: GPL-2.0
+// When tcp_receive_window() < tcp_max_receive_window(), tcp_sequence() accepts
+// packets that would be dropped under normal conditions (i.e. tcp_receive_window()
+// equal to tcp_max_receive_window()).
+// Test that such packets are handled as expected for RWIN == 0 and for RWIN > 0.
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
+   +0 setsockopt(3, SOL_SOCKET, SO_RCVBUF, [1000000], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 32792 <mss 1000,nop,nop,sackOK,nop,wscale 7>
+   +0 > S. 0:0(0) ack 1 win 65535 <mss 1460,nop,nop,sackOK,nop,wscale 4>
+   +0 < . 1:1(0) ack 1 win 257
+
+   +0 accept(3, ..., ...) = 4
+
+// Put 1040000 bytes into the receive buffer
+   +0 < P. 1:65001(65000) ack 1 win 257
+    * > .  1:1(0) ack 65001
+   +0 < P. 65001:130001(65000) ack 1 win 257
+    * > .  1:1(0) ack 130001
+   +0 < P. 130001:195001(65000) ack 1 win 257
+    * > .  1:1(0) ack 195001
+   +0 < P. 195001:260001(65000) ack 1 win 257
+    * > .  1:1(0) ack 260001
+   +0 < P. 260001:325001(65000) ack 1 win 257
+    * > .  1:1(0) ack 325001
+   +0 < P. 325001:390001(65000) ack 1 win 257
+    * > .  1:1(0) ack 390001
+   +0 < P. 390001:455001(65000) ack 1 win 257
+    * > .  1:1(0) ack 455001
+   +0 < P. 455001:520001(65000) ack 1 win 257
+    * > .  1:1(0) ack 520001
+   +0 < P. 520001:585001(65000) ack 1 win 257
+    * > .  1:1(0) ack 585001
+   +0 < P. 585001:650001(65000) ack 1 win 257
+    * > .  1:1(0) ack 650001
+   +0 < P. 650001:715001(65000) ack 1 win 257
+    * > .  1:1(0) ack 715001
+   +0 < P. 715001:780001(65000) ack 1 win 257
+    * > .  1:1(0) ack 780001
+   +0 < P. 780001:845001(65000) ack 1 win 257
+    * > .  1:1(0) ack 845001
+   +0 < P. 845001:910001(65000) ack 1 win 257
+    * > .  1:1(0) ack 910001
+   +0 < P. 910001:975001(65000) ack 1 win 257
+    * > .  1:1(0) ack 975001
+   +0 < P. 975001:1040001(65000) ack 1 win 257
+    * > .  1:1(0) ack 1040001
+
+// Trigger an extreme memory squeeze by shrinking SO_RCVBUF
+   +0 setsockopt(4, SOL_SOCKET, SO_RCVBUF, [16000], 4) = 0
+
+   +0 < P. 1040001:1105001(65000) ack 1 win 257
+    * > .  1:1(0) ack 1040001 win 0
+// Check LINUX_MIB_TCPRCVQDROP has been incremented
+   +0 `nstat -s | grep TcpExtTCPRcvQDrop| grep -q " 1 "`
+
+// RWIN == 0: rcv_wup = 1040001, rcv_wnd = 0, rcv_mwnd_seq > 1105001 (significantly larger, typically ~1970000)
+
+// Accept pure ack with seq in max adv. window
+   +0 write(4, ..., 1000) = 1000
+   +0 > P. 1:1001(1000) ack 1040001 win 0
+   +0 < .  1105001:1105001(0) ack 1001 win 257
+
+// In order segment, in max adv. window -> drop (SKB_DROP_REASON_TCP_ZEROWINDOW)
+   +0 < P. 1040001:1041001(1000) ack 1001 win 257
+   +0 > .  1001:1001(0) ack 1040001 win 0
+// Ooo partial segment, in max adv. window -> drop (SKB_DROP_REASON_TCP_ZEROWINDOW)
+   +0 < P. 1039001:1041001(2000) ack 1001 win 257
+   +0 > .  1001:1001(0) ack 1040001 win 0 <nop,nop,sack 1039001:1040001>
+// Check LINUX_MIB_TCPZEROWINDOWDROP has been incremented twice
+   +0 `nstat -s | grep TcpExtTCPZeroWindowDrop| grep -q " 2 "`
+
+// Ooo segment, in max adv. window -> drop (SKB_DROP_REASON_TCP_OVERWINDOW)
+   +0 < P. 1105001:1106001(1000) ack 1001 win 257
+   +0 > .  1001:1001(0) ack 1040001 win 0
+// Ooo segment, beyond max adv. window -> drop (SKB_DROP_REASON_TCP_INVALID_SEQUENCE)
+   +0 < P. 2000001:2001001(1000) ack 1001 win 257
+   +0 > .  1001:1001(0) ack 1040001 win 0
+// Check LINUX_MIB_BEYOND_WINDOW has been incremented twice
+   +0 `nstat -s | grep TcpExtBeyondWindow | grep -q " 2 "`
+
+// Read all data
+   +0 read(4, ..., 2000000) = 1040000
+    * > .  1001:1001(0) ack 1040001
+
+// RWIN > 0: rcv_wup = 1040001, 0 < rcv_wnd < 32000, rcv_mwnd_seq > 1105001 (significantly larger, typically ~1970000)
+
+// Accept pure ack with seq in max adv. window, beyond adv. window
+   +0 write(4, ..., 1000) = 1000
+   +0 > P.  1001:2001(1000) ack 1040001
+   +0 < . 1105001:1105001(0) ack 2001 win 257
+
+// In order segment, in max adv. window, in adv. window -> accept
+// Note: This also ensures that we cannot hit the empty queue exception in tcp_sequence() in the following tests
+   +0 < P. 1040001:1041001(1000) ack 2001 win 257
+    * > .  2001:2001(0) ack 1041001
+
+// Ooo partial segment, in adv. window -> accept
+   +0 < P. 1040001:1042001(2000) ack 2001 win 257
+   +0 > .  2001:2001(0) ack 1042001 <nop,nop,sack 1040001:1041001>
+
+// Ooo segment, in max adv. window, beyond adv. window -> drop (SKB_DROP_REASON_TCP_OVERWINDOW)
+   +0 < P. 1105001:1106001(1000) ack 2001 win 257
+   +0 > .  2001:2001(0) ack 1042001
+// Ooo segment, beyond max adv. window, beyond adv. window -> drop (SKB_DROP_REASON_TCP_INVALID_SEQUENCE)
+   +0 < P. 2000001:2001001(1000) ack 2001 win 257
+   +0 > .  2001:2001(0) ack 1042001
+// Check LINUX_MIB_BEYOND_WINDOW has been incremented twice
+   +0 `nstat -s | grep TcpExtBeyondWindow | grep -q " 4 "`
+
+// Let's probe how much more data we can squeeze in, 2 * 10k should be ok
+   +0 < P. 1042001:1052001(10000) ack 2001 win 257
+    * > .  2001:2001(0) ack 1052001
+   +0 < P. 1052001:1062001(10000) ack 2001 win 257
+    * > .  2001:2001(0) ack 1062001
+
+// Ooo segment, in max adv. window, seq 152002 in adv. window, not enough buffer space -> drop, _no_ ack
+   +0 < P. 1062002:1072002(10000) ack 2001 win 257
+// Check LINUX_MIB_TCPOFODROP has been incremented
+  +.1 `nstat -s | grep TcpExtTCPOFODrop | grep -q " 1 "`
+
+// In order segment, in max adv. window, not enough buffer space -> drop
+   +0 < P. 1062001:1072001(10000) ack 2001 win 257
+   +0 > .  2001:2001(0) ack 1062001 win 0
+// Check LINUX_MIB_TCPRCVQDROP has been incremented again
+   +0 `nstat -s | grep TcpExtTCPRcvQDrop | grep -q " 2 "`
+
+// Verify that our other counters did not change
+   +0 `nstat -s | grep TcpExtTCPZeroWindowDrop | grep -q " 2 "`
+   +0 `nstat -s | grep TcpExtBeyondWindow | grep -q " 4 "`

-- 
2.53.0

