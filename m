From: Quanye Yang <quanyeyang@proton.me>
Date: Wed, 28 Oct 2026 02:10:47 -0700
Subject: [PATCH mptcp-next] selftests: mptcp: connect: fix OOB read on
 read() error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-fix-mptcp-issue-636-v1-1-1f1e2ee07a1e@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBBFryKz7kAm1lB6ldJFTUYdoWnIxCKId
 zety8d//22gnIUV7s0Gmb+i8okV6NKAn15xZJRQGayxjoy94SArvlPxCUV1YXStQ+pMcFeiIbQ
 G6jNlrtq/+oBTjrwWeJ6bLv3MvvyysO8He/2o1IMAAAA=
X-Change-ID: 20261028-fix-mptcp-issue-636-150d6411fd30
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793178649; l=2933;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=5AkzoNWl9/i9Wmm1H6HE1sEtdhjRlQBNIjrUVgGp/uM=;
 b=/izKasSmI4b1Ey19uaSP6XVUothrGxwM6rdH+FcDKYdHRwVLuUl/eyfy25t6V+3zCSjInfV9m
 PejxSgd/PeLAIbIq/ijUSxuzB/5t5egbag8IxH4f6oWl/i4YhDDiQch
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

copyfd_io_poll() and sock_connect_mptcp() store the signed read()
return value in unsigned wstate.len. On failure, -1 becomes UINT_MAX,
so the later "len > 0" check is always true and the error path is
dead. do_rnd_write() / sendto() then copy past the 8192-byte stack
buffer.

Keep wstate.len unsigned, but capture read() in a ssize_t and only
store a non-negative length. Retry EINTR in the poll loop; abort the
TFO connect if the input file cannot be read.

Fixes: 048d19d444be ("mptcp: add basic kselftest for mptcp")
Fixes: ca7ae8916043 ("selftests: mptcp: mptfo Initiator/Listener")
Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/636
Signed-off-by: Quanye Yang <quanyeyang@proton.me>
---
 tools/testing/selftests/net/mptcp/mptcp_connect.c | 32 ++++++++++++++++-------
 1 file changed, 22 insertions(+), 10 deletions(-)

diff --git a/tools/testing/selftests/net/mptcp/mptcp_connect.c b/tools/testing/selftests/net/mptcp/mptcp_connect.c
index 178d98d91fea..d124fb96db15 100644
--- a/tools/testing/selftests/net/mptcp/mptcp_connect.c
+++ b/tools/testing/selftests/net/mptcp/mptcp_connect.c
@@ -398,9 +398,17 @@ static int sock_connect_mptcp(const char * const remoteaddr,
 			set_mark(sock, cfg_mark);
 
 		if (cfg_sockopt_types.mptfo) {
-			if (!winfo->total_len)
-				winfo->total_len = winfo->len = read(infd, winfo->buf,
-								     sizeof(winfo->buf));
+			if (!winfo->total_len) {
+				ssize_t ret = read(infd, winfo->buf,
+						   sizeof(winfo->buf));
+
+				if (ret < 0) {
+					perror("read");
+					close(sock);
+					return -1;
+				}
+				winfo->total_len = winfo->len = ret;
+			}
 
 			syn_copied = sendto(sock, winfo->buf, winfo->len, MSG_FASTOPEN,
 					    a->ai_addr, a->ai_addrlen);
@@ -698,8 +706,17 @@ static int copyfd_io_poll(int infd, int peerfd, int outfd,
 
 		if (fds.revents & POLLOUT) {
 			if (winfo->len == 0) {
+				ssize_t ret;
+
 				winfo->off = 0;
-				winfo->len = read(infd, winfo->buf, sizeof(winfo->buf));
+				ret = read(infd, winfo->buf, sizeof(winfo->buf));
+				if (ret < 0) {
+					if (errno == EINTR)
+						continue;
+					perror("read");
+					return 4;
+				}
+				winfo->len = ret;
 			}
 
 			if (winfo->len > 0) {
@@ -726,7 +743,7 @@ static int copyfd_io_poll(int infd, int peerfd, int outfd,
 				winfo->off += bw;
 				winfo->len -= bw;
 				total_wlen += bw;
-			} else if (winfo->len == 0) {
+			} else {
 				/* We have no more data to send. */
 				fds.events &= ~POLLOUT;
 
@@ -735,11 +752,6 @@ static int copyfd_io_poll(int infd, int peerfd, int outfd,
 					break;
 
 				shut_wr(peerfd);
-			} else {
-				if (errno == EINTR)
-					continue;
-				perror("read");
-				return 4;
 			}
 		}
 

---
base-commit: f2f79e9af965c1c49decfe56312fa547095fbbee
change-id: 20261028-fix-mptcp-issue-636-150d6411fd30

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

