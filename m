From: Simon Baatz <gmbnomis@gmail.com>
Date: Mon, 16 Mar 2026 19:51:10 +0100
Subject: [PATCH net-next] selftests/net: packetdrill: improve
 tcp_rcv_neg_window.pkt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260316-improve_tcp_neg_usable_wnd_test-v1-1-f16d5e365107@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3NQQrCMBBG4auUWRtoUivoVUSGmPzWAZ2GJNZC6
 d0NLr/NexsVZEGhS7dRxiJFZm2wh47C0+sEI7GZXO9O/WBHI++U5wVcQ2LFxJ/i7y/wVyNXlGq
 ct4M7x2PwdqRWSRkPWf+HKymqUayVbvv+AxTGEoB7AAAA
X-Change-ID: 20260315-improve_tcp_neg_usable_wnd_test-2a1329d4ca15
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773687085; l=2076;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=ns9OJwOj9IGXzUoNWp91AiRCpz66QceoQnlEDdYlvAg=;
 b=aGLkhiswPMUPyKJ30KormGEXHe9rlLCtTcgK3UyAcW1S57f5CBIuxVzZENkkCoVI0stE9jFtS
 15RLqZ4BcOvBtElun7+2vJzfo+ZGtH9lmc+5i+iqgra7IWtpM6KQ5yN
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The test depends on accepting a packet that is larger than the
advertised window and that does not trigger an immediate ACK.

Previously, the test might still pass even if kernel behavior changed
unexpectedly. Add assertions verifying that the large packet was
accepted and no ACK was sent.

Suggested-by: Eric Dumazet <edumazet@google.com>
Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../selftests/net/packetdrill/tcp_rcv_neg_window.pkt       | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_neg_window.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_neg_window.pkt
index 15a9b4938f16d175ac54f3fd192ed2b59b0a4399..b9ab264b2a118f273af269d83a371740ae47359c 100644
--- a/tools/testing/selftests/net/packetdrill/tcp_rcv_neg_window.pkt
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_neg_window.pkt
@@ -1,4 +1,7 @@
 // SPDX-License-Identifier: GPL-2.0
+// Test maximum advertised window limit when rcv_nxt advances past
+// rcv_mwnd_seq. The "usable window" must be properly clamped to zero
+// rather than becoming negative.
 
 --mss=1000
 
@@ -17,10 +20,15 @@
 
    +0 accept(3, ..., ...) = 4
 
-// A too big packet is accepted if the receive queue is empty
+// A too big packet is accepted if the receive queue is empty. It
+// does not trigger an immediate ACK.
    +0 < P. 1:20001(20000) ack 1 win 257
+   +0 %{ assert tcpi_bytes_received == 20000, tcpi_bytes_received; }%
+
 // Send a RST immediately so that there is no rcv_wup/rcv_mwnd_seq update yet
    +0 < R. 20001:20001(0) ack 1 win 257
 
-  +.1 %{ assert tcpi_state == TCP_CLOSE, tcpi_state }%
-
+// Verify that the RST was accepted. Indirectly this also verifies that no
+// immediate ACK was sent for the data packet above.
+   +0 < . 20001:20001(0) ack 1 win 257
+   +0 > R 1:1(0)

---
base-commit: 5446b8691eb8278f10deca92048fad84ffd1e4d5
change-id: 20260315-improve_tcp_neg_usable_wnd_test-2a1329d4ca15

Best regards,
-- 
Simon Baatz <gmbnomis@gmail.com>

