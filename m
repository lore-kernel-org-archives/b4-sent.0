From: Vladimir Kukharenko <vladimir@genproof.com>
Subject: [PATCH 0/2] lib/crypto: chacha: Handle lengths of 2 GiB or more on
 32-bit arm and MIPS
Date: Wed, 14 Oct 2026 20:34:20 +0000
Message-Id: <20261014-libcrypto-chacha-32bit-2gib-v1-0-e0719ca0be89@genproof.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE3nz2oC/zWN227CMBAFfyXyc428tpOQqKr4D8SDL2t3C0nAN
 qgV4t8xl0r7MtqjmSvLmAgzG5srS3ihTMtcAT4a5r7NHJGTr8ykkB0I0PxA1qW/Y1l4/dfjSlo
 qXEayvDUKW1SdER2wajgmDPT7tG93L85n+4OuPJTvRcLTuWbLa8YmzNk8s2Pz+V+FVnZCr5RUC
 gQHjpZixJQ3e0wzHlZLil8PnTUZuVumicrYaBF0HwwIAx4G1+ug1waUH3or0cLg22AHtfZsd7v
 dAVdR8MAIAQAA
X-Change-ID: 20261014-libcrypto-chacha-32bit-2gib-5a3e5e36a061
To: Eric Biggers <ebiggers@kernel.org>, 
 "Jason A. Donenfeld" <Jason@zx2c4.com>, Ard Biesheuvel <ardb@kernel.org>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mips@vger.kernel.org, 
 Vladimir Kukharenko <vladimir@genproof.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792010354; l=1694;
 i=vladimir@genproof.com; s=20261012; h=from:subject:message-id;
 bh=COt3GvWqWgF0CxI9plDeQb5zlZ9CoK/iukULf+JUTd8=;
 b=rnntLP2QYnFZTNLD0UoAJH+5N82xB9Y7wkvlKAyjJogo7+gLjT1eGgZHZSfqMxSU84345q47Q
 +cvgDd+YaR9DXMeWRNqIYZDj/OTr3obKCf6qGcBhKWqNd2UzOwlcVWW
X-Developer-Key: i=vladimir@genproof.com; a=ed25519;
 pk=EqOzBSKBgFn7ExzKj5f9T8u+1yTrGVlLBwf3fj/sdHM=
X-Endpoint-Received: by B4 Relay for vladimir@genproof.com/20261012 with auth_id=1169
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On 32-bit arm (the scalar code) and 32-bit MIPS, the ChaCha assembly
treats the length as signed, so lengths of 2 GiB or more are still
mishandled after "lib/crypto: chacha: Use size_t length", since size_t
is 32 bits there.

Patch 1 makes the arm assembly use unsigned conditions.  The MIPS
assembly relies on the sign of the remaining length, so patch 2 instead
limits each call to 1 GiB from C.

This applies on top of
https://lore.kernel.org/r/20261014152604.323310-1-ebiggers@kernel.org
Feel free to fold these into your series instead.

Tested with the lib/crypto KUnit tests in QEMU on arm (Cortex-A7 and
Cortex-A15) and 32-bit MIPS, plus a temporary 2 GiB test on the
Cortex-A7 and QEMU user mode runs of the MIPS assembly.

An LLM review found these bugs; I used an LLM-based assistant to write
the patches and reviewed its work.

---
Vladimir Kukharenko (2):
      lib/crypto: arm/chacha: Handle lengths of 2 GiB or more in scalar code
      lib/crypto: mips/chacha: Handle lengths of 2 GiB or more

 lib/crypto/arm/chacha-scalar-core.S |  8 ++++----
 lib/crypto/arm/chacha.h             |  2 +-
 lib/crypto/mips/chacha-core.S       |  8 ++++----
 lib/crypto/mips/chacha.h            | 20 +++++++++++++++++++-
 4 files changed, 28 insertions(+), 10 deletions(-)
---
base-commit: 40f47fa10a1d19c74f48a13d97b2eb19d5fb938d
change-id: 20261014-libcrypto-chacha-32bit-2gib-5a3e5e36a061
prerequisite-message-id: <20261014152604.323310-1-ebiggers@kernel.org>
prerequisite-patch-id: f66d78884d3d0cf68e1efc9635c084c6b700352f
prerequisite-patch-id: 64c39ea52fe4e25501701ffa262fb3525af29f0b

Best regards,
--  
Vladimir Kukharenko <vladimir@genproof.com>

