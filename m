From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sun, 22 Sep 2024 21:17:47 +0100
Subject: [PATCH 12/16] copy-firmware.sh: call ./check_whence.py before
 parsing the file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240922-misc-fixes-v1-12-8c6e52997c94@gmail.com>
References: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
In-Reply-To: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=911;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=HBkBN3KMWwFD5mmZPHeopiW498PMbVobsiZupVQ9os4=;
 b=1xy3n0AZjTt9jclFAS7Hp231LL49Rgn1RQBaBNj4pPeO9uSpwJa0m6QzJkzT5IPjigyrXQhf1
 /c9i30TSMaSCoiX77B0ge4C0hI4DC6xmt0Wz4TI+Lv6BVGjRCV06VN+
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This will prevent accidental changes (eg. you're hacking locally) to wreaking
chaos, as copy-firmware.sh expect a specific format.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index dc959cbad3be3e79a1174afd0ff68b8d6c0567a5..ff3124d9d055f1f72351f472609d0158bd91dfb7 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -70,6 +70,9 @@ if test -d "$destdir"; then
     find "$destdir" -type d -empty >/dev/null && warn "destination folder is not empty."
 fi
 
+$verbose "Checking that WHENCE file is formatted properly"
+./check_whence.py
+
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
 grep -E '^(RawFile|File):' WHENCE | sed -E -e 's/^(RawFile|File): */\1 /;s/"//g' | while read k f; do
     test -f "$f" || continue

-- 
2.46.1

