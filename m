From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Mon, 02 Nov 2026 01:45:35 +0000
Subject: [PATCH net v2] openvswitch: advance by the real header length in
 get_ipv6_ext_hdrs()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-ovs-exthdrs-v2-1-21ceef6a243d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD7r52oC/x3MQQqAIBBA0avIrBN0IImuEi1Kx5yNhRMShHdPW
 r7F/y8IFSaBWb1QqLLwmTtwUODTlg/SHLoBDTprDeqziqbnTqGI9tbYOIVxd+ihF1ehyM9/WyD
 TDWtrHwUwQcRiAAAA
To: Aaron Conole <aconole@redhat.com>, Eelco Chaudron <echaudro@redhat.com>, 
 Ilya Maximets <i.maximets@ovn.org>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: netdev@vger.kernel.org, dev@openvswitch.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Joas Antonio dos Santos <joasantonio108@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793583934; l=4412;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=hupOxG9gfTdg83Q56zynhHUJuMArSkJdz7lPZA5eIFw=;
 b=sjAGEwAfDl/oGKwvKIn9mFWS2sHBz4fC5dT+I4IDVYbp1Yt2G4YHThpjVkGolAxISJOHufuvn
 duFFwC6ZeezCQGyhQBOMBK4RxBdWNgdJeREkS4zgx7jrsuR3p59Jf+M
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_ipv6_ext_hdrs() walks the IPv6 extension header chain to fill
key->ipv6.exthdrs, but advances to the next header with ipv6_optlen()
whatever the current header is.  That is only right for Hop-by-Hop,
Destination Options and Routing headers:

 - an Authentication Header is ((hdrlen + 2) << 2) bytes long
   (ipv6_authlen()), so with hdrlen = 4 the walk skips 40 bytes instead
   of 24 and reads the next "header" from the ICV and payload;

 - a Fragment header is always 8 bytes, and the byte read as hdrlen is
   its Reserved field, which the sender controls and receivers ignore,
   so a non-zero value makes the walk skip up to 2048 bytes and miss
   the headers that follow;

 - in a non-first fragment nothing after the Fragment header is a
   header at all, it is the middle of the fragmentable part, yet the
   walk keeps parsing it as an extension header chain.

In all cases the OFPIEH12_* bits stored in key->ipv6.exthdrs depend on
bytes chosen by the sender rather than on the headers that are actually
present: payload bytes that look like another AH or a Hop-by-Hop header
add OFPIEH12_UNREP/OFPIEH12_UNSEQ, and real headers after a Fragment
header can go unreported.  Flows that match on OVS_KEY_ATTR_IPV6_EXTHDRS
then classify such packets wrongly.  There is no memory safety issue,
skb_header_pointer() bounds every read.

Advance by sizeof(struct frag_hdr) for Fragment headers and by
ipv6_authlen() for AH, and stop at the Fragment header if its offset is
non-zero, as ipv6_find_hdr() does.

Fixes: 28a3f0601727 ("net: openvswitch: IPv6: Add IPv6 extension header support")
Link: https://lore.kernel.org/all/178905555085.219967.6617611783437228045@kernel.org/
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
Changes in v2:
- Stop the walk at a non-first fragment, nothing after its Fragment
  header is a header (Ilya).
- Drop the Assisted-by tag (Ilya).

Found while going through the pre-existing issues the Sashiko review of
"openvswitch: fix wrong flag value in get_ipv6_ext_hdrs()" pointed out
(Link above).

Tested by building get_ipv6_ext_hdrs() from net/openvswitch/flow.c
before and after this patch in a userspace harness (skb_header_pointer()
replaced by a bounds-checked memcpy from a buffer) and feeding it
crafted packets:

  AH(hdrlen=4) + DSTOPTS + TCP, payload mimicking AH at old offset
    before: AUTH DEST UNREP UNSEQ      after: AUTH DEST UNSEQ
  FRAG(first, Reserved=0xff) + DSTOPTS + ROUTING + TCP
    before: DEST FRAG UNSEQ            after: DEST FRAG ROUTER UNSEQ
  FRAG(offset=1000), payload bytes looking like HOP + DSTOPTS
    before: DEST FRAG UNSEQ            after: FRAG
  ROUTING + FRAG(offset=16), payload bytes looking like AH
    before: AUTH FRAG ROUTER UNREP UNSEQ   after: FRAG ROUTER
  FRAG(first) + ROUTING + TCP, HOP + DST + ROUTING + TCP
    unchanged

net/openvswitch/ builds cleanly with W=1.  I did not test it on a live
datapath.

The analysis and testing were done with help from an LLM-based
assistant; I reviewed the change and ran the tests myself.

v1: https://lore.kernel.org/all/179328922134.76862.10417963652853801970@gmail.com/
---
 net/openvswitch/flow.c | 19 ++++++++++++++++++-
 1 file changed, 18 insertions(+), 1 deletion(-)

diff --git a/net/openvswitch/flow.c b/net/openvswitch/flow.c
index 1c4f3a079..3734416b5 100644
--- a/net/openvswitch/flow.c
+++ b/net/openvswitch/flow.c
@@ -369,11 +369,28 @@ static void get_ipv6_ext_hdrs(struct sk_buff *skb, struct ipv6hdr *nh,
 			return;
 		}
 
+		if (next_type == IPPROTO_FRAGMENT) {
+			struct frag_hdr _fh, *fh;
+
+			fh = skb_header_pointer(skb, start, sizeof(_fh), &_fh);
+			if (!fh)
+				break;
+			/* Only the first fragment has the headers that follow. */
+			if (fh->frag_off & htons(IP6_OFFSET))
+				break;
+			start += sizeof(_fh);
+			next_type = fh->nexthdr;
+			continue;
+		}
+
 		hp = skb_header_pointer(skb, start, sizeof(_hdr), &_hdr);
 		if (!hp)
 			break;
+		if (next_type == IPPROTO_AH)
+			start += ipv6_authlen(hp);
+		else
+			start += ipv6_optlen(hp);
 		next_type = hp->nexthdr;
-		start += ipv6_optlen(hp);
 	}
 }
 

---
base-commit: 94cea342e8915812b45f93c56e134041c7fdb4d7
change-id: 20261102-ovs-exthdrs-c101f8d5b62c

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

