From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:41 +0000
Subject: [PATCH v2 16/16] Makefile, copy-firmware: support xz/zstd
 compressed firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-16-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=4104;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=PRPQN2jK0uWMC2spdCgfbybC/qE0g9wrVkW5mSSOQwI=;
 b=vfKUbovacPM8zjMiu5ttwCVGAij4J8kq7to7D69iL8I9G39kxuMOyRc1dRgwFKlFCdyli9yzc
 fS8J95GZotzB9R1e9JZU2A+8zOcnfP+Dgd+GHkMna9i3HQAJro9tcct
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The kernel has supported compressed firmware for quite some time. So
let's add a couple of targets to produce that. In practical terms this
means it we'll use ~5x times less space on disk.

Reportedly the amd ucode, needs to be uncompressed _within_ the
initrd in order to work. Using compressed ucode in late load just works.
Ideally this will be addressed by the initrd generators, but considering
the files are tiny in size let's skip the compression.

v2
 - commit message, skip compression for files annotated as Raw

Cc: David Woodhouse <dwmw2@infradead.org>
Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 Makefile         |  8 ++++++++
 WHENCE           |  5 +++++
 copy-firmware.sh | 38 ++++++++++++++++++++++++++++++++++----
 3 files changed, 47 insertions(+), 4 deletions(-)

diff --git a/Makefile b/Makefile
index 83a0ec6..50a4c29 100644
--- a/Makefile
+++ b/Makefile
@@ -11,3 +11,11 @@ check:
 install:
 	install -d $(DESTDIR)$(FIRMWAREDIR)
 	./copy-firmware.sh $(DESTDIR)$(FIRMWAREDIR)
+
+install-xz:
+	install -d $(DESTDIR)$(FIRMWAREDIR)
+	./copy-firmware.sh --xz $(DESTDIR)$(FIRMWAREDIR)
+
+install-zst:
+	install -d $(DESTDIR)$(FIRMWAREDIR)
+	./copy-firmware.sh --zstd $(DESTDIR)$(FIRMWAREDIR)
diff --git a/WHENCE b/WHENCE
index bce94c5..6e44afa 100644
--- a/WHENCE
+++ b/WHENCE
@@ -3878,14 +3878,19 @@ License: Redistributable. See LICENSE.amd-sev for details
 Driver: microcode_amd - AMD CPU Microcode Update Driver for Linux
 
 File: amd-ucode/microcode_amd.bin
+Raw: amd-ucode/microcode_amd.bin
 Version: 2013-07-10
 File: amd-ucode/microcode_amd_fam15h.bin
+Raw: amd-ucode/microcode_amd_fam15h.bin
 Version: 2018-05-24
 File: amd-ucode/microcode_amd_fam16h.bin
+Raw: amd-ucode/microcode_amd_fam16h.bin
 Version: 2014-10-28
 File: amd-ucode/microcode_amd_fam17h.bin
+Raw: amd-ucode/microcode_amd_fam17h.bin
 Version: 2022-04-08
 File: amd-ucode/microcode_amd_fam19h.bin
+Raw: amd-ucode/microcode_amd_fam19h.bin
 Version: 2023-01-31
 File: amd-ucode/README
 
diff --git a/copy-firmware.sh b/copy-firmware.sh
index a52b847..6da9111 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -5,6 +5,9 @@
 #
 
 verbose=:
+# shellcheck disable=SC2209
+compress=cat
+compext=
 
 while test $# -gt 0; do
     case $1 in
@@ -14,6 +17,28 @@ while test $# -gt 0; do
             shift
             ;;
 
+        --xz)
+            if test "$compext" == ".zst"; then
+                echo "ERROR: cannot mix XZ and ZSTD compression"
+                exit 1
+            fi
+            compress="xz --compress --quiet --stdout --check=crc32"
+            compext=".xz"
+            shift
+            ;;
+
+        --zstd)
+            if test "$compext" == ".xz"; then
+                echo "ERROR: cannot mix XZ and ZSTD compression"
+                exit 1
+            fi
+            # shellcheck disable=SC2209
+            verbose=echo
+            compress="zstd --compress --quiet --stdout"
+            compext=".zst"
+            shift
+            ;;
+
         *)
             if test "x$destdir" != "x"; then
                 echo "ERROR: unknown command-line options: $*"
@@ -28,16 +53,21 @@ done
 
 # shellcheck disable=SC2162
 grep '^File:' WHENCE | sed -e 's/^File: *//g' | while read f; do
-    $verbose "copying file $f"
     install -d "$destdir/$(dirname "$f")"
-    cp "$f" "$destdir/$f"
+    $verbose "copying/compressing file $f$compext"
+    if test "$compress" != "cat" && grep -q "^Raw: $f\$" WHENCE; then
+        $verbose "compression will be skipped for file $f"
+        cat "$f" > "$destdir/$f"
+    else
+        $compress "$f" > "$destdir/$f$compext"
+    fi
 done
 
 # shellcheck disable=SC2162
 grep -E '^Link:' WHENCE | sed -e 's/^Link: *//g;s/-> //g' | while read f d; do
-    $verbose "creating link $f -> $d"
     install -d "$destdir/$(dirname "$f")"
-    ln -s "$d" "$destdir/$f"
+    $verbose "creating link $f$compext -> $d$compext"
+    ln -s "$d$compext" "$destdir/$f$compext"
 done
 
 exit 0

-- 
2.39.2

