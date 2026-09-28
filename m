From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 28 Sep 2026 16:09:16 +0200
Subject: [PATCH] crypto: caam/qi,qi2 - set plain_keylen for skcipher
 descriptors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-for-upstream-caam-qi-plain-keylen-v1-1-6edb56649cf9@free.fr>
X-B4-Tracking: v=1; b=H4sIAAt1umoC/x2NwQ6CMBAFf4Xs2U1oD7T4K8ZDgYduwFK3YCSEf
 7fxMslcZg7KUEGma3WQ4iNZlljEXCrqnyE+wDIUJ1vbpm6t53FR3lJeFeHFfSh4C6c5SOQJ+4z
 IzsJ3jTFw3lHpJMUo3//jdj/PH/OaIRBzAAAA
To: =?utf-8?q?Horia_Geant=C4=83?= <horia.geanta@nxp.com>, 
 Pankaj Gupta <pankaj.gupta@nxp.com>, Gaurav Jain <gaurav.jain@nxp.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, 
 Meenakshi Aggarwal <meenakshi.aggarwal@nxp.com>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790604557; l=2087;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=QDDTvtj++xXIso5yDNVOmdUEzAvrdil+dSqHLZL9pTY=;
 b=5putLZlLd+7hbZ9ZnG1Ls3k50acyXFDRr9A7KEm1OAwn7pwd9DHiGP8GDfNw3DHUvScB1xS4M
 X+1Hgp5PC9HApzvzZJto6dtdGBUgzIxLA9RdowDebMWf49Hw0KkJ/od
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the commit 66b9a095f7f9
  ("crypto: caam - Add support of paes algorithm")

The shared descriptor then loads a zero-length key and the SEC decodes
the inlined key bytes as commands.

Test: with CONFIG_CRYPTO_SELFTESTS on LX2160A every skcipher but xts fails:

  dpaa2_caam dpseci.0: 40000307: DECO: desc idx 3: Invalid LOAD Command
  alg: skcipher: ctr-aes-caam-qi2 encryption failed on test vector 0; expected_error=0, actual_error=-22, cfg="in-place (one sglist)"

caamalg_qi.c is compile-tested only.

Fixes: 66b9a095f7f9 ("crypto: caam - Add support of paes algorithm")
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/crypto/caam/caamalg_qi.c  | 2 ++
 drivers/crypto/caam/caamalg_qi2.c | 2 ++
 2 files changed, 4 insertions(+)

diff --git a/drivers/crypto/caam/caamalg_qi.c b/drivers/crypto/caam/caamalg_qi.c
index aa779caacfe5..2f2682c8bcd8 100644
--- a/drivers/crypto/caam/caamalg_qi.c
+++ b/drivers/crypto/caam/caamalg_qi.c
@@ -637,6 +637,8 @@ static int skcipher_setkey(struct crypto_skcipher *skcipher, const u8 *key,
 	ctx->cdata.keylen = keylen;
 	ctx->cdata.key_virt = key;
 	ctx->cdata.key_inline = true;
+	ctx->cdata.plain_keylen = keylen;
+	ctx->cdata.key_cmd_opt = 0;
 
 	/* skcipher encrypt, decrypt shared descriptors */
 	cnstr_shdsc_skcipher_encap(ctx->sh_desc_enc, &ctx->cdata, ivsize,
diff --git a/drivers/crypto/caam/caamalg_qi2.c b/drivers/crypto/caam/caamalg_qi2.c
index 6b47bcc16a50..d52706931285 100644
--- a/drivers/crypto/caam/caamalg_qi2.c
+++ b/drivers/crypto/caam/caamalg_qi2.c
@@ -961,6 +961,8 @@ static int skcipher_setkey(struct crypto_skcipher *skcipher, const u8 *key,
 	ctx->cdata.keylen = keylen;
 	ctx->cdata.key_virt = key;
 	ctx->cdata.key_inline = true;
+	ctx->cdata.plain_keylen = keylen;
+	ctx->cdata.key_cmd_opt = 0;
 
 	/* skcipher_encrypt shared descriptor */
 	flc = &ctx->flc[ENCRYPT];

---
base-commit: 10396a2d6d41d594975b6ece712278570c3c970c
change-id: 20260928-for-upstream-caam-qi-plain-keylen-72e8b611e787

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

