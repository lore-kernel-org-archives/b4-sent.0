From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Thu, 05 Feb 2026 15:44:05 +0100
Subject: [PATCH net-next] net: skb: allow up to 8 skb extension ids
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260205-skb_ext-v1-1-9ba992ccee8b@hartkopp.net>
X-B4-Tracking: v=1; b=H4sIALSshGkC/x3MQQqAIBBA0avErBNUUqqrRITZVENgoRKCePek5
 YfHzxDQEwYYmwweXwp0uxqibcCexh3IaKsNkkvNJVcsXOuCKTLDO6uFtUOvEKp+PO6U/tMEDiN
 zVcFcyge7h5FIYwAAAA==
X-Change-ID: 20260205-skb_ext-a04c61cc985e
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Florian Westphal <fw@strlen.de>, Oliver Hartkopp <socketcan@hartkopp.net>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770302657; l=1409;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=0xitE6f4X80qvcsu6zLeGOS3GWowolncxL3u1M9XXik=;
 b=n7mqLSz6Ke5GE/kkdWHvZq0icKMYfF8vtVChShC/3Pj1o2qwuQicxhqZuvlIEHc6u3fuBuSNX
 szWiAd6OiGZCS808ERBK4qSl0NwLUh3b2aeJxVmxmM8uWgyFUyGlpVr
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The skb extension ids range from 0 .. 7 to fit their bits as flags into
a single byte. The ids are automatically enumnerated in enum skb_ext_id
in skbuff.h, where SKB_EXT_NUM is defined as the last value.

When having 8 skb extension ids (0 .. 7), SKB_EXT_NUM becomes 8 which is
a valid value for SKB_EXT_NUM.

This patch intentionally lacks a Fixes tag. Backporting is pointless as
former kernels did not use the entire range of skb extension ids.

Link: https://lore.kernel.org/netdev/aXoMqaA7b2CqJZNA@strlen.de/
Reviewed-by: Florian Westphal <fw@strlen.de>
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 net/core/skbuff.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/core/skbuff.c b/net/core/skbuff.c
index 648c20e19038..609851d70173 100644
--- a/net/core/skbuff.c
+++ b/net/core/skbuff.c
@@ -5156,11 +5156,11 @@ static __always_inline unsigned int skb_ext_total_length(void)
 	return l;
 }
 
 static void skb_extensions_init(void)
 {
-	BUILD_BUG_ON(SKB_EXT_NUM >= 8);
+	BUILD_BUG_ON(SKB_EXT_NUM > 8);
 #if !IS_ENABLED(CONFIG_KCOV_INSTRUMENT_ALL)
 	BUILD_BUG_ON(skb_ext_total_length() > 255);
 #endif
 
 	skbuff_ext_cache = kmem_cache_create("skbuff_ext_cache",

---
base-commit: 021718d2cc1a2df2f53b06968fa89280199371bd
change-id: 20260205-skb_ext-a04c61cc985e

Best regards,
--  
Oliver Hartkopp <socketcan@hartkopp.net>

