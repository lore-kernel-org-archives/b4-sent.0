From: Andrei Lalaev <andrei.lalaev@anton-paar.com>
Date: Thu, 10 Sep 2026 09:41:55 +0200
Subject: [PATCH RESEND] ref-manual: update
 DEBUG_OPTIMIZATION/FULL_OPTIMIZATION
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-master-v1-1-7bf67b4fbebd@anton-paar.com>
To: docs@lists.yoctoproject.org
Cc: Andrei Lalaev <andrei.lalaev@anton-paar.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789026119; l=1856;
 i=andrei.lalaev@anton-paar.com; s=20250820; h=from:subject:message-id;
 bh=trinjwU2PSarYRydVzkoUwZSFKpYANZpkeqa7LktkOI=;
 b=lFzz6C3sUBv7upYZqYnwNXeDvjodRR6nIuQ0wVRxzvxmPAHea5vkq9hw0McDk/MIPN9O8crzP
 zXFZxkrQrbGCPxI/rcKhYXlOdnK/WGGqqWLatjxcy6tYWHJJVESbzkD
X-Developer-Key: i=andrei.lalaev@anton-paar.com; a=ed25519;
 pk=728nZXw7ILalhZmxQ0hPJ77AKRvsdNkq+v6XdryA5fM=
X-Endpoint-Received: by B4 Relay for andrei.lalaev@anton-paar.com/20250820 with auth_id=496
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 9badf68d78d9 ("bitbake.conf: Further cleanup compiler
optimization flags") in openembedded-core changed the default values
of these variables. But documentation wasn't updated.
Update to the correct values.

Signed-off-by: Andrei Lalaev <andrei.lalaev@anton-paar.com>
---
 documentation/ref-manual/variables.rst | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/documentation/ref-manual/variables.rst b/documentation/ref-manual/variables.rst
index 83bc59efe..e0055920e 100644
--- a/documentation/ref-manual/variables.rst
+++ b/documentation/ref-manual/variables.rst
@@ -2180,8 +2180,8 @@ system and gives an overview of their function and contents.
 
    :term:`DEBUG_OPTIMIZATION`
       The options to pass in :term:`TARGET_CFLAGS` and :term:`CFLAGS` when
-      compiling a system for debugging. This variable defaults to "-O
-      -fno-omit-frame-pointer ${DEBUG_FLAGS} -pipe".
+      compiling a system for debugging. This variable defaults to "-Og
+      ${DEBUG_LEVELFLAG}".
 
    :term:`DEBUG_PREFIX_MAP`
       Allows to set C compiler options, such as ``-fdebug-prefix-map``,
@@ -3811,8 +3811,8 @@ system and gives an overview of their function and contents.
 
    :term:`FULL_OPTIMIZATION`
       The options to pass in :term:`TARGET_CFLAGS` and :term:`CFLAGS` when
-      compiling an optimized system. This variable defaults to "-O2 -pipe
-      ${DEBUG_FLAGS}".
+      compiling an optimized system. This variable defaults to "-O2
+      ${DEBUG_LEVELFLAG}".
 
    :term:`GCCPIE`
       Enables Position Independent Executables (PIE) within the GNU C

---
base-commit: e35e86e9aea4e4ae12e8e0ba8a6391f2b2555b63
change-id: 20260910-master-cf1a97eb6bc2

Best regards,
--
Andrei Lalaev <andrei.lalaev@anton-paar.com>
-- 
Andrei Lalaev <andrei.lalaev@anton-paar.com>

