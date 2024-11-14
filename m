From: Stephen Horvath <s.horvath@outlook.com.au>
Date: Thu, 14 Nov 2024 16:37:37 +1000
Subject: [PATCH 3/6] decode-dimms: Decode timings and other data for DDR5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241114-decode-ddr5-v1-3-0ed2db8ef30f@outlook.com.au>
References: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
In-Reply-To: <20241114-decode-ddr5-v1-0-0ed2db8ef30f@outlook.com.au>
To: linux-i2c@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.de>, 
 Stephen Horvath <s.horvath@outlook.com.au>, 
 Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=10006;
 i=s.horvath@outlook.com.au; s=2024-05-10; h=from:subject:message-id;
 bh=QQnH74lM3Wn95RbrOayLURRrS0J6h2df26+YO0HbPrQ=;
 b=owEBbQKS/ZANAwAKAYC8XiInGJ2jAcsmYgBnNZtx5NU01sTpgZ8EEPWSFZb+kf6T0WTWVip7H
 mBc/YZMc9CJAjMEAAEKAB0WIQTIAeBGYgifSxYwNMiAvF4iJxidowUCZzWbcQAKCRCAvF4iJxid
 o5pID/9EkLxCxykpBeiKyQ2Yvl6r5rQMLrHUrzOMhfN2KFWvdqX+TvtQScvvfH1qCCNA1fNOjKx
 N2J0oHkvPGZaSZp0W/M15u6aedIbEioE8UuqGQP4/UxQzclcF1CesjT4GRoBlVnoBuLKJ/E0BlL
 3v6IMkV/dZ/xiZaJRi8bTjwHwcyL0wntnxGFrWJ4yRDqyRXj0etL6+NGMd4ksI6llIV5C5al9VC
 4rWCTQ1IJvtgCPHLmnZdd3BAKBO6N9zMW+QpiqqiOl4apaPVaK0XVjKqYrPDhUbIWP8SJ9f2dcZ
 qg98As//COC/st2/bs6+CPTO47VZkGguHBlR7bVyOyyHcBB5oJfWc8vcHc/2o5w526JpBAaoU+i
 WUU3Wq5o0OFIoHQjD94QFUu5uUYj4jIBLcVeZKBwQFkINpKW60JD6T89SlmWkX5aoNk5Qu90eiD
 5+egbHZVb3cTTzDZtnCpOA25ZnB0LTaXg3GK/n8BeKp3WVdGuXlmQUHkJTWP+pgLm2/ymvU0Bk0
 8fuSoUNS6kX0J5VGIFA8QYCvYbsQbdw0zvnVikZ50e8Z3RI8gz+YKOOeHyHEv31JcQL3yZVYkLb
 6dAyc1eeUJ5BeEB5Awk7OLj7kJaq74JRI5spNzUmyjPLIh5bd8bcuWPs/mqIEy6Hf3QjCV2oX40
 NidbjZwiBzpHFAg==
X-Developer-Key: i=s.horvath@outlook.com.au; a=openpgp;
 fpr=C801E04662089F4B163034C880BC5E2227189DA3
X-Endpoint-Received: by B4 Relay for s.horvath@outlook.com.au/2024-05-10 with auth_id=277
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Decode size, timings, and other data for DDR5. I'm no expert at RAM
timings, so I hope it's correct. The values in my BIOS do seem to match
up with those here.

Although I am a little confused why most of the timings are one cycle
less than it seems they should be (e.g. 40-39-39-77, and not 40-40-40-78),
but the output is correct (according to BIOS and module specs).

There are also more timings that I'd like to add in the future.

Signed-off-by: Stephen Horvath <s.horvath@outlook.com.au>
---
 eeprom/decode-dimms | 230 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 230 insertions(+)

diff --git a/eeprom/decode-dimms b/eeprom/decode-dimms
index b395eafca9ba17725e391e18a70d303c0baaa291..4a19e962cd1f837ccdb6660caa8d198f65e3fc4f 100755
--- a/eeprom/decode-dimms
+++ b/eeprom/decode-dimms
@@ -2127,6 +2127,231 @@ sub decode_ddr4_sdram($)
 	}
 }
 
+# DDR5 Rounding Algorithm
+sub ddr5_round($$)
+{
+	my ($tck, $twr) = @_;
+	my $correction = 3;  # 0.30% per the rounding algorithm
+	my $new_twr = $twr * (1000 - $correction);
+	$tck = ($new_twr / $tck) + 1000;
+
+	return $twr / int($tck / 1000);
+}
+
+# Return combined time in ns
+sub ddr5_ns($$)
+{
+	my ($bytes, $index) = @_;
+
+	return (($bytes->[$index + 1] << 8) | $bytes->[$index]) / 1000;
+}
+
+# Parameter: EEPROM bytes 0-639 (using 1-255)
+sub decode_ddr5_sdram($)
+{
+	my $bytes = shift;
+	my ($ctime, $ctime_max);
+	my $ii;
+
+	my @module_types = (
+		{ type => "Reserved (0x00)",	},
+		{ type => "RDIMM",		},
+		{ type => "UDIMM",		},
+		{ type => "SODIMM",		},
+		{ type => "LRDIMM",		},
+		{ type => "CUDIMM",		},
+		{ type => "CSOUDIMM",		},
+		{ type => "MRDIMM",		},
+		{ type => "CAMM2",		},
+		{ type => "Reserved (0x09)",	},
+		{ type => "DDIMM",		},
+		{ type => "Solder down",	},
+		{ type => "Reserved (0x0C)",	},
+		{ type => "Reserved (0x0D)",	},
+		{ type => "Reserved (0x0E)",	},
+		{ type => "Reserved (0x0F)",	},
+	);
+
+# SPD revision
+	printl("SPD Revision", ($bytes->[1] >> 4) . "." . ($bytes->[1] & 0xf));
+
+	my $raw_type = $bytes->[3];
+	my $type = $raw_type & 0x0f;
+	printl("Module Type", $module_types[$type]->{type});
+
+# time bases
+	if (($bytes->[19] & 0x03) != 0x00 || ($bytes->[19] & 0xc0) != 0x00) {
+		print STDERR "Unknown time base values, can't decode\n";
+		return;
+	}
+
+	my $twr = ddr5_ns($bytes, 40);
+
+# speed
+	prints("Memory Characteristics");
+
+	$ctime = ddr5_ns($bytes, 20);
+	$ctime = ddr5_round($ctime, $twr);
+	$ctime_max = ddr5_ns($bytes, 22);
+	$ctime_max = ddr5_round($ctime_max, $twr);
+
+	my $ddrclk = 2 * (1000 / $ctime);
+	my $tbits = 8 << ($bytes->[235] & 7);
+	my $pcclk = int ($ddrclk * $tbits / 8);
+	# Round down to comply with Jedec
+	$pcclk = $pcclk - ($pcclk % 100);
+	$ddrclk = int ($ddrclk);
+	printl("Maximum module speed", "$ddrclk MT/s (PC5-${pcclk})");
+
+# Size computation
+	my $rank_mix = $bytes->[234] & 0x40;
+	my $sdram_width0 = 4 << (($bytes->[6] >> 5) & 0x07);
+	my $sdram_width1 = 4 << (($bytes->[10] >> 5) & 0x07);
+	my $bus_width = 8 << ($bytes->[235] & 0x07);
+	my $ranks = (($bytes->[234] >> 3) & 0x07) + 1;
+	my $subchannels = 1 << (($bytes->[235] >> 5) & 0x07);
+
+	my $die_count0 = (($bytes->[4] >> 5) & 0x07) + 1;
+	my $die_3ds0 = $die_count0 > 2;
+	if ($die_3ds0) { $die_count0 >>= 1; }
+
+	my $die_count1 = (($bytes->[8] >> 5) & 0x07) + 1;
+	my $die_3ds1 = $die_count1 > 2;
+	if ($die_3ds1) { $die_count1 >>= 1; }
+
+	my $die_count = $die_count0 + $die_count1;
+	my $density0 = ($bytes->[4] & 0x1f) * 4;
+	my $density1 = ($bytes->[8] & 0x1f) * 4;
+
+	my $cap0 = $subchannels * ($bus_width / $sdram_width0) * $die_count0 * ($density0 / 8) * $ranks;
+	my $cap1 = $subchannels * ($bus_width / $sdram_width1) * $die_count1 * ($density1 / 8) * $ranks;
+	my $cap = $cap0 + $cap1;
+
+	printl("Size", $cap . " GB");
+
+	printl("Banks x Rows x Columns x Bits" . ($rank_mix ? " (Even Rank)" : ""),
+	       join(' x ', (1 << (($bytes->[7] >> 5) & 0x07)) * (1 << ($bytes->[7] & 0x07)),
+			   (( $bytes->[5]       & 0x1f) + 16),
+			   ((($bytes->[5] >> 5) & 0x05) + 10),
+			   (8 << ($bytes->[235] & 0x07))));
+
+	printl_cond($rank_mix, "Banks x Rows x Columns x Bits (Odd Rank)",
+		    join(' x ', (1 << (($bytes->[11] >> 5) & 0x07)) * (1 << ($bytes->[11] & 0x07)),
+			        (( $bytes->[9]       & 0x1f) + 16),
+			        ((($bytes->[9] >> 5) & 0x05) + 10),
+			        (8 << ($bytes->[235] & 0x07))));
+
+	printl("SDRAM Device Width" . ($rank_mix ? " (Even Rank)" : ""), "$sdram_width0 bits");
+	printl_cond($rank_mix, "SDRAM Device Width (Odd Rank)", "$sdram_width1 bits");
+
+	printl("Ranks", $ranks);
+	printl_cond($ranks > 1, "Rank Mix",
+		    $rank_mix ? "Asymmetrical" : "Symmetrical");
+	printl("Primary Bus Width", (8 << ($bytes->[235] & 7))." bits");
+	printl_cond($bytes->[235] & 0x18, "Bus Width Extension", (($bytes->[235] & 0x18) >> 1) ." bits");
+
+	my $taa;
+	my $trcd;
+	my $trp;
+	my $tras;
+
+	$taa  = ddr5_ns($bytes, 30);
+	$trcd = ddr5_ns($bytes, 32);
+	$trp  = ddr5_ns($bytes, 34);
+	$tras = ddr5_ns($bytes, 36);
+
+	printl("AA-RCD-RP-RAS (cycles)",
+	       ddr4_core_timings(ceil(($taa * 997 / $ctime + 1000) / 1000),
+	       			 $ctime, $trcd, $trp, $tras));
+
+# latencies
+	my %cas;
+	my $cas_sup = ($bytes->[28] << 32) + ($bytes->[27] << 24) +
+		      ($bytes->[26] << 16) + ($bytes->[25] << 8) + $bytes->[24];
+	my $base_cas = 20;
+
+	for ($ii = 0; $ii < 40; $ii++) {
+		if ($cas_sup & (1 << $ii)) {
+			$cas{$base_cas + ($ii * 2)}++;
+		}
+	}
+	printl("Supported CAS Latencies", cas_latencies(keys %cas));
+
+# standard DDR5 speeds
+	prints("Timings at Standard Speeds");
+	foreach my $ctime_at_speed (5/22, 5/21, 5/20, 5/19, 5/18, 5/17, 5/16,
+				    5/15, 5/14, 5/13, 5/12, 5/11, 5/10, 5/9, 5/8) {
+		my $best_cas = 0;
+
+
+		# Find min CAS latency at this speed
+		for ($ii = 39; $ii >= 0; $ii--) {
+			next unless ($cas_sup & (1 << $ii));
+			if (ceil(($taa * 997 / $ctime_at_speed + 1000) / 1000) <= $base_cas + ($ii * 2)) {
+				$best_cas = $base_cas + ($ii * 2);
+			}
+		}
+
+		printl_cond($best_cas && $ctime_at_speed >= $ctime
+				      && $ctime_at_speed <= $ctime_max,
+			    "AA-RCD-RP-RAS (cycles)" . as_ddr(5, $ctime_at_speed),
+			    ddr4_core_timings($best_cas, $ctime_at_speed,
+					     $trcd, $trp, $tras));
+	}
+
+# more timing information
+	prints("Timing Parameters");
+
+	printl("Minimum Cycle Time (tCKmin)", tns3($ctime));
+	printl("Maximum Cycle Time (tCKmax)", tns3($ctime_max));
+	printl("Minimum CAS Latency Time (tAA)", tns3($taa));
+	printl("Minimum RAS to CAS Delay (tRCD)", tns3($trcd));
+	printl("Minimum Row Precharge Delay (tRP)", tns3($trp));
+	printl("Minimum Active to Precharge Delay (tRAS)", tns3($tras));
+	printl("Minimum Active to Auto-Refresh Delay (tRC)", tns3(ddr5_ns($bytes, 38)));
+	printl("Minimum Recovery Delay (tRFC1)", tns3(ddr5_ns($bytes, 42)));
+	printl("Minimum Recovery Delay (tRFC2)", tns3(ddr5_ns($bytes, 44)));
+	printl("Minimum Recovery Delay (tRFCsb)", tns3(ddr5_ns($bytes, 46)));
+	printl("Minimum Four Activate Window Delay (tFAW)", tns3(ddr5_ns($bytes, 82)) . " (" . $bytes->[84] . " cycles)");
+	printl("Minimum Row Active to Row Active Delay (tRRD_L)", tns3(ddr5_ns($bytes, 70)) . " (" . $bytes->[72] . " cycles)");
+	printl("Minimum CAS to CAS Delay (tCCD_L)", tns3(ddr5_ns($bytes, 73)) . " (" . $bytes->[75] . " cycles)");
+	printl("Minimum Write Recovery Time (tWR)", tns3(ddr5_ns($bytes, 40)));
+	printl("Minimum Write to Read Time (tWTR_S)", tns3(ddr5_ns($bytes, 88)) . " (" . $bytes->[90] . " cycles)");
+	printl("Minimum Write to Read Time (tWTR_L)", tns3(ddr5_ns($bytes, 85)) . " (" . $bytes->[87] . " cycles)");
+
+# miscellaneous stuff
+	prints("Other Information");
+
+	my $package_type0 = $die_3ds0 ? "3DS" :
+			    $die_count0 > 1 ? "Dual-die package" :
+			    $die_count0 == 1 ? "Monolithic" : "Unknown";
+	$package_type0 .= sprintf(" (%u dies)", $die_count0) if $die_count0 >= 2;
+	printl("Package Type" . ($rank_mix ? " (Even Rank)" : ""), $package_type0);
+
+	my $package_type1 = $die_3ds1 ? "3DS" :
+			    $die_count1 > 1 ? "Dual-die package" :
+			    $die_count1 == 1 ? "Monolithic" : "Unknown";
+	$package_type1 .= sprintf(" (%u dies)", $die_count1) if $die_count1 >= 2;
+	printl_cond($rank_mix, "Package Type (Odd Rank)", $package_type1);
+
+	my $ppr = $bytes->[12] >> 7;
+	printl("Post Package Repair",
+	       $ppr == 0x00 ? "One row per bank group" :
+	       $ppr == 0x01 ? "One row per bank" : "Unknown");
+	printl("Soft PPR Undo/Lock", $bytes->[12] & 0x20 ?
+	       "Supported" : "Not Supported");
+	printl("MBIST PPR", $bytes->[12] & 0x02 ?
+	       "Supported" : "Not Supported");
+
+	printl("Module Nominal Voltage",
+	       ($bytes->[16] & 0xf0) == 0x00 ? "1.1 V" :
+	       ($bytes->[16] & 0x0c) == 0x00 ? "Unknown (1.1 V operable)" :
+	       ($bytes->[16] & 0x03) == 0x00 ? "Unknown (1.1 V endurant)" : "Unknown");
+
+	printl("Thermal Sensor",
+	       $bytes->[14] & 0x08 ? "Supported" : "No");
+}
+
 # Parameter: EEPROM bytes 0-127 (using 4-5)
 sub decode_direct_rambus($)
 {
@@ -2177,6 +2402,10 @@ sub decode_rambus($)
 	"DDR4E SDRAM"	=> \&decode_ddr4_sdram,
 	"LPDDR4 SDRAM"	=> \&decode_ddr4_sdram,
 	"LPDDR4X SDRAM"	=> \&decode_ddr4_sdram,
+	"DDR5 SDRAM"	=> \&decode_ddr5_sdram,
+	"LPDDR5 SDRAM"	=> \&decode_ddr5_sdram,
+	"DDR5 NVDIMM-P"	=> \&decode_ddr5_sdram,
+	"LPDDR5X SDRAM"	=> \&decode_ddr5_sdram,
 	"Direct Rambus"	=> \&decode_direct_rambus,
 	"Rambus"	=> \&decode_rambus,
 );
@@ -2841,6 +3070,7 @@ for $current (0 .. $#dimm) {
 			"DDR4E SDRAM", "LPDDR3 SDRAM",	# 14, 15
 			"LPDDR4 SDRAM", "LPDDR4X SDRAM", # 16, 17
 			"DDR5 SDRAM", "LPDDR5 SDRAM",	# 18, 19
+			"DDR5 NVDIMM-P", "LPDDR5X SDRAM", # 20, 21
 		);
 		if ($bytes[2] < @type_list) {
 			$type = $type_list[$bytes[2]];

-- 
2.45.2

