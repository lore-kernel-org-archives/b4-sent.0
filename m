From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sun, 28 Apr 2024 19:12:02 +0300
Subject: [PATCH 2/2] packages: nvram: add asus,rt-ac{3200,5300} to
 set_wireless_led_behaviour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240428-asus-rt-ac3200-ac5300-v1-2-36cda9d6dcb6@arinc9.com>
References: <20240428-asus-rt-ac3200-ac5300-v1-0-36cda9d6dcb6@arinc9.com>
In-Reply-To: <20240428-asus-rt-ac3200-ac5300-v1-0-36cda9d6dcb6@arinc9.com>
To: =?utf-8?q?Rafa=C5=82_Mi=C5=82ecki?= <zajec5@gmail.com>
Cc: Tom Brautaset <tbrautaset@gmail.com>, openwrt-devel@lists.openwrt.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714320729; l=1858;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=f2v3ioRgGbWHWAe2vjt930Zof3iE2cQ0GNdDJXEfy5I=;
 b=gWRBPBsi9qqL/JtUVBJrX1e1eK+qQDeVd9C2B3KrPmxb1J+++AXD7i3TVUZacM4GTZraERkXK
 0UgSv+1S18OB8/vmeUQieVTEnpfzcI6z7TMr7SaGH4IB+3bCyh4eniS
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ASUS RT-AC3200 and ASUS RT-AC5300 to the set wireless LED behaviour
quirk. ASUS RT-AC3200's wireless chip is different than ASUS RT-AC5300's,
the environment variables for it are 0:ledbh10 and 1:ledbh10.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 package/utils/nvram/Makefile                 |  2 +-
 package/utils/nvram/files/nvram-bcm53xx.init | 11 +++++++++--
 2 files changed, 10 insertions(+), 3 deletions(-)

diff --git a/package/utils/nvram/Makefile b/package/utils/nvram/Makefile
index 8547bfa2d6..ef65ae0cc2 100644
--- a/package/utils/nvram/Makefile
+++ b/package/utils/nvram/Makefile
@@ -8,7 +8,7 @@
 include $(TOPDIR)/rules.mk
 
 PKG_NAME:=nvram
-PKG_RELEASE:=12
+PKG_RELEASE:=13
 
 PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
 
diff --git a/package/utils/nvram/files/nvram-bcm53xx.init b/package/utils/nvram/files/nvram-bcm53xx.init
index f47c944897..d17d301c45 100755
--- a/package/utils/nvram/files/nvram-bcm53xx.init
+++ b/package/utils/nvram/files/nvram-bcm53xx.init
@@ -19,16 +19,23 @@ clear_partialboots() {
 
 set_wireless_led_behaviour() {
 	# set Broadcom wireless LED behaviour for both radios
-	# 0:ledbh9 -> Behaviour of 2.4GHz LED
-	# 1:ledbh9 -> Behaviour of 5GHz LED
+	# 0:ledbh9 -> Behaviour of 2.4GHz LED of Broadcom BCM4366
+	# 1:ledbh9 -> Behaviour of 5GHz LED of Broadcom BCM4366
+	# 0:ledbh10 -> Behaviour of 2.4GHz LED of Broadcom BCM43602
+	# 1:ledbh10 -> Behaviour of 5GHz LED of Broadcom BCM43602
 	# 0x7 makes the wireless LEDs on, when radios are enabled, and blink when there's activity
 
 	case $(board_name) in
 		asus,rt-ac3100|\
+		asus,rt-ac5300|\
 		asus,rt-ac88u)
 			COMMIT=1
 			nvram set 0:ledbh9=0x7 set 1:ledbh9=0x7
 			;;
+		asus,rt-ac3200)
+			COMMIT=1
+			nvram set 0:ledbh10=0x7 set 1:ledbh10=0x7
+			;;
 	esac
 }
 

-- 
2.40.1

