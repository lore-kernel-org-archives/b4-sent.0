From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Wed, 28 Oct 2026 23:47:13 -0500
Subject: [PATCH net v3] net/iucv: take a private, writable frame before
 rewriting it in place
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-b4-disp-1edbbc34-v3-1-13495411f5b9@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBAAv0L27CbQFkS/Qjyw3QXWQyVdNCaEv
 1v1OJPM7GCSVQyu1Q5ZXmr6SAX8qYK4jGkWVC4MrnZdU7seKSCrrdgIE0UfMPQjn1sm38ULlGz
 NMun7txwgyQa3v7Qn3SVu3xkcxwdfbNRMeQAAAA==
X-Change-ID: 20261028-b4-disp-1edbbc34-48ad75db36c9
To: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>
Cc: Hidayath Khan <hidayath@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 Ursula Braun <ursula.braun@de.ibm.com>, linux-s390@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793249232; l=3123;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=JFUfhciEChw7BgSLF92o8VaqbY3+Obn41qmQCu8hTpc=;
 b=xB7V2bhn6yEiVdWWxB5Zut++I9OEjUHTLT/m685QspAXcWfHaaewSgGT5tCMdViA7k7dk9yJ7
 utyXMSZzOVrDTYPb5i/zuzqgNgCwKAWEkEBwow0HPRXlVi4uA2y/PcJ
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

Unshare, then cow, in that order: skb_cow() can reach
pskb_expand_head(), which has BUG_ON(skb_shared()). skb_cow() tests
skb_cloned(), which is what a rewrite of the data needs; skb_cow_head()
tests only the header. Asking for ETH_HLEN also covers the unchecked
push in afiucv_swap_src_dest(); on the ordinary path eth_type_trans()
has already pulled that much, so it only compares.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Closes: https://sashiko.dev/#/patchset/20260813-b4-disp-60433a46-v1-1-509e1200533e@proton.me?part=1
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v3: skb_cow() instead of skb_cow_head(), as Paolo and the netdev AI
    review asked: the rewrite is in the data, and skb_cow_head()'s
    skb_header_cloned() test would leave it shared with a nohdr holder
    (none reaches af_iucv today; still the wrong contract). One-word
    change, rebased on net. v2 carried Alexandra's Reviewed-by; v3
    changes the helper on Paolo's point, so it is not carried. Same
    s390x QEMU A/B as v2, re-run on v3: same eight boots, same table.
    Unpatched, the tap and the ETH_P_AF_IUCV socket both read the 48
    name bytes in ASCII and a SYN with no listener never reaches the
    socket; with this version every frame arrives as sent. Drop
    skb_share_check() and the socket is broken again; drop skb_cow() and
    both are.

v2: https://lore.kernel.org/all/20261008-b4-disp-bf46f1ba-v2-1-46ff1ea9c40b@proton.me/
v1: https://lore.kernel.org/all/20260815-b4-disp-dc82fde4-v1-0-e83b10b22ce9@proton.me/
---
 net/iucv/af_iucv.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 5ba875798aa4..ce13fe3c85b5 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -2080,11 +2080,20 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
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
 
+	if (skb_cow(skb, ETH_HLEN)) {
+		kfree_skb(skb);
+		return NET_RX_SUCCESS;
+	}
+
 	trans_hdr = iucv_trans_hdr(skb);
 	EBCASC(trans_hdr->destAppName, sizeof(trans_hdr->destAppName));
 	EBCASC(trans_hdr->destUserID, sizeof(trans_hdr->destUserID));

---
base-commit: fcc00b15cb21a6de76826e5012b2c758505f5e65
change-id: 20261028-b4-disp-1edbbc34-48ad75db36c9

Best regards,
--  
bryamzxz <hexlabsecurity@proton.me>

