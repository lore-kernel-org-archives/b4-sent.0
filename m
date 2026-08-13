From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 13 Aug 2026 07:51:48 -0500
Subject: [PATCH net] net/iucv: only deliver HiperSockets frames to
 HiperSockets sockets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-b4-disp-60433a46-v1-1-509e1200533e@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywqDMBAAf0X23IW8SKu/UjzEZG23hyhZFUH8d
 9P2OAMzBwgVJoGuOaDQxsJTrqBvDcR3yC9CTpXBKOPVQ1scHCaWGb1y1gbncYwpBt3etWkD1Gw
 uNPL+Wz4h0wL9X8o6fCgu3xmc5wWnTC1ZeQAAAA==
X-Change-ID: 20260813-b4-disp-60433a46-fcdca197129a
To: Alexandra Winter <wintera@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>, Eric Dumazet <edumazet@google.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>
Cc: linux-s390@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786625507; l=3707;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=nDOO3oM08heQVmzsx4LEcCLvEFOxohiC/gWc4G5L6Gg=;
 b=l2IbGlWnwmg8daONne+d5f+6rWwtJIyBaGnEXDj6isxGgubMLGKKusZP3Tu/SQsv/71jDIYu+
 BfZJ0aGAI9yA4d8vJMu9Wm+iKi5w6rqiRhgihiDKe17glQBlkjbU+wI
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

afiucv_hs_rcv() selects a socket out of iucv_sk_list by the four name
fields alone, with no test on iucv->transport, so a frame arriving over
HiperSockets can be delivered to a socket bound to the classic z/VM IUCV
transport. iucv_sock_bind() makes that reachable rather than theoretical:
a bind to the local guest userid always takes the classic path, even on a
guest that also carries a HiperSockets device with the same identifier.

Skip sockets that are not on the HiperSockets transport. The two were
added as alternatives for environments assumed disjoint - IUCV under
z/VM, HiperSockets on LPAR - and this lookup still assumes a guest has
only one of them.

Fixes: 3881ac441f64 ("af_iucv: add HiperSockets transport")
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
The two transports were introduced as alternatives for environments the
2011 series treated as disjoint. Its cover letter says so:

  "The current transport mechanism for af_iucv (iucv) is only available
   on VM. HiperSockets provide similar capabilities as iucv and are
   available on LPAR."

  https://lore.kernel.org/all/20110727161339.530894848@de.ibm.com/

That premise is the one to check, and it is yours to settle: on a z/VM guest
that also has a HiperSockets device both exist at once, and iucv_sock_bind()
resolves the local userid to the classic transport at the test against
iucv_userid. If a guest can never reach both, this patch is unnecessary and
I would rather know that than have it applied.

Reach is wider than the HiperSockets LAN, which is what decides how urgently
this is worth taking: iucv_packet_type sets no .dev, afiucv_hs_rcv() ignores
its dev argument, and nothing checks dev_net() -- net/x25/x25_dev.c and
net/ieee802154/socket.c both do at exactly that point. An AF_PACKET frame on
lo from any netns holding CAP_NET_RAW reaches these sockets.

Two consequences I traced on a classic socket that matches an inbound frame:
afiucv_hs_callback_synfin() and _fin() overwrite its sk_state, and
afiucv_hs_callback_syn() builds an accept-queue child with transport HIPER
but hs_dev NULL, which LL_RESERVED_SPACE() dereferences unguarded on the
first send. That read lands in mapped lowcore on a default kernel and
afiucv_hs_send() then returns -ENODEV, so I am not claiming a panic; it
faults with relocate_lowcore. By inspection; not reproduced. Compile-tested
for s390x.

One case where this patch is a regression: a device whose hsuid is set to
the same 8 characters as
the guest's z/VM userid. iucv_sock_bind() tests siucv_user_id against
iucv_userid before it scans for a HiperSockets device, so such a socket
becomes classic and today receives HiperSockets frames only because this
lookup does not filter. After this patch it stops receiving them. If that
configuration is one you support, then this is the wrong patch and the fix
belongs in the bind ordering.
---
 net/iucv/af_iucv.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index ea047bab65e7..5fb6793b9a64 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -2079,6 +2079,8 @@ static int afiucv_hs_rcv(struct sk_buff *skb, struct net_device *dev,
 	sk = NULL;
 	read_lock(&iucv_sk_list.lock);
 	sk_for_each(sk, &iucv_sk_list.head) {
+		if (iucv_sk(sk)->transport != AF_IUCV_TRANS_HIPER)
+			continue;
 		if (trans_hdr->flags == AF_IUCV_FLAG_SYN) {
 			if ((!memcmp(&iucv_sk(sk)->src_name,
 				     trans_hdr->destAppName, 8)) &&

---
base-commit: 9006c116dd111d457bf5d074990210f70a4ad2c8
change-id: 20260813-b4-disp-60433a46-fcdca197129a

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

