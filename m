From: Stephen Horvath <s.horvath@outlook.com.au>
Date: Thu, 14 Nov 2024 16:37:38 +1000
Subject: [PATCH 4/6] decode-dimms: Decode DDR5 common module information
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241114-decode-ddr5-v1-4-0ed2db8ef30f@outlook.com.au>
References: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
In-Reply-To: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
To: linux-i2c@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.de>, 
 Stephen Horvath <s.horvath@outlook.com.au>, 
 Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2046;
 i=s.horvath@outlook.com.au; s=2024-05-10; h=from:subject:message-id;
 bh=DIxs5C5xxcrutDoF8/mc8o5mMwdN5y6h33snnMesEb0=;
 b=owEBbQKS/ZANAwAKAYC8XiInGJ2jAcsmYgBnNZtx6aw1AGIpoFCHHLkWsaRsM4PqZhna3zAlf
 aLERcLq0YOJAjMEAAEKAB0WIQTIAeBGYgifSxYwNMiAvF4iJxidowUCZzWbcQAKCRCAvF4iJxid
 o5+tD/4mDbisrDuru2XGWZdHUgFUeF19niyy+3V60FR172Db0Ftgqr/i9GZiltBEcN1CLFRgqy+
 6CXc61a/7qp9aF0fJSi/0Fzuxuc4AwWQ+QYImFqMPtfxHxY+Rj2luMrO2wYI4vEjVU6MbhiWqAU
 up+ed0ps2o/HaF0TYwQD71dbpLdL5iwd3m1aELwEw4tDIpXwj09PIlnQoWhTqaHsm1t3ITgPa/p
 9lZlaOymxy1akh5tUVj5eI0EU9zydqXjod74y5AxhxC+0VnoaPjHLmSjUiG8oA4q4ZgNo/9mABV
 sAUhJkrcG55TJZR4Gqx4Ge9oYt7zDCOGp8kCGb2mye/S3aMSZT+d/LupeeCuHz7DEvYW7FEr/S7
 5XwZfcZpPugkx6UNYTnVOZxgqKs9oyF+OpDhdJe1/bfOllUYQpg/5mYWLx2GS/2hINu/59Tq3dg
 bh1un7DV787soR5rv0mc0gShs1ACDkcCY6gD79DibZvdP3MkJ/AzZHkS3eockcoPqKVl8bd0zUp
 ozzJ/odaw/B0pyhc3msNku8p6gmG5AJzloBq2xVa2v1J7mBnUFrg05HIlQhna6U2o1qjGSv4Ik0
 7uShmEbl1tAmnU2bJ8kfdg5MoqM0VhQuPsUbDtHO38buHsNu+rmuZ1IJ1wwHu3zp9F8kabqa1Wh
 k0tX6ffH3FkUMDQ==
X-Developer-Key: i=s.horvath@outlook.com.au; a=openpgp;
 fpr=C801E04662089F4B163034C880BC5E2227189DA3
X-Endpoint-Received: by B4 Relay for s.horvath@outlook.com.au/2024-05-10 with auth_id=277
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Decode that extra manufacturer information that was mentioned earlier,
but only the info that is common between all DDR5 memory modules.
Also the physical size is here too.

Signed-off-by: Stephen Horvath <s.horvath@outlook.com.au>
---
 eeprom/decode-dimms | 36 ++++++++++++++++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/eeprom/decode-dimms b/eeprom/decode-dimms
index 4a19e962cd1f837ccdb6660caa8d198f65e3fc4f..f36af056a480d429203abc7e0dfda3751027948b 100755
--- a/eeprom/decode-dimms
+++ b/eeprom/decode-dimms
@@ -2350,6 +2350,42 @@ sub decode_ddr5_sdram($)
 
 	printl("Thermal Sensor",
 	       $bytes->[14] & 0x08 ? "Supported" : "No");
+
+# common module information
+	prints("Common Information");
+
+	my $spd_info_rev = $bytes->[192];
+	printl("SPD Module Info Revision", ($spd_info_rev >> 4) . "." . ($spd_info_rev & 0xf));
+
+	printl_cond($bytes->[196] & 0x80,
+		    "SPD Manufacturer",
+		    manufacturer_ddr3($bytes->[194], $bytes->[195]));
+	printl_cond($bytes->[200] & 0x80,
+		    "PMIC0 Manufacturer",
+		    manufacturer_ddr3($bytes->[198], $bytes->[199]));
+	printl_cond($bytes->[204] & 0x80,
+		    "PMIC1 Manufacturer",
+		    manufacturer_ddr3($bytes->[202], $bytes->[203]));
+	printl_cond($bytes->[208] & 0x80,
+		    "PMIC2 Manufacturer",
+		    manufacturer_ddr3($bytes->[206], $bytes->[207]));
+	printl_cond($bytes->[212] & 0xC0,
+		    "Thermal Sensors Manufacturer",
+		    manufacturer_ddr3($bytes->[210], $bytes->[211]));
+
+	prints("Physical Characteristics");
+
+	my $height = $bytes->[230] & 0x1f;
+	printl("Module Height",
+		$height == 0x00 ? "15 mm or less" :
+		$height == 0x1f ? "more than 45 mm" :
+		sprintf("%u mm", $height + 15));
+	printl("Module Thickness",
+		sprintf("%d mm front, %d mm back",
+			($bytes->[231] & 0x0f) + 1,
+			(($bytes->[231] >> 4) & 15) + 1));
+	printl("Module Reference Card",
+		ddr3_reference_card($bytes->[232], $bytes->[232]));
 }
 
 # Parameter: EEPROM bytes 0-127 (using 4-5)

-- 
2.45.2

