From: Daniel Gomez <da.gomez@samsung.com>
Date: Fri, 06 Sep 2024 13:01:29 +0200
Subject: [PATCH v2 2/8] file2alias: fix uuid_t definitions for macos
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240906-macos-build-support-v2-2-06beff418848@samsung.com>
References: <20240906-macos-build-support-v2-0-06beff418848@samsung.com>
In-Reply-To: <20240906-macos-build-support-v2-0-06beff418848@samsung.com>
To: Masahiro Yamada <masahiroy@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nicolas@fjasle.eu>, 
 Lucas De Marchi <lucas.demarchi@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, William Hubbs <w.d.hubbs@gmail.com>, 
 Chris Brannon <chris@the-brannons.com>, Kirk Reiser <kirk@reisers.ca>, 
 Samuel Thibault <samuel.thibault@ens-lyon.org>, 
 Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>, 
 Ondrej Mosnacek <omosnace@redhat.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 James Morse <james.morse@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Simona Vetter <simona.vetter@ffwll.ch>
Cc: linux-kernel@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 intel-xe@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 speakup@linux-speakup.org, selinux@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-serial@vger.kernel.org, llvm@lists.linux.dev, 
 Finn Behrens <me@kloenk.dev>, 
 "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725620498; l=10491;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=kEoEyvruU1xrPTnRzMVPNv/DX5W819KO2SPMHt88X9k=;
 b=zvtijQv+MlRcQEW1UxGj5ftHZV4daT/doF2R2i3mC2QdO36IpAm4k54Mo9R6dylpW1kAX3wl8
 V9KDI1IPuv8BNr7uRX/2M7DXWnZ8WXLYzBkClN04ARgNGx++SwQYVZp
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The uuid_t struct defined in sys/types.h on macOS hosts conflicts with
the one defined in file2alias, resulting in the typedef redefinition
error below. To resolve this conflict, define the _UUID_T and
__GETHOSTUUID_ in file2alias HOSTCFLAGS.

Error:
  HOSTCC  scripts/mod/file2alias.o scripts/mod/file2alias.c:45:3:
error: typedef redefinition with different types ('struct uuid_t' vs
'__darwin_uuid_t' (aka 'unsigned char[16]'))    45 | } uuid_t;       |
^
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   sys/_types/_uuid_t.h:31:25: note: previous definition is here 31 |
   typedef __darwin_uuid_t uuid_t;    |                         ^
scripts/mod/file2alias.c:1354:7: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1354 |
 uuid->b[0], uuid->b[1], uuid->b[2], uuid->b[3], uuid->b[4],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1354:19: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1354 |
 uuid->b[0], uuid->b[1], uuid->b[2], uuid->b[3], uuid->b[4],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1354:31: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1354 |
 uuid->b[0], uuid->b[1], uuid->b[2], uuid->b[3], uuid->b[4],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1354:43: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1354 |
 uuid->b[0], uuid->b[1], uuid->b[2], uuid->b[3], uuid->b[4],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1354:55: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1354 |
 uuid->b[0], uuid->b[1], uuid->b[2], uuid->b[3], uuid->b[4],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1355:7: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1355 |
 uuid->b[5], uuid->b[6], uuid->b[7], uuid->b[8], uuid->b[9],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1355:19: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1355 |
 uuid->b[5], uuid->b[6], uuid->b[7], uuid->b[8], uuid->b[9],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1355:31: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1355 |
 uuid->b[5], uuid->b[6], uuid->b[7], uuid->b[8], uuid->b[9],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1355:43: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1355 |
 uuid->b[5], uuid->b[6], uuid->b[7], uuid->b[8], uuid->b[9],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1355:55: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1355 |
 uuid->b[5], uuid->b[6], uuid->b[7], uuid->b[8], uuid->b[9],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1356:7: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1356 |
 uuid->b[10], uuid->b[11], uuid->b[12], uuid->b[13], uuid->b[14],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1356:20: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1356 |
 uuid->b[10], uuid->b[11], uuid->b[12], uuid->b[13], uuid->b[14],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1356:33: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1356 |
 uuid->b[10], uuid->b[11], uuid->b[12], uuid->b[13], uuid->b[14],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1356:46: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1356 |
 uuid->b[10], uuid->b[11], uuid->b[12], uuid->b[13], uuid->b[14],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1356:59: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1356 |
 uuid->b[10], uuid->b[11], uuid->b[12], uuid->b[13], uuid->b[14],      |
 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
scripts/mod/file2alias.c:1357:7: error: member reference base
 type 'typeof (((struct tee_client_device_id *)0)->uuid)' (aka
 'unsigned char[16]') is not a structure or union 1357 |
 uuid->b[15]);      |                 ~~~~^ ~
/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk/usr/include/
   secure/_stdio.h:47:56: note: expanded from macro 'sprintf' 47 |
   __builtin___sprintf_chk (str, 0, __darwin_obsz(str), __VA_ARGS__)
   |                                                        ^~~~~~~~~~~
17 errors generated.

Suggested-by: Nicolas Schier <nicolas@fjasle.eu>
Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/mod/Makefile     | 2 ++
 scripts/mod/file2alias.c | 3 +++
 2 files changed, 5 insertions(+)

diff --git a/scripts/mod/Makefile b/scripts/mod/Makefile
index c729bc936bae..75c12c045f21 100644
--- a/scripts/mod/Makefile
+++ b/scripts/mod/Makefile
@@ -8,6 +8,8 @@ modpost-objs	:= modpost.o file2alias.o sumversion.o symsearch.o
 
 devicetable-offsets-file := devicetable-offsets.h
 
+HOSTCFLAGS_file2alias.o += -D_UUID_T -D__GETHOSTUUID_H
+
 $(obj)/$(devicetable-offsets-file): $(obj)/devicetable-offsets.s FORCE
 	$(call filechk,offsets,__DEVICETABLE_OFFSETS_H__)
 
diff --git a/scripts/mod/file2alias.c b/scripts/mod/file2alias.c
index 99dce93a4188..ab743f6d60ef 100644
--- a/scripts/mod/file2alias.c
+++ b/scripts/mod/file2alias.c
@@ -11,6 +11,9 @@
  */
 
 #include "modpost.h"
+#ifdef __APPLE__
+#define uuid_t sys_uuid_t
+#endif
 #include "devicetable-offsets.h"
 
 /* We use the ELF typedefs for kernel_ulong_t but bite the bullet and

-- 
2.46.0

