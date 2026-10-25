From: Eli Skeggs <kernel@eliskeggs.com>
Date: Sun, 25 Oct 2026 16:41:57 -0700
Subject: [PATCH bpf 1/2] bpf, sockmap: Stop reporting EPIPE on zero-length
 skb redirect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-sockmap-bare-fin-v1-1-bb8feae7c4a7@eliskeggs.com>
References: <20261025-sockmap-bare-fin-v1-0-bb8feae7c4a7@eliskeggs.com>
In-Reply-To: <20261025-sockmap-bare-fin-v1-0-bb8feae7c4a7@eliskeggs.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Cong Wang <cong.wang@bytedance.com>, 
 Daniel Borkmann <daniel@iogearbox.net>, Alexei Starovoitov <ast@kernel.org>, 
 Andrii Nakryiko <andrii@kernel.org>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, Shuah Khan <shuah@kernel.org>
Cc: Geliang Tang <geliang@kernel.org>, netdev@vger.kernel.org, 
 bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Eli Skeggs <kernel@eliskeggs.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792971941; l=2155;
 i=kernel@eliskeggs.com; s=20261021; h=from:subject:message-id;
 bh=tMsJNHGrPmApxQR/k04sdDxy9WoPcaNMSS8fSsBnQhE=;
 b=aqOQiUQEIH5hPFtqejVgawPtZtjmbWIer2omhEGNDqEVU8Wi6bSfPUeGRerJbm9UpJT86HvRe
 5QQD3b2EqgpCCK7UqRblzXI9yZLAkfs46dNpxxTr6MuytG4PjkHfCJZ
X-Developer-Key: i=kernel@eliskeggs.com; a=ed25519;
 pk=38k+FqQ3STTnr2H4HZ7IEseBOHWRDYVhvyMmQlB51gc=
X-Endpoint-Received: by B4 Relay for kernel@eliskeggs.com/20261021 with auth_id=1252
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A FIN can arrive on a packet with no data. In that case, tcp_read_skb()
produces an empty skb, and the attached BPF stream_verdict program may
choose to redirect the skb to another socket. Further data redirected to
that socket from any socket gets dropped, and the target socket starts
reporting EPIPE. A userspace application may see that EPIPE and decide
the socket is no longer usable. For a BPF-based proxy, this can break a
bidirectional stream, truncating the response instead of leaving the
socket half-open.

Prior to the introduction of tcp_read_skb(), tcp_read_sock() never
passed a zero-length skb to its actor, sk_psock_verdict_recv(). When a
redirected skb landed in sk_psock_backlog(), it was always non-empty.
tcp_read_skb() deviated from the historical behavior by passing any
zero-length skbs to recv_actor(), exposing this latent bug by adding
zero-length skbs to a queue that hadn't previously received them.  When
sk_psock_backlog() encounters a zero-length skb, it interprets ret == 0
as a hard error, reports EPIPE, and clears the transmit flag.

Treat a return of 0 as success when there is no data to send, while
continuing to fail on a 0 return with residual bytes. The loop exits
without incident on an empty skb, and the skb gets cleaned up as usual.
On an ingress redirect, the empty message is still queued as before, but
the target socket no longer reports EPIPE.

Fixes: 965b57b469a5 ("net: Introduce a new proto_ops ->read_skb()")
Signed-off-by: Eli Skeggs <kernel@eliskeggs.com>
---
 net/core/skmsg.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/core/skmsg.c b/net/core/skmsg.c
index df385a5a961e..f9b2e3486cfb 100644
--- a/net/core/skmsg.c
+++ b/net/core/skmsg.c
@@ -716,7 +716,7 @@ static void sk_psock_backlog(struct work_struct *work)
 			if (!sock_flag(psock->sk, SOCK_DEAD))
 				ret = sk_psock_handle_skb(psock, skb, off,
 							  len, ingress);
-			if (ret <= 0) {
+			if (ret < 0 || (!ret && len)) {
 				if (ret == -EAGAIN) {
 					sk_psock_skb_state(psock, state, len, off);
 					/* Restore redir info we cleared before */

-- 
2.56.0

