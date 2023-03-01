From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:56:22 +0000
Subject: [PATCH RESEND v2 08/16] copy-firmware: remove non-applicable file
 presence test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-8-e2b71974e842@gmail.com>
References: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
To: linux-firmware@kernel.org
Cc: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696976; l=655;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=xcjzktk1cmFxjASRD0WzRiBZcDi7DUscCBvzM13kFwk=;
 b=UOlleUcGNnltDjFZjBxfbap1Iib7OFVEZo69yUHreDIaUQEZgzagV7O4X16DkhBiFhR4aO0UC
 cx9hLiEqoODB2b8URandbwYPvL9COHzy7fG3mLASDAjMvYEOI6yzHEW
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The check_whence.py script already ensures that the files listed in
WHENCE are present on-disk. Thus the extra check isn't needed.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 1 -
 1 file changed, 1 deletion(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 6bceef3..656b0ec 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -32,7 +32,6 @@ while test $# -gt 0; do
 done
 
 grep '^File:' WHENCE | sed -e's/^File: *//g' | while read f; do
-    test -f "$f" || continue
     $verbose "copying file $f"
     install -d $destdir/$(dirname "$f")
     cp -d "$f" $destdir/"$f"

-- 
2.39.2

