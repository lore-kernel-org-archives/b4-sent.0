From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 15 Aug 2026 11:07:26 -0500
Subject: [PATCH net 1/2] net/iucv: drop HiperSockets frames from other
 network namespaces
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-b4-disp-dc82fde4-v1-1-e83b10b22ce9@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786810045; l=1465;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=+i2AgKp/ZjTfUK6HdWlXZJX/pS4StiSoANqdxYojTkk=;
 b=BuLoDOmzIn0S4VKpqh1WYiwaOJBHGdNtDPQP/gu4GIp9H49XsOt+f10dJKKrFgGCf5kHRpLA/
 lJ/mgMrpQfoDE3pBCTdkJivzh3qswm4AkJqMjxmqdrXp4gjJv0hO+yg
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iucv_packet_type sets neither .dev nor .af_packet_net, so it lands in the
machine-global ptype_base[] that __netif_receive_skb_core walks for every
frame in every namespace, and afiucv_hs_rcv() ignores its dev argument.
An ETH_P_AF_IUCV frame sent from any namespace holding CAP_NET_RAW is
therefore matched against the global iucv_sk_list and can move a socket
owned by the initial namespace: afiucv_hs_callback_synfin() and _fin()
overwrite its sk_state, and _syn() builds an accept-queue child.

Filter on the namespace. The core does not do it for ptype_base[] --
net/core/dev.c leaves namespace filtering to the ptype owner -- and
net/x25/x25_dev.c and net/ieee802154/socket.c both test dev_net(dev) at
exactly this point.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/iucv/af_iucv.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index ea047bab65e7..e3ec965d96ca 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -2064,6 +2064,11 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 	int err = NET_RX_SUCCESS;
 	char nullstring[8];
 
+	if (!net_eq(dev_net(dev), &init_net)) {
+		kfree_skb(skb);
+		return NET_RX_SUCCESS;
+	}
+
 	if (!pskb_may_pull(skb, sizeof(*trans_hdr))) {
 		kfree_skb(skb);
 		return NET_RX_SUCCESS;

-- 
2.55.0

