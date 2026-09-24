From: Alireza Asgari <alireza@asgari.net>
Date: Thu, 24 Sep 2026 13:00:24 +0000
Subject: [PATCH net 1/2] net: fix checksum offsets in
 skb_splice_from_iter()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-fix-udp-splice-checksum-v1-1-fe61d65447a8@asgari.net>
References: <20260924-fix-udp-splice-checksum-v1-0-fe61d65447a8@asgari.net>
In-Reply-To: <20260924-fix-udp-splice-checksum-v1-0-fe61d65447a8@asgari.net>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 David Howells <dhowells@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Alireza Asgari <alireza@asgari.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790254849; l=2218;
 i=alireza@asgari.net; s=alireza-kernel; h=from:subject:message-id;
 bh=10aQjP+oz2coB4vcqJcDFDEfRRP5f98Xv2+8tCwyCi0=;
 b=8NR5L/W06Aj8/yjz7hVEj6ADVyibkr2aTYt0eJphxQ91qw1jWWZMr+3Nh+mtaDUaJSWXgexDO
 AJ7KA2lDCjdCv88GE8f7DIhQ2ZBk5mbl+igEgcTtyM/A+G9zJsiQpzz
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=wuQ0/M69FqoVnrCMUJ13EQCwrCwVjCrtz75k15vW8tw=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/alireza-kernel with auth_id=1055
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

skb_splice_from_iter() appends multiple page fragments before updating
skb->len. However, skb_splice_csum_page() uses that unchanged length as the
offset for every fragment checksum. If bytes already appended during the
call have an odd total length, a later fragment's checksum is combined
with the wrong parity.

For example, prime a UDP socket with sendto(MSG_MORE) and splice two
distinct pipe buffers containing "abc" and "DEFGH". Uncorking reports
success, but the receiver discards the packet for a bad checksum.
This also affects IPv6 and fragments beginning near a page boundary.

Pass the initial skb length plus the bytes already spliced to the checksum
helper. Keep the existing final length update and partial-progress error
handling unchanged. CHECKSUM_PARTIAL does not use this helper and remains
unaffected.

Fixes: 2e910b95329c ("net: Add a function to splice pages into an skbuff for MSG_SPLICE_PAGES")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Alireza Asgari <alireza@asgari.net>
---
 net/core/skbuff.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/net/core/skbuff.c b/net/core/skbuff.c
index b4edbd0665..38783953db 100644
--- a/net/core/skbuff.c
+++ b/net/core/skbuff.c
@@ -7403,7 +7403,8 @@ nodefer:	kfree_skb_napi_cache(skb);
 }
 
 static void skb_splice_csum_page(struct sk_buff *skb, struct page *page,
-				 size_t offset, size_t len)
+				 size_t offset, size_t len,
+				 unsigned int csum_offset)
 {
 	const char *kaddr;
 	__wsum csum;
@@ -7411,7 +7412,7 @@ static void skb_splice_csum_page(struct sk_buff *skb, struct page *page,
 	kaddr = kmap_local_page(page);
 	csum = csum_partial(kaddr + offset, len, 0);
 	kunmap_local(kaddr);
-	skb->csum = csum_block_add(skb->csum, csum, skb->len);
+	skb->csum = csum_block_add(skb->csum, csum, csum_offset);
 }
 
 /**
@@ -7471,7 +7472,8 @@ ssize_t skb_splice_from_iter(struct sk_buff *skb, struct iov_iter *iter,
 			}
 
 			if (skb->ip_summed == CHECKSUM_NONE)
-				skb_splice_csum_page(skb, page, off, part);
+				skb_splice_csum_page(skb, page, off, part,
+						     skb->len + spliced);
 
 			off = 0;
 			spliced += part;

-- 
2.34.1

