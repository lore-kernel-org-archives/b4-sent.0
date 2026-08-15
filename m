From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 15 Aug 2026 11:07:27 -0500
Subject: [PATCH net 2/2] net/iucv: take a private, writable frame before
 rewriting it in place
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-b4-disp-dc82fde4-v1-2-e83b10b22ce9@proton.me>
References: <20260815-b4-disp-dc82fde4-v1-0-e83b10b22ce9@proton.me>
In-Reply-To: <20260815-b4-disp-dc82fde4-v1-0-e83b10b22ce9@proton.me>
To: Thorsten Winkler <twinkler@linux.ibm.com>, 
 Jakub Kicinski <kuba@kernel.org>, Eric Dumazet <edumazet@google.com>, 
 Paolo Abeni <pabeni@redhat.com>, "David S. Miller" <davem@davemloft.net>, 
 Alexandra Winter <wintera@linux.ibm.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ursula Braun <ursula.braun@de.ibm.com>, Simon Horman <horms@kernel.org>, 
 Hidayath Khan <hidayath@linux.ibm.com>, linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786810045; l=1834;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=tsDMGsCItYL7yGu9iox8Y2HomWMGmH4vOL9gyPjm2GY=;
 b=iPwsieAZOfqGqomsQKlBiFLG94t+SwU+dzIZVVfjU8mETwPrjWD9heRwtLzT+FM1Z7vqmL5RQ
 t3ZDazceEsKBPkWggR439tMlOz3W5VUDXwxD3JFrhGFvrOq2H1l8Vky
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

afiucv_hs_rcv() rewrites the frame in place -- EBCASC() converts four name
fields in the transport header, afiucv_swap_src_dest() swaps them and
pushes an Ethernet header back on -- without taking a private, writable
copy. It sits on the global ptype_base[], so a packet socket (tcpdump is
enough) has packet_rcv() clone every frame first, and net/core/dev.c has
warned since 1998 that such a handler "is not able to sense, that packet
is cloned and should be copied-on-write".

Unshare, then cow the head, in that order: skb_cow_head() can reach
pskb_expand_head(), which has BUG_ON(skb_shared()). Asking for ETH_HLEN
also covers the unchecked push in afiucv_swap_src_dest() --
eth_type_trans() has already pulled that much on the ordinary path, so the
call compares and returns.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Closes: https://sashiko.dev/#/patchset/20260813-b4-disp-60433a46-v1-1-509e1200533e@proton.me?part=1
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/iucv/af_iucv.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index e3ec965d96ca..10cfc5e82f04 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -2069,11 +2069,20 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 		return NET_RX_SUCCESS;
 	}
 
+	skb = skb_share_check(skb, GFP_ATOMIC);
+	if (!skb)
+		return NET_RX_SUCCESS;
+
 	if (!pskb_may_pull(skb, sizeof(*trans_hdr))) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;
 	}
 
+	if (skb_cow_head(skb, ETH_HLEN)) {
+		kfree_skb(skb);
+		return NET_RX_SUCCESS;
+	}
+
 	trans_hdr = iucv_trans_hdr(skb);
 	EBCASC(trans_hdr->destAppName, sizeof(trans_hdr->destAppName));
 	EBCASC(trans_hdr->destUserID, sizeof(trans_hdr->destUserID));

-- 
2.55.0

