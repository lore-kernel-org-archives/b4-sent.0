From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 15 Oct 2024 13:34:54 +0200
Subject: [PATCH 4/5] guestfs: bringup: fix user check when debug
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241015-bringup-guestfs-debug-v1-4-bd74c0c31412@samsung.com>
References: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
In-Reply-To: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.com>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728992109; l=792;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=v9hvEPJijMSXr0qDwFBjQSGQk2G5W+FZoAA2dzyx9Og=;
 b=M6rDRkrLXvypRZjVY5Kfin5tW8SsT1PdsmSP4rg/OpIzsUVbnOkXPsv8RpNWURctgWLqWdiup
 +0uBi1fOk8hBmI7RVbGGJr5gtrEwlWnGhdkUKsGXmoElc45B2GmIoXO
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace id -u with getent to check if the user exists.

Avoids id: ‘kdevops’: no such user.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/bringup_guestfs.sh | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/scripts/bringup_guestfs.sh b/scripts/bringup_guestfs.sh
index 19117e9a6ab55cfbe7c79f17e4a9b736edeb2607..54d8d92dcf2ff5f1de2099cbff785866c9f1c27d 100755
--- a/scripts/bringup_guestfs.sh
+++ b/scripts/bringup_guestfs.sh
@@ -200,8 +200,7 @@ _EOT
 pre_install_customizations()
 {
 	KDEVOPS_UID=""
-	id -u kdevops 2>&1 > /dev/null
-	if [ $? -eq 0 ]; then
+	if getent passwd kdevops > /dev/null 2>&1; then
 		KDEVOPS_UID="-u `id -u kdevops`"
 	fi
 	if echo $OS_VERSION | grep -qE "^(rhel|fedora|centos)"; then

-- 
2.39.2

