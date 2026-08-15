From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 15 Aug 2026 11:04:45 -0500
Subject: [PATCH net 1/2] net/iucv: only send the window update on
 HiperSockets sockets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-b4-disp-8a791503-v1-1-fbae9a511144@proton.me>
References: <20260815-b4-disp-8a791503-v1-0-fbae9a511144@proton.me>
In-Reply-To: <20260815-b4-disp-8a791503-v1-0-fbae9a511144@proton.me>
To: Paolo Abeni <pabeni@redhat.com>, Jakub Kicinski <kuba@kernel.org>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>
Cc: netdev@vger.kernel.org, Ursula Braun <ursula.braun@de.ibm.com>, 
 linux-s390@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786809884; l=1687;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=WnxZgTaOhpPitiiiLaLvwFQWVkmqD2AinGJexdA9fUA=;
 b=VfcjCeTe0PnK0zFvAdcxQaHl1YwL3Uz0N1TOdAxv+IXmfOkO+FtPu0L+C+ZT0589Af1aNDq0g
 YdMd98ZoQrhCAdqOZJP+VbbQ+9cP4oVdJP0/bcogNK2uUJp09CwiV0E
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iucv_sock_recvmsg() sends AF_IUCV_FLAG_WIN without testing the transport,
but that flag exists only on HiperSockets. On a classic z/VM socket
iucv->hs_dev is NULL and iucv_send_ctrl() sizes the skb from
LL_RESERVED_SPACE(iucv->hs_dev), so the read goes through NULL;
afiucv_hs_send() then returns -ENODEV and recvmsg() moves the socket to
IUCV_DISCONN. Reaching it takes an application that sets SO_MSGLIMIT to 1
on its own socket, since msg_recv is incremented only on the HiperSockets
path, so this is a correctness fix rather than a security one.

Test the transport. Three of the other four iucv_send_ctrl() callers do;
the fourth, afiucv_netdev_event(), selects on hs_dev instead. Without
relocate_lowcore the NULL read lands in mapped lowcore and the symptom is
the spurious disconnect; with lowcore relocation it faults.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/iucv/af_iucv.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index ea047bab65e7..0bc4a15f4b56 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -1331,7 +1331,8 @@ static int iucv_sock_recvmsg(struct socket *sock, struct msghdr *msg,
 		if (skb_queue_empty(&iucv->backlog_skb_q)) {
 			if (!list_empty(&iucv->message_q.list))
 				iucv_process_message_q(sk);
-			if (atomic_read(&iucv->msg_recv) >=
+			if (iucv->transport == AF_IUCV_TRANS_HIPER &&
+			    atomic_read(&iucv->msg_recv) >=
 							iucv->msglimit / 2) {
 				err = iucv_send_ctrl(sk, AF_IUCV_FLAG_WIN);
 				if (err) {

-- 
2.55.0

