From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 13:03:36 +0000
Subject: [PATCH 5.10.y-cip] net: skbuff: propagate shared-frag marker in
 skb_zerocopy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-cip-nfq-510-v1-1-100519287635@certik.com>
X-B4-Tracking: v=1; b=H4sIAKd/CWsC/02NwQ7CIBBEf6XZs1uBBBv8FeMBlsViDK1Qjabpv
 wt68Tgzb2ZWKJwjFzh2K2R+xhKnVIXcdUCjTRfG6KsGJdRBSjUgxRlTuKOWAoMejDDkjSADtTF
 nDvH1XTuB7qXo342H8y8rD3dlWtpco50tjC7bRGOzCie/TNMNm7//u4Ft+wDJKdZQpwAAAA==
X-Change-ID: 20261127-cip-nfq-510-f57909cd90c9
To: cip-dev@lists.cip-project.org
Cc: Pavel Machek <pavel@nabladev.com>, 
 Nobuhiro Iwamatsu <nobuhiro.iwamatsu.x90@mail.toshiba>, 
 Ulrich Hecht <uli@fpond.eu>, Zizhen Liu <pointerliu@126.com>, 
 netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795784615; l=2684;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=xm+LCu4gjgfqDzef9HZ1mCC0CWg3F4chAeh/3bn3m3o=;
 b=bCBVOHJwDqFzgtH634XtNE/DPLg1E7QsuJRBEzy4Au4u+0dGmFzcf33JO0tAZxttdHzRQPtkh
 rxD54kxtbB1CeCDMC6KO89rW8SyGCQSvTpIQkbs1l5VCJoUvXlQLD3W
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zizhen Liu <pointerliu@126.com>

commit 79dc34beb1fdb3da79753e51e15c68591a2561fe upstream.

skb_zerocopy() moves frag descriptors from @from into @to and takes a
reference on each frag, but it does not copy skb_shinfo(from)->flags into
skb_shinfo(to)->flags.  A destination skb holding the same page-cache
backed frags as the source therefore reports skb_has_shared_frag() as
false.

That breaks the invariant relied on by later in-place writers.  ESP input
checks skb_has_shared_frag() before deciding whether an uncloned
nonlinear skb can skip skb_cow_data(); with the marker lost, an skb that
skb_zerocopy() built for nfnetlink_queue or for an openvswitch upcall is
decrypted in place, letting an unprivileged user write into the page
cache of a root-owned read-only file.

Propagate SKBFL_SHARED_FRAG when frag descriptors are copied, as done for
the other frag-transfer helpers.

Fixes: af2806f8f90a ("net: Export skb_zerocopy() to zerocopy from one skb to another")
Fixes: f4c50a4034e6 ("xfrm: esp: avoid in-place decrypt on shared skb frags")
Cc: stable@kernel.org
Signed-off-by: Zizhen Liu <pointerliu@126.com>
Reviewed-by: Eric Dumazet <edumazet@kernel.org>
Link: https://patch.msgid.link/20261022104217.1852191-1-pointerliu@126.com
Signed-off-by: Jakub Kicinski <kuba@kernel.org>
[ adapted to 5.10.y-cip: propagate SKBTX_SHARED_FRAG through skb_shared_info.tx_flags ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
5.10 stores the shared fragment marker in skb_shared_info.tx_flags.
The backport propagates SKBTX_SHARED_FRAG from that field.

Tested on 5.10.272-cip79: net/core/skbuff.o built with W=1 before
and after the patch, with no new diagnostics. The same paired build
passed on the 5.10.275-cip80 tip. On v5.10.275, the base and patched
QEMU guests each passed all eight stock nft_queue.sh checks. The
runtime test was not rerun on the CIP tip.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 net/core/skbuff.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/net/core/skbuff.c b/net/core/skbuff.c
index 207c4d85fad7..56c4805413cc 100644
--- a/net/core/skbuff.c
+++ b/net/core/skbuff.c
@@ -3135,6 +3135,8 @@ skb_zerocopy(struct sk_buff *to, struct sk_buff *from, int len, int hlen)
 	}
 	skb_shinfo(to)->nr_frags = j;
 
+	skb_shinfo(to)->tx_flags |= skb_shinfo(from)->tx_flags & SKBTX_SHARED_FRAG;
+
 	return 0;
 }
 EXPORT_SYMBOL_GPL(skb_zerocopy);

---
base-commit: bd8b111cdf1d9897bf4d826b7305a9c16bfe5f71
change-id: 20261127-cip-nfq-510-f57909cd90c9

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

