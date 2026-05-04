From: Ivan Nestlerode <ivan.nestlerode@sonos.com>
Date: Mon, 04 May 2026 17:28:43 -0400
Subject: [PATCH] glibc: Fix recipe bug that disabled stack protector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-glibc-fix-stackprot-v1-1-fbfd0f22ddd2@sonos.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7bsHKEvpKdDBdbSlSNCKI/p50H
 JiZBzIlpgxj9UCiizOHo0BTV2BWfXhCtoWhFe0geiHR77wYdHxjPrXZYgonStV0UlstFuWglDF
 REf7rNL/vBybS8xdlAAAA
X-Change-ID: 20260504-glibc-fix-stackprot-47134ada0b7f
To: openembedded-core@lists.openembedded.org
Cc: Ivan Nestlerode <ivan.nestlerode@sonos.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777930134; l=1583;
 i=ivan.nestlerode@sonos.com; s=20260504; h=from:subject:message-id;
 bh=sz53G9VmClsk4hMabYD7S+5Wg5jjaID8amIrvH975nc=;
 b=fM1gNscflG5MLDvzGU2f8STsfz3/YdUIwv3uSEPbwuZ4+DhYK6axt0C78Rme6RglDaTJPzSzD
 psdaczaPH64AL8L5e+G7tYVLdPDVw49zq6/X5ON9NX+SbkAcB6viNHX
X-Developer-Key: i=ivan.nestlerode@sonos.com; a=ed25519;
 pk=kcjfcLwbjs7Fqv95W59a7YVW52AGAkgpAOoPa23YKXU=
X-Endpoint-Received: by B4 Relay for ivan.nestlerode@sonos.com/20260504 with auth_id=767
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes [YOCTO #16265]

The glibc recipe is supposed to be building with
--enable-stack-protector=strong, but some CACHED_CONFIGVARS values are
actually breaking this, causing glibc to be built with no stack
protector at all.

Remove these CACHED_CONFIGVARS values so that stack protector support is
detected properly in do_configure and then enabled properly during
do_compile.

Full details are here:
https://bugzilla.yoctoproject.org/show_bug.cgi?id=16265

Signed-off-by: Ivan Nestlerode <ivan.nestlerode@sonos.com>
---
The glibc recipe is supposed to be building with
--enable-stack-protector=strong, but some CACHED_CONFIGVARS values
are actually breaking this, causing glibc to be built with no stack
protector at all.
    
Full details are here:
https://bugzilla.yoctoproject.org/show_bug.cgi?id=16265
---
 meta/recipes-core/glibc/glibc.inc | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/meta/recipes-core/glibc/glibc.inc b/meta/recipes-core/glibc/glibc.inc
index 30d93bca77..dae087d53f 100644
--- a/meta/recipes-core/glibc/glibc.inc
+++ b/meta/recipes-core/glibc/glibc.inc
@@ -21,9 +21,6 @@ CACHED_CONFIGUREVARS += " \
   libc_cv_slibdir=${base_libdir} \
   libc_cv_rootsbindir=${base_sbindir} \
   libc_cv_localedir=${localedir} \
-  libc_cv_ssp_strong=no \
-  libc_cv_ssp_all=no \
-  libc_cv_ssp=no \
   libc_cv_include_x86_isa_level=no \
 "
 

---
base-commit: 9ca41405e6bca276468a3b6f67eaa328b8016485
change-id: 20260504-glibc-fix-stackprot-47134ada0b7f

Best regards,
-- 
Ivan Nestlerode <ivan.nestlerode@sonos.com>

