From: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
Date: Wed, 04 Mar 2026 09:20:23 +0100
Subject: [PATCH] net: bridge: fix NULL dereference in br_do_suppress_nd
 when ipv6.disable=1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260304-br-nd-suppress-ipv6-null-fix-v1-1-084356ba8257@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqDMBAAvyJ77kISNQW/Ij1E3bQLIQ1ZFEHyd
 xePMwxzgVBlEpi6CyodLPzPCvbVwfoL+UvImzI447zpzYBLxbyh7KVUEkEuh8e8p4SRTzRhtD6
 u7h1tAF1oo/rZz5/Wbl62a91uAAAA
X-Change-ID: 20260304-br-nd-suppress-ipv6-null-fix-0a516fc27f1a
To: Nikolay Aleksandrov <razor@blackwall.org>, 
 Ido Schimmel <idosch@nvidia.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: bridge@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Guruprasad C P <gurucp2005@bugzilla.kernel.org>, 
 Maximilian Pezzullo <maximilianpezzullo@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772612423; l=1381;
 i=maximilianpezzullo@gmail.com; s=20260303; h=from:subject:message-id;
 bh=HvIRU/i10xnVMJH/+ZNsf/sb22J8jejklG20d/MkhlI=;
 b=H1UIZ23bHg2tUhPT/B36gsRLVgF6dOQrgedgYPa2gB8N3k2aMndRbMNRp4MyC68a1YB916q2k
 IM7hHazRSNcBZO/shE3Z1glFxiwlDELetWeaLorRqMzb6U+TS9nqXKb
X-Developer-Key: i=maximilianpezzullo@gmail.com; a=ed25519;
 pk=TRTR4c2Vb1IfluQvv5OUDPg7EE+pIzdPBND85UU559w=
X-Endpoint-Received: by B4 Relay for maximilianpezzullo@gmail.com/20260303 with auth_id=658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the kernel is booted with ipv6.disable=1, the IPv6 module loads
but skips full initialization, leaving ipv6_stub as NULL. If the bridge
neigh_suppress feature is enabled on a port and an ICMPv6 Neighbor
Solicitation arrives, br_do_suppress_nd() calls neigh_lookup() via
ipv6_stub->nd_tbl without first checking whether ipv6_stub is valid,
causing a kernel panic.

Fix this by returning early if ipv6_stub or its nd_tbl pointer is NULL.

Reported-by: Guruprasad C P <gurucp2005@bugzilla.kernel.org>
Closes: https://bugzilla.kernel.org/show_bug.cgi?id=221143
Signed-off-by: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
---
 net/bridge/br_arp_nd_proxy.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/net/bridge/br_arp_nd_proxy.c b/net/bridge/br_arp_nd_proxy.c
index 1e2b51769eec..0b1b9ba29b7d 100644
--- a/net/bridge/br_arp_nd_proxy.c
+++ b/net/bridge/br_arp_nd_proxy.c
@@ -455,6 +455,9 @@ void br_do_suppress_nd(struct sk_buff *skb, struct net_bridge *br,
 		return;
 	}
 
+	if (!ipv6_stub || !ipv6_stub->nd_tbl)
+		return;
+
 	n = neigh_lookup(ipv6_stub->nd_tbl, &msg->target, vlandev);
 	if (n) {
 		struct net_bridge_fdb_entry *f;

---
base-commit: af4e9ef3d78420feb8fe58cd9a1ab80c501b3c08
change-id: 20260304-br-nd-suppress-ipv6-null-fix-0a516fc27f1a

Best regards,
-- 
Maximilian Pezzullo <maximilianpezzullo@gmail.com>

