From: Quanye Yang <quanyeyang@proton.me>
Date: Thu, 15 Oct 2026 04:20:32 -0700
Subject: [PATCH mptcp-net] selftests: mptcp: sockopt: pass total bytes to
 do_getsockopts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-fix-mptcp-issue-638-v1-1-5de999ad601c@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywrCMBBFf6XM2oEkpfXxK9KFJrc6gjFkUhFK/
 72pXR7uuWcmRRYoXZqZMr6i8okV7KEh/7zFB1hCZXLG9dbYjkf58TsVn1hUJ3DfnhjehtCa8ej
 OHdVnyqjav3qlXY4oNOyTTvcXfNmqtCwr1Je2XIIAAAA=
X-Change-ID: 20261015-fix-mptcp-issue-638-ec1dd30f7295
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792063242; l=1443;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=U42LN1KsOOub+KeywRtAdFlCeTRcN444mHVbdXwEBv0=;
 b=PJj+rySFGPhUTnT2w+LcBKumlAoHM9Lr//AJsj5yZw69ADoN4oa0sRWIk9UBCHkfOskqapHve
 ebEszr34pX1ASP1wlpLYvPfgXhzab1U2U0JqV2fJESIkg8LgcT8VOSU
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

connect_one_server() reads the echoed payload in a loop because
read() on a stream socket can return a partial chunk. After the
loop, it still passed the last read() return value to
do_getsockopts() instead of the accumulated byte count.

do_getsockopt_tcp_info() then compared the subflow TCP counters
against that partial size, polled until timeout, and failed the
test. Use the total instead.

Fixes: ce9979129a0b ("selftests: mptcp: add mptcp getsockopt test cases")
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/638
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 tools/testing/selftests/net/mptcp/mptcp_sockopt.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
index b6e58d936ebe..7b4ccbe10ae1 100644
--- a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
+++ b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
@@ -627,7 +627,7 @@ static void connect_one_server(int fd, int pipefd)
 	if (s.tcpi_rcv_delta)
 		assert(s.tcpi_rcv_delta <= total);
 
-	do_getsockopts(&s, fd, ret, ret);
+	do_getsockopts(&s, fd, total, total);
 
 	if (eof)
 		total += 1; /* sequence advances due to FIN */

---
base-commit: a22035be824449c4921ec406f6383089016a628c
change-id: 20261015-fix-mptcp-issue-638-ec1dd30f7295

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

