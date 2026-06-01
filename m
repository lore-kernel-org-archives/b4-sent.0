From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Date: Mon, 01 Jun 2026 09:13:05 +0200
Subject: [PATCH 4/6] package_manager: remove [True, False] list eval
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-topic-packagemanager-cleanup-v1-4-926e4d5b724d@linaro.org>
References: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
In-Reply-To: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
To: openembedded-core@lists.openembedded.org
Cc: Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780297982; l=3544;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=EWUMxfp5xIJ+TSxGcoFdO33TOCfs6Lu7ITMhUnFxKqw=;
 b=QUe2V7gCu/RfQpPv1I6Pkf4mAHIDO3eu6Z5hcCzBKIPxIGxgpirkCuZWerkWb8H49p+y2uDQy
 QcM/asyjYTXB0mBTxB5fSmmdY0upMg+uh+7b1AJ8nZoO/4fSVN4+GPV
X-Developer-Key: i=rouven.czerwinski@linaro.org; a=ed25519;
 pk=/5pmUK/XIAIIo8JA0axgfy1k8NRhRTQkxVwZYa1ga7U=
X-Endpoint-Received: by B4 Relay for rouven.czerwinski@linaro.org/20260126 with auth_id=616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove a [True, False] list evaluation that itself relied on evaluating
a boolean condition. Instead pass the boolean condition directly.

The previous version works because int(True)=1 and int(False)=0.
So:
 => pkg_type = Manifest.PKG_TYPE_ATTEMPT_ONLY
 => [False, True][pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY]
 => [False, True][True]
 => [False, True][1]
 => True

No functional changes.

Signed-off-by: Rouven Czerwinski <rouven.czerwinski@linaro.org>
---
 meta/lib/oe/package_manager/deb/rootfs.py | 2 +-
 meta/lib/oe/package_manager/deb/sdk.py    | 2 +-
 meta/lib/oe/package_manager/ipk/rootfs.py | 2 +-
 meta/lib/oe/package_manager/ipk/sdk.py    | 2 +-
 4 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/meta/lib/oe/package_manager/deb/rootfs.py b/meta/lib/oe/package_manager/deb/rootfs.py
index 21d6cc5e5d..d2b077cc37 100644
--- a/meta/lib/oe/package_manager/deb/rootfs.py
+++ b/meta/lib/oe/package_manager/deb/rootfs.py
@@ -165,7 +165,7 @@ class PkgRootfs(DpkgOpkgRootfs):
         for pkg_type in Manifest.INSTALL_ORDER:
             if pkg_type in pkgs_to_install:
                 self.pm.install(pkgs_to_install[pkg_type],
-                                [False, True][pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY])
+                                pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY)
                 self.pm.fix_broken_dependencies()
 
         if self.progress_reporter:
diff --git a/meta/lib/oe/package_manager/deb/sdk.py b/meta/lib/oe/package_manager/deb/sdk.py
index 690b10d2ba..519b5c9f90 100644
--- a/meta/lib/oe/package_manager/deb/sdk.py
+++ b/meta/lib/oe/package_manager/deb/sdk.py
@@ -57,7 +57,7 @@ class PkgSdk(Sdk):
         for pkg_type in Manifest.INSTALL_ORDER:
             if pkg_type in pkgs_to_install:
                 pm.install(pkgs_to_install[pkg_type],
-                           [False, True][pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY])
+                           pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY)
 
     def _populate(self):
         execute_pre_post_process(self.d, self.d.getVar("POPULATE_SDK_PRE_TARGET_COMMAND"))
diff --git a/meta/lib/oe/package_manager/ipk/rootfs.py b/meta/lib/oe/package_manager/ipk/rootfs.py
index bc822bac87..a760000d3f 100644
--- a/meta/lib/oe/package_manager/ipk/rootfs.py
+++ b/meta/lib/oe/package_manager/ipk/rootfs.py
@@ -307,7 +307,7 @@ class PkgRootfs(DpkgOpkgRootfs):
                     self._multilib_test_install(pkgs_to_install[pkg_type])
 
                 self.pm.install(pkgs_to_install[pkg_type],
-                                [False, True][pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY])
+                                pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY)
 
         if self.progress_reporter:
             self.progress_reporter.next_stage()
diff --git a/meta/lib/oe/package_manager/ipk/sdk.py b/meta/lib/oe/package_manager/ipk/sdk.py
index 8dc01661ef..e75e9bd991 100644
--- a/meta/lib/oe/package_manager/ipk/sdk.py
+++ b/meta/lib/oe/package_manager/ipk/sdk.py
@@ -53,7 +53,7 @@ class PkgSdk(Sdk):
         for pkg_type in Manifest.INSTALL_ORDER:
             if pkg_type in pkgs_to_install:
                 pm.install(pkgs_to_install[pkg_type],
-                           [False, True][pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY])
+                           pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY)
 
     def _populate(self):
         execute_pre_post_process(self.d, self.d.getVar("POPULATE_SDK_PRE_TARGET_COMMAND"))

-- 
2.52.0

