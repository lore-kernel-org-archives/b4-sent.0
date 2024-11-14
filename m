From: Stephen Horvath <s.horvath@outlook.com.au>
Date: Thu, 14 Nov 2024 16:37:36 +1000
Subject: [PATCH 2/6] decode-dimms: Decode DDR5 Manufacturer Data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241114-decode-ddr5-v1-2-0ed2db8ef30f@outlook.com.au>
References: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
In-Reply-To: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
To: linux-i2c@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.de>, 
 Stephen Horvath <s.horvath@outlook.com.au>, 
 Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2612;
 i=s.horvath@outlook.com.au; s=2024-05-10; h=from:subject:message-id;
 bh=X+AyiLEN3z1mvM8HVdsBTc0C94+YdcCxZGbiG8Yc8z8=;
 b=owEBbQKS/ZANAwAKAYC8XiInGJ2jAcsmYgBnNZtwxV640gxcrt/p8+Gcp2OmC2qjcM3OSgx/a
 dLt+UkkkUSJAjMEAAEKAB0WIQTIAeBGYgifSxYwNMiAvF4iJxidowUCZzWbcAAKCRCAvF4iJxid
 o/fpD/wO3w1wRNeW81epW68dGr4rY/7t5l0EVMyMT1KoW6L0ZJ8w5L2313RNr+ot5cBI6KOPtEc
 ihnmWlEKOcs5z8ad41OaMtbrqj9WJ3kQ+Ph/Z/DcrJLbckKk0ePOJPSsfsMmV7+v/mlgtF+X/7W
 pW5xQvGvCf9tCZRdEjOKSmHOLy96E9ZvZumTeFmF7U9bxEjn/IuUdrM0m6dg3DIo4Wd1hxXoksQ
 P5FUAZDiRB+e3/nP7K/jcEQEyAZQfq5ayJZkNlC2mc1gwuc6wvg9A0qLHhHLfZwCThC/00yyTjP
 pceZ5+GxWeQaHbQl5zpsj3gXD/eH54SUR5HWG+vLPYLdWQ75434rk02JO2YZfQFRkAkBNWkAR2M
 0Ft2zvLwm0ZafmmIusMRbMm+NFxfktJAF8t+4drq6gX0FGkgYyoEi+xk4KtIuPHxkLLIICIEV3I
 7EbzcDUiogOhlyt/dkdqhMGzc5giWKeGA9RQPH1KZIkHtOpaqFlkvM+WCGZWoI0KVpmPjhaF5hh
 WlmyP5k/+H+eqewG9EipXQg1tZiupIV7cI3L8hUmgSaW5k28t4xMJlNocia/0rkmHOXClBQ7vRe
 inurInrKawtTZ7ylglIMbt3KgQo/H04Z7vSvSJQJJKDy3Gc979Lc6Wkgp1kASPfZ1kuARVS61Y7
 uTjarXWWBH0Af1A==
X-Developer-Key: i=s.horvath@outlook.com.au; a=openpgp;
 fpr=C801E04662089F4B163034C880BC5E2227189DA3
X-Endpoint-Received: by B4 Relay for s.horvath@outlook.com.au/2024-05-10 with auth_id=277
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Decode the DRAM's manufacturer data for DDR5.
There are more manufacturers in the common and type specific sections,
but I decided to limit myself to only reading the
'Manufacturing Information' section of the eeprom.

Signed-off-by: Stephen Horvath <s.horvath@outlook.com.au>
---
 eeprom/decode-dimms | 51 +++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 51 insertions(+)

diff --git a/eeprom/decode-dimms b/eeprom/decode-dimms
index 88ebe67d86d52486c8ce439d885fb3f9c89526b6..b395eafca9ba17725e391e18a70d303c0baaa291 100755
--- a/eeprom/decode-dimms
+++ b/eeprom/decode-dimms
@@ -2278,6 +2278,48 @@ sub decode_ddr4_mfg_data($)
 		    sprintf("0x%02X", $bytes->[349]));
 }
 
+# Parameter: EEPROM bytes 0-639 (using 512-554)
+sub decode_ddr5_mfg_data($)
+{
+	my $bytes = shift;
+
+	prints("Manufacturer Data");
+
+	printl("Module Manufacturer",
+	       manufacturer_ddr3($bytes->[512], $bytes->[513]));
+
+	printl_cond(spd_written(@{$bytes}[552..553]),
+		    "DRAM Manufacturer",
+		    manufacturer_ddr3($bytes->[552], $bytes->[553]));
+
+	printl_mfg_location_code($bytes->[514]);
+
+	printl_cond(spd_written(@{$bytes}[515..516]),
+		    "Manufacturing Date",
+		    manufacture_date($bytes->[515], $bytes->[516]));
+
+	printl_mfg_assembly_serial(@{$bytes}[517..520]);
+
+	printl("Part Number", part_number(@{$bytes}[521..550]));
+
+	printl_cond(spd_written(@{$bytes}[551]),
+		    "Revision Code",
+		    sprintf("0x%02X", $bytes->[551]));
+
+	if ($bytes->[554] != 0xff) {
+		# DRAM Stepping may be a number or an uppercase ASCII letter
+		# 0x00-0xfe is valid, 0xff is invalid
+		my $stepping = $bytes->[554];
+		if ($stepping < 0x41 || $stepping > 0x5a) {
+			printl("DRAM Stepping",
+			       sprintf("0x%02X", $stepping));
+		} else {
+			printl("DRAM Stepping",
+			       sprintf("%c", $stepping));
+		}
+	}
+}
+
 # Parameter: EEPROM bytes 0-127 (using 64-98)
 sub decode_manufacturing_information($)
 {
@@ -2828,6 +2870,15 @@ for $current (0 .. $#dimm) {
 		} elsif (!$use_hexdump && $dimm[$current]->{driver} ne "ee1004") {
 			print STDERR "HINT: You should be using the ee1004 driver instead of the $dimm[$current]->{driver} driver\n";
 		}
+	} elsif ($type eq "DDR5 SDRAM" ||
+		 $type eq "LPDDR5 SDRAM" ||
+		 $type eq "DDR5 NVDIMM-P" ||
+		 $type eq "LPDDR5X SDRAM") {
+		if (@bytes >= 640) {
+			# Decode DDR5-specific manufacturing data in bytes
+			# 512-639
+			decode_ddr5_mfg_data(\@bytes);
+		}
 	} else {
 		# Decode next 35 bytes (64-98, common to most
 		# memory types)

-- 
2.45.2

