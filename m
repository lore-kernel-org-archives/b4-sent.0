From: Gleb Pesin <dormancygrace@gmail.com>
Date: Fri, 20 Nov 2026 19:37:18 +0000
Subject: [PATCH] crypto: eip93 - return request validation errors
 synchronously
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-eip93-sync-errors-v1-1-1a83ae607181@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ6CQAxA4auQrmkyHYP8XIW40KFIWQykBaOZc
 HcHXX6L9xIYq7BBVyRQfonJEjOoLCBM9/hklCEbvPNXIu+QZW0vaJ8YkFUXNRyH2rnQtDVVBLl
 blUd5/5797W/bHzOH7RzBcXwBVOfKRXUAAAA=
X-Change-ID: 20261120-eip93-sync-errors-fd700c897151
To: Christian Marangi <ansuelsmth@gmail.com>, 
 Antoine Tenart <atenart@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795203472; l=2301;
 i=dormancygrace@gmail.com; s=eip93-20261120; h=from:subject:message-id;
 bh=+TERzP8CffsbpcQ4hBerOf52PVosyn07V8S4OEMiU+s=;
 b=PZQlB1FHao03xhRgyUZoCNx9qVq7bZcoCSRfK8UXjiMndmeNRgXSkKxLZPA4fO2R5XtMKl+Oi
 Pej7t3wOQrnB1J95q7sjZIt+4R0fumYtk6gHihhEiNW83n+1qkOiHRU
X-Developer-Key: i=dormancygrace@gmail.com; a=ed25519;
 pk=XHpoYk1e6byKypiKa/3bDHJ2i4leWLeZDDjx4gJVsmc=
X-Endpoint-Received: by B4 Relay for dormancygrace@gmail.com/eip93-20261120 with auth_id=1587
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The skcipher and AEAD paths validate requests before submitting them
to the hardware. On validation failure they invoke the completion
callback and return the same error. Callers handle that return value
as a synchronous failure and can complete the request a second time.

Return the validation error directly in both paths. Keep completion
callbacks in the hardware result handlers.

Codex (gpt-6.2-sol) assisted with comparing the two paths, preparing the
change and writing the changelog. The corresponding OpenWrt 6.18.64
driver object was cross-compiled on MIPS.

Fixes: 9739f5f93b78 ("crypto: eip93 - Add Inside Secure SafeXcel EIP-93 crypto engine support")
Reported-by: Herbert Xu <herbert@gondor.apana.org.au>
Closes: https://lore.kernel.org/linux-crypto/aXxmIuU9PKJiDs7n@gondor.apana.org.au/
Signed-off-by: Gleb Pesin <dormancygrace@gmail.com>
---
 drivers/crypto/inside-secure/eip93/eip93-aead.c   | 4 +---
 drivers/crypto/inside-secure/eip93/eip93-cipher.c | 4 +---
 2 files changed, 2 insertions(+), 6 deletions(-)

diff --git a/drivers/crypto/inside-secure/eip93/eip93-aead.c b/drivers/crypto/inside-secure/eip93/eip93-aead.c
index 0b7a899b1..12134b6aa 100644
--- a/drivers/crypto/inside-secure/eip93/eip93-aead.c
+++ b/drivers/crypto/inside-secure/eip93/eip93-aead.c
@@ -47,10 +47,8 @@ static int eip93_aead_send_req(struct crypto_async_request *async)
 	int err;
 
 	err = check_valid_request(rctx);
-	if (err) {
-		aead_request_complete(req, err);
+	if (err)
 		return err;
-	}
 
 	return eip93_send_req(async, req->iv, rctx);
 }
diff --git a/drivers/crypto/inside-secure/eip93/eip93-cipher.c b/drivers/crypto/inside-secure/eip93/eip93-cipher.c
index 4dd7ab750..7b6d510f4 100644
--- a/drivers/crypto/inside-secure/eip93/eip93-cipher.c
+++ b/drivers/crypto/inside-secure/eip93/eip93-cipher.c
@@ -38,10 +38,8 @@ static int eip93_skcipher_send_req(struct crypto_async_request *async)
 
 	err = check_valid_request(rctx);
 
-	if (err) {
-		skcipher_request_complete(req, err);
+	if (err)
 		return err;
-	}
 
 	return eip93_send_req(async, req->iv, rctx);
 }

---
base-commit: 26ca5f34841f0a86d0883664a1c13be89a01d351
change-id: 20261120-eip93-sync-errors-fd700c897151

Best regards,
--  
Gleb Pesin <dormancygrace@gmail.com>

