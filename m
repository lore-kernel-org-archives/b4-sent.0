From: Vladimir Kukharenko <vladimir@genproof.com>
Date: Mon, 12 Oct 2026 21:31:22 +0000
Subject: [PATCH 5/5] lib/crypto: chacha: Take a size_t length in
 chacha_crypt()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-libcrypto-4gib-lengths-v1-5-ea566c129a2e@genproof.com>
References: <20261012-libcrypto-4gib-lengths-v1-0-ea566c129a2e@genproof.com>
In-Reply-To: <20261012-libcrypto-4gib-lengths-v1-0-ea566c129a2e@genproof.com>
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Eric Biggers <ebiggers@kernel.org>, 
 "Jason A. Donenfeld" <Jason@zx2c4.com>, Ard Biesheuvel <ardb@kernel.org>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-mips@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, 
 Vladimir Kukharenko <vladimir@genproof.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791840683; l=3015;
 i=vladimir@genproof.com; s=20261012; h=from:subject:message-id;
 bh=EeWzQrmZlf68OfajrkB+W/t3+tJsiZ8lDU4fkz0igMY=;
 b=/ZTtirlILLZ+d+u1I7hRscr5gq2jf876h7ZB9XwqO0kZdL3/9zpYE3Jyvj7zgU5YdUH/8YzTT
 Vtshyrqsd45AR52IOsPPgryK4vOhyYiganDS1gkEOv9pttEVqP2Rb4H
X-Developer-Key: i=vladimir@genproof.com; a=ed25519;
 pk=EqOzBSKBgFn7ExzKj5f9T8u+1yTrGVlLBwf3fj/sdHM=
X-Endpoint-Received: by B4 Relay for vladimir@genproof.com/20261012 with auth_id=1169
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

chacha20poly1305_encrypt(), chacha20poly1305_decrypt() and the
xchacha20poly1305 variants take size_t lengths.  They pass these lengths
to chacha20_crypt(), which takes an unsigned int.

For a message of 2^32 + k bytes, chacha20_crypt() processes only the
first k bytes.  In-place encryption leaves the remaining bytes as
plaintext.  Until poly1305_update() took a size_t, those bytes were not
authenticated either.  Commit ed20078b7e33 ("crypto: chacha20poly1305 -
import construction and selftest from Zinc") introduced this behavior.

Change chacha_crypt() and chacha20_crypt() to take size_t lengths, as
poly1305_update() and the other library functions do.  The architecture
code takes an unsigned int length.  Split inputs larger than UINT_MAX
into chunks of at most UINT_MAX bytes.  Round each non-final chunk down
to a multiple of CHACHA_BLOCK_SIZE to keep the keystream continuous.

Lengths up to UINT_MAX make the same single call as before.  The
RFC 8439 limit of 2^38 - 64 bytes per message still applies.

No in-tree caller passes messages this large, so this is an ABI
robustness improvement.  I found the bug while writing a Coq/VST proof
of this code with LLM agents, and reproduced it in userspace.

Assisted-by: LLM
Signed-off-by: Vladimir Kukharenko <vladimir@genproof.com>
---
 include/crypto/chacha.h |  4 ++--
 lib/crypto/chacha.c     | 15 ++++++++++++++-
 2 files changed, 16 insertions(+), 3 deletions(-)

diff --git a/include/crypto/chacha.h b/include/crypto/chacha.h
index 1cc301a48469..4c18e99eb4f7 100644
--- a/include/crypto/chacha.h
+++ b/include/crypto/chacha.h
@@ -86,10 +86,10 @@ static inline void chacha_init(struct chacha_state *state,
 }
 
 void chacha_crypt(struct chacha_state *state, u8 *dst, const u8 *src,
-		  unsigned int bytes, int nrounds);
+		  size_t bytes, int nrounds);
 
 static inline void chacha20_crypt(struct chacha_state *state,
-				  u8 *dst, const u8 *src, unsigned int bytes)
+				  u8 *dst, const u8 *src, size_t bytes)
 {
 	chacha_crypt(state, dst, src, bytes, 20);
 }
diff --git a/lib/crypto/chacha.c b/lib/crypto/chacha.c
index 86e5d382a4e0..ffa0c75ce501 100644
--- a/lib/crypto/chacha.c
+++ b/lib/crypto/chacha.c
@@ -39,8 +39,21 @@ chacha_crypt_generic(struct chacha_state *state, u8 *dst, const u8 *src,
 #endif
 
 void chacha_crypt(struct chacha_state *state, u8 *dst, const u8 *src,
-		  unsigned int bytes, int nrounds)
+		  size_t bytes, int nrounds)
 {
+	/*
+	 * chacha_crypt_arch() takes an unsigned int length.  Process longer
+	 * messages in chunks that are a multiple of CHACHA_BLOCK_SIZE, so that
+	 * the keystream continues correctly from one chunk to the next.
+	 */
+	while (bytes > UINT_MAX) {
+		unsigned int l = round_down(UINT_MAX, CHACHA_BLOCK_SIZE);
+
+		chacha_crypt_arch(state, dst, src, l, nrounds);
+		dst += l;
+		src += l;
+		bytes -= l;
+	}
 	chacha_crypt_arch(state, dst, src, bytes, nrounds);
 }
 EXPORT_SYMBOL_GPL(chacha_crypt);

-- 
2.43.0

