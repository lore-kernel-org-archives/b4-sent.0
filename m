From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Thu, 23 Apr 2026 23:02:04 +0200
Subject: [PATCH meta-virtualization][PATCH 1/2] podman: fix PV to right
 version
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260423-podman-fixes-v1-1-3ffa0badf612@belden.com>
References: <20260423-podman-fixes-v1-0-3ffa0badf612@belden.com>
In-Reply-To: <20260423-podman-fixes-v1-0-3ffa0badf612@belden.com>
To: meta-virtualization@lists.yoctoproject.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776978137; l=895;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=3dEjye6kkclmDTUzTAvsaM4X6/mfANGzqzb9BtRfOWw=;
 b=tHT3fAz/NiMZJm5Ii7Z0khjWwFYDOB9zLoYd24AKwxrrH/1zmQG12bvIJhQSW+83kI2uRZZPU
 x8WHHV8DO4PB0A7KvXBXl90WQNJmywtU2DVRLyEg9PBcCUeRBviMYYs
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 3b9ff919799daa5eccd56b481cefd61db652ab99 updated the SRCREV as well as
the branch in the SRC_URI but left PV untouched. This now sets PV to v5.8.1
which corresponds with the SRCREV.

Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 recipes-containers/podman/podman_git.bb | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/recipes-containers/podman/podman_git.bb b/recipes-containers/podman/podman_git.bb
index df333dfc..fd0cd908 100644
--- a/recipes-containers/podman/podman_git.bb
+++ b/recipes-containers/podman/podman_git.bb
@@ -27,7 +27,7 @@ LIC_FILES_CHKSUM = "file://src/import/LICENSE;md5=3d9b931fa23ab1cacd0087f9e2ee12
 
 GO_IMPORT = "import"
 
-PV = "v5.7.1"
+PV = "v5.8.1"
 
 CVE_STATUS[CVE-2022-2989] = "fixed-version: fixed since v4.3.0"
 CVE_STATUS[CVE-2023-0778] = "fixed-version: fixed since v4.5.0"

-- 
2.43.0

