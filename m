From: Luigi Leonardi <luigi.leonardi@outlook.com>
Date: Wed, 26 Jun 2024 14:08:35 +0200
Subject: [PATCH net-next v3 1/3] vsock: add support for SIOCOUTQ ioctl for
 all vsock socket types.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240626-ioctl_next-v3-1-63be5bf19a40@outlook.com>
References: <20240626-ioctl_next-v3-0-63be5bf19a40@outlook.com>
In-Reply-To: <20240626-ioctl_next-v3-0-63be5bf19a40@outlook.com>
To: Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Stefan Hajnoczi <stefanha@redhat.com>, 
 "Michael S. Tsirkin" <mst@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>, 
 Xuan Zhuo <xuanzhuo@linux.alibaba.com>
Cc: virtualization@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kvm@vger.kernel.org, 
 Luigi Leonardi <luigi.leonardi@outlook.com>, 
 Daan De Meyer <daan.j.demeyer@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719403717; l=3696;
 i=luigi.leonardi@outlook.com; s=20240626; h=from:subject:message-id;
 bh=XBc988xsxIc7ZI663M8AXQFntIOWVVx66o4JkV1CeRo=;
 b=s27ZRWrsGEs4wcLLVlRYz+AUXUZaj9wTRP3v7Pa7DLHqXA29iNZ4ZWw7fFVu6KPGHz0cd2lc8
 x18vpqqFMyvDIt/62Lc5LJolWtc88+UnKO2FOSOEYCKXO8qKCUxUYgd
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=RYXD8JyCxGnx/izNc/6b3g3pgpohJMAI0LJ7ynxXzi8=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240626 with auth_id=177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for ioctl(s) for SOCK_STREAM SOCK_SEQPACKET and SOCK_DGRAM
in AF_VSOCK.
The only ioctl available is SIOCOUTQ/TIOCOUTQ, which returns the number
of unsent bytes in the socket. This information is transport-specific
and is delegated to them using a callback.

Suggested-by: Daan De Meyer <daan.j.demeyer@gmail.com>
Signed-off-by: Luigi Leonardi <luigi.leonardi@outlook.com>
---
 include/net/af_vsock.h   |  3 +++
 net/vmw_vsock/af_vsock.c | 60 +++++++++++++++++++++++++++++++++++++++++++++---
 2 files changed, 60 insertions(+), 3 deletions(-)

diff --git a/include/net/af_vsock.h b/include/net/af_vsock.h
index 535701efc1e5..7b5375ae7827 100644
--- a/include/net/af_vsock.h
+++ b/include/net/af_vsock.h
@@ -169,6 +169,9 @@ struct vsock_transport {
 	void (*notify_buffer_size)(struct vsock_sock *, u64 *);
 	int (*notify_set_rcvlowat)(struct vsock_sock *vsk, int val);
 
+	/* SIOCOUTQ ioctl */
+	size_t (*unsent_bytes)(struct vsock_sock *vsk);
+
 	/* Shutdown. */
 	int (*shutdown)(struct vsock_sock *, int);
 
diff --git a/net/vmw_vsock/af_vsock.c b/net/vmw_vsock/af_vsock.c
index 4b040285aa78..d6140d73d122 100644
--- a/net/vmw_vsock/af_vsock.c
+++ b/net/vmw_vsock/af_vsock.c
@@ -112,6 +112,7 @@
 #include <net/sock.h>
 #include <net/af_vsock.h>
 #include <uapi/linux/vm_sockets.h>
+#include <uapi/asm-generic/ioctls.h>
 
 static int __vsock_bind(struct sock *sk, struct sockaddr_vm *addr);
 static void vsock_sk_destruct(struct sock *sk);
@@ -1292,6 +1293,59 @@ int vsock_dgram_recvmsg(struct socket *sock, struct msghdr *msg,
 }
 EXPORT_SYMBOL_GPL(vsock_dgram_recvmsg);
 
+static int vsock_do_ioctl(struct socket *sock, unsigned int cmd,
+			  int __user *arg)
+{
+	struct sock *sk = sock->sk;
+	struct vsock_sock *vsk;
+	int retval;
+
+	vsk = vsock_sk(sk);
+
+	switch (cmd) {
+	case SIOCOUTQ: {
+		size_t n_bytes;
+
+		if (!vsk->transport || !vsk->transport->unsent_bytes) {
+			retval = -EOPNOTSUPP;
+			break;
+		}
+
+		if (vsk->transport->unsent_bytes) {
+			if (sock_type_connectible(sk->sk_type) && sk->sk_state == TCP_LISTEN) {
+				retval = -EINVAL;
+				break;
+			}
+
+			n_bytes = vsk->transport->unsent_bytes(vsk);
+			if (n_bytes < 0) {
+				retval = n_bytes;
+				break;
+			}
+
+			retval = put_user(n_bytes, arg);
+		}
+		break;
+	}
+	default:
+		retval = -ENOIOCTLCMD;
+	}
+
+	return retval;
+}
+
+static int vsock_ioctl(struct socket *sock, unsigned int cmd,
+		       unsigned long arg)
+{
+	int ret;
+
+	lock_sock(sock->sk);
+	ret = vsock_do_ioctl(sock, cmd, (int __user *)arg);
+	release_sock(sock->sk);
+
+	return ret;
+}
+
 static const struct proto_ops vsock_dgram_ops = {
 	.family = PF_VSOCK,
 	.owner = THIS_MODULE,
@@ -1302,7 +1356,7 @@ static const struct proto_ops vsock_dgram_ops = {
 	.accept = sock_no_accept,
 	.getname = vsock_getname,
 	.poll = vsock_poll,
-	.ioctl = sock_no_ioctl,
+	.ioctl = vsock_ioctl,
 	.listen = sock_no_listen,
 	.shutdown = vsock_shutdown,
 	.sendmsg = vsock_dgram_sendmsg,
@@ -2286,7 +2340,7 @@ static const struct proto_ops vsock_stream_ops = {
 	.accept = vsock_accept,
 	.getname = vsock_getname,
 	.poll = vsock_poll,
-	.ioctl = sock_no_ioctl,
+	.ioctl = vsock_ioctl,
 	.listen = vsock_listen,
 	.shutdown = vsock_shutdown,
 	.setsockopt = vsock_connectible_setsockopt,
@@ -2308,7 +2362,7 @@ static const struct proto_ops vsock_seqpacket_ops = {
 	.accept = vsock_accept,
 	.getname = vsock_getname,
 	.poll = vsock_poll,
-	.ioctl = sock_no_ioctl,
+	.ioctl = vsock_ioctl,
 	.listen = vsock_listen,
 	.shutdown = vsock_shutdown,
 	.setsockopt = vsock_connectible_setsockopt,

-- 
2.45.2

