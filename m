From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 08 Oct 2026 04:21:57 -0500
Subject: [PATCH net v2] net/iucv: take a private, writable frame before
 rewriting it in place
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-b4-disp-bf46f1ba-v2-1-46ff1ea9c40b@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCQAwAv1JyNpCuaxG/Ih6aNNF4WMumilD6d
 1c9zsDMCqHVNeDUrVD15eGP0iDtOpDbWK6KPjWGRGnoiY7IGSePGdnyYD2PSHZg2ZtQkgwtm6u
 av3/LMxRd4PKX8eS7yvKdwbZ9AFQV4aV5AAAA
X-Change-ID: 20261008-b4-disp-bf46f1ba-0f5bc3fc02c4
To: Alexandra Winter <wintera@linux.ibm.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Eric Dumazet <edumazet@kernel.org>
Cc: linux-s390@vger.kernel.org, Ursula Braun <ursula.braun@de.ibm.com>, 
 netdev@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 Hidayath Khan <hidayath@linux.ibm.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791451316; l=3692;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=R6y/vNgxdBH4QyJ1cYdPY08lmNL7AuKT8aaHPnJEsq8=;
 b=xpNt1dGFAdwuich/Pe6XUVJvlL3e7zIYfVIOLpdfUCVyEfqmWnrR6n8c83KGbesDTFyUT9nK8
 xA5EGqn1C0OCy1Dm8bpHt4djxW6CzuRjskkAZtVYEGYmHzhaEtbmszP
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

afiucv_hs_rcv() rewrites the frame in place -- EBCASC() on four name
fields, then afiucv_swap_src_dest() swaps them and pushes an Ethernet
header -- and can hand the same skb to dev_queue_xmit(), without making
it private first, so a packet socket that also gets the frame reads the
rewritten names. An ETH_P_ALL tap runs first and leaves af_iucv a
cloned skb; a socket opened for ETH_P_AF_IUCV sits on a ptype_specific
list, walked after ptype_base[], so deliver_skb() takes a reference and
af_iucv runs on an skb that is shared but not cloned.

Unshare, then cow the head, in that order: skb_cow_head() can reach
pskb_expand_head(), which has BUG_ON(skb_shared()). Asking for ETH_HLEN
also covers the unchecked push in afiucv_swap_src_dest(); on the ordinary
path eth_type_trans() has already pulled that much, so it only compares.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Closes: https://sashiko.dev/#/patchset/20260813-b4-disp-60433a46-v1-1-509e1200533e@proton.me?part=1
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
Reviewed-by: Alexandra Winter <wintera@linux.ibm.com>
---
Sorry for the long silence since August: a major earthquake hit where I
live, and I was finishing a postgrad program. Back now.

v2: the old 2/2 alone. 1/2 is dropped; Alexandra's 80230a18c164
    ("net/iucv: filter frames in afiucv_hs_rcv() by ingress device")
    replaced it and is in mainline. Rebased on net, no code change,
    carries Alexandra's R-b. Kept on net; Alexandra agreed on v1 to
    treat it as a fix. The commit message now covers both cases: v1
    described the ETH_P_ALL tap, where af_iucv gets a cloned skb, and
    the v1 thread added the ETH_P_AF_IUCV socket, where it gets a shared
    one. My reply there said v1 had the delivery order backwards. It
    didn't; both cases are real, and the A/B below shows each call is
    needed.

v1: https://lore.kernel.org/all/20260815-b4-disp-dc82fde4-v1-0-e83b10b22ce9@proton.me/

Tested on s390x under QEMU TCG, KASAN and lockdep on. No z/VM there, so
af_iucv gets its frames from lo (80230a18c164 filters after the
EBCASC(), so lo frames still hit the rewrite), and a packet socket
reads each one back. Unpatched, the tap and the ETH_P_AF_IUCV socket
both get the 48 name bytes already in ASCII, and a SYN with no listener
never reaches that socket as a 0xfbfb frame. Patched, every frame
arrives as sent. Drop skb_share_check() and the ETH_P_AF_IUCV socket is
broken again; drop skb_cow_head() and both are. FWIW no splat in any
boot, patched or not -- on lo the damage is in what the other receivers
read. Builds clean for s390 with W=1. Repro and logs on request.
---
 net/iucv/af_iucv.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index db261ecd19af..493dc156e9f5 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -2072,11 +2072,20 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 	int err = NET_RX_SUCCESS;
 	char nullstring[8];
 
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

---
base-commit: 6d25ffca055a77787c21a36b66c253f76239411b
change-id: 20261008-b4-disp-bf46f1ba-0f5bc3fc02c4

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

