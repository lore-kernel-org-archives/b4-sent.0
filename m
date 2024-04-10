From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Thu, 11 Apr 2024 00:24:19 +0100
Subject: [PATCH] kbuild/x86: Use $(KBUILD_AFLAGS) in Kbuild's version of
 $(as-instr)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240411-as-instr-opt-wrussq-v1-1-99b1a1a99f93@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKIfF2YC/x3MwQ6CMAyA4VchPdtkjEWIr2I8lFGhBwa2Q00I7
 +7w+B3+fwdjFTa4VTsov8VkSQX1pYI4URoZZSgG73xwoXZIhpIsKy5rxo9uZi8MHcem5ebqXYB
 SrspP+f6v90dxT8bYK6U4na+ZLLPCcfwA/OQD3n4AAAA=
To: Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, Ingo Molnar <mingo@redhat.com>, 
 "H. Peter Anvin" <hpa@zytor.com>, Masahiro Yamada <masahiroy@kernel.org>, 
 Thomas Gleixner <tglx@linutronix.de>, x86@kernel.org
Cc: linux-kernel@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712791479; l=3696;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=+llTpAM1iXzBXWQE4E3YCDwpY226FU9sEdHRM+0QVpA=;
 b=8Y1dDthNatE9Xo7kK5BBVgBX5fExnKyrSVxyAhLa+w7TzV95A+BV7gNVUNoKRliO6m+acwj3rYt4
 kenCR8tzAX9gMGMTbmRDQllZ2+0SgDhz3Kcz3A1eOdUDCXljlqae
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

At Arista some products use compatible 32-bit userspace running on x86.
As a part of disto build for ia32 it also compiles the 64-bit kernel.
While the toolchain for the kernel build is yet the same, with 64-bit gcc:
> / @Bru-na-Boinne% file /usr/bin/gcc-11
> /usr/bin/gcc-11: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=6571ad50d8f12eece053f1bac7a95a2c767f32c9, for GNU/Linux 3.2.0, stripped

It seems that gcc is being smart and detects that it's running in
a 32-bit container (personality flag? 32-bit mmap base? something else
inherited post-exec?  haven't yet figured it out) and by default tries
to build 32-bit binaries.

That results in a failing toolchain check:
> / @Bru-na-Boinne% printf "%b\n" "wrussq %rax, (%rbx)" | /usr/bin/gcc-11 -Wa,--fatal-warnings -c -x assembler-with-cpp -o /dev/null -
> <stdin>: Assembler messages:
> <stdin>:1: Error: `wrussq' is only supported in 64-bit mode

Which passes when -m64 is directly specify for the build check:
> / @Bru-na-Boinne% printf "%b\n" "wrussq %rax, (%rbx)" | /usr/bin/gcc-11 -m64 -Wa,--fatal-warnings -c -x assembler-with-cpp -o /dev/null -
> / @Bru-na-Boinne% echo $?
> 0

As a result, kbuild produces different value for CONFIG_AS_WRUSS
for native 64-bit containers and ia32 containers with 64-bit gcc,
which produces different kernels with enabled/disabled
CONFIG_X86_USER_SHADOW_STACK.

arch/x86/Makefile already properly defines KBUILD_AFLAGS += -m64,
which is luckly already available at the point of toolchain check
in arch/x86/Kconfig.assembler

By hacking around Kbuild variable the following way:
> --- a/scripts/Kconfig.include
> +++ b/scripts/Kconfig.include
> @@ -13,7 +13,8 @@ left_paren  := (
>
>  # $(if-success,<command>,<then>,<else>)
>  # Return <then> if <command> exits with 0, <else> otherwise.
> -if-success = $(shell,{ $(1); } >/dev/null 2>&1 && echo "$(2)" || echo "$(3)")
> +if-success = $(shell,echo '$(1)' 1>&2;{ $(1); } >/dev/null 2>&1 && echo "$(2)" || echo "$(3)")

I got the following output for the toolchain check, before:
> linux @Bru-na-Boinne% make ARCH=x86_64 oldconfig V=1 2>&1 | grep wrus
> printf "%b\n" "wrussq %rax,(%rbx)" | gcc  -c -x assembler-with-cpp -o /dev/null -

and after:
> linux @Bru-na-Boinne% make ARCH=x86_64 oldconfig V=1 2>&1 | grep wrus
> printf "%b\n" "wrussq %rax,(%rbx)" | gcc -D__ASSEMBLY__ -fno-PIE -m64 -c -x assembler-with-cpp -o /dev/null -

Which seems appropriate to me.
This also reflects the existing definition in scripts/Makefile.compiler
for $(as-instr) that already has $(KBUILD_AFLAGS).

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 scripts/Kconfig.include | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/Kconfig.include b/scripts/Kconfig.include
index 3ee8ecfb8c04..d8574c1faf2d 100644
--- a/scripts/Kconfig.include
+++ b/scripts/Kconfig.include
@@ -33,7 +33,7 @@ ld-option = $(success,$(LD) -v $(1))
 
 # $(as-instr,<instr>)
 # Return y if the assembler supports <instr>, n otherwise
-as-instr = $(success,printf "%b\n" "$(1)" | $(CC) $(CLANG_FLAGS) -Wa$(comma)--fatal-warnings -c -x assembler-with-cpp -o /dev/null -)
+as-instr = $(success,printf "%b\n" "$(1)" | $(CC) $(CLANG_FLAGS) $(KBUILD_AFLAGS) -Wa$(comma)--fatal-warnings -c -x assembler-with-cpp -o /dev/null -)
 
 # check if $(CC) and $(LD) exist
 $(error-if,$(failure,command -v $(CC)),C compiler '$(CC)' not found)

---
base-commit: 2c71fdf02a95b3dd425b42f28fd47fb2b1d22702
change-id: 20240410-as-instr-opt-wrussq-48ec37e36204

Best regards,
-- 
Dmitry Safonov <0x7f454c46@gmail.com>

