From: Koakuma <koachan@protonmail.com>
Date: Wed, 17 Jul 2024 23:10:15 +0700
Subject: [PATCH v2 1/2] sparc/build: Remove all usage of -fcall-used* flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240717-sparc-cflags-v2-1-259407e6eb5f@protonmail.com>
References: <20240717-sparc-cflags-v2-0-259407e6eb5f@protonmail.com>
In-Reply-To: <20240717-sparc-cflags-v2-0-259407e6eb5f@protonmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 glaubitz@physik.fu-berlin.de, Masahiro Yamada <masahiroy@kernel.org>, 
 Nicolas Schier <nicolas@fjasle.eu>
Cc: sparclinux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, linux-kbuild@vger.kernel.org, 
 Koakuma <koachan@protonmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721232727; l=2404;
 i=koachan@protonmail.com; s=20240620; h=from:subject:message-id;
 bh=BmBOSeK5N1Oy/bbdHrIC4l2mSYFoxSF/u0TXtn+HPh4=;
 b=MDVSlMcoYXgsyyvNQtnK9WTRCXYuPfjMAj3GvKKG5BXguIwLI3+64HoWlTSXoJtvYHolxIPZQ
 VI+Ux/+2ko0C0mb15ccb41nEUfBNAcPw2n5uAA2Dd+rz808U+R8Z+yE
X-Developer-Key: i=koachan@protonmail.com; a=ed25519;
 pk=UA59FS3yiAA1cnAAUZ1rehTmr6skh95PgkNRBLcoKCg=
X-Endpoint-Received: by B4 Relay for koachan@protonmail.com/20240620 with auth_id=174
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove all usage of -fcall-used* flags so that all flags used are
portable between GCC and clang.

The reasoning is as follows:

In the (normal) 32-bit ABI, %g5 and %g7 is normally reserved, and in
the 64-bit ABI, %g7 is the reserved one.
Linux turns them into volatile registers by the way of -fcall-used-*,
but on the other hand, omitting the flags shouldn't be harmful;
compilers will now simply refuse to touch them, and any assembly
code that happens to touch them would still work like usual (because
Linux' conventions already treats them as volatile anyway).

Signed-off-by: Koakuma <koachan@protonmail.com>
---
 arch/sparc/Makefile      | 4 ++--
 arch/sparc/vdso/Makefile | 2 +-
 2 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/sparc/Makefile b/arch/sparc/Makefile
index 757451c3ea1d..7318a8b452c3 100644
--- a/arch/sparc/Makefile
+++ b/arch/sparc/Makefile
@@ -29,7 +29,7 @@ UTS_MACHINE    := sparc
 # versions of gcc.  Some gcc versions won't pass -Av8 to binutils when you
 # give -mcpu=v8.  This silently worked with older bintutils versions but
 # does not any more.
-KBUILD_CFLAGS  += -m32 -mcpu=v8 -pipe -mno-fpu -fcall-used-g5 -fcall-used-g7
+KBUILD_CFLAGS  += -m32 -mcpu=v8 -pipe -mno-fpu
 KBUILD_CFLAGS  += -Wa,-Av8
 
 KBUILD_AFLAGS  += -m32 -Wa,-Av8
@@ -45,7 +45,7 @@ export BITS   := 64
 UTS_MACHINE   := sparc64
 
 KBUILD_CFLAGS += -m64 -pipe -mno-fpu -mcpu=ultrasparc -mcmodel=medlow
-KBUILD_CFLAGS += -ffixed-g4 -ffixed-g5 -fcall-used-g7 -Wno-sign-compare
+KBUILD_CFLAGS += -ffixed-g4 -ffixed-g5 -Wno-sign-compare
 KBUILD_CFLAGS += -Wa,--undeclared-regs
 KBUILD_CFLAGS += $(call cc-option,-mtune=ultrasparc3)
 KBUILD_AFLAGS += -m64 -mcpu=ultrasparc -Wa,--undeclared-regs
diff --git a/arch/sparc/vdso/Makefile b/arch/sparc/vdso/Makefile
index 243dbfc4609d..e009443145af 100644
--- a/arch/sparc/vdso/Makefile
+++ b/arch/sparc/vdso/Makefile
@@ -46,7 +46,7 @@ CFL := $(PROFILING) -mcmodel=medlow -fPIC -O2 -fasynchronous-unwind-tables -m64
        -fno-omit-frame-pointer -foptimize-sibling-calls \
        -DDISABLE_BRANCH_PROFILING -DBUILD_VDSO
 
-SPARC_REG_CFLAGS = -ffixed-g4 -ffixed-g5 -fcall-used-g5 -fcall-used-g7
+SPARC_REG_CFLAGS = -ffixed-g4 -ffixed-g5
 
 $(vobjs): KBUILD_CFLAGS := $(filter-out $(RANDSTRUCT_CFLAGS) $(GCC_PLUGINS_CFLAGS) $(SPARC_REG_CFLAGS),$(KBUILD_CFLAGS)) $(CFL)
 

-- 
2.45.2

