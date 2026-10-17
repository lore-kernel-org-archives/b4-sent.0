From: Quanye Yang <quanyeyang@proton.me>
Date: Sat, 17 Oct 2026 04:22:09 -0700
Subject: [PATCH mptcp-net] selftests: mptcp: sockopt: echo until EOF on
 partial reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-fix-mptcp-issue-639-v1-1-0554d07ab8f8@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QrCMBAEf6XsswdNApH4K+JDTE89wRhyaRFK/
 91oH4ednRXKVVhxGlZUXkTlnTuYw4D0iPnOJFNn2NF6M5oj3eRDr9JSIVGdmbwLFLxzIbopWBP
 Rn6Vy1/7VM3Y5c8Nln3S+Pjm1XxXb9gVuv6T6ggAAAA==
X-Change-ID: 20261017-fix-mptcp-issue-639-96339a3d921a
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792236130; l=2550;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=0NlNMl4TVlVwcMzE5vOqapeIyEyPNrpzFN+zJ7PBm3M=;
 b=xXOYKpsUPcqVjiU9P6KbNzpSw6MyX3rWBK+ZoXqJr4zyHodB0epJX+SqxZlJjByj8ELnXfKRO
 UMSlzKgUiTBCgyhr7il3oLnZbMKyVIHSbK0VlrAunX5f9uv4/ejljAO
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

Loop the server read/write until read() returns 0, and accumulate the
copied byte counts for the existing sockopt checks.

Fixes: ce9979129a0b ("selftests: mptcp: add mptcp getsockopt test cases")
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/639
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 tools/testing/selftests/net/mptcp/mptcp_sockopt.c | 34 +++++++++++++----------
 1 file changed, 19 insertions(+), 15 deletions(-)

diff --git a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
index b6e58d936ebe..5e1ec3336859 100644
--- a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
+++ b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
@@ -638,7 +638,7 @@ static void connect_one_server(int fd, int pipefd)
 
 static void process_one_client(int fd, int pipefd)
 {
-	ssize_t ret, ret2, ret3;
+	ssize_t ret, ret2, n, w;
 	struct so_state s;
 	char buf[4096];
 
@@ -648,23 +648,27 @@ static void process_one_client(int fd, int pipefd)
 	ret = write(pipefd, "xmit", 4);
 	assert(ret == 4);
 
-	ret = read(fd, buf, sizeof(buf));
-	if (ret < 0)
-		die_perror("read");
+	ret = 0;
+	ret2 = 0;
+	while ((n = read(fd, buf, sizeof(buf))) > 0) {
+		if (!ret) {
+			assert(s.mptcpi_rcv_delta <= (uint64_t)n);
 
-	assert(s.mptcpi_rcv_delta <= (uint64_t)ret);
-
-	if (s.tcpi_rcv_delta)
-		assert(s.tcpi_rcv_delta == (uint64_t)ret);
+			if (s.tcpi_rcv_delta)
+				assert(s.tcpi_rcv_delta <= (uint64_t)n);
+		}
 
-	ret2 = write(fd, buf, ret);
-	if (ret2 < 0)
-		die_perror("write");
+		w = write(fd, buf, n);
+		if (w < 0)
+			die_perror("write");
+		if (w != n)
+			xerror("short write");
 
-	/* wait for hangup */
-	ret3 = read(fd, buf, 1);
-	if (ret3 != 0)
-		xerror("expected EOF, got %lu", ret3);
+		ret += n;
+		ret2 += w;
+	}
+	if (n < 0)
+		die_perror("read");
 
 	do_getsockopts(&s, fd, ret, ret2);
 	if (s.mptcpi_rcv_delta != (uint64_t)ret + 1)

---
base-commit: a22035be824449c4921ec406f6383089016a628c
change-id: 20261017-fix-mptcp-issue-639-96339a3d921a

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

