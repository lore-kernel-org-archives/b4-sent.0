From: Simon Baatz <gmbnomis@gmail.com>
Date: Tue, 24 Feb 2026 09:20:13 +0100
Subject: [PATCH net v2 2/2] selftests/net: packetdrill: Verify acceptance
 of FIN packets when RWIN is 0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260224-fix_zero_wnd_fin-v2-2-a16677ea7cea@gmail.com>
References: <20260224-fix_zero_wnd_fin-v2-0-a16677ea7cea@gmail.com>
In-Reply-To: <20260224-fix_zero_wnd_fin-v2-0-a16677ea7cea@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771921224; l=1458;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=H8ZjJQB2JKY6JAi2lxsgvvCVKMl7+c9eEHI+rYT/o+E=;
 b=U+Im8KLHDGvfSdGH6ZJ4Pbo/TI6ozyHEDdYtHgVRn3+rZ6VnvnSOwiAc7vyyHHaWdGEccskrB
 odip6I5gtU9C8FskMM09BSTFIdrChX/Pp9M8cWuXODj5aTITgZuuUfj
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a packetdrill test that verifies we accept bare FIN packets when
the advertised receive window is zero.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 .../net/packetdrill/tcp_rcv_zero_wnd_fin.pkt       | 27 ++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/tools/testing/selftests/net/packetdrill/tcp_rcv_zero_wnd_fin.pkt b/tools/testing/selftests/net/packetdrill/tcp_rcv_zero_wnd_fin.pkt
new file mode 100644
index 0000000000000000000000000000000000000000..e245359a1a91d4b6d7ef64496681cea57792cb71
--- /dev/null
+++ b/tools/testing/selftests/net/packetdrill/tcp_rcv_zero_wnd_fin.pkt
@@ -0,0 +1,27 @@
+// SPDX-License-Identifier: GPL-2.0
+
+// Some TCP stacks send FINs even though the window is closed. We break
+// a possible FIN/ACK loop by accepting the FIN.
+
+--mss=1000
+
+`./defaults.sh`
+
+// Establish a connection.
+   +0 socket(..., SOCK_STREAM, IPPROTO_TCP) = 3
+   +0 setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
+   +0 setsockopt(3, SOL_SOCKET, SO_RCVBUF, [20000], 4) = 0
+   +0 bind(3, ..., ...) = 0
+   +0 listen(3, 1) = 0
+
+   +0 < S 0:0(0) win 32792 <mss 1000,nop,wscale 7>
+   +0 > S. 0:0(0) ack 1 <mss 1460,nop,wscale 0>
+   +0 < . 1:1(0) ack 1 win 257
+
+   +0 accept(3, ..., ...) = 4
+
+   +0 < P. 1:60001(60000) ack 1 win 257
+    * > .  1:1(0) ack 60001 win 0
+
+   +0 < F. 60001:60001(0) ack 1 win 257
+   +0 > . 1:1(0) ack 60002 win 0

-- 
2.53.0

