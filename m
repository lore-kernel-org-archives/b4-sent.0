From: Arina Kharlamova <arina.kharlamova@mbzuai.ac.ae>
Date: Tue, 24 Nov 2026 03:37:45 +0400
Subject: [PATCH] selinux: reject a 65535-byte xfrm context that ctx_len
 cannot hold
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-dev-v1-1-00b99ee684ec@mbzuai.ac.ae>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyMT3ZTUMl1jIzNz4+RkC2MzUzMloMqCotS0zAqwKdGxEH5xaVJWanI
 JSKtSbS0AjuyniWcAAAA=
X-Change-ID: 20261124-dev-32673cc83656
To: Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>, 
 =?utf-8?q?Ondrej_Mosn=C3=A1=C4=8Dek?= <omosnacek@gmail.com>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: selinux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, stable@vger.kernel.org, 
 Arina Kharlamova <arina.kharlamova@mbzuai.ac.ae>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795477118; l=2642;
 i=arina.kharlamova@mbzuai.ac.ae; s=20261123; h=from:subject:message-id;
 bh=Z7AJMpvi6SLYbFT+owIrY8vSwJq5AGT0uGxXNqbrlAE=;
 b=Ar6QmklyIzqD+a5uCiu5IjDZKs7GTVmt6UryLLGPxeHsXub11JIu7vvJo8WDXBtpbHA9LBn3B
 5m9am+0ZMXsDbMhnvdQPkyZt+lMZLvvHY//Z1rLqhVLarbTzka0VtzK
X-Developer-Key: i=arina.kharlamova@mbzuai.ac.ae; a=ed25519;
 pk=DzQWwMpUtJvSDuzprqvRdbrC72n4Sq8dW6cq3NRt2Mk=
X-Endpoint-Received: by B4 Relay for arina.kharlamova@mbzuai.ac.ae/20261123 with auth_id=1625
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 86c8db86af43 ("selinux: fix selinux_xfrm_alloc_user() to set
correct ctx_len") made ctx_len count the terminating NUL. ctx_len is a
__u16 and selinux_xfrm_alloc_user() only rejects str_len >= PAGE_SIZE.
With 64K pages, str_len = 65535 passes, and ctx_len = str_len + 1 wraps
to 0 (kmalloc_flex() stores the same truncated value first).

ctx_str[] is __counted_by(ctx_len), so the following memcpy() of
str_len bytes is checked against a buffer of size 0. With
CONFIG_FORTIFY_SOURCE this ends in __fortify_panic():

  memcpy: detected buffer overflow: 65535 byte write of buffer size 0
  kernel BUG at lib/string_helpers.c:1044!
  ...
   selinux_xfrm_state_alloc+0x18/0x24
   security_xfrm_state_alloc+0x3c/0x6c

The memory written stays inside the allocation (65536 bytes for the
string); without FORTIFY_SOURCE the context is stored with ctx_len 0.

A user context of 65535 bytes can reach this hook through PF_KEY
(af_key.c only limits sadb_x_ctx_len to PAGE_SIZE); the xfrm netlink
path cannot, because there uctx->len (a __u16) includes the header.

Reject a str_len that does not leave room for the NUL in ctx_len.

Found while surveying callers of kmalloc_flex() whose __counted_by()
counter is narrower than the count, with the help of an AI coding
assistant (Claude); I reviewed the analysis and the fix. Tested on
v7.4-rc2, arm64 with ARM64_64K_PAGES, FORTIFY_SOURCE and SELinux, under
QEMU (GCC 15.2.0), with a KUnit case that passes a 65535-byte context to
security_xfrm_state_alloc(): the unpatched kernel hits the BUG above,
the patched one returns -ENOMEM. The PF_KEY path itself was not
exercised.

Fixes: 86c8db86af43 ("selinux: fix selinux_xfrm_alloc_user() to set correct ctx_len")
Cc: stable@vger.kernel.org
Signed-off-by: Arina Kharlamova <arina.kharlamova@mbzuai.ac.ae>
---
 security/selinux/xfrm.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/security/selinux/xfrm.c b/security/selinux/xfrm.c
index 8e00b3306574..181748bb5eb3 100644
--- a/security/selinux/xfrm.c
+++ b/security/selinux/xfrm.c
@@ -85,7 +85,8 @@ static int selinux_xfrm_alloc_user(struct xfrm_sec_ctx **ctxp,
 		return -EINVAL;
 
 	str_len = uctx->ctx_len;
-	if (str_len >= PAGE_SIZE)
+	/* ctx->ctx_len below includes the NUL and has to fit its type. */
+	if (str_len >= PAGE_SIZE || str_len >= type_max(ctx->ctx_len))
 		return -ENOMEM;
 
 	ctx = kmalloc_flex(*ctx, ctx_str, str_len + 1, gfp);

---
base-commit: 347b0c5bacbe94bc99f7683e3c9269c77a0b9c92
change-id: 20261124-dev-32673cc83656

Best regards,
--  
Arina Kharlamova <arina.kharlamova@mbzuai.ac.ae>

