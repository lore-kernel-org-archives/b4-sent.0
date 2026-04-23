From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Thu, 23 Apr 2026 23:02:05 +0200
Subject: [PATCH meta-virtualization][PATCH 2/2] podman: update SRC_URI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260423-podman-fixes-v1-2-3ffa0badf612@belden.com>
References: <20260423-podman-fixes-v1-0-3ffa0badf612@belden.com>
In-Reply-To: <20260423-podman-fixes-v1-0-3ffa0badf612@belden.com>
To: meta-virtualization@lists.yoctoproject.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776978137; l=1439;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=yO29jiJJsf/MoZvBQEld2qyQLCDdtYNhT/accy+vUbQ=;
 b=Iobn5nn+f1sz774eOJPLwCKEmil0s6eXOfddUllf7/A95R95HQWEP2F3ukzMIvFS7GIREMHVW
 5ROXjaegxfQAO7FXzpfpfuE0oUQqeVSzPfIrkjG1mqfadyRZgahFpmS
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Podman is hosted under github as podman and not libpod. Accessing
github.com/containers/libpod automatically forwards to
github.com/containers/podman.

This commit does not really fix a problem but reflects more the current
repository name.

Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 recipes-containers/podman/podman_git.bb | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/recipes-containers/podman/podman_git.bb b/recipes-containers/podman/podman_git.bb
index fd0cd908..8e108c4e 100644
--- a/recipes-containers/podman/podman_git.bb
+++ b/recipes-containers/podman/podman_git.bb
@@ -18,7 +18,7 @@ DEPENDS = " \
 
 SRCREV = "9d66b48e1c9bc1f4e757384f44c4ecb2838138d7"
 SRC_URI = " \
-    git://github.com/containers/libpod.git;branch=v5.8;protocol=https;destsuffix=${GO_SRCURI_DESTSUFFIX} \
+    git://github.com/containers/podman.git;branch=v5.8;protocol=https;destsuffix=${GO_SRCURI_DESTSUFFIX} \
     ${@bb.utils.contains('PACKAGECONFIG', 'rootless', 'file://50-podman-rootless.conf', '', d)} \
 "
 
@@ -34,7 +34,7 @@ CVE_STATUS[CVE-2023-0778] = "fixed-version: fixed since v4.5.0"
 
 PACKAGES =+ "${PN}-contrib"
 
-PODMAN_PKG = "github.com/containers/libpod"
+PODMAN_PKG = "github.com/containers/podman"
 
 BUILDTAGS_EXTRA ?= "${@bb.utils.contains('VIRTUAL-RUNTIME_container_networking','cni','cni','',d)}"
 BUILDTAGS ?= "seccomp varlink \

-- 
2.43.0

