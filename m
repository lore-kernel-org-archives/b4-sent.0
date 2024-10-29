From: Koakuma <koachan@protonmail.com>
Date: Tue, 29 Oct 2024 21:49:07 +0700
Subject: [PATCH v3 1/2] sparc/build: Put usage of -fcall-used* flags behind
 cc-option
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241029-sparc-cflags-v3-1-b28745a6bd71@protonmail.com>
References: <20241029-sparc-cflags-v3-0-b28745a6bd71@protonmail.com>
In-Reply-To: <20241029-sparc-cflags-v3-0-b28745a6bd71@protonmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 glaubitz@physik.fu-berlin.de, Masahiro Yamada <masahiroy@kernel.org>, 
 Nicolas Schier <nicolas@fjasle.eu>, Jonathan Corbet <corbet@lwn.net>
Cc: sparclinux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, linux-kbuild@vger.kernel.org, 
 linux-doc@vger.kernel.org, Koakuma <koachan@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730213393; l=2721;
 i=koachan@protonmail.com; s=20240620; h=from:subject:message-id;
 bh=j/K37+Baat6IoHsWFp39+kRW4co5mJJ6tRxT2CAjvfU=;
 b=+hjWwxlr7VTHDpLFtlamCVvHi/a0OH/j3VFREyh7jZVAPzEJmwLiEHi3HSeUjllvhM20Uemvd
 cTmir13kw+QD1TCZxCUMeECwfkCF9MB/AMaGO9DaYbHRCEeue6Hqnjs
X-Developer-Key: i=koachan@protonmail.com; a=ed25519;
 pk=UA59FS3yiAA1cnAAUZ1rehTmr6skh95PgkNRBLcoKCg=
X-Endpoint-Received: by B4 Relay for koachan@protonmail.com/20240620 with auth_id=174
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Place -fcall-used* flags behind cc-option so that clang (which doesn't
support them) can still compile the kernel.

This is a safe change, the reasoning is as follows:

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
index 757451c3ea1df63b948e68a45988c78f5974f9ea..0400078076e588be93a702d1c64eb9fd34466075 100644
--- a/arch/sparc/Makefile
+++ b/arch/sparc/Makefile
@@ -29,7 +29,7 @@ UTS_MACHINE    := sparc
 # versions of gcc.  Some gcc versions won't pass -Av8 to binutils when you
 # give -mcpu=v8.  This silently worked with older bintutils versions but
 # does not any more.
-KBUILD_CFLAGS  += -m32 -mcpu=v8 -pipe -mno-fpu -fcall-used-g5 -fcall-used-g7
+KBUILD_CFLAGS  += -m32 -mcpu=v8 -pipe -mno-fpu $(call cc-option,-fcall-used-g5) $(call cc-option,-fcall-used-g7)
 KBUILD_CFLAGS  += -Wa,-Av8
 
 KBUILD_AFLAGS  += -m32 -Wa,-Av8
@@ -45,7 +45,7 @@ export BITS   := 64
 UTS_MACHINE   := sparc64
 
 KBUILD_CFLAGS += -m64 -pipe -mno-fpu -mcpu=ultrasparc -mcmodel=medlow
-KBUILD_CFLAGS += -ffixed-g4 -ffixed-g5 -fcall-used-g7 -Wno-sign-compare
+KBUILD_CFLAGS += -ffixed-g4 -ffixed-g5 $(call cc-option,-fcall-used-g7) -Wno-sign-compare
 KBUILD_CFLAGS += -Wa,--undeclared-regs
 KBUILD_CFLAGS += $(call cc-option,-mtune=ultrasparc3)
 KBUILD_AFLAGS += -m64 -mcpu=ultrasparc -Wa,--undeclared-regs
diff --git a/arch/sparc/vdso/Makefile b/arch/sparc/vdso/Makefile
index 243dbfc4609d804fc221c3591eebe891107ffdab..50ec2978cda5397841daad6ffdc9682811b9b38e 100644
--- a/arch/sparc/vdso/Makefile
+++ b/arch/sparc/vdso/Makefile
@@ -46,7 +46,7 @@ CFL := $(PROFILING) -mcmodel=medlow -fPIC -O2 -fasynchronous-unwind-tables -m64
        -fno-omit-frame-pointer -foptimize-sibling-calls \
        -DDISABLE_BRANCH_PROFILING -DBUILD_VDSO
 
-SPARC_REG_CFLAGS = -ffixed-g4 -ffixed-g5 -fcall-used-g5 -fcall-used-g7
+SPARC_REG_CFLAGS = -ffixed-g4 -ffixed-g5 $(call cc-option,-fcall-used-g5) $(call cc-option,-fcall-used-g7)
 
 $(vobjs): KBUILD_CFLAGS := $(filter-out $(RANDSTRUCT_CFLAGS) $(GCC_PLUGINS_CFLAGS) $(SPARC_REG_CFLAGS),$(KBUILD_CFLAGS)) $(CFL)
 

-- 
2.47.0

