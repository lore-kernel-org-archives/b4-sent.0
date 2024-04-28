From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sun, 28 Apr 2024 19:12:01 +0300
Subject: [PATCH 1/2] bcm53xx: add support for ASUS RT-AC3200 and ASUS
 RT-AC5300
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240428-asus-rt-ac3200-ac5300-v1-1-36cda9d6dcb6@arinc9.com>
References: <20240428-asus-rt-ac3200-ac5300-v1-0-36cda9d6dcb6@arinc9.com>
In-Reply-To: <20240428-asus-rt-ac3200-ac5300-v1-0-36cda9d6dcb6@arinc9.com>
To: =?utf-8?q?Rafa=C5=82_Mi=C5=82ecki?= <zajec5@gmail.com>
Cc: Tom Brautaset <tbrautaset@gmail.com>, openwrt-devel@lists.openwrt.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714320729; l=2412;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=aNWIn4LtkVHBNOQ2LZZjtOJ+MBrzIhUh/NySRv0jmp0=;
 b=OvRtGT2otaTfgCjnDHqCj/ez/tiDeO5nEnc0d/P2o8M+jbx5qzXVLu0D09DDhKS8BqvCRdnb0
 woLqvaM7KIuCXmM5eVyIJme9vy2Ky407WKEvIRDUUoQze4yZ2MCitf8
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ASUS RT-AC3200 and ASUS RT-AC5300 are AC3200 and AC5300 routers,
respectively, featuring 5 Ethernet ports over the integrated Broadcom
switch.

ASUS RT-AC3200 hardware info:
* Processor: Broadcom BCM4709A0 dual-core @ 1.0 GHz
* Switch: BCM53012 in BCM4709A0
* DDR3 RAM: 256 MB
* Flash: 128 MB
* 2.4GHz: BCM43602 3x3 single chip 802.11b/g/n SoC
* 5GHz: BCM43602 3x3 two chips 802.11a/n/ac SoC
* Ports: 4 LAN Ports, 1 WAN Port

ASUS RT-AC5300 hardware info:
* Processor: Broadcom BCM4709C0 dual-core @ 1.4 GHz
* Switch: BCM53012 in BCM4709C0
* DDR3 RAM: 512 MB
* Flash: 128 MB
* 2.4GHz: BCM4366 4x4 single chip 802.11b/g/n SoC
* 5GHz: BCM4366 4x4 two chips 802.11a/n/ac SoC
* Ports: 4 LAN Ports, 1 WAN Port

Flashing instructions:
* Boot to CFE Recovery Mode by holding the reset button while power-on.
* Connect to the router with an ethernet cable.
* Set IPv4 address of the computer to 192.168.1.2 subnet 255.255.255.0.
* Head to http://192.168.1.1.
* Reset NVRAM.
* Upload the OpenWrt image.

CFE bootloader may reject flashing the image due to image integrity check.
In that case, follow the instructions below.

* Rename the OpenWrt image as firmware.trx.
* Run a TFTP server and make it serve the firmware.trx file.
* Run the URL below on a browser or curl.
  http://192.168.1.1/do.htm?cmd=flash+-noheader+192.168.1.2:firmware.trx+flash0.trx

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 target/linux/bcm53xx/image/Makefile | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/target/linux/bcm53xx/image/Makefile b/target/linux/bcm53xx/image/Makefile
index 88590c3755..a263e2caed 100644
--- a/target/linux/bcm53xx/image/Makefile
+++ b/target/linux/bcm53xx/image/Makefile
@@ -180,6 +180,22 @@ define Device/asus_rt-ac3100
 endef
 TARGET_DEVICES += asus_rt-ac3100
 
+define Device/asus_rt-ac3200
+  $(call Device/asus)
+  DEVICE_MODEL := RT-AC3200
+  DEVICE_PACKAGES := $(BRCMFMAC_43602A1) $(USB3_PACKAGES)
+  ASUS_PRODUCTID := RT-AC3200
+endef
+TARGET_DEVICES += asus_rt-ac3200
+
+define Device/asus_rt-ac5300
+  $(call Device/asus)
+  DEVICE_MODEL := RT-AC5300
+  DEVICE_PACKAGES := $(BRCMFMAC_4366B1) $(BRCMFMAC_4366C0) $(USB3_PACKAGES)
+  ASUS_PRODUCTID := RT-AC5300
+endef
+TARGET_DEVICES += asus_rt-ac5300
+
 define Device/asus_rt-ac56u
   $(call Device/asus)
   DEVICE_MODEL := RT-AC56U

-- 
2.40.1

