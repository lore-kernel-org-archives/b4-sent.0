From: Vladimir Kukharenko <vladimir@genproof.com>
Date: Mon, 12 Oct 2026 21:31:20 +0000
Subject: [PATCH 3/5] lib/crypto: arm64/poly1305: Fix 32-bit length treated
 as 64-bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-libcrypto-4gib-lengths-v1-3-ea566c129a2e@genproof.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791840683; l=1781;
 i=vladimir@genproof.com; s=20261012; h=from:subject:message-id;
 bh=3X4KjNZCvYTpASxJw7cTyOKaRln3LqL4XSBvokwu7TM=;
 b=W2t+f5+yF8aKsOGkWzZBLm4nYHkonWwAO7SmhDYiVEI4JDEB/vmFQan2b6+ZguD/gEb1HKimy
 TOTzMpjGThnCdpj01JXCsli5BOroYcTU+x+DnbWYgOBTXABEvFUFWeG
X-Developer-Key: i=vladimir@genproof.com; a=ed25519;
 pk=EqOzBSKBgFn7ExzKj5f9T8u+1yTrGVlLBwf3fj/sdHM=
X-Endpoint-Received: by B4 Relay for vladimir@genproof.com/20261012 with auth_id=1169
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The C code declares the length argument of poly1305_blocks_arm64() and
poly1305_blocks_neon() as u32, but the assembly, which comes from
OpenSSL/CRYPTOGAMS where the length is a size_t, reads it from the
64-bit register x2.  The arm64 ABI leaves the upper 32 bits of a 32-bit
argument unspecified, and gcc and clang don't zero-extend it.  In
practice the upper bits are zero in the current callers, so I don't
know of a failure.

Declare the length as size_t, as OpenSSL and the x86_64 code do, rather
than changing the imported assembly.  The assembly also reads hibit from
x3, but the callers always pass the constant 0 or 1.

This has been the case since commit f569ca164751 ("crypto:
arm64/poly1305 - incorporate OpenSSL/CRYPTOGAMS NEON implementation").

Assisted-by: LLM
Signed-off-by: Vladimir Kukharenko <vladimir@genproof.com>
---
 lib/crypto/arm64/poly1305.h | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/lib/crypto/arm64/poly1305.h b/lib/crypto/arm64/poly1305.h
index 3d4bde857699..205a7b5fcf47 100644
--- a/lib/crypto/arm64/poly1305.h
+++ b/lib/crypto/arm64/poly1305.h
@@ -14,9 +14,9 @@
 asmlinkage void poly1305_block_init(struct poly1305_block_state *state,
 				    const u8 raw_key[POLY1305_BLOCK_SIZE]);
 asmlinkage void poly1305_blocks_arm64(struct poly1305_block_state *state,
-				      const u8 *src, u32 len, u32 hibit);
+				      const u8 *src, size_t len, u32 hibit);
 asmlinkage void poly1305_blocks_neon(struct poly1305_block_state *state,
-				     const u8 *src, u32 len, u32 hibit);
+				     const u8 *src, size_t len, u32 hibit);
 asmlinkage void poly1305_emit(const struct poly1305_state *state,
 			      u8 digest[POLY1305_DIGEST_SIZE],
 			      const u32 nonce[4]);

-- 
2.43.0

