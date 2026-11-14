From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 08:44:13 +0000
Subject: [PATCH 1/2] crypto: ecc - Keep the random initial Z below 2^521 on
 P-521
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-ecc-p521-small-scalars-v1-1-7b114f076b33@gmail.com>
References: <20261114-ecc-p521-small-scalars-v1-0-7b114f076b33@gmail.com>
In-Reply-To: <20261114-ecc-p521-small-scalars-v1-0-7b114f076b33@gmail.com>
To: Lukas Wunner <lukas@wunner.de>, Ignat Korchagin <ignat@linux.win>, 
 Stefan Berger <stefanb@linux.ibm.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, 
 Jarkko Sakkinen <jarkko@kernel.org>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Erwin Pawliczek <pawliczekerwin@gmail.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794645852; l=2966;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=wa3uFN73ClJd7AvFAJuDLQdKh5vQeib0sCHSRe3QqSQ=;
 b=FcAzELUZBNaEmGagMVdfvJxjEzQxoUfrIcg9OFBUxu9czlokhL3k0AYFKAEKqwaduWH+AU2X4
 IxbxRS+NBwICAjs296DJcrJeUiF3Ko2yxjUfvTxy6bA4JyQ/XxO7bs0
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Erwin Pawliczek's commit cd65eaf17841 ("crypto: ecc - Randomize the
initial Z in ecc_make_pub_key()") takes the initial Z from ndigits * 8
random bytes, as crypto_ecdh_shared_secret() already did. On P-521 that
is a 576-bit number, but vli_mmod_fast_521() only reduces products of
numbers below 2^521. With a 576-bit Z, every P-521 ecc_make_pub_key()
call returns -EAGAIN. There is no in-tree P-521 caller yet.

Get Z from one helper at both sites that keeps the random bits to the
curve's bit length. The other curves are unchanged.

Tested in UML: P-521 ecc_make_pub_key() now matches a Python reference
for the tested keys from 2^522 - 2n up to n - 3. Smaller keys are fixed
by the next patch. The ecdsa-nist-p521 self-tests still pass.

Fixes: cd65eaf17841 ("crypto: ecc - Randomize the initial Z in ecc_make_pub_key()")
Cc: Erwin Pawliczek <pawliczekerwin@gmail.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 crypto/ecc.c | 20 ++++++++++++--------
 1 file changed, 12 insertions(+), 8 deletions(-)

diff --git a/crypto/ecc.c b/crypto/ecc.c
index 6696bf0d90a6..a56a33e4eccb 100644
--- a/crypto/ecc.c
+++ b/crypto/ecc.c
@@ -1609,13 +1609,22 @@ int ecc_gen_privkey(unsigned int curve_id, unsigned int ndigits,
 }
 EXPORT_SYMBOL(ecc_gen_privkey);
 
+/* Random initial Z for ecc_point_mult(), below 2^nbits */
+static void ecc_rand_z(const struct ecc_curve *curve, u64 *z,
+		       unsigned int ndigits)
+{
+	get_random_bytes(z, ndigits << ECC_DIGITS_TO_BYTES_SHIFT);
+	/* P-521: the fast reduction only takes products of 521-bit numbers */
+	if (curve->nbits % 64)
+		z[ndigits - 1] &= GENMASK_ULL(curve->nbits % 64 - 1, 0);
+}
+
 int ecc_make_pub_key(unsigned int curve_id, unsigned int ndigits,
 		     const u64 *private_key, u64 *public_key)
 {
 	int ret = 0;
 	struct ecc_point *pk;
 	u64 rand_z[ECC_MAX_DIGITS];
-	unsigned int nbytes;
 	const struct ecc_curve *curve = ecc_get_curve(curve_id);
 
 	if (!private_key || ndigits > ARRAY_SIZE(rand_z)) {
@@ -1623,9 +1632,7 @@ int ecc_make_pub_key(unsigned int curve_id, unsigned int ndigits,
 		goto out;
 	}
 
-	nbytes = ndigits << ECC_DIGITS_TO_BYTES_SHIFT;
-
-	get_random_bytes(rand_z, nbytes);
+	ecc_rand_z(curve, rand_z, ndigits);
 
 	pk = ecc_alloc_point(ndigits);
 	if (!pk) {
@@ -1719,7 +1726,6 @@ int crypto_ecdh_shared_secret(unsigned int curve_id, unsigned int ndigits,
 	int ret = 0;
 	struct ecc_point *product, *pk;
 	u64 rand_z[ECC_MAX_DIGITS];
-	unsigned int nbytes;
 	const struct ecc_curve *curve = ecc_get_curve(curve_id);
 
 	if (!private_key || !public_key || ndigits > ARRAY_SIZE(rand_z)) {
@@ -1727,9 +1733,7 @@ int crypto_ecdh_shared_secret(unsigned int curve_id, unsigned int ndigits,
 		goto out;
 	}
 
-	nbytes = ndigits << ECC_DIGITS_TO_BYTES_SHIFT;
-
-	get_random_bytes(rand_z, nbytes);
+	ecc_rand_z(curve, rand_z, ndigits);
 
 	pk = ecc_alloc_point(ndigits);
 	if (!pk) {

-- 
2.55.0

