From: Vladimir Kukharenko <vladimir@genproof.com>
Date: Wed, 14 Oct 2026 20:34:21 +0000
Subject: [PATCH 1/2] lib/crypto: arm/chacha: Handle lengths of 2 GiB or
 more in scalar code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-libcrypto-chacha-32bit-2gib-v1-1-e0719ca0be89@genproof.com>
References: <20261014-libcrypto-chacha-32bit-2gib-v1-0-e0719ca0be89@genproof.com>
In-Reply-To: <20261014-libcrypto-chacha-32bit-2gib-v1-0-e0719ca0be89@genproof.com>
To: Eric Biggers <ebiggers@kernel.org>, 
 "Jason A. Donenfeld" <Jason@zx2c4.com>, Ard Biesheuvel <ardb@kernel.org>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mips@vger.kernel.org, 
 Vladimir Kukharenko <vladimir@genproof.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792010354; l=2466;
 i=vladimir@genproof.com; s=20261012; h=from:subject:message-id;
 bh=pzSd8TFs88R98kv6edfMDr8bkMgX1eosda2YXawMBn0=;
 b=6d7Nwwo7vU9yVqLrOVqivtH2LtgqZSgHFYRvB69uenNRwHXzVyioVyYsBtQ5vU/ktvxcQXpAA
 CNKagi23N0OD3QoMGsqpURHAtta46eZ1XqyZO8jUct9NIKN76SJKvrN
X-Developer-Key: i=vladimir@genproof.com; a=ed25519;
 pk=EqOzBSKBgFn7ExzKj5f9T8u+1yTrGVlLBwf3fj/sdHM=
X-Endpoint-Received: by B4 Relay for vladimir@genproof.com/20261012 with auth_id=1169
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

chacha_doarm() compares the remaining length with signed conditions
(blt, movle/movgt, bgt), and DIV_ROUND_UP(bytes, CHACHA_BLOCK_SIZE) in
chacha_crypt_arch() wraps above 0xffffffc0, so lengths of 2 GiB or
more are mishandled.  size_t is 32 bits on arm, so declaring the length
as size_t does not avoid this.  On a Cortex-A7, an in-place
chacha20_crypt() of 2 GiB + 4101 bytes changed only one byte.

Use unsigned conditions (blo, movls/movhi, bhi) and
DIV_ROUND_UP_POW2().

This affects the scalar code, which is used when NEON isn't usable and
always on Cortex-A5 and Cortex-A7.  No in-tree caller passes such
lengths.  Tested in QEMU on a Cortex-A7 with CONFIG_VMSPLIT_1G.  An LLM
review of this code found the bug.

Assisted-by: LLM
Signed-off-by: Vladimir Kukharenko <vladimir@genproof.com>
---
 lib/crypto/arm/chacha-scalar-core.S | 8 ++++----
 lib/crypto/arm/chacha.h             | 2 +-
 2 files changed, 5 insertions(+), 5 deletions(-)

diff --git a/lib/crypto/arm/chacha-scalar-core.S b/lib/crypto/arm/chacha-scalar-core.S
index 509b2f277b57..d9d0a8cee941 100644
--- a/lib/crypto/arm/chacha-scalar-core.S
+++ b/lib/crypto/arm/chacha-scalar-core.S
@@ -163,7 +163,7 @@
 
 	// Use slow path if fewer than 64 bytes remain.
 	cmp		r11, #64
-	blt		.Lxor_slowpath\@
+	blo		.Lxor_slowpath\@
 
 	// Use slow path if IN and/or OUT isn't 4-byte aligned.  Needed even on
 	// ARMv6+, since ldmia and stmia (used below) still require alignment.
@@ -324,8 +324,8 @@
 	ldr		r14, [sp, #160]		// OUT
 	cmp		r9, #64
 	  mov		r0, sp
-	movle		r1, r9
-	movgt		r1, #64
+	movls		r1, r9
+	movhi		r1, #64
 	// r1 is number of bytes to XOR, in range [1, 64]
 
 .if __LINUX_ARM_ARCH__ < 6
@@ -360,7 +360,7 @@
 .Lxor_slowpath_done\@:
 	subs		r9, #64
 	add		sp, #96
-	bgt		.Lprepare_for_next_block\@
+	bhi		.Lprepare_for_next_block\@
 
 .Ldone\@:
 .endm	// _chacha
diff --git a/lib/crypto/arm/chacha.h b/lib/crypto/arm/chacha.h
index 8ce5375f58aa..5b366f4de78d 100644
--- a/lib/crypto/arm/chacha.h
+++ b/lib/crypto/arm/chacha.h
@@ -78,7 +78,7 @@ static void chacha_crypt_arch(struct chacha_state *state, u8 *dst,
 	if (!IS_ENABLED(CONFIG_KERNEL_MODE_NEON) || !neon_usable() ||
 	    bytes <= CHACHA_BLOCK_SIZE) {
 		chacha_doarm(dst, src, bytes, state, nrounds);
-		state->x[12] += DIV_ROUND_UP(bytes, CHACHA_BLOCK_SIZE);
+		state->x[12] += DIV_ROUND_UP_POW2(bytes, CHACHA_BLOCK_SIZE);
 		return;
 	}
 

-- 
2.43.0

