From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Date: Mon, 01 Jun 2026 09:13:03 +0200
Subject: [PATCH 2/6] package_manager: rootfs: remove install_order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-topic-packagemanager-cleanup-v1-2-926e4d5b724d@linaro.org>
References: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
In-Reply-To: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
To: openembedded-core@lists.openembedded.org
Cc: Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780297982; l=2345;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=TjZBf0G6Bjkiu10F3DJm+xgYkZbJVsvMLVkTSeOxqHg=;
 b=+2krNKmwmQWUDxa8jYWhlTNPNieLJq1xUujFk5F8n7v4WpAJ5qaO5orJIgrMq0qMxft+1ac3R
 r25SDa+7IQCAHCb67upOfnQv7a05FxjQzmWd+gwGreCwjq8x0uK/Y2n
X-Developer-Key: i=rouven.czerwinski@linaro.org; a=ed25519;
 pk=/5pmUK/XIAIIo8JA0axgfy1k8NRhRTQkxVwZYa1ga7U=
X-Endpoint-Received: by B4 Relay for rouven.czerwinski@linaro.org/20260126 with auth_id=616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The install_order instance variable was only ever set to
Manifest.INSTALL_ORDER, modified nowhere and used as is. Instead of
using an instance variable use Manifest.INSTALL_ORDER directly to
simplify the code for those reading it.

No functional changes.

Signed-off-by: Rouven Czerwinski <rouven.czerwinski@linaro.org>
---
 meta/lib/oe/package_manager/deb/rootfs.py | 2 +-
 meta/lib/oe/package_manager/ipk/rootfs.py | 2 +-
 meta/lib/oe/rootfs.py                     | 2 --
 3 files changed, 2 insertions(+), 4 deletions(-)

diff --git a/meta/lib/oe/package_manager/deb/rootfs.py b/meta/lib/oe/package_manager/deb/rootfs.py
index 1e25b64ed9..21d6cc5e5d 100644
--- a/meta/lib/oe/package_manager/deb/rootfs.py
+++ b/meta/lib/oe/package_manager/deb/rootfs.py
@@ -162,7 +162,7 @@ class PkgRootfs(DpkgOpkgRootfs):
         if self.progress_reporter:
             self.progress_reporter.next_stage()
 
-        for pkg_type in self.install_order:
+        for pkg_type in Manifest.INSTALL_ORDER:
             if pkg_type in pkgs_to_install:
                 self.pm.install(pkgs_to_install[pkg_type],
                                 [False, True][pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY])
diff --git a/meta/lib/oe/package_manager/ipk/rootfs.py b/meta/lib/oe/package_manager/ipk/rootfs.py
index ba93eb62ea..bc822bac87 100644
--- a/meta/lib/oe/package_manager/ipk/rootfs.py
+++ b/meta/lib/oe/package_manager/ipk/rootfs.py
@@ -298,7 +298,7 @@ class PkgRootfs(DpkgOpkgRootfs):
         if self.progress_reporter:
             self.progress_reporter.next_stage()
 
-        for pkg_type in self.install_order:
+        for pkg_type in Manifest.INSTALL_ORDER:
             if pkg_type in pkgs_to_install:
                 # For multilib, we perform a sanity test before final install
                 # If sanity test fails, it will automatically do a bb.fatal()
diff --git a/meta/lib/oe/rootfs.py b/meta/lib/oe/rootfs.py
index 7ef7e71f9e..5eee48f587 100644
--- a/meta/lib/oe/rootfs.py
+++ b/meta/lib/oe/rootfs.py
@@ -27,8 +27,6 @@ class Rootfs(object, metaclass=ABCMeta):
         self.logcatcher = logcatcher
         self.warn_check_regex = r'^(warn|Warn|WARNING:)'
 
-        self.install_order = Manifest.INSTALL_ORDER
-
     @abstractmethod
     def _create(self):
         pass

-- 
2.52.0

