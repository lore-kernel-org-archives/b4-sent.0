From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:56:16 +0000
Subject: [PATCH RESEND v2 02/16] WHENCE: remove unnecessary filename
 quotation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-2-e2b71974e842@gmail.com>
References: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-e2b71974e842@gmail.com>
To: linux-firmware@kernel.org
Cc: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696976; l=4112;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=LFy1r3HGJ4+v4UvtUZc84svNrI/yxDH3yCVCY8I/o00=;
 b=RzCf/yWqXzMY923D750524RYZtBqYCovRJabUWhs/uz2ULN65IBVfV4oLiSGhSJcre1aiM2rT
 +Zg5+kJ2V0uC1YnZHaluEeQwJlJ/hjw7r23yDW8s1JxFtdyLh3XHbeN
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 WHENCE | 32 ++++++++++++++++----------------
 1 file changed, 16 insertions(+), 16 deletions(-)

diff --git a/WHENCE b/WHENCE
index 205162e..d4654dd 100644
--- a/WHENCE
+++ b/WHENCE
@@ -2691,20 +2691,20 @@ Link: brcm/brcmfmac54591-pcie.clm_blob -> ../cypress/cyfmac54591-pcie.clm_blob
 Licence: Redistributable. See LICENCE.cypress for details.
 
 File: "brcm/brcmfmac43241b4-sdio.Intel Corp.-VALLEYVIEW C0 PLATFORM.txt"
-File: "brcm/brcmfmac4330-sdio.Prowise-PT301.txt"
+File: brcm/brcmfmac4330-sdio.Prowise-PT301.txt
 File: "brcm/brcmfmac43340-sdio.ASUSTeK COMPUTER INC.-TF103CE.txt"
-File: "brcm/brcmfmac43340-sdio.meegopad-t08.txt"
-File: "brcm/brcmfmac43340-sdio.pov-tab-p1006w-data.txt"
-File: "brcm/brcmfmac43340-sdio.predia-basic.txt"
-File: "brcm/brcmfmac43362-sdio.WC121.txt"
-File: "brcm/brcmfmac43362-sdio.cubietech,cubietruck.txt"
+File: brcm/brcmfmac43340-sdio.meegopad-t08.txt
+File: brcm/brcmfmac43340-sdio.pov-tab-p1006w-data.txt
+File: brcm/brcmfmac43340-sdio.predia-basic.txt
+File: brcm/brcmfmac43362-sdio.WC121.txt
+File: brcm/brcmfmac43362-sdio.cubietech,cubietruck.txt
 Link: brcm/brcmfmac43362-sdio.kobo,aura.txt -> brcmfmac43362-sdio.WC121.txt
 Link: brcm/brcmfmac43362-sdio.kobo,tolino-shine2hd.txt -> brcmfmac43362-sdio.WC121.txt
 Link: brcm/brcmfmac43362-sdio.lemaker,bananapro.txt -> brcmfmac43362-sdio.cubietech,cubietruck.txt
-File: "brcm/brcmfmac43430a0-sdio.ilife-S806.txt"
-File: "brcm/brcmfmac43430a0-sdio.jumper-ezpad-mini3.txt"
+File: brcm/brcmfmac43430a0-sdio.ilife-S806.txt
+File: brcm/brcmfmac43430a0-sdio.jumper-ezpad-mini3.txt
 File: "brcm/brcmfmac43430a0-sdio.ONDA-V80 PLUS.txt"
-File: "brcm/brcmfmac43430-sdio.AP6212.txt"
+File: brcm/brcmfmac43430-sdio.AP6212.txt
 Link: brcm/brcmfmac43430-sdio.sinovoip,bpi-m2-plus.txt -> brcmfmac43430-sdio.AP6212.txt
 Link: brcm/brcmfmac43430-sdio.sinovoip,bpi-m2-zero.txt -> brcmfmac43430-sdio.AP6212.txt
 Link: brcm/brcmfmac43430-sdio.sinovoip,bpi-m2-ultra.txt -> brcmfmac43430-sdio.AP6212.txt
@@ -2713,19 +2713,19 @@ Link: brcm/brcmfmac43430-sdio.friendlyarm,nanopi-r1.txt -> brcmfmac43430-sdio.AP
 Link: brcm/brcmfmac43430-sdio.starfive,visionfive-v1.txt -> brcmfmac43430-sdio.AP6212.txt
 Link: brcm/brcmfmac43430-sdio.beagle,beaglev-starlight-jh7100-a1.txt -> brcmfmac43430-sdio.AP6212.txt
 Link: brcm/brcmfmac43430-sdio.beagle,beaglev-starlight-jh7100-r0.txt -> brcmfmac43430-sdio.AP6212.txt
-File: "brcm/brcmfmac43430-sdio.Hampoo-D2D3_Vi8A1.txt"
-File: "brcm/brcmfmac43430-sdio.MUR1DX.txt"
-File: "brcm/brcmfmac43430-sdio.raspberrypi,3-model-b.txt"
+File: brcm/brcmfmac43430-sdio.Hampoo-D2D3_Vi8A1.txt
+File: brcm/brcmfmac43430-sdio.MUR1DX.txt
+File: brcm/brcmfmac43430-sdio.raspberrypi,3-model-b.txt
 Link: brcm/brcmfmac43430-sdio.raspberrypi,model-zero-w.txt -> brcmfmac43430-sdio.raspberrypi,3-model-b.txt
 Link: brcm/brcmfmac43430-sdio.raspberrypi,model-zero-2-w.txt -> brcmfmac43430-sdio.raspberrypi,3-model-b.txt
-File: "brcm/brcmfmac43455-sdio.acepc-t8.txt"
-File: "brcm/brcmfmac43455-sdio.raspberrypi,3-model-b-plus.txt"
+File: brcm/brcmfmac43455-sdio.acepc-t8.txt
+File: brcm/brcmfmac43455-sdio.raspberrypi,3-model-b-plus.txt
 Link: brcm/brcmfmac43455-sdio.raspberrypi,3-model-a-plus.txt -> brcmfmac43455-sdio.raspberrypi,3-model-b-plus.txt
-File: "brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt"
+File: brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt
 Link: brcm/brcmfmac43455-sdio.Raspberry\ Pi\ Foundation-Raspberry\ Pi\ 4\ Model\ B.txt -> brcmfmac43455-sdio.raspberrypi,4-model-b.txt
 Link: brcm/brcmfmac43455-sdio.Raspberry\ Pi\ Foundation-Raspberry\ Pi\ Compute\ Module\ 4.txt -> brcmfmac43455-sdio.raspberrypi,4-model-b.txt
 File: "brcm/brcmfmac43455-sdio.MINIX-NEO Z83-4.txt"
-File: "brcm/brcmfmac4356-pcie.gpd-win-pocket.txt"
+File: brcm/brcmfmac4356-pcie.gpd-win-pocket.txt
 File: "brcm/brcmfmac4356-pcie.Xiaomi Inc-Mipad2.txt"
 File: brcm/brcmfmac4356-sdio.AP6356S.txt
 Link: brcm/brcmfmac4356-sdio.firefly,firefly-rk3399.txt -> brcmfmac4356-sdio.AP6356S.txt

-- 
2.39.2

