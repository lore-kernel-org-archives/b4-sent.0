From: Stephen Horvath <s.horvath@outlook.com.au>
Date: Thu, 14 Nov 2024 16:37:35 +1000
Subject: [PATCH 1/6] decode-dimms: Implement DDR5 checksum parsing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241114-decode-ddr5-v1-1-0ed2db8ef30f@outlook.com.au>
References: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
In-Reply-To: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
To: linux-i2c@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.de>, 
 Stephen Horvath <s.horvath@outlook.com.au>, 
 Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2979;
 i=s.horvath@outlook.com.au; s=2024-05-10; h=from:subject:message-id;
 bh=4QAYYDVnAHLOSY3cYarYhZv9TKmYHfU0kIsepg5zKVM=;
 b=owEBbQKS/ZANAwAKAYC8XiInGJ2jAcsmYgBnNZtwQKU+SUFBvzfpk4QnPZ9dbLFo2uh/U8+cw
 jpgqCojheCJAjMEAAEKAB0WIQTIAeBGYgifSxYwNMiAvF4iJxidowUCZzWbcAAKCRCAvF4iJxid
 o0tvD/90+QuXjFr/6T6iZvx1L0B5R8iUI7YmnrPQgMs0gQe6CuoQp+SLRqNObnstOrgg9ooMZVh
 cytPXdDu4aM/FFpPwZw1bRmT1H6SUg2OBUR8Q7+uiPw9D6PKdjLtArgc5CvoJ1wkosThorgHqlO
 jcpEak90JeRr0zfVZ4kL6BQpeKD/ezK0mAiPwfq3A9XjBWuLpJ5829yo2NAmfyUyQ5au0c+12fi
 sfzbM4lv2bsWifsUHDtThk/BBjzCnT4Y399Qdk0ZJv86V6dctZPc7Op0YCNr1jj8RatQRX6o6RQ
 NcfpUVg1lXabFlrv4KoLaXIBLZLNLaoE2ZoGhpGUC3X4TJqQFf+pPa+bqLNR/m/Dh+IsQmASDMZ
 FdHAFLfbvHvv6hPUi7b6Fjc2tt1AtuEuX84Ca+EjllhtSE+LydkfjkOoTOOHjbKyk8oMPiNnYDZ
 bGFXSYu9JqS++yDPrlRoaTtFduyG/P/7mGE2AtHTD/+FIJG+iWxdHxYulNSDkKn4BKZMl1YktJh
 jYFU4L6OA/gUoj1XR0IRc9kKmIAngXMkd59sZCmuPmCzOmHR8CzFtPeAdJsPugFVEqQ9HNwdsYz
 xlCzQxrmTJsrCEcEbs0RFGxtyT2hCWuH6m4o6tmCMEwoKvKsL5WJOcV5E5jx2YZU61LcgsWh2LU
 5tS75bwIF8vcdyQ==
X-Developer-Key: i=s.horvath@outlook.com.au; a=openpgp;
 fpr=C801E04662089F4B163034C880BC5E2227189DA3
X-Endpoint-Received: by B4 Relay for s.horvath@outlook.com.au/2024-05-10 with auth_id=277
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The code here was mostly written by Guenter Roeck with some modifications
for compatibility with other types by me, but it was originally written
only to verify that the eeprom is being read correctly while developing
spd5118. It looks okay to me, although there might be a better way of
figuring out the amount of bytes needed to check the checksum.

Link: https://lore.kernel.org/linux-hwmon/efb77b37-30e5-48a8-b4af-eb9995a2882b@roeck-us.net/
Cc: Guenter Roeck <linux@roeck-us.net>
Signed-off-by: Stephen Horvath <s.horvath@outlook.com.au>
---
 eeprom/decode-dimms | 24 ++++++++++++++++++++----
 1 file changed, 20 insertions(+), 4 deletions(-)

diff --git a/eeprom/decode-dimms b/eeprom/decode-dimms
index 32e840a107cd3425039fcbc6ce317e2ef610acc1..88ebe67d86d52486c8ce439d885fb3f9c89526b6 100755
--- a/eeprom/decode-dimms
+++ b/eeprom/decode-dimms
@@ -2402,7 +2402,12 @@ sub spd_sizes($)
 	my $bytes = shift;
 	my $type = $bytes->[2];
 
-	if ($type == 12 || $type == 14 || $type == 16 || $type == 17) {
+	if ($type == 18 || $type == 19 || $type == 20 || $type == 21) {
+		# DDR5
+		my $spd_len = 256 * ((($bytes->[0] >> 4) & 7) + 1);
+		my $used = $spd_len;
+		return ($spd_len, $used);
+	} elsif ($type == 12 || $type == 14 || $type == 16 || $type == 17) {
 		# DDR4
 		my $spd_len = 256 * (($bytes->[0] >> 4) & 7);
 		my $used = 128 * ($bytes->[0] & 15);
@@ -2511,10 +2516,16 @@ sub calculate_crc($$$)
 sub check_crc($)
 {
 	my $bytes = shift;
+	my $is_ddr5 = ($bytes->[0] & 0x70) == 0x30;
 	my $crc_cover = $bytes->[0] & 0x80 ? 116 : 125;
+	my $crc_start = 126;
+	if ($is_ddr5) {
+	    $crc_cover = 509;
+	    $crc_start = 510;
+	}
 	my $crc = calculate_crc($bytes, 0, $crc_cover + 1);
 
-	my $dimm_crc = ($bytes->[127] << 8) | $bytes->[126];
+	my $dimm_crc = ($bytes->[$crc_start + 1] << 8) | $bytes->[$crc_start];
 	return ("EEPROM CRC of bytes 0-$crc_cover",
 		($dimm_crc == $crc) ? 1 : 0,
 		sprintf("0x%04X", $dimm_crc),
@@ -2617,7 +2628,8 @@ sub get_dimm_list
 	if ($use_sysfs) {
 		@drivers = ('eeprom',
 			    'at24',
-			    'ee1004');	# DDR4
+			    'ee1004',	# DDR4
+			    'spd5118');	# DDR5
 	} else {
 		@drivers = ('eeprom');
 		$dir = '/proc/sys/dev/sensors';
@@ -2642,7 +2654,8 @@ sub get_dimm_list
 				next unless defined $attr &&
 					    ($attr eq "eeprom" ||
 					     $attr eq "spd" ||
-					     $attr eq "ee1004");	# DDR4
+					     $attr eq "ee1004" ||	# DDR4
+					     $attr eq "spd5118");	# DDR5
 			} else {
 				next unless $file =~ /^eeprom-/;
 			}
@@ -2684,6 +2697,9 @@ for my $i (0 .. $#dimm) {
 		 $dimm[$i]->{chk_spd}, $dimm[$i]->{chk_calc}) =
 			checksum(\@bytes);
 	} else {
+		if (($bytes[0] & 0x70) == 0x30) {	# DDR5's checksum is at 510-511
+			push(@bytes, readspd(@bytes, 512, $dimm[$i]->{file}));
+		}
 		($dimm[$i]->{chk_label}, $dimm[$i]->{chk_valid},
 		 $dimm[$i]->{chk_spd}, $dimm[$i]->{chk_calc}) =
 			check_crc(\@bytes);

-- 
2.45.2

