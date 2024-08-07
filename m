From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 07 Aug 2024 12:40:43 +0200
Subject: [PATCH 2/3] Makefile.kdevops: add extra dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240807-fix-startup-kdevops-v1-2-87af646e1237@samsung.com>
References: <20240807-fix-startup-kdevops-v1-0-87af646e1237@samsung.com>
In-Reply-To: <20240807-fix-startup-kdevops-v1-0-87af646e1237@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723027254; l=1064;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=ai3aG5Zj6epkrP5QDmNPVsP8/UZOK5AB/Q5sE4VlzKE=;
 b=N/LpQysrkwPbcQgbU4qJxtbMMqvsGKli3zuG1i0gIlv/Vf4FbXl9cXDT65PQmQDPn5oA2GEHv
 B9QlrgzKOYADHmGaB1Mt/4rzavxhq5w6/3VZIYJ2SBfylOpDiuvbSNV
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To be able to run kdevops project, we need to make sure all dependencies
are met. For that, make sure the kdevops-deps includes min_deps target
(checks for sudo, make, nc and ansible-playbook) and menuconfig-deps
(installs ncurses).

Keep menuconfig-deps as target for users who do not want to run the full
kdevops dependency list check.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile.kdevops | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Makefile.kdevops b/Makefile.kdevops
index ac83bd8..3edbeda 100644
--- a/Makefile.kdevops
+++ b/Makefile.kdevops
@@ -68,7 +68,7 @@ kdevops_libvirt_storage_pool_create:
 PHONY += kdevops_libvirt_storage_pool_create
 KDEVOPS_VAGRANT_WORK += kdevops_libvirt_storage_pool_create
 
-kdevops_deps: kdevops_terraform_deps $(KDEVOPS_VAGRANT_WORK) $(KDEVOPS_DEPS)
+kdevops_deps: $(BINARY_DEPS) $(BINARY_DEP_VCHECKS) menuconfig-deps kdevops_terraform_deps $(KDEVOPS_VAGRANT_WORK) $(KDEVOPS_DEPS)
 	@echo Installed dependencies
 PHONY += kdevops_deps
 

-- 
Git-146)

