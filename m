From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 07 Aug 2024 01:09:15 +0200
Subject: [PATCH 01/12] scripts: subarch.include: fix SUBARCH on MacOS hosts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240807-macos-build-support-v1-1-4cd1ded85694@samsung.com>
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
 Daniel Gomez <da.gomez@samsung.com>, 
 Nick Desaulniers <nick.desaulniers@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722985800; l=1489;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=pKrUy+kUc7s1sGJ4V0pnKiAjUgJie+thKNoMDcFS8Ws=;
 b=BaL7A1rlA7gJqeye5jr4ewbPFIbJKovsy2703k4UjEVlRUIdHP5xKklCusXzrOGVDQfD0QJSj
 APMBaZZ1ODpAzcjGgS5l4MO4plml4BUxFF4TM1ExHvcSpGvrfIornNn
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Nick Desaulniers <nick.desaulniers@gmail.com>

When building the Linux kernel on an aarch64 MacOS based host, if we don't
specify a value for ARCH when invoking make, we default to arm and thus
multi_v7_defconfig rather than the expected arm64 and arm64's defconfig.

This is because subarch.include invokes `uname -m` which on MacOS hosts
evaluates to `arm64` but on Linux hosts evaluates to `aarch64`,

This allows us to build ARCH=arm64 natively on MacOS (as in ARCH need
not be specified on an aarch64-based system).

Utilize a negative lookahead regular expression to avoid matching arm64.

Add a separate expression to support for armv.* as per error reported by
Nicolas Schier [1].

[1] https://lore.kernel.org/all/Y3MRvtwdjIwMHvRo@bergen.fjasle.eu/#t

Signed-off-by: Nick Desaulniers <nick.desaulniers@gmail.com>
Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/subarch.include | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/scripts/subarch.include b/scripts/subarch.include
index 4bd327d0ae42..5d84ad8c0dee 100644
--- a/scripts/subarch.include
+++ b/scripts/subarch.include
@@ -6,7 +6,8 @@
 
 SUBARCH := $(shell uname -m | sed -e s/i.86/x86/ -e s/x86_64/x86/ \
 				  -e s/sun4u/sparc64/ \
-				  -e s/arm.*/arm/ -e s/sa110/arm/ \
+				  -e s/armv.*/arm/ \
+				  -e s/arm\(?:\(?!64\).*\)/arm/ -e s/sa110/arm/ \
 				  -e s/s390x/s390/ \
 				  -e s/ppc.*/powerpc/ -e s/mips.*/mips/ \
 				  -e s/sh[234].*/sh/ -e s/aarch64.*/arm64/ \

-- 
Git-146)

