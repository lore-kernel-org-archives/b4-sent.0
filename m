From: Christoph Paasch <cpaasch@openai.com>
Date: Mon, 25 Aug 2025 21:30:36 -0700
Subject: [PATCH mptcp-next v2 2/2] mptcp: record subflows in RPS table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-b4-mptcp_perf-v2-2-5d2d68dfa8af@openai.com>
References: <20250825-b4-mptcp_perf-v2-0-5d2d68dfa8af@openai.com>
In-Reply-To: <20250825-b4-mptcp_perf-v2-0-5d2d68dfa8af@openai.com>
To: MPTCP Upstream <mptcp@lists.linux.dev>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756182640; l=2802;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=EJDbbksEFb3idphcuBVUNxNVnpEhd5gHKPEhq+R1c7o=;
 b=9mVN1MqwAAvWHrWjMkN2EyUuY1L99cQ29Kty3mn36f41cWguEOPANLKNW0dykVeD2mkcJN6Ic
 VR10yJgWlUeASXt9vcgc04Cx40QG2OzstGDX6hZMmYWtnGzICaDNw+M
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Accelerated Receive Flow Steering (aRFS) relies on sockets recording
their RX flow hash into the rps_sock_flow_table so that incoming packets
are steered to the CPU where the application runs.

With MPTCP, the application interacts with the parent MPTCP socket while
data is carried over per-subflow TCP sockets. Without recording these
subflows, aRFS cannot steer interrupts and RX processing for the flows
to the desired CPU.

Record all subflows in the RPS table by calling sock_rps_record_flow()
for each subflow at the start of mptcp_sendmsg(), mptcp_recvmsg() and
mptcp_stream_accept(), by using the new helper
mptcp_rps_record_subflows().

It does not by itself improve throughput, but ensures that IRQ and RX
processing are directed to the right CPU, which is a
prerequisite for effective aRFS.

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 net/mptcp/protocol.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index 4b510e04724f5c8be08a00a1cc03093bcd031905..543506b6a011af78208381857ab9c1962cbc6636 100644
--- a/net/mptcp/protocol.c
+++ b/net/mptcp/protocol.c
@@ -12,6 +12,7 @@
 #include <linux/sched/signal.h>
 #include <linux/atomic.h>
 #include <net/aligned_data.h>
+#include <net/rps.h>
 #include <net/sock.h>
 #include <net/inet_common.h>
 #include <net/inet_hashtables.h>
@@ -1740,6 +1741,20 @@ static u32 mptcp_send_limit(const struct sock *sk)
 	return limit - not_sent;
 }
 
+static void mptcp_rps_record_subflows(const struct mptcp_sock *msk)
+{
+	struct mptcp_subflow_context *subflow;
+
+	if (!rfs_is_needed())
+		return;
+
+	mptcp_for_each_subflow(msk, subflow) {
+		struct sock *ssk = mptcp_subflow_tcp_sock(subflow);
+
+		sock_rps_record_flow(ssk);
+	}
+}
+
 static int mptcp_sendmsg(struct sock *sk, struct msghdr *msg, size_t len)
 {
 	struct mptcp_sock *msk = mptcp_sk(sk);
@@ -1753,6 +1768,8 @@ static int mptcp_sendmsg(struct sock *sk, struct msghdr *msg, size_t len)
 
 	lock_sock(sk);
 
+	mptcp_rps_record_subflows(msk);
+
 	if (unlikely(inet_test_bit(DEFER_CONNECT, sk) ||
 		     msg->msg_flags & MSG_FASTOPEN)) {
 		int copied_syn = 0;
@@ -2131,6 +2148,8 @@ static int mptcp_recvmsg(struct sock *sk, struct msghdr *msg, size_t len,
 		goto out_err;
 	}
 
+	mptcp_rps_record_subflows(msk);
+
 	timeo = sock_rcvtimeo(sk, flags & MSG_DONTWAIT);
 
 	len = min_t(size_t, len, INT_MAX);
@@ -3921,6 +3940,8 @@ static int mptcp_stream_accept(struct socket *sock, struct socket *newsock,
 				mptcp_sock_graft(ssk, newsock);
 		}
 
+		mptcp_rps_record_subflows(msk);
+
 		/* Do late cleanup for the first subflow as necessary. Also
 		 * deal with bad peers not doing a complete shutdown.
 		 */

-- 
2.50.1

