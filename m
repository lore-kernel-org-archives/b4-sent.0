From: Christoph Paasch <cpaasch@openai.com>
Date: Thu, 07 Aug 2025 11:14:37 -0700
Subject: [PATCH mptcp-next] mptcp: record subflows in RPS table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250807-b4-mptcp_perf-v1-1-e89cc14179cc@openai.com>
X-B4-Tracking: v=1; b=H4sIAAztlGgC/x2MWwqAIBAArxL73YLai7pKRFSutR+ZaEQg3T3xc
 2BmIgTyTAGGIoKnhwNfNoEsC9iOxe6ErBODEqoRXSVxrfF09+ZmR96gUL1UWtembVZIjfNk+M2
 /EbKHlt4bpu/7AQZ4m2lrAAAA
X-Change-ID: 20250731-b4-mptcp_perf-02912dd4f65b
To: MPTCP Upstream <mptcp@lists.linux.dev>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754590482; l=2520;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=FJ3ox47iJ4biHGad51VRAfWRAzrLGfltGE4gslXghQ8=;
 b=wv+rXLZfbxXWuVn+Z5RG6Yr5X/2CwyFJGbOm3Q7T21GnBH1dRLaklEBCbSjLsgVY2Swr0uRaE
 eQKOZewkOAcAeyjdgOxJC3xROIGezplcDt2blATh4r/DK1xZwT5GO3q
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
for each subflow at the start of mptcp_sendmsg() and mptcp_recvmsg().

It does not by itself improve throughput, but ensures that IRQ and RX
processing are directed to the right CPU, which is a
prerequisite for effective aRFS.

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 net/mptcp/protocol.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/net/mptcp/protocol.c b/net/mptcp/protocol.c
index 4b510e04724f5c8be08a00a1cc03093bcd031905..86f1fc5be47bd5f6dc8bf40a488de32f253c1beb 100644
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
@@ -1740,6 +1741,17 @@ static u32 mptcp_send_limit(const struct sock *sk)
 	return limit - not_sent;
 }
 
+static void mptcp_rps_record_subflows(const struct mptcp_sock *msk)
+{
+	struct mptcp_subflow_context *subflow;
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
@@ -1753,6 +1765,8 @@ static int mptcp_sendmsg(struct sock *sk, struct msghdr *msg, size_t len)
 
 	lock_sock(sk);
 
+	mptcp_rps_record_subflows(msk);
+
 	if (unlikely(inet_test_bit(DEFER_CONNECT, sk) ||
 		     msg->msg_flags & MSG_FASTOPEN)) {
 		int copied_syn = 0;
@@ -2131,6 +2145,8 @@ static int mptcp_recvmsg(struct sock *sk, struct msghdr *msg, size_t len,
 		goto out_err;
 	}
 
+	mptcp_rps_record_subflows(msk);
+
 	timeo = sock_rcvtimeo(sk, flags & MSG_DONTWAIT);
 
 	len = min_t(size_t, len, INT_MAX);

---
base-commit: f756e5bb29fa59378c111a2401fc64e44cd53442
change-id: 20250731-b4-mptcp_perf-02912dd4f65b

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

