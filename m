From: Stephen Horvath <s.horvath@outlook.com.au>
Date: Thu, 14 Nov 2024 16:37:39 +1000
Subject: [PATCH 5/6] decode-dimms: Add basic decoding of type specific
 information for DDR5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241114-decode-ddr5-v1-5-0ed2db8ef30f@outlook.com.au>
References: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
In-Reply-To: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
To: linux-i2c@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.de>, 
 Stephen Horvath <s.horvath@outlook.com.au>, 
 Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3016;
 i=s.horvath@outlook.com.au; s=2024-05-10; h=from:subject:message-id;
 bh=xmqPimQasKa21RJvUonC9M0tQw4eLI+Xk5I4HAGl3eM=;
 b=owEBbQKS/ZANAwAKAYC8XiInGJ2jAcsmYgBnNZtxuoJg6+JOrWylS9sxKxe+htPek3xI3xmDT
 v4hGbPgBIqJAjMEAAEKAB0WIQTIAeBGYgifSxYwNMiAvF4iJxidowUCZzWbcQAKCRCAvF4iJxid
 o4v2D/9jJ2MDWc5dN9I0CjcQ/IXvJ+tzsS0hADztT/kt9agqKoigVlLPoOFpaXUCuRVlMqqvSCL
 yfIU4Ojw0RvBW7VwC1TFVXBToy1F8jbhY3dUZTuF/RxttfPcirz+ehBLt3LCBKSmDffMuJP7hiR
 r+OVGo4xBDQvoG7RknZn4LW4LY4RQrHLe34aW2kHz4CuIR7lFEoaC71qyOGHRw9nislAwLjAgEx
 abbsb1/3UBs+fJwk6pfSeifycGSIeQC0wDPrjFHKoiwFZu3LjBrLHU1Rw5tRFTprPi0tx5Apu5c
 Qxn476D4LN3MMOEuFg+Vvph0Ui4lDcJbNSYMxa15oHL0jStWjHkVl87XwnHG7m69kDXJqzGCT7+
 Ljev/5HsoA04LCT9tY9OUr+Gnxjhwb71WRHNxfrZiXXGWPtnvbDPdvsfpZebCZlv+eEF+BGn3m7
 vXGPxKvsIOlwKaNWuvgHUFCZcFvkvMFRISqF3iStJ+QvW7zCWZenH+kKEcPHL8ektMRx40T15ZX
 qUNoZ+XMqZmgg5bzB0nU/8I1nSze8A5hSb8B48oks2tjkJHK7vKw+tLbBxbnFjzT1dCvo2FZYW6
 M97od63PNmIF1f2GMMw45tmJRsZoeuTp06i4cWIYZRNSDCHW9dNHL/1pVQKqdTijMbT3fyuO6Ng
 gt7jm1i2FT4zjAw==
X-Developer-Key: i=s.horvath@outlook.com.au; a=openpgp;
 fpr=C801E04662089F4B163034C880BC5E2227189DA3
X-Endpoint-Received: by B4 Relay for s.horvath@outlook.com.au/2024-05-10 with auth_id=277
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Decode more manufacturer information, but only the info that is specific
to certain types of DDR5 memory modules. This is completely untested
since my modules don't expose this. I also only have UDIMMs.

Signed-off-by: Stephen Horvath <s.horvath@outlook.com.au>
---
 eeprom/decode-dimms | 71 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 71 insertions(+)

diff --git a/eeprom/decode-dimms b/eeprom/decode-dimms
index f36af056a480d429203abc7e0dfda3751027948b..a3b613bc869bbd1d8183958c42d05c3b3e3653ca 100755
--- a/eeprom/decode-dimms
+++ b/eeprom/decode-dimms
@@ -2386,6 +2386,77 @@ sub decode_ddr5_sdram($)
 			(($bytes->[231] >> 4) & 15) + 1));
 	printl("Module Reference Card",
 		ddr3_reference_card($bytes->[232], $bytes->[232]));
+
+# type-specific settings
+	if ($spd_info_rev == 0x11 &&
+	    ($type == 0x02 || # UDIMM
+	    $type == 0x03 || # SODIMM
+	    $type == 0x05 || # CUDIMM
+	    $type == 0x06)) { # CSODIMM
+		prints("Unbuffered Memory Module");
+
+		printl("Clock driver manufacturer",
+			manufacturer_ddr3($bytes->[240], $bytes->[241]));
+	}
+
+	if ($spd_info_rev == 0x11 &&
+	    ($type == 0x01 || # RDIMM
+	    $type == 0x04)) { # LRDIMM
+		prints("Registered Memory Module");
+
+		printl("Clock driver manufacturer",
+			manufacturer_ddr3($bytes->[240], $bytes->[241]));
+		printl("Data buffer manufacturer",
+			manufacturer_ddr3($bytes->[244], $bytes->[245]));
+	}
+
+	if ($spd_info_rev == 0x11 &&
+	    ($type == 0x07)) { # MRDIMM
+		prints("Multiplexed Rank Memory Module");
+
+		printl("Clock driver manufacturer",
+			manufacturer_ddr3($bytes->[240], $bytes->[241]));
+		printl("Data buffer manufacturer",
+			manufacturer_ddr3($bytes->[244], $bytes->[245]));
+	}
+
+	if ($spd_info_rev == 0x10 &&
+	    ($type == 0x0A)) { # DDIMM
+		prints("Differential Memory Module");
+
+		printl("Memory buffer manufacturer",
+			manufacturer_ddr3($bytes->[240], $bytes->[241]));
+	}
+
+	if ($spd_info_rev == 0x01 &&
+	    ($raw_type & 0xf0 == 0x90)) { # NVDIMM-N
+		prints("Non-Volatile Memory Module");
+
+		printl("Clock driver manufacturer",
+			manufacturer_ddr3($bytes->[240], $bytes->[241]));
+		printl("Data buffer manufacturer",
+			manufacturer_ddr3($bytes->[244], $bytes->[245]));
+	}
+
+	if ($spd_info_rev == 0x10 &&
+	    ($raw_type & 0xf0 == 0xA0)) { # NVDIMM-P
+		prints("Non-Volatile Memory Module");
+
+		printl("Clock driver manufacturer",
+			manufacturer_ddr3($bytes->[240], $bytes->[241]));
+		printl("Data buffer manufacturer",
+			manufacturer_ddr3($bytes->[244], $bytes->[245]));
+	}
+
+	if ($spd_info_rev == 0x10 &&
+	    ($type == 0x08)) { # CAMM2
+		prints("Compression Attached Memory Module");
+
+		printl("Clock driver 0 manufacturer",
+			manufacturer_ddr3($bytes->[240], $bytes->[241]));
+		printl("Clock driver 1 manufacturer",
+			manufacturer_ddr3($bytes->[244], $bytes->[245]));
+	}
 }
 
 # Parameter: EEPROM bytes 0-127 (using 4-5)

-- 
2.45.2

