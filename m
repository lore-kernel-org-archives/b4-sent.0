From: Vladimir Kukharenko <vladimir@genproof.com>
Date: Mon, 12 Oct 2026 21:31:19 +0000
Subject: [PATCH 2/5] lib/crypto: mips/poly1305: Fix 32-bit length treated
 as 64-bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-libcrypto-4gib-lengths-v1-2-ea566c129a2e@genproof.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791840683; l=2076;
 i=vladimir@genproof.com; s=20261012; h=from:subject:message-id;
 bh=fo5zvO7UGWzgKX7Y6Cw4E2/Klsa+sRLhgZA+i34R0sg=;
 b=qNZ/9YoLUTr8vXw0bDqkJZS43lC7EbywsG6X/i3+sSaB8XXjEggmfsTbfNvgZUWX0Tu6pxc7B
 To4AbqoJXZaAUjuzCKv2HtNnM2a74xvrwkGl+SRB1gqKqFv4A28EdkB
X-Developer-Key: i=vladimir@genproof.com; a=ed25519;
 pk=EqOzBSKBgFn7ExzKj5f9T8u+1yTrGVlLBwf3fj/sdHM=
X-Endpoint-Received: by B4 Relay for vladimir@genproof.com/20261012 with auth_id=1169
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The C code declares the length argument of the assembly function
poly1305_blocks() as u32.  The assembly comes from OpenSSL/CRYPTOGAMS,
which declares the length as size_t, and its 64-bit flavour uses all
64 bits of the register.  However, the MIPS n64 ABI keeps 32-bit values,
including unsigned ones, sign-extended in 64-bit registers.  So for a
length of 2 GiB or more, the assembly computes an end pointer 4 GiB
lower than the correct one, below the start of the input, and the loop
reads past the input until it faults.  poly1305_update() passes all
complete blocks to poly1305_blocks() in one call, so a single
poly1305_update() of 2 GiB to 4 GiB triggers this on 64-bit kernels.

Declare the length as size_t, as OpenSSL and the x86_64 code do, rather
than changing the imported assembly.  32-bit kernels use the o32 flavour
of the assembly, and size_t is 32 bits wide there, so nothing changes
for them.

This bug was introduced by commit a11d055e7a64 ("crypto: mips/poly1305 -
incorporate OpenSSL/CRYPTOGAMS optimized implementation").  No in-tree
caller passes 2 GiB or more in one call, so this is an ABI robustness
improvement.

I reproduced the fault on mips64 in QEMU with a single 2 GiB
poly1305_update(), and this patch fixes it.

Assisted-by: LLM
Signed-off-by: Vladimir Kukharenko <vladimir@genproof.com>
---
 lib/crypto/mips/poly1305.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/lib/crypto/mips/poly1305.h b/lib/crypto/mips/poly1305.h
index 85de450f1a93..9e9147f40d17 100644
--- a/lib/crypto/mips/poly1305.h
+++ b/lib/crypto/mips/poly1305.h
@@ -8,7 +8,7 @@
 asmlinkage void poly1305_block_init(struct poly1305_block_state *state,
 				    const u8 raw_key[POLY1305_BLOCK_SIZE]);
 asmlinkage void poly1305_blocks(struct poly1305_block_state *state,
-				const u8 *src, u32 len, u32 hibit);
+				const u8 *src, size_t len, u32 hibit);
 asmlinkage void poly1305_emit(const struct poly1305_state *state,
 			      u8 digest[POLY1305_DIGEST_SIZE],
 			      const u32 nonce[4]);

-- 
2.43.0

