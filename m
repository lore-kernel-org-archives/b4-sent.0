From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sun, 22 Sep 2024 21:17:48 +0100
Subject: [PATCH 13/16] copy-firmware.sh: remove no longer reachable test -f
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240922-misc-fixes-v1-13-8c6e52997c94@gmail.com>
References: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
In-Reply-To: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=919;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=t8fMalUkOjIwVjj7TfNU6qNxywuo+7I6qOlYq5VYSx4=;
 b=gZ3n93HLYXpuw9326PL76Fz9Jb5Bi64hD4so/Kat7LLRpC3ZhSRCcCrbH1fZoKWvJVnp6+b/u
 6Y98bwJKvNUDRKNByToc/qlHHNDVO3z8CB8jrZn/Px1UVOPAKqLPadj
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With previous commit we call check_whence.py, which ensures that all files
listed are available. Drop the now dead code test -f.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 1 -
 1 file changed, 1 deletion(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index ff3124d9d055f1f72351f472609d0158bd91dfb7..d1d526f43d2c71a5f1456ed6c09ed94a73a1229e 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -75,7 +75,6 @@ $verbose "Checking that WHENCE file is formatted properly"
 
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
 grep -E '^(RawFile|File):' WHENCE | sed -E -e 's/^(RawFile|File): */\1 /;s/"//g' | while read k f; do
-    test -f "$f" || continue
     install -d "$destdir/$(dirname "$f")"
     $verbose "copying/compressing file $f$compext"
     if test "$compress" != "cat" && test "$k" = "RawFile"; then

-- 
2.46.1

