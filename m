From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 07 Aug 2024 01:09:20 +0200
Subject: [PATCH 06/12] selinux/genheaders: include bitsperlong and
 posix_types headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240807-macos-build-support-v1-6-4cd1ded85694@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722985800; l=952;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=zkjqCDDWwxxcXmEm+jW0QannFSOP4w7DOpEHzeqzznI=;
 b=KS1HzePsm7adJO0+ulRuXmL0XzGu396kl5PQIL/Y+Ha4sBVswReLg26gtWlRY9ulp9HZfXTef
 mC9Dy8SO9GADeLaEPqz0n4cBifOqORRoKLP9Y+NObQyFVh4zLY67qbh
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The genheaders requires the bitsperlong.h and posix_types.h headers.
To ensure these headers are found during compilation on macOS hosts,
add usr/include to HOST_EXTRACFLAGS in the genheaders Makefile. This
adjustment allows the compiler to locate all necessary headers when they
are not available by default on macOS.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/selinux/genheaders/Makefile | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/scripts/selinux/genheaders/Makefile b/scripts/selinux/genheaders/Makefile
index 1faf7f07e8db..017149c90f8e 100644
--- a/scripts/selinux/genheaders/Makefile
+++ b/scripts/selinux/genheaders/Makefile
@@ -2,4 +2,5 @@
 hostprogs-always-y += genheaders
 HOST_EXTRACFLAGS += \
 	-I$(srctree)/include/uapi -I$(srctree)/include \
-	-I$(srctree)/security/selinux/include
+	-I$(srctree)/security/selinux/include \
+	-I$(srctree)/usr/include

-- 
Git-146)

