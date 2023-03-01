From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:56:26 +0000
Subject: [PATCH RESEND v2 12/16] copy-firmware: quote deskdir to prevent
 word splitting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-12-e2b71974e842@gmail.com>
References: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
To: linux-firmware@kernel.org
Cc: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696976; l=818;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=KXTAfCujjlDu+I24tx9P5qTfiOLnyiIaZNoMdWFkZJQ=;
 b=028WvJesyrCJDbs8G8GB+15JQqmXVudP4wrybO10XEawvcmu/OGz3lq3Fuy+nTM7pbsECETn/
 4MQferEp7CGAsIdUkXydjS9yHglETlLKs//BXliAASD/VlOMv2uBEOr
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 0132244..c6a2fe9 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -27,13 +27,13 @@ done
 
 grep '^File:' WHENCE | sed -e's/^File: *//g' | while read f; do
     $verbose "copying file $f"
-    install -d $destdir/$(dirname "$f")
-    cp "$f" $destdir/"$f"
+    install -d "$destdir"/$(dirname "$f")
+    cp "$f" "$destdir/$f"
 done
 
 grep -E '^Link:' WHENCE | sed -e's/^Link: *//g' -e's/-> //g' | while read f d; do
     $verbose "creating link $f -> $d"
-    install -d $destdir/$(dirname "$f")
+    install -d "$destdir"/$(dirname "$f")
     ln -s "$d" "$destdir/$f"
 done
 

-- 
2.39.2

