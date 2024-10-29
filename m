From: Koakuma <koachan@protonmail.com>
Date: Tue, 29 Oct 2024 21:49:08 +0700
Subject: [PATCH v3 2/2] sparc/build: Add SPARC target flags for compiling
 with clang
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241029-sparc-cflags-v3-2-b28745a6bd71@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730213393; l=1720;
 i=koachan@protonmail.com; s=20240620; h=from:subject:message-id;
 bh=qC+xpLMUpGByab1qovPWQQ3aHiMZ1dz7yem8GqVZgaw=;
 b=j3CG9BnJ7FWIRbyhXXEAVLB8dkBqluDHfp9prkX2enPrqN3tWd26RoXX/dgFs1O0iNkgciARn
 sw7SoBukKcCDoNEFREPzB0cpBbb11mSllQ7KnMz+fTX23bhUK2DgdHV
X-Developer-Key: i=koachan@protonmail.com; a=ed25519;
 pk=UA59FS3yiAA1cnAAUZ1rehTmr6skh95PgkNRBLcoKCg=
X-Endpoint-Received: by B4 Relay for koachan@protonmail.com/20240620 with auth_id=174
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

clang only supports building 64-bit kernel, so we use the
sparc64-linux-gnu target.

See also: https://lore.kernel.org/lkml/e26PTXUXEz8OYXmaeKn4Mpuejr4IOlFfFwdB5vpsluXlYiqDdlyQTYcDtdAny_o4gO4SfPeQCCN2qpyT6e0nog5EaP3xk2SeUPTrF54p1gM=@protonmail.com/T/#m068e010dcf8b99d3510a90d7532bcdb70e2e2c6b

Signed-off-by: Koakuma <koachan@protonmail.com>
---
 Documentation/kbuild/llvm.rst | 3 +++
 scripts/Makefile.clang        | 1 +
 2 files changed, 4 insertions(+)

diff --git a/Documentation/kbuild/llvm.rst b/Documentation/kbuild/llvm.rst
index 6dc66b4f31a7bb62ba5bb6174730dc0a69ee0bba..bc8a283bc44bbfa9948ad3c9fe8031269ce10be4 100644
--- a/Documentation/kbuild/llvm.rst
+++ b/Documentation/kbuild/llvm.rst
@@ -179,6 +179,9 @@ yet. Bug reports are always welcome at the issue tracker below!
    * - s390
      - Maintained
      - ``LLVM=1`` (LLVM >= 18.1.0), ``CC=clang`` (LLVM < 18.1.0)
+   * - sparc (sparc64 only)
+     - Maintained
+     - ``CC=clang LLVM_IAS=0`` (LLVM >= 20)
    * - um (User Mode)
      - Maintained
      - ``LLVM=1``
diff --git a/scripts/Makefile.clang b/scripts/Makefile.clang
index 6c23c6af797fb016232914589c948208345417ad..2435efae67f53a26d55a1c0f1bf254a49d9fc731 100644
--- a/scripts/Makefile.clang
+++ b/scripts/Makefile.clang
@@ -10,6 +10,7 @@ CLANG_TARGET_FLAGS_mips		:= mipsel-linux-gnu
 CLANG_TARGET_FLAGS_powerpc	:= powerpc64le-linux-gnu
 CLANG_TARGET_FLAGS_riscv	:= riscv64-linux-gnu
 CLANG_TARGET_FLAGS_s390		:= s390x-linux-gnu
+CLANG_TARGET_FLAGS_sparc	:= sparc64-linux-gnu
 CLANG_TARGET_FLAGS_x86		:= x86_64-linux-gnu
 CLANG_TARGET_FLAGS_um		:= $(CLANG_TARGET_FLAGS_$(SUBARCH))
 CLANG_TARGET_FLAGS		:= $(CLANG_TARGET_FLAGS_$(SRCARCH))

-- 
2.47.0

