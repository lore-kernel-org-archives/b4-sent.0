From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:38:29 +0000
Subject: [PATCH v2 2/3] crypto: ecc - Fix P-521 scalar multiplication for
 small scalars
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-ecc-p521-small-scalars-v2-2-0648f492bca4@gmail.com>
References: <20261128-ecc-p521-small-scalars-v2-0-0648f492bca4@gmail.com>
In-Reply-To: <20261128-ecc-p521-small-scalars-v2-0-0648f492bca4@gmail.com>
To: Lukas Wunner <lukas@wunner.de>, Ignat Korchagin <ignat@linux.win>, 
 Stefan Berger <stefanb@linux.ibm.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, 
 Jarkko Sakkinen <jarkko@kernel.org>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Erwin Pawliczek <pawliczekerwin@gmail.com>, 
 Laveesh Bansal <laveeshb@laveeshbansal.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887508; l=1819;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=8swt0d/3mPiEQ4HYrvtUfhuwkb2hZC6GxX5xty+8q9I=;
 b=K0NDjTHjayXNkwFbSVt+Ok2g4Am830fLLpLyH3wzB16QbCFy/GEQsVuM1U38ZSt7A3t3tSfCZ
 0HlYQUWLOP/D7i6Il8y2ih30LDfsUpls/rhmkf2RA8CjUGI/vSDsN3d
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Stefan Berger's commit 114e80437e0e ("crypto: ecc - Add special case
for NIST P521 in ecc_point_mult") made the ladder run on k + n or
k + 2n with bit 522 as the top bit.

For k < n that is always k + 2n, and its bit 522 is set only for
k >= 2^522 - 2n (about 2^259.5). For smaller k the result is
(k + 2^522) * P instead of k * P.

Use k + n if its bit 521 is set, else k + 2n, and start the ladder at
bit 521.

The only in-tree P-521 caller, ecc_is_pubkey_valid_full(), passes
k = n and gets the same result. Its ladder now runs on 2n instead of
3n, as on P-192, P-256 and P-384.

Tested in UML against a Python reference for small k, k on both sides
of 2^522 - 2n and 40 random k. The ecdsa-nist-p521 self-tests still
pass.

Fixes: 114e80437e0e ("crypto: ecc - Add special case for NIST P521 in ecc_point_mult")
Tested-by: Laveesh Bansal <laveeshb@laveeshbansal.com>
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

