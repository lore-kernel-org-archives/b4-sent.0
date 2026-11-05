From: =?utf-8?q?Orkun_Emin_Sar=C4=B1?= <sariorkunemin@gmail.com>
Date: Thu, 05 Nov 2026 16:23:39 +0300
Subject: [PATCH bpf] bpf: lwt: Don't let bpf_lwt_push_encap() wrap gso_size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261105-bpf-lwt-gso-v1-1-cda5e19d321a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywqDMBBFf0Xu2oFE8IG/Ii5MOtEpRSWjbUH8d
 2O7PJd7zgHlKKxoswOR36KyzAlsnsFPwzwyySMxClNU1pqS3Bro9dlo1IXqUBrHjfU+NEjGGjn
 I91frkI7o/6Pu7sl+uzs4zws8SA9ndAAAAA==
X-Change-ID: 20261105-bpf-lwt-gso-7f50be81ccf8
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, 
 Martin KaFai Lau <martin.lau@linux.dev>
Cc: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Josef Bacik <josef@toxicpanda.com>, bpf@vger.kernel.org, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Orkun_Emin_Sar=C4=B1?= <sariorkunemin@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793885019; l=2284;
 i=sariorkunemin@gmail.com; s=20261103; h=from:subject:message-id;
 bh=OabHy4jnG0JqeGBm2zFBbMq6JrHCZ6mnFb/ssUZq31s=;
 b=K2qToYY0e5rmJnMHod+0n8EB4eoKafi6TKBoscUn3C31d2HEhO1ZE/pBsMB1wPy7F6BOte3nQ
 YYMEJq5s6NiBkjZ4bIH0qOlhvacrby6haOzjeA/5z0oGKjvi3PtL6s6
X-Developer-Key: i=sariorkunemin@gmail.com; a=ed25519;
 pk=MJ3Y3somkGDQVAXOSR189QAqWOcfzYCRkL1cSQgJXnE=
X-Endpoint-Received: by B4 Relay for sariorkunemin@gmail.com/20261103 with auth_id=1408
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When bpf_lwt_push_encap() adds an IP header to a TCP GSO skb in
BPF_LWT_ENCAP_IP mode, handle_gso_type() lowers gso_size by the length
of the header. Nothing checks the result. gso_size has 16 bits, so a
gso_size smaller than the header wraps, and one less than the header
length gives GSO_BY_FRAGS. skb_segment() then takes the segment lengths
from a frag_list that the skb does not have.

This is the problem that commit 12d07c38e1b0 ("bpf: Don't let
bpf_skb_adjust_room() use up the MSS") fixed for bpf_skb_adjust_room().
As there, gso_size comes from the peer if GRO built the skb, or from the
virtio header if it came from a tun device or a packet socket, so it can
be as small as TCP_MIN_GSO_SIZE.

Refuse the encap if less than TCP_MIN_GSO_SIZE would be left, before the
skb is changed. Return -ENOTSUPP, as handle_gso_encap() does for GSO
skbs it cannot handle.

Found with AI-assisted code review (Claude Code).

Fixes: ca78801a81e0 ("bpf: handle GSO in bpf_lwt_push_encap")
Signed-off-by: Orkun Emin Sarı <sariorkunemin@gmail.com>
---
No reproducer was run and the fix is not runtime-tested. Build-tested
with LLVM=1 W=1 and CONFIG_LWTUNNEL_BPF=y. checkpatch prefers
EOPNOTSUPP; ENOTSUPP is kept to match the other errors of this helper.
---
 net/core/lwt_bpf.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/net/core/lwt_bpf.c b/net/core/lwt_bpf.c
index da49364ec6..c151a013a8 100644
--- a/net/core/lwt_bpf.c
+++ b/net/core/lwt_bpf.c
@@ -13,6 +13,7 @@
 #include <net/gre.h>
 #include <net/ip.h>
 #include <net/ip6_route.h>
+#include <net/tcp.h>
 
 struct bpf_lwt_prog {
 	struct bpf_prog *prog;
@@ -632,6 +633,14 @@ int bpf_lwt_push_ip_encap(struct sk_buff *skb, void *hdr, u32 len, bool ingress)
 		return -EINVAL;
 	}
 
+	/*
+	 * The MSS is lowered by len. Leave the least that the stack lets a
+	 * TCP GSO packet have, or gso_size can wrap.
+	 */
+	if (skb_is_gso(skb) &&
+	    skb_shinfo(skb)->gso_size < len + TCP_MIN_GSO_SIZE)
+		return -ENOTSUPP;
+
 	if (ingress)
 		err = skb_cow_head(skb, len + skb->mac_len);
 	else

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261105-bpf-lwt-gso-7f50be81ccf8

Best regards,
--  
Orkun Emin Sarı <sariorkunemin@gmail.com>

