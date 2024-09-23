From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:30 +0100
Subject: [PATCH v2 02/16] check_whence.py: ban link-to-a-link
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-2-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=5197;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=tpFP/8RCkGti+Iy3v6E5vnbDdezqQZi6/o4Ei1YEWN4=;
 b=rud466N/SdWVg7rH/h9C5EI36cvtn3LZzmL5T2Eqfw7cbx9jhhq0d0ikuHcqsxWeY48cttYFs
 IUQVKjtTzYRA2ZzXOaeW4P7S+pL0SsQLcwYkNFnhzpQvn18Echr88mS
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Using link-to-a-link reduces legibility and changes to the root link,
also changes the leafs. Where the latter may be undesired and in some
cases just wrong.

We have a couple of instances in-tree, so fix them up and ban the
combination.

One particularly good example, why we'd want this is:
https://gitlab.com/kernel-firmware/linux-firmware/-/merge_requests/272

In there we have the following:

    File: ti/tas2781/TAS2XXX1EB30.bin
    [snip]
    Link: TAS2XXX1EB3.bin -> ti/tas2781/TAS2XXX1EB3.bin
    Link: ti/tas2781/TAS2XXX1EB3.bin -> TAS2XXX1EB30.bin
    Link: TAS2XXX1EB30.bin -> ti/tas2781/TAS2XXX1EB30.bin

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 WHENCE          | 14 +++++++-------
 check_whence.py | 12 ++++++++++--
 2 files changed, 17 insertions(+), 9 deletions(-)

diff --git a/WHENCE b/WHENCE
index 3897121a115e185cc36e782b33ef66e43d87d557..6af1a97e2672922f2a3a1fcf0306b158eae1b6f7 100644
--- a/WHENCE
+++ b/WHENCE
@@ -3686,7 +3686,7 @@ File: ath10k/WCN3990/hw1.0/qcm2290/wlanmdsp.mbn
 Version: WLAN.HL.3.3.7.c2-00931-QCAHLSWMTPLZ-1
 Link: ath10k/WCN3990/hw1.0/qrb4210/wlanmdsp.mbn -> ../qcm2290/wlanmdsp.mbn
 Link: qcom/qcm2290/wlanmdsp.mbn -> ../../ath10k/WCN3990/hw1.0/qcm2290/wlanmdsp.mbn
-Link: qcom/qrb4210/wlanmdsp.mbn -> ../../ath10k/WCN3990/hw1.0/qrb4210/wlanmdsp.mbn
+Link: qcom/qrb4210/wlanmdsp.mbn -> ../../ath10k/WCN3990/hw1.0/qcm2290/wlanmdsp.mbn
 File: ath10k/WCN3990/hw1.0/qcm2290/firmware-5.bin
 Link: ath10k/WCN3990/hw1.0/qrb4210/firmware-5.bin -> ../qcm2290/firmware-5.bin
 
@@ -5214,11 +5214,11 @@ Link: nvidia/gp104/acr/bl.bin -> ../../gp102/acr/bl.bin
 Link: nvidia/gp104/acr/ucode_load.bin -> ../../gp102/acr/ucode_load.bin
 Link: nvidia/gp104/acr/ucode_unload.bin -> ../../gp102/acr/ucode_unload.bin
 Link: nvidia/gp104/acr/unload_bl.bin -> ../../gp102/acr/unload_bl.bin
-Link: nvidia/gp104/gr/fecs_bl.bin -> ../../gp102/gr/fecs_bl.bin
+Link: nvidia/gp104/gr/fecs_bl.bin -> ../../gm200/gr/fecs_bl.bin
 File: nvidia/gp104/gr/fecs_data.bin
 File: nvidia/gp104/gr/fecs_inst.bin
 File: nvidia/gp104/gr/fecs_sig.bin
-Link: nvidia/gp104/gr/gpccs_bl.bin -> ../../gp102/gr/gpccs_bl.bin
+Link: nvidia/gp104/gr/gpccs_bl.bin -> ../../gm200/gr/gpccs_bl.bin
 File: nvidia/gp104/gr/gpccs_data.bin
 File: nvidia/gp104/gr/gpccs_inst.bin
 File: nvidia/gp104/gr/gpccs_sig.bin
@@ -5237,11 +5237,11 @@ Link: nvidia/gp106/acr/bl.bin -> ../../gp102/acr/bl.bin
 Link: nvidia/gp106/acr/ucode_load.bin -> ../../gp102/acr/ucode_load.bin
 Link: nvidia/gp106/acr/ucode_unload.bin -> ../../gp102/acr/ucode_unload.bin
 Link: nvidia/gp106/acr/unload_bl.bin -> ../../gp102/acr/unload_bl.bin
-Link: nvidia/gp106/gr/fecs_bl.bin -> ../../gp102/gr/fecs_bl.bin
+Link: nvidia/gp106/gr/fecs_bl.bin -> ../../gm200/gr/fecs_bl.bin
 File: nvidia/gp106/gr/fecs_data.bin
 Link: nvidia/gp106/gr/fecs_inst.bin -> ../../gp102/gr/fecs_inst.bin
 File: nvidia/gp106/gr/fecs_sig.bin
-Link: nvidia/gp106/gr/gpccs_bl.bin -> ../../gp102/gr/gpccs_bl.bin
+Link: nvidia/gp106/gr/gpccs_bl.bin -> ../../gm200/gr/gpccs_bl.bin
 File: nvidia/gp106/gr/gpccs_data.bin
 Link: nvidia/gp106/gr/gpccs_inst.bin -> ../../gp102/gr/gpccs_inst.bin
 File: nvidia/gp106/gr/gpccs_sig.bin
@@ -5924,10 +5924,10 @@ File: netronome/flower/nic_AMDA0096.nffw
 File: netronome/flower/nic_AMDA0097.nffw
 File: netronome/flower/nic_AMDA0058.nffw
 Link: netronome/flower/nic_AMDA0081.nffw -> nic_AMDA0097.nffw
-Link: netronome/flower/nic_AMDA0081-0001_1x40.nffw -> nic_AMDA0081.nffw
+Link: netronome/flower/nic_AMDA0081-0001_1x40.nffw -> nic_AMDA0097.nffw
 Link: netronome/flower/nic_AMDA0097-0001_2x40.nffw -> nic_AMDA0097.nffw
 Link: netronome/flower/nic_AMDA0099-0001_2x10.nffw -> nic_AMDA0099.nffw
-Link: netronome/flower/nic_AMDA0081-0001_4x10.nffw -> nic_AMDA0081.nffw
+Link: netronome/flower/nic_AMDA0081-0001_4x10.nffw -> nic_AMDA0097.nffw
 Link: netronome/flower/nic_AMDA0097-0001_4x10_1x40.nffw -> nic_AMDA0097.nffw
 Link: netronome/flower/nic_AMDA0099-0001_2x25.nffw -> nic_AMDA0099.nffw
 Link: netronome/flower/nic_AMDA0096-0001_2x10.nffw -> nic_AMDA0096.nffw
diff --git a/check_whence.py b/check_whence.py
index c270ee6020083044645353235a94eee0b2497960..d7742f1ed951acab6efc89916c7f6621ba56881b 100755
--- a/check_whence.py
+++ b/check_whence.py
@@ -115,12 +115,20 @@ def main():
         sys.stderr.write("E: %s listed in WHENCE as Link, is in tree\n" % name)
         ret = 1
 
+    invalid_targets = set(link[0] for link in links_list)
+    for link, target in sorted(links_list):
+        if target in invalid_targets:
+            sys.stderr.write(
+                "E: target %s of link %s is also a link\n" % (target, link)
+            )
+            ret = 1
+
     for name in sorted(list(known_files - git_files)):
         sys.stderr.write("E: %s listed in WHENCE does not exist\n" % name)
         ret = 1
 
-    # A link can point to another link, or to a file...
-    valid_targets = set(link[0] for link in links_list) | git_files
+    # A link can point to a file...
+    valid_targets = set(git_files)
 
     # ... or to a directory
     for target in set(valid_targets):

-- 
2.46.1

