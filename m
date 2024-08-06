From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 07 Aug 2024 01:09:18 +0200
Subject: [PATCH 04/12] drm/xe: xe_gen_wa_oob: fix
 program_invocation_short_name for macos
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240807-macos-build-support-v1-4-4cd1ded85694@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722985800; l=1537;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=xYJE9WRRAIRv4i+z5sDXuKkMiFQ3KMmcYsQNverwAeg=;
 b=b7BMXAQke1LOkRHzmeWm0G5v1jBPAvdTULfW44FJ1gmeQ2FlQKfG/qqW9uaRzI43lVO8Cvgjq
 vO6Mvk57URgBL7EXOhPLs+fmTIcw6Z85RQzfx1AxgOGdYc6oq2bS1zD
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use getprogname() [1] instead of program_invocation_short_name() [2]
for macOS hosts.

[1]:
https://www.gnu.org/software/gnulib/manual/html_node/
program_005finvocation_005fshort_005fname.html

[2]:
https://developer.apple.com/library/archive/documentation/System/
Conceptual/ManPages_iPhoneOS/man3/getprogname.3.html

Fixes build error for macOS hosts:

drivers/gpu/drm/xe/xe_gen_wa_oob.c:34:3: error: use of
undeclared identifier 'program_invocation_short_name'    34 |
program_invocation_short_name);       |                 ^ 1 error
generated.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 drivers/gpu/drm/xe/xe_gen_wa_oob.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/xe/xe_gen_wa_oob.c b/drivers/gpu/drm/xe/xe_gen_wa_oob.c
index 904cf47925aa..079b8870c461 100644
--- a/drivers/gpu/drm/xe/xe_gen_wa_oob.c
+++ b/drivers/gpu/drm/xe/xe_gen_wa_oob.c
@@ -9,6 +9,12 @@
 #include <stdbool.h>
 #include <stdio.h>
 #include <string.h>
+#define PROG_INV_NAME program_invocation_short_name
+
+#ifdef __APPLE__
+#include <stdlib.h>
+#define PROG_INV_NAME getprogname()
+#endif
 
 #define HEADER \
 	"// SPDX-License-Identifier: MIT\n" \
@@ -31,7 +37,7 @@
 static void print_usage(FILE *f)
 {
 	fprintf(f, "usage: %s <input-rule-file> <generated-c-source-file> <generated-c-header-file>\n",
-		program_invocation_short_name);
+		PROG_INV_NAME);
 }
 
 static void print_parse_error(const char *err_msg, const char *line,

-- 
Git-146)

