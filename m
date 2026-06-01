From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Date: Mon, 01 Jun 2026 09:13:02 +0200
Subject: [PATCH 1/6] package_manager: sdk: remove install_order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-topic-packagemanager-cleanup-v1-1-926e4d5b724d@linaro.org>
References: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
In-Reply-To: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
To: openembedded-core@lists.openembedded.org
Cc: Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780297982; l=2091;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=3s/tqeGzYl2p0pcIZGxjct/H6oVWX//wOCliBO0pCZg=;
 b=c7eH2wARsnjnysK7kMUWArRpJ/yr+0VmsEYEbOPU+LwRjJYbMqcCC7gl8BHpuLd2ANp7x7NhG
 vjykJ5qnpLiDsvVCFRVawDi364lFDdx/gAW9OT26XzDSh+WPJxoMEPj
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
 meta/lib/oe/package_manager/deb/sdk.py | 2 +-
 meta/lib/oe/package_manager/ipk/sdk.py | 2 +-
 meta/lib/oe/sdk.py                     | 2 --
 3 files changed, 2 insertions(+), 4 deletions(-)

diff --git a/meta/lib/oe/package_manager/deb/sdk.py b/meta/lib/oe/package_manager/deb/sdk.py
index 6f3005053e..1169744674 100644
--- a/meta/lib/oe/package_manager/deb/sdk.py
+++ b/meta/lib/oe/package_manager/deb/sdk.py
@@ -54,7 +54,7 @@ class PkgSdk(Sdk):
         pm.write_index()
         pm.update()
 
-        for pkg_type in self.install_order:
+        for pkg_type in Manifest.INSTALL_ORDER:
             if pkg_type in pkgs_to_install:
                 pm.install(pkgs_to_install[pkg_type],
                            [False, True][pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY])
diff --git a/meta/lib/oe/package_manager/ipk/sdk.py b/meta/lib/oe/package_manager/ipk/sdk.py
index 3acd55f548..c39a32fa24 100644
--- a/meta/lib/oe/package_manager/ipk/sdk.py
+++ b/meta/lib/oe/package_manager/ipk/sdk.py
@@ -50,7 +50,7 @@ class PkgSdk(Sdk):
 
         pm.update()
 
-        for pkg_type in self.install_order:
+        for pkg_type in Manifest.INSTALL_ORDER:
             if pkg_type in pkgs_to_install:
                 pm.install(pkgs_to_install[pkg_type],
                            [False, True][pkg_type == Manifest.PKG_TYPE_ATTEMPT_ONLY])
diff --git a/meta/lib/oe/sdk.py b/meta/lib/oe/sdk.py
index 9fe0fbb752..c2c5431c0d 100644
--- a/meta/lib/oe/sdk.py
+++ b/meta/lib/oe/sdk.py
@@ -29,8 +29,6 @@ class Sdk(object, metaclass=ABCMeta):
 
         self.remove(self.sdk_output, True)
 
-        self.install_order = Manifest.INSTALL_ORDER
-
     @abstractmethod
     def _populate(self):
         pass

-- 
2.52.0

