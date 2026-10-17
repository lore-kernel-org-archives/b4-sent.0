From: Quanye Yang <quanyeyang@proton.me>
Date: Fri, 16 Oct 2026 22:33:54 -0700
Subject: [PATCH mptcp-net v2] selftests: mptcp: sockopt: pass total bytes
 to do_getsockopts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-fix-mptcp-issue-638-v2-1-cc32774a8b0c@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OTQ6DIBCFr2Jm3WkAoy1d9R6NCwtjpYlAAEkb4
 92Luu/y5X3vZ4FIwVCEW7VAoGyicbYIcapAjb19ERpdNAgmWs54g4P54OST8mhinAnb+oqkuNY
 1Gy5CNlCSPlDB9tYHHLClBN1hxfn5JpW21g0eTUwufPcHme+Rv2OZI8dGk5Sy1y3j6u6DS86eJ
 4JuXdcf2Wr1CdMAAAA=
X-Change-ID: 20261015-fix-mptcp-issue-638-ec1dd30f7295
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792215265; l=1730;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=bDtX/TG0Nx3wxWN1lrqFhjE3N6kmDiE8hS4Puy/FOAk=;
 b=vjNMCeKagb08Jo0WPKIqdHp2PfwFCDPgFSMAHeYlimtfTLNzfvNPMMQ1L6FjnCW+kqr7aecOh
 ndy+IePxKh2DHr6xAOZCi++ijmNdOYDgPnU+Jv1TO5vxhnnZdRJ//HF
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

connect_one_server() reads the echoed payload in a loop because read()
on a stream socket can return a partial chunk. After the loop, it still
passed the last read() return value to do_getsockopts() instead of the
accumulated byte count.

do_getsockopts() checks MPTCP_INFO first. The client samples
mptcpi_write_seq before write(), and write() has already advanced
msk->write_seq by the full length, so a partial last read() makes
the write_seq assert fail. Pass the total instead.

Fixes: ce9979129a0b ("selftests: mptcp: add mptcp getsockopt test cases")
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/638
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
Changes in v2:
- fix commit message to describe the write_seq assert, not the TCP_INFO timeout
- Link to v1: https://patch.msgid.link/20261015-fix-mptcp-issue-638-v1-1-5de999ad601c@proton.me
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

