From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:38 +0000
Subject: [PATCH v2 13/16] copy-firmware: tweak sed invocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-13-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=964;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=2JinCNkOkfhD9LPQJIFYKPvaZoBwAPTHtJg2ynGM9rE=;
 b=al1fE+NGKjGsSw4pgLDdeevfVWHy3wKXlJ4Yz2UelQVRSRoY2OH19LSSBDxxWPriy5sizBGiP
 xIe48DhJF5tD90xUwywZRBhrlt33U7tvD8EGnqA9DsXe3YeDekqwy8T
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add space between the arguments and pattern and combine patterns where
possible.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index c6a2fe9..722227f 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -25,13 +25,13 @@ while test $# -gt 0; do
     esac
 done
 
-grep '^File:' WHENCE | sed -e's/^File: *//g' | while read f; do
+grep '^File:' WHENCE | sed -e 's/^File: *//g' | while read f; do
     $verbose "copying file $f"
     install -d "$destdir"/$(dirname "$f")
     cp "$f" "$destdir/$f"
 done
 
-grep -E '^Link:' WHENCE | sed -e's/^Link: *//g' -e's/-> //g' | while read f d; do
+grep -E '^Link:' WHENCE | sed -e 's/^Link: *//g;s/-> //g' | while read f d; do
     $verbose "creating link $f -> $d"
     install -d "$destdir"/$(dirname "$f")
     ln -s "$d" "$destdir/$f"

-- 
2.39.2

