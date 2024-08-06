From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 07 Aug 2024 01:09:26 +0200
Subject: [PATCH 12/12] scripts/kallsyms: add compatibility support for
 macos
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240807-macos-build-support-v1-12-4cd1ded85694@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722985800; l=1149;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=m407j60dxP91/ofe/fC4k8KKLnSnwDft1+cuKD+Nr3Q=;
 b=9wVc3kFNW+eWlInTH68OVYW9lOTG64z9J8uGc06BNi0UKGSdgCWwd1pkJsrDb88EilcZAB+Hc
 BJiETDqZxOnA90nq/6n8hSEX1pXA+98beHklgtsWgzrpZRnNCLjTyIj
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 67bf347ba924 ("kbuild: remove PROVIDE() for kallsyms symbols")
introduces the use of scripts/kallsyms with /dev/null as input to
generate the kernel symbols file. This results in getline() returning
ENOTTY as the errno value on macOS hosts. To handle this different
behavior, add a specific #ifdef condition for macOS.

Fixes:
+ scripts/kallsyms --base-relative /dev/null
read_symbol: Inappropriate ioctl for device
make[1]: *** [scripts/Makefile.vmlinux:34: vmlinux] Error 1
make: *** [Makefile:1172: vmlinux] Error 2

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/kallsyms.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/scripts/kallsyms.c b/scripts/kallsyms.c
index 0ed873491bf5..cb200120a072 100644
--- a/scripts/kallsyms.c
+++ b/scripts/kallsyms.c
@@ -130,7 +130,11 @@ static struct sym_entry *read_symbol(FILE *in, char **buf, size_t *buf_len)
 	errno = 0;
 	readlen = getline(buf, buf_len, in);
 	if (readlen < 0) {
+#ifndef __APPLE__
 		if (errno) {
+#else
+		if (errno && errno != ENOTTY) {
+#endif
 			perror("read_symbol");
 			exit(EXIT_FAILURE);
 		}

-- 
Git-146)

