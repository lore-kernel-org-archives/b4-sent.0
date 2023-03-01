From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:39 +0000
Subject: [PATCH v2 14/16] copy-firmware: quote the output of dirname
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-14-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=952;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=sqz+7/rDijj7yKvt+728HKEpkgelptx0CPqhbGox/6I=;
 b=vvSuhsdU0oRiSKWF+7SrXlZaDKA9jIVBvGsmH557b+y8IXGWjwT/5ROSMS9va+/qrd1R5Z8Gu
 DlbKSgDyZoZBZf3Hy9Szb2CNlv/rW/Vo02bZ/K9E1zyIfjSvw5wN6+g
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As highlighted by shellcheck - as-is one could get word splitting. That
isn't an issue, yet, since none of the in-tree directories have space in
their name.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 722227f..5a5e1a8 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -27,13 +27,13 @@ done
 
 grep '^File:' WHENCE | sed -e 's/^File: *//g' | while read f; do
     $verbose "copying file $f"
-    install -d "$destdir"/$(dirname "$f")
+    install -d "$destdir/$(dirname "$f")"
     cp "$f" "$destdir/$f"
 done
 
 grep -E '^Link:' WHENCE | sed -e 's/^Link: *//g;s/-> //g' | while read f d; do
     $verbose "creating link $f -> $d"
-    install -d "$destdir"/$(dirname "$f")
+    install -d "$destdir/$(dirname "$f")"
     ln -s "$d" "$destdir/$f"
 done
 

-- 
2.39.2

