MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-ktls-net-v1-1-a047fdb54612@certik.com>
X-B4-Tracking: v=1; b=H4sIAK5fCWsC/yWMywrCMBAAf6Xs2QU3Fl+/Ij0k6cZGy0ayUYTSf
 2+ixxmGWUA5R1a4dgtk/kSNSSrQrgM/WbkzxrEymL05EpkTPsusKFzQBHs4E4eezAVq/soc4ve
 3ukENYPhLfbsH+9ImLXNWGV224qemlGUsKc3YPKzrBuQy0KCRAAAA
X-Change-ID: 20261127-ktls-net-2fa381ef4129
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 08:47:22 +0000
Subject: [PATCH net] tls: rx: fix skb extension reference leak
To: netdev@vger.kernel.org
Cc: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Willem de Bruijn <willemb@google.com>, 
 Simon Horman <horms@kernel.org>, security@kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795776430; l=2316;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=ZT9LWyJjTuc2AU4pnEhY6CiCH+8k4KmgqGBYXiphoUY=;
 b=KGxIvDDLwpFRYgdm+3LyKKsEUxfv3yV3taUjwPxDtsXdp7ZF5+eevhRkvnDYsDqwkUZ43NP7c
 orcFTUu/RXdDdqib2VXMKu6M81n/keFbTbRmjonCNqDb6qqroK5mupn
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tls_strp_load_anchor_with_queue() reuses strp->anchor for every record
and calls skb_copy_header() to copy the header of the first queued skb
onto it. skb_copy_header() goes through __copy_skb_header(), which uses
__skb_ext_copy(): it takes a reference on the source skb's extensions
and overwrites the anchor's extension pointer without dropping the
reference the anchor already held. When the received skbs carry
extensions, for example TC_SKB_EXT set by tc or SKB_EXT_BRIDGE_NF set
by br_netfilter, every reload of the anchor leaks one skb_ext.

skbuff_ext_cache is not charged to the memory cgroup, so the leaked
objects also escape memcg limits.

Drop the anchor's extensions with skb_ext_reset() before copying the
new header.

Fixes: 84c61fe1a75b ("tls: rx: do not use the standard strparser")
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
Tested on x86_64 UML with KASAN and kmemleak at v7.4-rc4:
- kTLS RX receiving 5,000 one-byte records whose skbs carried
  TC_SKB_EXT (tc flower in a user namespace) or SKB_EXT_BRIDGE_NF
  (bridge with br_netfilter): skbuff_ext_cache grew by exactly 5,000
  objects and kmemleak reported 4,900 to 4,978 unreferenced objects
  from __skb_ext_alloc. With the fix: no growth and no reports. With the
  fix reverted: 5,000 again.
- The same kTLS traffic without extensions, and plain TCP with
  extensions: no leak before or after the fix.
- On v6.1.193 (bridge path, run from a user namespace) kmemleak
  reported 3,038 leaked skb_ext objects before the fix and none after.
  The patch applies unchanged to 6.1.y, 6.6.y, 6.12.y and 6.18.y.

A reproducer is available if it helps.

This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

 net/tls/tls_strp.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/net/tls/tls_strp.c b/net/tls/tls_strp.c
index 53d3256d0..8ad7f339d 100644
--- a/net/tls/tls_strp.c
+++ b/net/tls/tls_strp.c
@@ -475,6 +475,7 @@ static void tls_strp_load_anchor_with_queue(struct tls_strparser *strp, int len)
 
 	skb_shinfo(strp->anchor)->frag_list = first;
 
+	skb_ext_reset(strp->anchor);
 	skb_copy_header(strp->anchor, first);
 	strp->anchor->destructor = NULL;
 
-- 
2.43.0

