From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 19 Mar 2025 03:13:34 +0000
Subject: [PATCH net-next v2 1/7] selftests/net: Print TCP flags in more
 common format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-tcp-ao-selftests-polling-v2-1-da48040153d1@gmail.com>
References: <20250319-tcp-ao-selftests-polling-v2-0-da48040153d1@gmail.com>
In-Reply-To: <20250319-tcp-ao-selftests-polling-v2-0-da48040153d1@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>, Dmitry Safonov <0x7f454c46@gmail.com>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742354050; l=1922;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=iOlW43ng3yBwP5kn3YXXAavX+5ElU/Vcbzg1cmgHkUw=;
 b=/+hRgGy1a3TxFF9aNzAm4ditnNMPN89DK7HhC1C7dEgHmLJJI8E/fCYVraGO8WaqbEoDS6YGb
 6D0neO2WTVvCNtEi/J4kAvyqCW1WAmXgg2Ll7ANTW/EkDUPjy7jDBiQ
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Before:
># 13145[lib/ftrace-tcp.c:427] trace event filter tcp_ao_key_not_found [2001:db8:1::1:-1 => 2001:db8:254::1:7010, L3index 0, flags: !FS!R!P!., keyid: 100, rnext: 100, maclen: -1, sne: -1] = 1

After:
># 13487[lib/ftrace-tcp.c:427] trace event filter tcp_ao_key_not_found [2001:db8:1::1:-1 => 2001:db8:254::1:7010, L3index 0, flags: S, keyid: 100, rnext: 100, maclen: -1, sne: -1] = 1

For the history, I think the initial format was to emphasize the absence
of flags as well as their presence (!R meant no RST flag). But looking
again, it's just unreadable and hard to understand.
Make it the standard/expected one.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/ftrace-tcp.c | 7 ++-----
 1 file changed, 2 insertions(+), 5 deletions(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/ftrace-tcp.c b/tools/testing/selftests/net/tcp_ao/lib/ftrace-tcp.c
index 24380c68fec6b7613c363cdee68d13293e593aeb..27403f875054706718256e0007a4db77f82e60c8 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/ftrace-tcp.c
+++ b/tools/testing/selftests/net/tcp_ao/lib/ftrace-tcp.c
@@ -427,11 +427,8 @@ static void dump_trace_event(struct expected_trace_point *e)
 	test_print("trace event filter %s [%s:%d => %s:%d, L3index %d, flags: %s%s%s%s%s, keyid: %d, rnext: %d, maclen: %d, sne: %d] = %zu",
 		   trace_event_names[e->type],
 		   src, e->src_port, dst, e->dst_port, e->L3index,
-		   (e->fin > 0) ? "F" : (e->fin == 0) ? "!F" : "",
-		   (e->syn > 0) ? "S" : (e->syn == 0) ? "!S" : "",
-		   (e->rst > 0) ? "R" : (e->rst == 0) ? "!R" : "",
-		   (e->psh > 0) ? "P" : (e->psh == 0) ? "!P" : "",
-		   (e->ack > 0) ? "." : (e->ack == 0) ? "!." : "",
+		   e->fin ? "F" : "", e->syn ? "S" : "", e->rst ? "R" : "",
+		   e->psh ? "P" : "", e->ack ? "." : "",
 		   e->keyid, e->rnext, e->maclen, e->sne, e->matched);
 }
 

-- 
2.42.2

