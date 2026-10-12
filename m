From: Vladimir Kukharenko <vladimir@genproof.com>
Date: Mon, 12 Oct 2026 21:31:18 +0000
Subject: [PATCH 1/5] lib/crypto: riscv/poly1305: Fix 32-bit length treated
 as 64-bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-libcrypto-4gib-lengths-v1-1-ea566c129a2e@genproof.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791840683; l=1981;
 i=vladimir@genproof.com; s=20261012; h=from:subject:message-id;
 bh=FUk3igHcdyvJr77P9LhCKrgECrkRv7kXrMD3TWIWkCM=;
 b=dyyyhEM/gItvT7Fo5HXi8C3uel40Qr+fe+goqtFZzKvMbMv5Ls7+Z/8XLcKwxhlxwqC5KvITd
 CADJ0jH+RMoCfR/VzHLC0DoHk09yrD44sOW0otUWBXCwpqIsybInjJu
X-Developer-Key: i=vladimir@genproof.com; a=ed25519;
 pk=EqOzBSKBgFn7ExzKj5f9T8u+1yTrGVlLBwf3fj/sdHM=
X-Endpoint-Received: by B4 Relay for vladimir@genproof.com/20261012 with auth_id=1169
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The C code declares the length argument of the assembly function
poly1305_blocks() as u32.  The assembly comes from OpenSSL/CRYPTOGAMS,
which declares the length as size_t, and on riscv64 it uses all 64 bits
of the register.  However, the RISC-V psABI sign-extends 32-bit
arguments, including unsigned ones, to 64 bits.  So for a length of
2 GiB or more, the assembly computes an end pointer 4 GiB lower than the
correct one, below the start of the input, and the loop reads past the
input until it faults.  poly1305_update() passes all complete blocks to
poly1305_blocks() in one call, so a single poly1305_update() of 2 GiB to
4 GiB triggers this.

Declare the length as size_t, as OpenSSL and the x86_64 code do, rather
than changing the imported assembly.  On riscv32, size_t is 32 bits
wide, so nothing changes there.

This bug was introduced by commit bef9c7559869 ("lib/crypto:
riscv/poly1305: Import OpenSSL/CRYPTOGAMS implementation").  No in-tree
caller passes 2 GiB or more in one call, so this is an ABI robustness
improvement.

I reproduced the fault on riscv64 in QEMU with a single 2 GiB
poly1305_update(), and this patch fixes it.

Assisted-by: LLM
Signed-off-by: Vladimir Kukharenko <vladimir@genproof.com>
---
 lib/crypto/riscv/poly1305.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/lib/crypto/riscv/poly1305.h b/lib/crypto/riscv/poly1305.h
index 88f3df44e355..aaf24d0f6674 100644
--- a/lib/crypto/riscv/poly1305.h
+++ b/lib/crypto/riscv/poly1305.h
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

