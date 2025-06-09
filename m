From: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
Date: Mon, 09 Jun 2025 15:26:59 +0200
Subject: [PATCH bpf-next v2 2/5] tcp_bpf: Fix reading with splice(2)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250609-sockmap-splice-v2-2-9c50645cfa32@datadoghq.com>
References: <20250609-sockmap-splice-v2-0-9c50645cfa32@datadoghq.com>
In-Reply-To: <20250609-sockmap-splice-v2-0-9c50645cfa32@datadoghq.com>
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>
Cc: Kuniyuki Iwashima <kuniyu@amazon.com>, netdev@vger.kernel.org, 
 bpf@vger.kernel.org, Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749475632; l=2078;
 i=vincent.whitchurch@datadoghq.com; s=20240606; h=from:subject:message-id;
 bh=InhXGybr0db9Lk1NjNwJ/NeOyi7WHVAFjgQS5ZRfqY4=;
 b=oJ8HXYLPWoZXO7csNkUjoLc+mB71mQ0eZWRdwED+DnqRzstVaPf+M/+5niNZtws0ZGhgtKPr9
 yEyn6RRwrweDf4lAKGb0ryDSwgG90Z61YnRN7s+8T5Lo0xgg03fIKPn
X-Developer-Key: i=vincent.whitchurch@datadoghq.com; a=ed25519;
 pk=GwUiPK96WuxbUAD4UjapyK7TOt+aX0EqABOZ/BOj+/M=
X-Endpoint-Received: by B4 Relay for vincent.whitchurch@datadoghq.com/20240606 with auth_id=170
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a socket is added to a sockmap with a verdict program which returns
SK_PASS, splice(2) is not able to read from the socket.

The verdict code removes skbs from the receive queue, checks them using
the bpf program, and then re-queues them onto a separate queue
(psock->ingress_msg).  The sockmap code modifies the TCP recvmsg hook to
check this second queue also so that works. But the splice_read hooks is
not modified and the default tcp_read_splice() only reads the normal
receive queue so it never sees the skbs which have been re-queued.

Fix it by using copy_splice_read() when replacing the proto for the
sockmap.  This could eventually be replaced with a more efficient custom
version.

Signed-off-by: Vincent Whitchurch <vincent.whitchurch@datadoghq.com>
---
 net/ipv4/tcp_bpf.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/net/ipv4/tcp_bpf.c b/net/ipv4/tcp_bpf.c
index ba581785adb4..197429b6adae 100644
--- a/net/ipv4/tcp_bpf.c
+++ b/net/ipv4/tcp_bpf.c
@@ -3,6 +3,7 @@
 
 #include <linux/skmsg.h>
 #include <linux/filter.h>
+#include <linux/fs.h>
 #include <linux/bpf.h>
 #include <linux/init.h>
 #include <linux/wait.h>
@@ -381,6 +382,13 @@ static int tcp_bpf_recvmsg(struct sock *sk, struct msghdr *msg, size_t len,
 	return ret;
 }
 
+static ssize_t tcp_bpf_splice_read(struct socket *sock, loff_t *ppos,
+				   struct pipe_inode_info *pipe, size_t len,
+				   unsigned int flags)
+{
+	return copy_splice_read(sock->file, ppos, pipe, len, flags);
+}
+
 static int tcp_bpf_send_verdict(struct sock *sk, struct sk_psock *psock,
 				struct sk_msg *msg, int *copied, int flags)
 {
@@ -605,6 +613,7 @@ static void tcp_bpf_rebuild_protos(struct proto prot[TCP_BPF_NUM_CFGS],
 	prot[TCP_BPF_BASE].destroy		= sock_map_destroy;
 	prot[TCP_BPF_BASE].close		= sock_map_close;
 	prot[TCP_BPF_BASE].recvmsg		= tcp_bpf_recvmsg;
+	prot[TCP_BPF_BASE].splice_read		= tcp_bpf_splice_read;
 	prot[TCP_BPF_BASE].sock_is_readable	= sk_msg_is_readable;
 
 	prot[TCP_BPF_TX]			= prot[TCP_BPF_BASE];

-- 
2.34.1

