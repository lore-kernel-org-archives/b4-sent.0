From: Florian Bauckholt <florian.bauckholt@cispa.de>
Date: Thu, 19 Nov 2026 00:19:29 +0100
Subject: [PATCH v2 2/2] KEYS: asymmetric: Fix PKCS#1 decryption of an empty
 message
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-keyctl-pkey-fixes-v2-2-9e2d1c7db7ec@cispa.de>
References: <20261119-keyctl-pkey-fixes-v2-0-9e2d1c7db7ec@cispa.de>
In-Reply-To: <20261119-keyctl-pkey-fixes-v2-0-9e2d1c7db7ec@cispa.de>
To: David Howells <dhowells@redhat.com>, 
 Jarkko Sakkinen <jarkko@kernel.org>, Lukas Wunner <lukas@wunner.de>, 
 Ignat Korchagin <ignat@linux.win>, Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>
Cc: Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>, Hui Peng <benquike@gmail.com>, 
 Stefan Berger <stefanb@linux.ibm.com>, 
 Rodolfo Giometti <giometti@enneenne.com>, keyrings@vger.kernel.org, 
 linux-crypto@vger.kernel.org, linux-security-module@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Florian Bauckholt <florian.bauckholt@cispa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795044005; l=2154;
 i=florian.bauckholt@cispa.de; s=20261105; h=from:subject:message-id;
 bh=61cY2hx+6753NibYFuLl6rSMCEQVY9VLZLVipWWk1vM=;
 b=iX57flM5+ziDYBQrrp9KJ7kUDnjAqKWOgTIfvcM4S0fiRan6GPJMyfgKXEnDX3bFjNNWS3w4q
 GB7GkxeEikiD9yfpiYk3HDJJC6gB7oaIQwQerKvj+g48chhA1UksQao
X-Developer-Key: i=florian.bauckholt@cispa.de; a=ed25519;
 pk=n9klXQ+dI45FWy0qWLrGpQfXU5ylIA0SN+uWSmOx3ok=
X-Endpoint-Received: by B4 Relay for florian.bauckholt@cispa.de/20261105 with auth_id=1420
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KEYCTL_PKEY_DECRYPT with enc=pkcs1 on a valid ciphertext of an empty
message returns the key size instead of 0, and the output buffer is
filled with the ciphertext.

crypto_akcipher_sync_encrypt() returns 0 on success, so
software_key_eds_op() maps a result of 0 to crypto_akcipher_maxsize().
The mapping is applied to decryption as well, but
crypto_akcipher_sync_decrypt() returns the length of the plaintext,
which is 0 for an empty message. By then crypto_akcipher_sync_post()
has copied its scratch buffer to the output. pkcs1pad copied nothing
into that buffer, so it still holds the ciphertext.

Only the caller's own input is returned, so nothing is disclosed, and
messages that are not empty are decrypted correctly. An empty message
is valid, though: RFC 8017 section 7.2 only limits the message length
to k - 11 octets.

Apply the mapping to encryption only.

Fixes: 63ba4d67594a ("KEYS: asymmetric: Use new crypto interface without scatterlists")
Cc: stable@vger.kernel.org # v6.5+
Link: https://lore.kernel.org/all/20260919221742.3709658-1-benquike@gmail.com/
Reviewed-by: Jarkko Sakkinen <jarkko@kernel.org>
Signed-off-by: Florian Bauckholt <florian.bauckholt@cispa.de>
---
 crypto/asymmetric_keys/public_key.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/crypto/asymmetric_keys/public_key.c b/crypto/asymmetric_keys/public_key.c
index 09a0b83d5d77..d71747d93b2c 100644
--- a/crypto/asymmetric_keys/public_key.c
+++ b/crypto/asymmetric_keys/public_key.c
@@ -341,6 +341,9 @@ static int software_key_eds_op(struct kernel_pkey_params *params,
 			break;
 		ret = crypto_akcipher_sync_encrypt(tfm, in, params->in_len,
 						   out, params->out_len);
+		/* Returns 0 on success and always fills the whole output. */
+		if (ret == 0)
+			ret = crypto_akcipher_maxsize(tfm);
 		break;
 	case kernel_pkey_decrypt:
 		if (issig)
@@ -358,9 +361,6 @@ static int software_key_eds_op(struct kernel_pkey_params *params,
 		BUG();
 	}
 
-	if (!issig && ret == 0)
-		ret = crypto_akcipher_maxsize(tfm);
-
 error_free_tfm:
 	if (issig)
 		crypto_free_sig(sig);

-- 
2.56.0

