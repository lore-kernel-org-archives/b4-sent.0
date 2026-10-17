From: Quanye Yang <quanyeyang@proton.me>
Date: Sat, 17 Oct 2026 01:53:38 -0700
Subject: [PATCH mptcp-net] selftests: mptcp: sockopt: drop unreachable FIN
 accounting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-fix-mptcp-issue-637-v1-1-cda9bf1c79de@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBBFryKz7kBGrSm9SnFh4lSn0DRkohTEu
 zfV5eO//zZQTsIK92qDxKuofEIBulTg5yFMjDIWhtrUHRmy+JQvvmP2EUV1Yewai8ZRa6kd3PX
 moDxj4qId1QeccuAM/Tnp4l7s878K+/4D6FUn3IIAAAA=
X-Change-ID: 20261017-fix-mptcp-issue-637-0b14714ab58b
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792227218; l=2417;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=ZpuiPIB1QPb3VfM2ymJIY8rzST/1xBmMmukn2oZWteo=;
 b=BeOP1DqZ/SubdQM53wLwhMHTnd1mlQTstUn+9MPvSbF0jX+bNF7zd/uVgzLYP4ZvDB/rl49Nj
 dwcljeOQjNLCLEkztvsAZ+YC69voT55zw1APHdJCscUHDKCwl949tv8
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

connect_one_server() sets eof when read() returns 0, then immediately
checks total != len. The receive loop only observes EOF while total is
still below len, so that check always fires and xerror() terminates the
process. The later if (eof) block that increments total for DATA_FIN is
therefore unreachable.

The client also does not wait for the peer to close: process_one_client()
blocks on hangup first, so a peer DATA_FIN cannot arrive before this
assertion. DATA_FIN sequence advancement is already checked on the server
after EOF. Treat an early EOF as a hard error and drop the dead
adjustment.

Fixes: ce9979129a0b ("selftests: mptcp: add mptcp getsockopt test cases")
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/637
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 tools/testing/selftests/net/mptcp/mptcp_sockopt.c | 13 ++++---------
 1 file changed, 4 insertions(+), 9 deletions(-)

diff --git a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
index b6e58d936ebe..20e0050e7cd7 100644
--- a/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
+++ b/tools/testing/selftests/net/mptcp/mptcp_sockopt.c
@@ -572,7 +572,6 @@ static void connect_one_server(int fd, int pipefd)
 	char buf[4096], buf2[4096];
 	size_t len, i, total;
 	struct so_state s;
-	bool eof = false;
 	ssize_t ret;
 
 	memset(&s, 0, sizeof(s));
@@ -610,16 +609,15 @@ static void connect_one_server(int fd, int pipefd)
 		ret = read(fd, buf2 + total, sizeof(buf2) - total);
 		if (ret < 0)
 			die_perror("read");
-		if (ret == 0) {
-			eof = true;
-			break;
-		}
+		if (ret == 0)
+			xerror("unexpected EOF, total %lu, len %lu\n",
+			       total, len);
 
 		total += ret;
 	} while (total < len);
 
 	if (total != len)
-		xerror("total %lu, len %lu eof %d\n", total, len, eof);
+		xerror("total %lu, len %lu\n", total, len);
 
 	if (memcmp(buf, buf2, len))
 		xerror("data corruption");
@@ -629,9 +627,6 @@ static void connect_one_server(int fd, int pipefd)
 
 	do_getsockopts(&s, fd, ret, ret);
 
-	if (eof)
-		total += 1; /* sequence advances due to FIN */
-
 	assert(s.mptcpi_rcv_delta == (uint64_t)total);
 	close(fd);
 }

---
base-commit: a22035be824449c4921ec406f6383089016a628c
change-id: 20261017-fix-mptcp-issue-637-0b14714ab58b

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

