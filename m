From: Wesley Atwell <atwellwea@gmail.com>
Date: Fri, 27 Nov 2026 22:54:25 -0700
Subject: [PATCH] crypto: mldsa - report correct sizes for keyctl
 verification
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-mldsa-keyctl-sizing-v1-1-9ff5b4345cce@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MUQ6CMAwA0Ks0/V4TNtHprmL8GKNAI0yyEqMQ7
 k70HeBtqFyEFQNsWPgtKq+MAawBTEPMPZO0GABd5S7WOk/T2GqkJ3/TMpLKKrmn2l+dr89d5U8
 3NIBz4U4+//X+MIBNVKamxJyG3zVFXbjgvh+G5AiGfgAAAA==
X-Change-ID: 20261127-mldsa-keyctl-sizing-4782745f0739
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>
Cc: keyrings@vger.kernel.org, Ignat Korchagin <ignat@linux.win>, 
 linux-crypto@vger.kernel.org, Jarkko Sakkinen <jarkko@kernel.org>, 
 David Howells <dhowells@redhat.com>, Lukas Wunner <lukas@wunner.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795845276; l=5264;
 i=atwellwea@gmail.com; s=20261127; h=from:subject:message-id;
 bh=gL5uvRWcy+UhykJUrDnQWcxJi/24PYvJiGeIvNoXXiI=;
 b=N4f3cOr95LqB3YnzdstBIM62Pm1jix+3fnK5e4DQwNFWYeU82FtNa+2gJdFEqujjPKvciAQCQ
 LrQSkDits5fACnw4TyE/NHJr/q+l3Jsui9P09KdcdPWKNWhv3m3IyIX
X-Developer-Key: i=atwellwea@gmail.com; a=ed25519;
 pk=Buny5Y3000rYoA3OYcxvjG5W3dpuSWh28lf8IVDjANo=
X-Endpoint-Received: by B4 Relay for atwellwea@gmail.com/20261127 with auth_id=1671
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A user can import an ML-DSA X.509 public certificate into a session
keyring and verify a detached signature with keyctl pkey_verify. Pure
ML-DSA verifies the raw message with hash=none. The ML-DSA key_size
callback returns the public-key length in bytes, although crypto_sig
requires key size in bits. The generic digest_size fallback then
divides that value by eight, so an ML-DSA-44 query reports a 1312-bit
key and a 164-byte maximum input. keyctl rejects longer valid messages
before calling the verifier.

In a Fedora keyutils guest, verification of a valid signature over a
164-byte message succeeded, while verification of valid signatures
over 165-byte and 1 KiB messages failed with -EINVAL. OpenSSL
verified all three signatures. This affects direct keyctl verification;
it does not establish a failure in module or PKCS#7 verification.

Keep public-key length checking in bytes and report crypto_sig key_size
in bits. In software_key_query(), report U16_MAX as the ML-DSA
max_data_size instead of deriving that raw-message limit from
crypto_sig_digestsize(). keyctl's max_data_size is a 16-bit field, and
pure ML-DSA verifies the full message rather than a fixed-size digest.
This allows keyctl to pass messages up to the largest size its query
interface can represent.

The post-fix keyutils guest verified 4 KiB inputs with all three
ML-DSA strengths, accepted 65535 bytes for ML-DSA-44, and rejected
65536 bytes at the keyctl interface boundary.

OpenAI Codex identified the key-size unit mismatch during source
review, prepared the keyutils/QEMU reproducer, generated the signed
fixtures, and proposed the two-file change. The unmodified and changed
kernels were tested with Fedora keyctl as UID 65534 using signatures
independently verified by OpenSSL.

Fixes: d3b6dd90e23e ("crypto: Add ML-DSA crypto_sig support")
Signed-off-by: Wesley Atwell <atwellwea@gmail.com>
---
 crypto/asymmetric_keys/public_key.c | 18 ++++++++++++++----
 crypto/mldsa.c                      |  9 +++++++--
 2 files changed, 21 insertions(+), 6 deletions(-)

diff --git a/crypto/asymmetric_keys/public_key.c b/crypto/asymmetric_keys/public_key.c
index d71747d93..03f4593c9 100644
--- a/crypto/asymmetric_keys/public_key.c
+++ b/crypto/asymmetric_keys/public_key.c
@@ -15,6 +15,7 @@
 #include <linux/asn1.h>
 #include <linux/err.h>
 #include <linux/kernel.h>
+#include <linux/limits.h>
 #include <linux/module.h>
 #include <linux/seq_file.h>
 #include <linux/slab.h>
@@ -58,6 +59,13 @@ static void public_key_destroy(void *payload0, void *payload3)
 	public_key_signature_free(payload3);
 }
 
+static bool public_key_is_mldsa(const struct public_key *pkey)
+{
+	return strcmp(pkey->pkey_algo, "mldsa44") == 0 ||
+	       strcmp(pkey->pkey_algo, "mldsa65") == 0 ||
+	       strcmp(pkey->pkey_algo, "mldsa87") == 0;
+}
+
 /*
  * Given a public_key, and an encoding and hash_algo to be used for signing
  * and/or verification with that key, determine the name of the corresponding
@@ -142,9 +150,7 @@ software_key_determine_akcipher(const struct public_key *pkey,
 		if (strcmp(hash_algo, "streebog256") != 0 &&
 		    strcmp(hash_algo, "streebog512") != 0)
 			return -EINVAL;
-	} else if (strcmp(pkey->pkey_algo, "mldsa44") == 0 ||
-		   strcmp(pkey->pkey_algo, "mldsa65") == 0 ||
-		   strcmp(pkey->pkey_algo, "mldsa87") == 0) {
+	} else if (public_key_is_mldsa(pkey)) {
 		if (strcmp(encoding, "raw") != 0)
 			return -EINVAL;
 		if (!hash_algo)
@@ -217,7 +223,11 @@ static int software_key_query(const struct kernel_pkey_params *params,
 		len = crypto_sig_keysize(sig);
 		info->key_size = len;
 		info->max_sig_size = crypto_sig_maxsize(sig);
-		info->max_data_size = crypto_sig_digestsize(sig);
+		/* Pure ML-DSA verifies raw messages, not fixed-size digests. */
+		if (public_key_is_mldsa(pkey))
+			info->max_data_size = U16_MAX;
+		else
+			info->max_data_size = crypto_sig_digestsize(sig);
 
 		info->supported_ops = KEYCTL_SUPPORTS_VERIFY;
 		if (pkey->key_is_private)
diff --git a/crypto/mldsa.c b/crypto/mldsa.c
index d8de082cc..4753940d4 100644
--- a/crypto/mldsa.c
+++ b/crypto/mldsa.c
@@ -36,7 +36,7 @@ static int crypto_mldsa_verify(struct crypto_sig *tfm,
 			    ctx->pk, ctx->pk_len);
 }
 
-static unsigned int crypto_mldsa_key_size(struct crypto_sig *tfm)
+static unsigned int crypto_mldsa_public_key_len(struct crypto_sig *tfm)
 {
 	struct crypto_mldsa_ctx *ctx = crypto_sig_ctx(tfm);
 
@@ -53,11 +53,16 @@ static unsigned int crypto_mldsa_key_size(struct crypto_sig *tfm)
 	}
 }
 
+static unsigned int crypto_mldsa_key_size(struct crypto_sig *tfm)
+{
+	return crypto_mldsa_public_key_len(tfm) * BITS_PER_BYTE;
+}
+
 static int crypto_mldsa_set_pub_key(struct crypto_sig *tfm,
 				    const void *key, unsigned int keylen)
 {
 	struct crypto_mldsa_ctx *ctx = crypto_sig_ctx(tfm);
-	unsigned int expected_len = crypto_mldsa_key_size(tfm);
+	unsigned int expected_len = crypto_mldsa_public_key_len(tfm);
 
 	if (keylen != expected_len)
 		return -EINVAL;

---
base-commit: 9fb9278d13dca54ce7ecd3254c7df8839e59f03d
change-id: 20261127-mldsa-keyctl-sizing-4782745f0739

Best regards,
-- 
Wesley Atwell <atwellwea@gmail.com>

