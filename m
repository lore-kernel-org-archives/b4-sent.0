From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 15 Oct 2024 13:34:51 +0200
Subject: [PATCH 1/5] scripts: lib: rename KDEVOPS_WORKFLOW_FSTESTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-bringup-guestfs-debug-v1-1-bd74c0c31412@samsung.com>
References: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
In-Reply-To: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.com>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728992109; l=976;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=agitDxiFrlhGQt6+adPfPU5KDudXEO2FENVxQ7uzWr8=;
 b=Q8aKuK61rd1dzqJEEStXfu7NcfeQvfWKTqzgYFF/CDZHRrLKFSScrxAcf5Id77bo9GnniWNNt
 nnL7ZWpV6DOB+AHwZ4g3nO8dXPzpi0+0WvydSLVdzve+EnrSoPUowDH
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kdevops variable was renamed and this was silently failing. Make sure
the proper workflow variable is checked but only if defined/set to avoid
'unbound variable' issue.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/lib.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/lib.sh b/scripts/lib.sh
index 041b7e279a0f9793bcb5ee797caa244ceeccdd01..56093b1a58ea1af104d9c0af2842b105783dbe80 100644
--- a/scripts/lib.sh
+++ b/scripts/lib.sh
@@ -33,7 +33,7 @@ FSTESTS_STARTED_FILE="${TOPDIR}/workflows/fstests/.begin"
 BLKTESTS_STARTED_FILE="${TOPDIR}/workflows/blktests/.begin"
 REBOOT_LIMIT_STARTED_FILE="${TOPDIR}/workflows/demos/reboot-limit/.begin"
 
-if [[ "$CONFIG_KDEVOPS_WORKFLOW_FSTESTS" == "y" ]]; then
+if [[ "${CONFIG_KDEVOPS_WORKFLOW_ENABLE_FSTESTS+x}" && "$CONFIG_KDEVOPS_WORKFLOW_ENABLE_FSTESTS" == "y" ]]; then
 	FSTYP="$CONFIG_FSTESTS_FSTYP"
 	TEST_DEV="$CONFIG_FSTESTS_TEST_DEV"
 fi

-- 
2.39.2

