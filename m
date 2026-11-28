From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 18:23:46 +0000
Subject: [PATCH 6.12.y] crypto: nx - fix nx_crypto_ctx_exit argument
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-nx-612-v1-1-7610a67512f3@certik.com>
X-B4-Tracking: v=1; b=H4sIADEcC2sC/yWMQQrCMBAAv1L27Faz6lb8inhI0tVGJJFslUrp3
 03scYZhZlDJQRTOzQxZPkFDigXMpgE/2HgXDH1hoB2xMXTCOCEbQhahjln2x0MHJX5luYXpP7o
 At4baL1xXr2/3ED/WSy2dVUGXbfRDVSqxH1N6YvXb9Q7L8gORPdlmmQAAAA==
X-Change-ID: 20261128-nx-612-6ee2766e3547
To: stable@vger.kernel.org
Cc: Sam James <sam@gentoo.org>, Herbert Xu <herbert@gondor.apana.org.au>, 
 Eric Biggers <ebiggers@kernel.org>, leitao@debian.org, 
 Nayna Jain <nayna@linux.ibm.com>, 
 Paulo Flabiano Smorigo <pfsmorigo@gmail.com>, linux-crypto@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795890225; l=3358;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=aB4HR+znA9D6EQ8XLQLZ4whL3VZ/EVrQCTXfZ2ow9oc=;
 b=P640s0WQ+DNkyjd7te2JL8BcjfeBU5hCvfXQ9A5yBTz3enPCx7ZTLjTzhXk5blYaJa8wZNTZe
 gi2JUsneFSiCJjsSkyLQgBvdWUM0Y6sxFGIzhC9JACWfzcin90VNiM+
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sam James <sam@gentoo.org>

commit 4e67f504ee9ded15e256b64f4fde150e917381d7 upstream.

nx_crypto_ctx_shash_exit calls nx_crypto_ctx_exit with crypto_shash_ctx(...)
but crypto_shash_ctx gives a nx_crypto_ctx *, not a crypto_tfm *.

Fix the type in nx_crypto_ctx_exit and drop the bogus crypto_tfm_ctx
call.

This fixes the following oops:

  BUG: Unable to handle kernel data access at 0xc0403effffffffc8
  Faulting instruction address: 0xc000000000396cb4
  Oops: Kernel access of bad area, sig: 11 [#15]
  Call Trace:
   nx_crypto_ctx_shash_exit+0x24/0x60
   crypto_shash_exit_tfm+0x28/0x40
   crypto_destroy_tfm+0x98/0x140
   crypto_exit_ahash_using_shash+0x20/0x40
   crypto_destroy_tfm+0x98/0x140
   hash_release+0x1c/0x30
   alg_sock_destruct+0x38/0x60
   __sk_destruct+0x48/0x2b0
   af_alg_release+0x58/0xb0
   __sock_release+0x68/0x150
   sock_close+0x20/0x40
   __fput+0x110/0x3a0
   sys_close+0x48/0xa0
   system_call_exception+0x140/0x2d0
   system_call_common+0xf4/0x258

.. which came from hardlink(1) opportunistically using AF_ALG.

The same problem exists with nx_crypto_ctx_skcipher_exit getting a context
it wasn't expecting, but apparently nobody hit that for years.

Cc: Eric Biggers <ebiggers@kernel.org>
Cc: stable@vger.kernel.org
Fixes: bfd9efddf990 ("crypto: nx - convert AES-ECB to skcipher API")
Fixes: 9420e628e7d8 ("crypto: nx - Use API partial block handling")
Acked-by: Breno Leitao <leitao@debian.org>
Reviewed-by: Eric Biggers <ebiggers@kernel.org>
Reported-by: Calvin Buckley <calvin@cmpct.info>
Tested-by: Calvin Buckley <calvin@cmpct.info>
Suggested-by: Brad Spengler <brad.spengler@opensrcsec.com>
Signed-off-by: Sam James <sam@gentoo.org>
Signed-off-by: Herbert Xu <herbert@gondor.apana.org.au>
[ adapted to 6.12.y: pass the skcipher tfm to the legacy exit helper ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This one never made it to 6.12.y. The shash half of the upstream fix
doesn't apply here, since 6.12 predates 9420e628e7d8, but the skcipher
half does: nx_crypto_ctx_skcipher_exit() still passes the skcipher ctx
where nx_crypto_ctx_exit() expects a crypto_tfm. The backport passes
crypto_skcipher_tfm(tfm), so the exit finds the same nx_crypto_ctx
that the aes_*_init() helpers set up through crypto_skcipher_ctx().

Tested on 6.12 (e2e4b92c2b2a): big-endian ppc64 pSeries W=1
cross-build of drivers/crypto/nx, base vs patched, no new warnings.
Build-only - I don't have NX hardware, so nothing ran.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/crypto/nx/nx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/crypto/nx/nx.c b/drivers/crypto/nx/nx.c
index 010e87d9da36..e9186ff33945 100644
--- a/drivers/crypto/nx/nx.c
+++ b/drivers/crypto/nx/nx.c
@@ -756,7 +756,7 @@ void nx_crypto_ctx_exit(struct crypto_tfm *tfm)
 
 void nx_crypto_ctx_skcipher_exit(struct crypto_skcipher *tfm)
 {
-	nx_crypto_ctx_exit(crypto_skcipher_ctx(tfm));
+	nx_crypto_ctx_exit(crypto_skcipher_tfm(tfm));
 }
 
 void nx_crypto_ctx_aead_exit(struct crypto_aead *tfm)

---
base-commit: e2e4b92c2b2a3ae78423cb343951cb5d2241b405
change-id: 20261128-nx-612-6ee2766e3547

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

