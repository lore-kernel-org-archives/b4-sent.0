From: Daniel Gomez <da.gomez@samsung.com>
Date: Fri, 06 Sep 2024 13:01:31 +0200
Subject: [PATCH v2 4/8] arm64: nvhe: add bee-headers support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240906-macos-build-support-v2-4-06beff418848@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725620498; l=2402;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=GBZv2DjLBaUWb0PDIN6CGSbBXyjcjj4bMncdBaf72Bg=;
 b=yNvjUITe4cvXufxVrbYIve+SAb1jzGrq0iUGR/YAun7lLTKIwhk8EC7uDEMgN45dqdtRk38Jy
 pDk3TLY/uhoBnN1Zcnbu2S82L1cVlw0uRFYjv554A/iIpET4qlSs/in
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

endian.h header is not provided by default in macOS. Use pkg-config with
the new development package 'bee-headers' [1] to find the path where the
headers are installed.

[1] Bee Headers Project links:
https://github.com/bee-headers/headers
https://github.com/bee-headers/homebrew-bee-headers

It requires to install bee-headers Homebrew Tap:

  brew tap bee-headers/bee-headers
  brew install bee-headers/bee-headers/bee-headers

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 arch/arm64/kernel/pi/Makefile     | 1 +
 arch/arm64/kernel/vdso32/Makefile | 1 +
 arch/arm64/kvm/hyp/nvhe/Makefile  | 3 ++-
 3 files changed, 4 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/kernel/pi/Makefile b/arch/arm64/kernel/pi/Makefile
index 4d11a8c29181..259c9a45fba0 100644
--- a/arch/arm64/kernel/pi/Makefile
+++ b/arch/arm64/kernel/pi/Makefile
@@ -20,6 +20,7 @@ KBUILD_CFLAGS	:= $(filter-out $(CC_FLAGS_SCS), $(KBUILD_CFLAGS))
 KBUILD_CFLAGS	:= $(filter-out $(CC_FLAGS_LTO), $(KBUILD_CFLAGS))
 
 hostprogs	:= relacheck
+HOSTCFLAGS_relacheck.o = $(shell $(HOSTPKG_CONFIG) --cflags bee-headers 2> /dev/null)
 
 quiet_cmd_piobjcopy = $(quiet_cmd_objcopy)
       cmd_piobjcopy = $(cmd_objcopy) && $(obj)/relacheck $(@) $(<)
diff --git a/arch/arm64/kernel/vdso32/Makefile b/arch/arm64/kernel/vdso32/Makefile
index 25a2cb6317f3..6cb8a04bd829 100644
--- a/arch/arm64/kernel/vdso32/Makefile
+++ b/arch/arm64/kernel/vdso32/Makefile
@@ -107,6 +107,7 @@ VDSO_LDFLAGS += --orphan-handling=$(CONFIG_LD_ORPHAN_WARN_LEVEL)
 # $(hostprogs) with $(obj)
 munge := ../../../arm/vdso/vdsomunge
 hostprogs := $(munge)
+HOSTCFLAGS_$(munge).o = $(shell $(HOSTPKG_CONFIG) --cflags bee-headers 2> /dev/null)
 
 c-obj-vdso := note.o
 c-obj-vdso-gettimeofday := vgettimeofday.o
diff --git a/arch/arm64/kvm/hyp/nvhe/Makefile b/arch/arm64/kvm/hyp/nvhe/Makefile
index b43426a493df..d20a440b6964 100644
--- a/arch/arm64/kvm/hyp/nvhe/Makefile
+++ b/arch/arm64/kvm/hyp/nvhe/Makefile
@@ -15,7 +15,8 @@ ccflags-y += -fno-stack-protector	\
 	     $(DISABLE_STACKLEAK_PLUGIN)
 
 hostprogs := gen-hyprel
-HOST_EXTRACFLAGS += -I$(objtree)/include
+HOST_EXTRACFLAGS += -I$(objtree)/include \
+	$(shell $(HOSTPKG_CONFIG) --cflags bee-headers 2> /dev/null)
 
 lib-objs := clear_page.o copy_page.o memcpy.o memset.o
 lib-objs := $(addprefix ../../../lib/, $(lib-objs))

-- 
2.46.0

