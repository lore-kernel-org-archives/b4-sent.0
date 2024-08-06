From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 07 Aug 2024 01:09:25 +0200
Subject: [PATCH 11/12] tty/vt: conmakehash requires linux/limits.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240807-macos-build-support-v1-11-4cd1ded85694@samsung.com>
References: <20240807-macos-build-support-v1-0-4cd1ded85694@samsung.com>
In-Reply-To: <20240807-macos-build-support-v1-0-4cd1ded85694@samsung.com>
To: Masahiro Yamada <masahiroy@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nicolas@fjasle.eu>, 
 Lucas De Marchi <lucas.demarchi@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Daniel Vetter <daniel@ffwll.ch>, 
 William Hubbs <w.d.hubbs@gmail.com>, Chris Brannon <chris@the-brannons.com>, 
 Kirk Reiser <kirk@reisers.ca>, 
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
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: linux-kernel@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 intel-xe@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 speakup@linux-speakup.org, selinux@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-serial@vger.kernel.org, llvm@lists.linux.dev, 
 Finn Behrens <me@kloenk.dev>, 
 "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722985800; l=1705;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=GlY+ZLQcYSKSN3SyY915ZDHwX28gVnVDJorFIIf1+Jo=;
 b=TXC+qEwbi6LwhRfspoNf9uCJM5mS5rpVYHpZ3bnRG1KFrfzm+UI/apLoI43ShxbZHbpUUEVBL
 CkbYZiLdsfUA4G8wSWyMc3cIK3tGKT6BD0jGlYhjBBXl1eg0MflhqKS
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

macOS hosts do not provide the linux/limits.h header required for
conmakehash. To address this, ensure that usr/include is included in
the conmakehash HOSTCFLAGS. This will provide the necessary header for
successful compilation on macOS.

Fixes error:
HOSTCC  drivers/tty/vt/conmakehash - due to target missing
  clang -Wp,-MMD,drivers/tty/vt/.conmakehash.d -Wall
-Wmissing-prototypes -Wstrict-prototypes -O2 -fomit-frame-pointer
-std=gnu11   -I ./scripts/include     -o drivers/tty/vt/conmakehash
drivers/tty/vt/conmakehash.c
drivers/tty/vt/conmakehash.c:15:10: fatal error: 'linux/
   limits.h' file not found 15 | #include <linux/limits.h>    |
   ^~~~~~~~~~~~~~~~
1 error generated.
make[5]: *** [scripts/Makefile.host:116: drivers/tty/vt/conmakehash]
Error 1
make[4]: *** [scripts/Makefile.build:485: drivers/tty/vt] Error 2
make[3]: *** [scripts/Makefile.build:485: drivers/tty] Error 2
make[2]: *** [scripts/Makefile.build:485: drivers] Error 2
make[1]: *** [/Volumes/src/kernel/linux-next/Makefile:1925: .] Error 2
make: *** [Makefile:224: __sub-make] Error 2

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 drivers/tty/vt/Makefile | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/tty/vt/Makefile b/drivers/tty/vt/Makefile
index 2c8ce8b592ed..d266895357e5 100644
--- a/drivers/tty/vt/Makefile
+++ b/drivers/tty/vt/Makefile
@@ -13,6 +13,7 @@ obj-$(CONFIG_CONSOLE_TRANSLATIONS)	+= consolemap.o consolemap_deftbl.o
 clean-files := consolemap_deftbl.c defkeymap.c
 
 hostprogs += conmakehash
+HOSTCFLAGS_conmakehash.o = -I$(srctree)/usr/include
 
 quiet_cmd_conmk = CONMK   $@
       cmd_conmk = $(obj)/conmakehash $< > $@

-- 
Git-146)

