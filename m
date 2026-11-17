From: Yongjian Wang <echoowall@gmail.com>
Date: Tue, 17 Nov 2026 16:09:16 +0800
Subject: [PATCH net-next] tcp: document black hole detection for
 tcp_mtu_probing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-tcp-mtu-probing-doc-v1-v1-1-552ae04de4ef@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKsL/GoC/yWM0QrCMAwAf2Xk2YDZnAV/RXxYs2xGsC1tNgZj/
 27Vx+O426FIVilwa3bIsmrRGCrQqQF+DmEW1LEytOf2SkQOjRO+bcGUo9cw4xgZV8KuJ/auv0y
 D81DjlGXS7Te+QxDDIJvB42/K4l/C9v3CcXwAl7FO74QAAAA=
X-Change-ID: 20261117-tcp-mtu-probing-doc-v1-351cb754fa7b
To: corbet@lwn.net, pabeni@redhat.com, edumazet@kernel.org, 
 davem@davemloft.net, kuba@kernel.org
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, kuniyu@google.com, 
 rdunlap@infradead.org, horms@kernel.org, ncardwell@google.com, 
 linux-doc@vger.kernel.org, skhan@linuxfoundation.org, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794902956; l=2370;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=uFO+5f2+BsqKYlZQnC2908gTApJQjYev79CULLrFyVs=;
 b=CTFRsXj4zsCMBDDo033TASmfOhkpWF8sCLe3jBnz3Qrz0p1qrRih9+UYwaftb9K38pxZJd4/f
 c15nntriJSoAe9rckuW1XmJPrcLXwr80ROaq2bwkr9FY2/TxNZncrLI
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ip-sysctl.rst says that tcp_mtu_probing=1 enables MTU probing once an
ICMP black hole is detected, but not when that happens or what TCP
does then.

Describe both, as implemented in tcp_write_timeout() and
tcp_mtu_probing(). Also add the missing defaults of tcp_mtu_probing
and tcp_base_mss.

Signed-off-by: Yongjian Wang <echoowall@gmail.com>
---
This describes the behavior checked by the black hole detection tests
added in commit 8a83f21ad75d ("selftests/net: packetdrill: add TCP black
hole detection tests").
---
 Documentation/networking/ip-sysctl.rst | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/Documentation/networking/ip-sysctl.rst b/Documentation/networking/ip-sysctl.rst
index 0b7bfbd98a92..a11baf04758c 100644
--- a/Documentation/networking/ip-sysctl.rst
+++ b/Documentation/networking/ip-sysctl.rst
@@ -412,6 +412,8 @@ tcp_base_mss - INTEGER
 	Path MTU discovery (MTU probing).  If MTU probing is enabled,
 	this is the initial MSS used by the connection.
 
+	Default: 1024
+
 tcp_mtu_probe_floor - INTEGER
 	If MTU probing is enabled this caps the minimum MSS used for search_low
 	for the connection.
@@ -711,6 +713,20 @@ tcp_mtu_probing - INTEGER
 	- 1 - Disabled by default, enabled when an ICMP black hole detected
 	- 2 - Always enabled, use initial MSS of tcp_base_mss.
 
+	A black hole is detected when the retransmission timer fires after
+	the handshake and retransmissions have stayed unacknowledged for as
+	long as tcp_retries1 retransmissions would take with the minimum
+	RTO, which is 3 seconds with the default tcp_retries1.
+
+	With value 1, the first detection enables MTU probing and the MSS
+	falls back to tcp_base_mss. Each later detection, or any detection
+	with value 2, lowers search_low to half its MSS, keeping it at most
+	tcp_base_mss and at least tcp_mtu_probe_floor and tcp_min_snd_mss.
+	Once MTU probing is enabled, the connection also probes for a larger
+	MSS, as with value 2.
+
+	Default: 0
+
 tcp_probe_interval - UNSIGNED INTEGER
 	Controls how often to start TCP Packetization-Layer Path MTU
 	Discovery reprobe. The default is reprobing every 10 minutes as

---
base-commit: 6ff4c5942a301675eb12e5b49d53a81e604624a1
change-id: 20261117-tcp-mtu-probing-doc-v1-351cb754fa7b

Best regards,
--  
Yongjian Wang <echoowall@gmail.com>

