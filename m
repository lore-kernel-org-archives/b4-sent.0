From: Koakuma <koachan@protonmail.com>
Subject: [PATCH 0/2] sparc/module: R_SPARC_UA64 handling to help with LLVM
 IAS enablement
Date: Mon, 09 Jun 2025 20:53:10 +0700
Message-Id: <20250609-b4-sparc-relocs-v1-0-aa52631735af@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEbnRmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDYwNT3SQT3eKCxKJk3aLUnPzkYl0z08Rkc/PkRAtLIwMloK6CotS0zAq
 widGxtbUA0+z9X2EAAAA=
X-Change-ID: 20250305-b4-sparc-relocs-65ac77ca8920
To: "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <nick.desaulniers+lkml@gmail.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: sparclinux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, Koakuma <koachan@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749477207; l=971;
 i=koachan@protonmail.com; s=20240620; h=from:subject:message-id;
 bh=V+mythbreill/uQ07oLyN3AK3aHIgulv4FDYTI1Uhu0=;
 b=DTvScNJYKi4QCDIPcpVUpBhr7cM6oJp4mKjnD++hSRipZtVeyLWgyFUFxyKQf9lO9wr1ZXLX/
 If7HLxjnZ17CZkF0EP2ln29vZ5SNMbXjYH4DjbHtv1Qe5VpcxAzLRhq
X-Developer-Key: i=koachan@protonmail.com; a=ed25519;
 pk=UA59FS3yiAA1cnAAUZ1rehTmr6skh95PgkNRBLcoKCg=
X-Endpoint-Received: by B4 Relay for koachan@protonmail.com/20240620 with auth_id=174
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello~

This series lets the module loader handle R_SPARC_UA64, which is emitted
by LLVM's IAS in certain conditions. Additionally, I put on a small change
to the error log to make it clearer that the printed relocation number
is in hex.

The intention is to get both the kernel and LLVM in a state where
doing a clang+IAS build is possible.

As with before, on the LLVM side the project is tracked here:
https://github.com/llvm/llvm-project/issues/40792

Signed-off-by: Koakuma <koachan@protonmail.com>
---
Koakuma (2):
      sparc/module: Add R_SPARC_UA64 relocation handling
      sparc/module: Make it clear that relocation numbers are shown in hex

 arch/sparc/include/asm/elf_64.h | 1 +
 arch/sparc/kernel/module.c      | 3 ++-
 2 files changed, 3 insertions(+), 1 deletion(-)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250305-b4-sparc-relocs-65ac77ca8920

Best regards,
-- 
Koakuma <koachan@protonmail.com>

