From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:29 +0000
Subject: [PATCH v2 04/16] WHENCE: remove duplicate File entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-4-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=2057;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=W4W/vcckzNejCfAKf2O2Ih3Dx4xTlABXVUtkRUnu0fI=;
 b=WMbiqjn62dW9gv4xl85LnlNaCwcxgMFcbAaygIh1gz8XRR7HfcTpPkc+LRY5w/swXkWmEAO/v
 Vd+qzYvieunBbv1r8wuFe+fBg1CeOrMYUT6+QTUHssF1Xjhr4v7vsKj
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 WHENCE | 19 -------------------
 1 file changed, 19 deletions(-)

diff --git a/WHENCE b/WHENCE
index 214952e..7de6d6b 100644
--- a/WHENCE
+++ b/WHENCE
@@ -1073,10 +1073,6 @@ Version: 75.27f1c37b.0
 File: iwlwifi-so-a0-jf-b0-77.ucode
 Version: 74.f92b5fed.0
 
-File: iwlwifi-so-a0-gf-a0.pnvm
-
-File: iwlwifi-so-a0-gf4-a0.pnvm
-
 File: iwlwifi-ty-a0-gf-a0.pnvm
 
 Licence: Redistributable. See LICENCE.iwlwifi_firmware for details
@@ -2980,19 +2976,6 @@ Licence: Redistributable. See LICENCE.rtlwifi_firmware.txt for details.
 
 --------------------------------------------------------------------------
 
-Driver: r8723au - Realtek 802.11n WLAN driver for RTL8723AU
-
-Info: Taken from Realtek driver rtl8723A_WiFi_linux_v4.1.3_6044.20121224
-      Firmware is embedded in the driver as data statements. This info
-      has been extracted into a binary file.
-File: rtlwifi/rtl8723aufw_A.bin
-File: rtlwifi/rtl8723aufw_B.bin
-File: rtlwifi/rtl8723aufw_B_NoBT.bin
-
-Licence: Redistributable. See LICENCE.rtlwifi_firmware.txt for details.
-
---------------------------------------------------------------------------
-
 Driver: rtl8188ee - Realtek 802.11n WLAN driver for RTL8188EE
 
 Info: Taken from Realtek version rtl_92ce_92se_92de_8723ae_88ee_linux_mac80211_0010.0109.2013
@@ -5942,8 +5925,6 @@ Link: cirrus/cs35l41-dsp1-spk-prot-103c8995.wmfw -> cs35l41/v6.61.1/halo_cspl_RA
 Link: cirrus/cs35l41-dsp1-spk-cali-103c8995.wmfw -> cs35l41/v6.61.1/halo_cspl_RAM_revB2_29.63.1.wmfw
 Link: cirrus/cs35l41-dsp1-spk-prot-103c89c6.wmfw -> cs35l41/v6.61.1/halo_cspl_RAM_revB2_29.63.1.wmfw
 Link: cirrus/cs35l41-dsp1-spk-cali-103c89c6.wmfw -> cs35l41/v6.61.1/halo_cspl_RAM_revB2_29.63.1.wmfw
-File: cirrus/cs35l41-dsp1-spk-cali-103c8971.bin
-File: cirrus/cs35l41-dsp1-spk-prot-103c8971.bin
 File: cirrus/cs35l41-dsp1-spk-prot-103c8971.bin
 File: cirrus/cs35l41-dsp1-spk-cali-103c8971.bin
 File: cirrus/cs35l41-dsp1-spk-prot-103c8972.bin

-- 
2.39.2

