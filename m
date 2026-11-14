From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 14 Nov 2026 08:44:14 +0000
Subject: [PATCH 2/2] crypto: ecc - Fix P-521 scalar multiplication for
 small scalars
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-ecc-p521-small-scalars-v1-2-7b114f076b33@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794645852; l=1867;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ChgYZL5sUZcr2EItC0wbDpEzrtX14Y+YYUPb21F2SXA=;
 b=Uc/1ROh6prmhq8ZQxgMFw4YpS+STmEcKmdAaft7SbGrjt4Xtg3MNhB/aHPkICU5x9fZx65b4K
 qkP+z+SgvYsA/0+AlEeDofpQfCyTeweCSoFE5QfvADC00ESqPaItyw6
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Stefan Berger's commit 114e80437e0e ("crypto: ecc - Add special case
for NIST P521 in ecc_point_mult") made the ladder run on k + n or
k + 2n with bit 522 as the top bit.

For k < n, k + n never carries out of the nine digits, so k + 2n is
always used. Its bit 522 is set only for k >= 2^522 - 2n (about
2^259.5); for smaller k the result is (k + 2^522) * P instead of k * P.

Use k + n if its bit 521 is set, else k + 2n, and start the ladder at
bit 521.

No caller is affected today: the only P-521 caller,
ecc_is_pubkey_valid_full(), passes k = n.

Tested in UML on top of the previous patch: ecc_make_pub_key() on
P-521 now matches a Python reference for k = 2, 3, 4, 2^200 + 5, k
around 2^521 - n and 2^522 - 2n, and 40 random k. Before, every k
below 2^522 - 2n was wrong. The ecdsa-nist-p521 self-tests (k = n)
still pass.

Fixes: 114e80437e0e ("crypto: ecc - Add special case for NIST P521 in ecc_point_mult")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 crypto/ecc.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/crypto/ecc.c b/crypto/ecc.c
index a56a33e4eccb..370c60595fa9 100644
--- a/crypto/ecc.c
+++ b/crypto/ecc.c
@@ -1365,11 +1365,14 @@ static void ecc_point_mult(struct ecc_point *result,
 
 	carry = vli_add(sk[0], scalar, curve->n, ndigits);
 	vli_add(sk[1], sk[0], curve->n, ndigits);
-	scalar = sk[!carry];
-	if (curve->nbits == 521)	/* NIST P521 */
-		num_bits = curve->nbits + 2;
-	else
+	if (curve->nbits == 521) {	/* NIST P521 */
+		/* k + n or k + 2n, whichever has bit 521 as its top bit */
+		carry = !!vli_test_bit(sk[0], curve->nbits);
+		num_bits = curve->nbits + 1;
+	} else {
 		num_bits = sizeof(u64) * ndigits * 8 + 1;
+	}
+	scalar = sk[!carry];
 
 	vli_set(rx[1], point->x, ndigits);
 	vli_set(ry[1], point->y, ndigits);

-- 
2.55.0

