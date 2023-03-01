From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:26 +0000
Subject: [PATCH v2 01/16] WHENCE: remove trailing white space
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-1-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=2576;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=mgS7Y0cvjYzJn1nYe+Iu8x0mMDsUQ+mbNDsX3/lyyJ4=;
 b=Cvw7FZHaxVeU09kL/uInBWXYflK1kyUgHpUY4wewE+WHpbHWFGCi1tkpDqI8MX4FG/ciuag6D
 3L7z1w/jHI0DkeNK4391LV8qdkwew3GDw/gwUqWYQxliZigGjJlXuaR
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 WHENCE | 36 ++++++++++++++++++------------------
 1 file changed, 18 insertions(+), 18 deletions(-)

diff --git a/WHENCE b/WHENCE
index e957cc9..205162e 100644
--- a/WHENCE
+++ b/WHENCE
@@ -395,7 +395,7 @@ Version: 8.07.00 MIDQ
 
 Licence: Redistributable. See LICENCE.qla2xxx for details
 
-Available from http://ldriver.qlogic.com/firmware/ 
+Available from http://ldriver.qlogic.com/firmware/
 
 --------------------------------------------------------------------------
 
@@ -2563,29 +2563,29 @@ Licence: Redistributable. See LICENCE.ueagle-atm4-firmware for details
 Driver: ueagle-atm - Driver for USB ADSL Modems based on Eagle I,II,III
 
 File: ueagle-atm/930-fpga.bin
-File: ueagle-atm/CMVeiWO.bin    
-File: ueagle-atm/CMVepFR10.bin  
-File: ueagle-atm/DSP9p.bin	
+File: ueagle-atm/CMVeiWO.bin
+File: ueagle-atm/CMVepFR10.bin
+File: ueagle-atm/DSP9p.bin
 File: ueagle-atm/eagleIII.fw
-File: ueagle-atm/adi930.fw     
-File: ueagle-atm/CMVep.bin      
-File: ueagle-atm/CMVepFR.bin    
+File: ueagle-atm/adi930.fw
+File: ueagle-atm/CMVep.bin
+File: ueagle-atm/CMVepFR.bin
 File: ueagle-atm/DSPei.bin
-File: ueagle-atm/CMV9i.bin     
-File: ueagle-atm/CMVepES03.bin  
-File: ueagle-atm/CMVepIT.bin    
+File: ueagle-atm/CMV9i.bin
+File: ueagle-atm/CMVepES03.bin
+File: ueagle-atm/CMVepIT.bin
 File: ueagle-atm/DSPep.bin
-File: ueagle-atm/CMV9p.bin     
-File: ueagle-atm/CMVepES.bin    
-File: ueagle-atm/CMVepWO.bin    
+File: ueagle-atm/CMV9p.bin
+File: ueagle-atm/CMVepES.bin
+File: ueagle-atm/CMVepWO.bin
 File: ueagle-atm/eagleI.fw
-File: ueagle-atm/CMVei.bin     
-File: ueagle-atm/CMVepFR04.bin  
-File: ueagle-atm/DSP9i.bin	    
+File: ueagle-atm/CMVei.bin
+File: ueagle-atm/CMVepFR04.bin
+File: ueagle-atm/DSP9i.bin
 File: ueagle-atm/eagleII.fw
 Version: 1.1
 
-Licence: Redistributable. Based on 
+Licence: Redistributable. Based on
          https://mail.gna.org/public/eagleusb-dev/2004-11/msg00172.html
 
 --------------------------------------------------------------------------
@@ -3951,7 +3951,7 @@ License:
 
   This SDD ("Static Dynamic Data") file is licensed strictly for use with
   the Sagrad WiFi modules (such as the SG901-1091/1098) that utilize the
-  cw1200 driver. There is no warranty expressed or implied about its 
+  cw1200 driver. There is no warranty expressed or implied about its
   fitness for any purpose.
 
   Permission is hereby granted for the distribution of this SDD file as

-- 
2.39.2

