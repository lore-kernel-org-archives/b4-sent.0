From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:56:17 +0000
Subject: [PATCH RESEND v2 03/16] check_whence, WHENCE, copy-firmware:
 escape filenames with spaces
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-3-e2b71974e842@gmail.com>
References: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
To: linux-firmware@kernel.org
Cc: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696976; l=4045;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=Sb2gdykaMauBYEvNG+HdSFH39+KPWGoLA26M3Nsel4w=;
 b=1zMcXgW0tw6rp5lklgvxwDc5PaaA26gMW3VsAvMcqQv1GOaogtX9imBmXXUE1w5s07s194P58
 tYqDMjTqpEGAV07QYDiHc+mW3NOYALohBkgv/6M/pPSZCnG3My+KFFS
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We have a handful of instances which have space in the filename - just
escape them (like we do for the symlinks) and drop the extra re pattern.

With this we can also drop the extra sed pattern, stripping out the
quotation marks.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 WHENCE           | 10 +++++-----
 check_whence.py  |  8 ++------
 copy-firmware.sh |  2 +-
 3 files changed, 8 insertions(+), 12 deletions(-)

diff --git a/WHENCE b/WHENCE
index d4654dd..214952e 100644
--- a/WHENCE
+++ b/WHENCE
@@ -2690,9 +2690,9 @@ Link: brcm/brcmfmac54591-pcie.clm_blob -> ../cypress/cyfmac54591-pcie.clm_blob
 
 Licence: Redistributable. See LICENCE.cypress for details.
 
-File: "brcm/brcmfmac43241b4-sdio.Intel Corp.-VALLEYVIEW C0 PLATFORM.txt"
+File: brcm/brcmfmac43241b4-sdio.Intel\ Corp.-VALLEYVIEW\ C0\ PLATFORM.txt
 File: brcm/brcmfmac4330-sdio.Prowise-PT301.txt
-File: "brcm/brcmfmac43340-sdio.ASUSTeK COMPUTER INC.-TF103CE.txt"
+File: brcm/brcmfmac43340-sdio.ASUSTeK\ COMPUTER\ INC.-TF103CE.txt
 File: brcm/brcmfmac43340-sdio.meegopad-t08.txt
 File: brcm/brcmfmac43340-sdio.pov-tab-p1006w-data.txt
 File: brcm/brcmfmac43340-sdio.predia-basic.txt
@@ -2703,7 +2703,7 @@ Link: brcm/brcmfmac43362-sdio.kobo,tolino-shine2hd.txt -> brcmfmac43362-sdio.WC1
 Link: brcm/brcmfmac43362-sdio.lemaker,bananapro.txt -> brcmfmac43362-sdio.cubietech,cubietruck.txt
 File: brcm/brcmfmac43430a0-sdio.ilife-S806.txt
 File: brcm/brcmfmac43430a0-sdio.jumper-ezpad-mini3.txt
-File: "brcm/brcmfmac43430a0-sdio.ONDA-V80 PLUS.txt"
+File: brcm/brcmfmac43430a0-sdio.ONDA-V80\ PLUS.txt
 File: brcm/brcmfmac43430-sdio.AP6212.txt
 Link: brcm/brcmfmac43430-sdio.sinovoip,bpi-m2-plus.txt -> brcmfmac43430-sdio.AP6212.txt
 Link: brcm/brcmfmac43430-sdio.sinovoip,bpi-m2-zero.txt -> brcmfmac43430-sdio.AP6212.txt
@@ -2724,9 +2724,9 @@ Link: brcm/brcmfmac43455-sdio.raspberrypi,3-model-a-plus.txt -> brcmfmac43455-sd
 File: brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt
 Link: brcm/brcmfmac43455-sdio.Raspberry\ Pi\ Foundation-Raspberry\ Pi\ 4\ Model\ B.txt -> brcmfmac43455-sdio.raspberrypi,4-model-b.txt
 Link: brcm/brcmfmac43455-sdio.Raspberry\ Pi\ Foundation-Raspberry\ Pi\ Compute\ Module\ 4.txt -> brcmfmac43455-sdio.raspberrypi,4-model-b.txt
-File: "brcm/brcmfmac43455-sdio.MINIX-NEO Z83-4.txt"
+File: brcm/brcmfmac43455-sdio.MINIX-NEO\ Z83-4.txt
 File: brcm/brcmfmac4356-pcie.gpd-win-pocket.txt
-File: "brcm/brcmfmac4356-pcie.Xiaomi Inc-Mipad2.txt"
+File: brcm/brcmfmac4356-pcie.Xiaomi\ Inc-Mipad2.txt
 File: brcm/brcmfmac4356-sdio.AP6356S.txt
 Link: brcm/brcmfmac4356-sdio.firefly,firefly-rk3399.txt -> brcmfmac4356-sdio.AP6356S.txt
 Link: brcm/brcmfmac4356-sdio.khadas,vim2.txt -> brcmfmac4356-sdio.AP6356S.txt
diff --git a/check_whence.py b/check_whence.py
index 8805e99..f347f0e 100755
--- a/check_whence.py
+++ b/check_whence.py
@@ -6,13 +6,9 @@ from io import open
 def list_whence():
     with open('WHENCE', encoding='utf-8') as whence:
         for line in whence:
-            match = re.match(r'(?:File|Source):\s*"(.*)"', line)
+            match = re.match(r'(?:File|Source):\s*(.*)', line)
             if match:
-                yield match.group(1)
-                continue
-            match = re.match(r'(?:File|Source):\s*(\S*)', line)
-            if match:
-                yield match.group(1)
+                yield match.group(1).replace("\ ", " ")
                 continue
             match = re.match(r'Licen[cs]e: (?:.*\bSee (.*) for details\.?|(\S*))\n',
                              line)
diff --git a/copy-firmware.sh b/copy-firmware.sh
index bbacb92..6bceef3 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -31,7 +31,7 @@ while test $# -gt 0; do
     esac
 done
 
-grep '^File:' WHENCE | sed -e's/^File: *//g' -e's/"//g' | while read f; do
+grep '^File:' WHENCE | sed -e's/^File: *//g' | while read f; do
     test -f "$f" || continue
     $verbose "copying file $f"
     install -d $destdir/$(dirname "$f")

-- 
2.39.2

