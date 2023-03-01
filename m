From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:34 +0000
Subject: [PATCH v2 09/16] check_whence: error if File: is actually a link
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-9-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=1339;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=0av+eIxNaRMO5FMJU9ukW6YWNWL0wtYKOyBS7RQJeUw=;
 b=HlB9KcCbPNltexF0+V4WSZVsBrf5Da6MLJoS76AGi+1a40BVfdnrAxpaHIht9fFEPMdlIW0g2
 xs0FUw1S4EKAmtwPdi4CVoSvphTZyjRCC5sMSa1+1QAzfXZvVJa3D4x
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This allows us to remove the -d aka --no-dereference --preserve=links
from the copy command.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 check_whence.py  | 5 +++++
 copy-firmware.sh | 2 +-
 2 files changed, 6 insertions(+), 1 deletion(-)

diff --git a/check_whence.py b/check_whence.py
index 130966e..92b104e 100755
--- a/check_whence.py
+++ b/check_whence.py
@@ -56,6 +56,11 @@ def main():
         sys.stderr.write('E: %s listed in WHENCE twice\n' % name)
         ret = 1
 
+    for name in set(link for link in whence_files if os.path.islink(link)):
+        sys.stderr.write('E: %s listed in WHENCE as File, but is a symlink\n' %
+                         name)
+        ret = 1
+
     for name in sorted(list(known_files - git_files)):
         sys.stderr.write('E: %s listed in WHENCE does not exist\n' % name)
         ret = 1
diff --git a/copy-firmware.sh b/copy-firmware.sh
index 656b0ec..e3f3176 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -34,7 +34,7 @@ done
 grep '^File:' WHENCE | sed -e's/^File: *//g' | while read f; do
     $verbose "copying file $f"
     install -d $destdir/$(dirname "$f")
-    cp -d "$f" $destdir/"$f"
+    cp "$f" $destdir/"$f"
 done
 
 grep -E '^Link:' WHENCE | sed -e's/^Link: *//g' -e's/-> //g' | while read f d; do

-- 
2.39.2

