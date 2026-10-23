From: Quanye Yang <quanyeyang@proton.me>
Date: Fri, 23 Oct 2026 07:46:28 -0700
Subject: [PATCH mptcp-next v2] selftests: mptcp: sockopt: echo until EOF on
 partial reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-fix-mptcp-issue-639-v2-1-14a3d3746d2d@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OyQ6CMBRFf8W8tc90kKGu/A/DosBDagJt2kIwh
 H+3wN7lzT13WCGQNxTgcVnB02yCsWMS4nqBptfjm9C0SYNgIueMF9iZBQcXG4cmhIkwlwpVLqX
 SslWCa0hJ5ylhR+sLTnikJUJ1emGqP9TEvXanexOi9d/jwsyPzN+1mSNHlmX3lhW6Lrvy6byNd
 rwNBNW2bT+CCqIH1AAAAA==
X-Change-ID: 20261017-fix-mptcp-issue-639-96339a3d921a
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792766790; l=4572;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=YFBOuJzzXnClbJR18ebSuZTHm9Q2G8VNkK/qk0+YwCo=;
 b=2DCnDe3eQBEdXXw5WJ4YIEVv1hcxesRVTcOX7vCIIOAo/4ohN8fI3DYfVMCXmN2E9SKbePm9E
 kW0YvEDBm75Dy/M0mhGoY5c1VYZh6xNA5kan6vtgG+XubZJ4SKCGah2
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

process_one_client() used a single read() and write() before waiting
for hangup. A SOCK_STREAM read() can return a short count when the
payload is segmented, so the server echoed only part of the data and
then blocked on FIN.

The client keeps reading until it has the full length and only then
closes the socket. The two sides wait on each other and the test
hangs until SIGALRM.

The server does not know the payload length, so echo each chunk until
read() returns 0. Retry short writes, and accumulate nread/nwritten for
the existing sockopt checks.

Fixes: ce9979129a0b ("selftests: mptcp: add mptcp getsockopt test cases")
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/639
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
Changes in v2:
- target mptcp-next instead of mptcp-net
- echo until hangup with goto; retry short writes; use nread/nwritten
- Link to v1: https://patch.msgid.link/20261017-fix-mptcp-issue-639-v1-1-0554d07ab8f8@proton.me
---
 tools/testing/selftests/net/mptcp/mptcp_sockopt.c | 60 +++++++++++++----------
 1 file changed, 34 insertions(+), 26 deletions(-)

diff --git a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
index b6e58d936ebe..deb239058e79 100644
--- a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
+++ b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
@@ -638,7 +638,8 @@ static void connect_one_server(int fd, int pipefd)
 
 static void process_one_client(int fd, int pipefd)
 {
-	ssize_t ret, ret2, ret3;
+	size_t nread = 0, nwritten = 0;
+	ssize_t ret, n, w, off;
 	struct so_state s;
 	char buf[4096];
 
@@ -648,46 +649,53 @@ static void process_one_client(int fd, int pipefd)
 	ret = write(pipefd, "xmit", 4);
 	assert(ret == 4);
 
-	ret = read(fd, buf, sizeof(buf));
-	if (ret < 0)
+read_more:
+	n = read(fd, buf, sizeof(buf));
+	if (n < 0)
 		die_perror("read");
+	if (n == 0)
+		goto hangup;
+
+	for (off = 0; off < n; off += w) {
+		w = write(fd, buf + off, n - off);
+		if (w < 0)
+			die_perror("write");
+		if (w == 0)
+			xerror("write returned 0");
+	}
+	nread += n;
+	nwritten += n;
+	goto read_more;
 
-	assert(s.mptcpi_rcv_delta <= (uint64_t)ret);
+hangup:
+	assert(s.mptcpi_rcv_delta <= nread);
 
 	if (s.tcpi_rcv_delta)
-		assert(s.tcpi_rcv_delta == (uint64_t)ret);
-
-	ret2 = write(fd, buf, ret);
-	if (ret2 < 0)
-		die_perror("write");
-
-	/* wait for hangup */
-	ret3 = read(fd, buf, 1);
-	if (ret3 != 0)
-		xerror("expected EOF, got %lu", ret3);
+		assert(s.tcpi_rcv_delta <= nread);
 
-	do_getsockopts(&s, fd, ret, ret2);
-	if (s.mptcpi_rcv_delta != (uint64_t)ret + 1)
+	do_getsockopts(&s, fd, nread, nwritten);
+	if (s.mptcpi_rcv_delta != (uint64_t)nread + 1)
 		xerror("mptcpi_rcv_delta %" PRIu64 ", expect %" PRIu64 ", diff %" PRId64,
-		       s.mptcpi_rcv_delta, ret + 1, s.mptcpi_rcv_delta - (ret + 1));
+		       s.mptcpi_rcv_delta, (uint64_t)nread + 1,
+		       s.mptcpi_rcv_delta - ((uint64_t)nread + 1));
 
 	/* be nice when running on top of older kernel */
 	if (s.pkt_stats_avail) {
-		if (s.last_sample.mptcpi_bytes_sent != ret2)
+		if (s.last_sample.mptcpi_bytes_sent != nwritten)
 			xerror("mptcpi_bytes_sent %" PRIu64 ", expect %" PRIu64
 			       ", diff %" PRId64,
-			       s.last_sample.mptcpi_bytes_sent, ret2,
-			       s.last_sample.mptcpi_bytes_sent - ret2);
-		if (s.last_sample.mptcpi_bytes_received != ret)
+			       s.last_sample.mptcpi_bytes_sent, nwritten,
+			       s.last_sample.mptcpi_bytes_sent - nwritten);
+		if (s.last_sample.mptcpi_bytes_received != nread)
 			xerror("mptcpi_bytes_received %" PRIu64 ", expect %" PRIu64
 			       ", diff %" PRId64,
-			       s.last_sample.mptcpi_bytes_received, ret,
-			       s.last_sample.mptcpi_bytes_received - ret);
-		if (s.last_sample.mptcpi_bytes_acked != ret)
+			       s.last_sample.mptcpi_bytes_received, nread,
+			       s.last_sample.mptcpi_bytes_received - nread);
+		if (s.last_sample.mptcpi_bytes_acked != nread)
 			xerror("mptcpi_bytes_acked %" PRIu64 ", expect %" PRIu64
 			       ", diff %" PRId64,
-			       s.last_sample.mptcpi_bytes_acked, ret,
-			       s.last_sample.mptcpi_bytes_acked - ret);
+			       s.last_sample.mptcpi_bytes_acked, nread,
+			       s.last_sample.mptcpi_bytes_acked - nread);
 	}
 
 	close(fd);

---
base-commit: a22035be824449c4921ec406f6383089016a628c
change-id: 20261017-fix-mptcp-issue-639-96339a3d921a

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

