From: Vladimir Kukharenko <vladimir@genproof.com>
Subject: [PATCH 0/5] lib/crypto: Handle large lengths in poly1305 and
 chacha20poly1305
Date: Mon, 12 Oct 2026 21:31:17 +0000
Message-Id: <20261012-libcrypto-4gib-lengths-v1-0-ea566c129a2e@genproof.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKZRzWoC/yXMQQqDMBBA0avIrDsQoyjtVUoXThzjFImSiaKId
 2/aLt/i/xOUo7DCozgh8iYqc8gobwW4sQueUfpssMY2pTF3nIRcPJY0Y+2FcOLg06joqr5tLNW
 WTAc5XiIPsv/Gz9ffutKbXfre4Lo+98koOXoAAAA=
X-Change-ID: 20261009-libcrypto-4gib-lengths-c3d762b42b0a
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791840683; l=2752;
 i=vladimir@genproof.com; s=20261012; h=from:subject:message-id;
 bh=xNIifAwkZ3zfHyHYKd9B57SvHI2QibtziT5cigfmjhE=;
 b=B2tj45pTmtk9anofHBHKuIunQaJ4YIVf6sAPMRE6NnR+PqTO4gXf5G7YQ6HSQ3nbZwUk52mc6
 urC1etknsSRDRB63j1A5Z3xo93zQm9w3fAKY4uadRO3N3ROLIrvq1nr
X-Developer-Key: i=vladimir@genproof.com; a=ed25519;
 pk=EqOzBSKBgFn7ExzKj5f9T8u+1yTrGVlLBwf3fj/sdHM=
X-Endpoint-Received: by B4 Relay for vladimir@genproof.com/20261012 with auth_id=1169
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series makes the Poly1305 and ChaCha20-Poly1305 library code handle
large lengths:

- poly1305_update() can write past its 16-byte buffer if it holds a
  partial block and nbytes >= 2^32 - desc->buflen.
- The chacha20poly1305 functions use only the low 32 bits of their
  size_t message and associated data lengths.
- On 64-bit MIPS and RISC-V, the poly1305 assembly reads past its input
  for lengths of 2 GiB or more: these ABIs sign-extend its u32 length
  argument, and the assembly uses all 64 bits.  arm64 has the same
  prototype mismatch, with no known failure.

Patches 1-3 fix the assembly prototypes, one architecture per patch.
The assembly already treats the length as 64-bit, so they declare it as
size_t, as commit f3d6cb3dc039 ("lib/crypto: x86/sha1: Migrate
optimized code into library") did for the x86 SHA-1 assembly.
Patches 4 and 5 make poly1305_update() and chacha_crypt() take size_t
lengths.  The patches apply independently, except that on 64-bit MIPS
and RISC-V patch 4 relies on patches 1 and 2 for inputs of 2 GiB or more.

No in-tree caller passes inputs this large (WireGuard passes at most one
packet, big_key at most 1 MiB), so I consider these ABI robustness
improvements rather than fixes and have not added Fixes or Cc stable tags.

I tested with the lib/crypto KUnit suite on UML, x86_64, i386, arm64,
riscv64 and mips64, with a temporary 2 GiB KUnit test on arm64, riscv64
and mips64 (it oopses on riscv64 and mips64 without patches 1 and 2), and
in userspace against OpenSSL for inputs above 4 GiB.

I found the bugs fixed by patches 4 and 5 while writing Coq/VST proofs of
this code with LLM agents, and an LLM review of patch 4 found the one
fixed by patches 1-3.  I used an LLM-based assistant to write the patches
and descriptions, and reviewed its work.

---
Vladimir Kukharenko (5):
      lib/crypto: riscv/poly1305: Fix 32-bit length treated as 64-bit
      lib/crypto: mips/poly1305: Fix 32-bit length treated as 64-bit
      lib/crypto: arm64/poly1305: Fix 32-bit length treated as 64-bit
      lib/crypto: poly1305: Take a size_t length in poly1305_update()
      lib/crypto: chacha: Take a size_t length in chacha_crypt()

 include/crypto/chacha.h     |  4 ++--
 include/crypto/poly1305.h   |  2 +-
 lib/crypto/arm64/poly1305.h |  4 ++--
 lib/crypto/chacha.c         | 15 ++++++++++++++-
 lib/crypto/mips/poly1305.h  |  2 +-
 lib/crypto/poly1305.c       | 14 +++++++-------
 lib/crypto/riscv/poly1305.h |  2 +-
 7 files changed, 28 insertions(+), 15 deletions(-)
---
base-commit: 6a50ce0af5c91fd665d65d357af8ae55db1df7d0
change-id: 20261009-libcrypto-4gib-lengths-c3d762b42b0a

Best regards,
--  
Vladimir Kukharenko <vladimir@genproof.com>

