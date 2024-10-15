From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 15 Oct 2024 13:34:52 +0200
Subject: [PATCH 2/5] guestfs: bringup: check if domain exists
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-bringup-guestfs-debug-v1-2-bd74c0c31412@samsung.com>
References: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
In-Reply-To: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.com>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728992109; l=1281;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=r7n0kftrpxoYrS4NehqDL4UaHsnPJitiFNTCeq6FTxM=;
 b=vp9aLU0cSzArKTbTygFbVbXN1ysAAaVm49NQITltYeX2pbooDuHVIOfLu+aCcrizZahnfbZua
 ldM31EoLtx/Chhm7EPZLp+tI4YG471JehW3QkyCw3xWbS4NEM7MO09g
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

virsh domstate fails (exit 1) if domain checked does not exist. This
conflicts when debugging the script with set -euxo pipefile. Replace the
command with virsh list --all and search for the domain in the list.
Also, capture the state to avoid trying to start a domain that is
already running.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/bringup_guestfs.sh | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/scripts/bringup_guestfs.sh b/scripts/bringup_guestfs.sh
index 32aadba0f4e5a0abc81d247f51cdddd0f2255785..5786975e48647321ecbc71ca9be6fb09c8aa63ff 100755
--- a/scripts/bringup_guestfs.sh
+++ b/scripts/bringup_guestfs.sh
@@ -334,10 +334,12 @@ do
 	# If the guest is already defined, then just stop what we're doing
 	# and plead to the developer to clean things up.
 	#
-	virsh domstate $name 1>/dev/null 2>&1
-	if [ $? -eq 0 ]; then
-		echo "Domain $name is already defined."
-		virsh start $name
+	if virsh list --all | grep --quiet --word-regexp "$name"; then
+		output_domstate=$(virsh domstate $name 2>/dev/null)
+		echo "Domain $name is already defined. (state: $output_domstate)"
+		if [ "$output_domstate" != "running" ]; then
+			virsh start $name
+		fi
 		exit 0
 	fi
 

-- 
2.39.2

