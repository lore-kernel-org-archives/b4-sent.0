From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sun, 05 Jul 2026 22:24:36 -0500
Subject: [PATCH net] net/iucv: take a reference on the socket found in
 afiucv_hs_rcv()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-b4-disp-fc79c0dc-v1-1-d2cdcb57afa9@proton.me>
X-B4-Tracking: v=1; b=H4sIAPMfS2oC/x2MQQqAIBAAvxJ7bmETU+or0aF0q72YaEQQ/j3pO
 AwzL2ROwhnG5oXEt2Q5Q4WubcAdS9gZxVcGRcqQpR5XjV5yxM3ZwZF3SN1gbLVKWwU1i4k3ef7
 lBIEvmEv5ACdZ+3BnAAAA
To: Paolo Abeni <pabeni@redhat.com>, Jakub Kicinski <kuba@kernel.org>, 
 Eric Dumazet <edumazet@google.com>, "David S. Miller" <davem@davemloft.net>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 Alexandra Winter <wintera@linux.ibm.com>
Cc: Nagamani PV <nagamani@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-s390@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783308275; l=2220;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=Cm/xe4O+TSWFJ/AEyzNeIJNe6xtikMnB2Bp/3kQXcy8=;
 b=cSkRDDBTHSAhSaz7Obcwozgj1qGGIduMb5BUznx+g+g91Yx+di+G1GLBvekSxC8S3yqinvfIh
 R3LnALR+STgBQEuDArfqcCgWfpMzF815NlfzcTeMRGxG7cOrqqdfbNN
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

afiucv_hs_rcv() looks up the destination socket under iucv_sk_list.lock,
drops the lock, and then passes the socket to the afiucv_hs_callback_*()
handlers without holding a reference. AF_IUCV sockets are not
RCU-protected and are freed synchronously by iucv_sock_kill() ->
sock_put(), so a concurrent close can free the socket in the window
between read_unlock() and the handler, which then dereferences freed
memory (for example sk->sk_data_ready() in afiucv_hs_callback_syn()).

Take a reference with sock_hold() while the socket is still on the list
and release it with sock_put() once the handler has run.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
afiucv_netdev_event() has the same iucv_sk_list use-after-free and is
being fixed separately by Nagamani PV:
  https://lore.kernel.org/all/20260508170534.2208812-1-nagamani@linux.ibm.com/
This patch covers the receive path, afiucv_hs_rcv(), which that fix does
not touch.

Verified with an LKMM/herd7 litmus (the missing sock_hold() is the only
delta between a flagged data race and none) and with an in-kernel KASAN
model that reproduces the afiucv_hs_rcv() lookup-without-hold path (the
freed socket's sk_data_ready pointer is read after the callback runs);
adding the reference clears it. af_iucv is s390-only, so this is the
model rather than the driver. Reproducer available on request.
---
 net/iucv/af_iucv.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index fed240b453bd..b85fb9767dec 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -2089,6 +2089,8 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 			}
 		}
 	}
+	if (sk)
+		sock_hold(sk);
 	read_unlock(&iucv_sk_list.lock);
 	if (!iucv)
 		sk = NULL;
@@ -2138,6 +2140,8 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 		kfree_skb(skb);
 	}
 
+	if (sk)
+		sock_put(sk);
 	return err;
 }
 

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260705-b4-disp-fc79c0dc-019670262472

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

