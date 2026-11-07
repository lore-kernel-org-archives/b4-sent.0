From: Ruk Doe <info@doany.io>
Date: Sat, 07 Nov 2026 09:55:55 +0000
Subject: [PATCH] Revert "media: siano: Convert to use sysfs_emit_at() API"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-siano-revert-v1-1-704ffc11fc6b@doany.io>
X-B4-Tracking: v=1; b=H4sIAKr17moC/yXMQQ5AMBCF4avIrDXplGjiKmJRNRiLkg4iEXdXL
 L/kvf8CocgkUGcXRDpYeAkJmGfgJxdGUtwng9GmQtRWCbuwqDSluKnSocdCU2mshXRZIw18frm
 m/S17N5Pf3gbc9wOjJowDcAAAAA==
X-Change-ID: 20261107-siano-revert-4a1c130e4277
To: Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, Hans Verkuil <hverkuil@kernel.org>, 
 linux-kernel@vger.kernel.org, ye xingchen <ye.xingchen@zte.com.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794045354; l=21809;
 i=info@doany.io; s=20261107; h=from:subject:message-id;
 bh=VIkMRaNTHHjCDP+MZEIhs6QNuorbd9wE0fCLPYDZojw=;
 b=h76ls/N0EsaMzosAw/8e3/CqKNysRmostbKVr3Bj16r9scFtYyC0OWIBpbxRldg1yJ5CMhgD8
 zbmnqBYUHm0BQ9o9wvUDMKQxACsVHyqzt9Ewly8LrY6R+NOlrXECfNK
X-Developer-Key: i=info@doany.io; a=ed25519;
 pk=TBxzz5FhdHVfnNz1WIg8x49EuXI/bLC0e8VgmH2Hg0U=
X-Endpoint-Received: by B4 Relay for info@doany.io/20261107 with auth_id=1440
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit 2f7d0c94396e8df1db6a5bc3b6ea272d640e874d.

The statistics text is written to smsdvb_debugfs::stats_data, a
PAGE_SIZE array that sits a few bytes into a kzalloc()ed struct, after
a kref and a spinlock, so it is not page aligned. sysfs_emit_at() is
meant for sysfs show() buffers and rejects any buffer with a non-zero
offset_in_page(): it WARNs and returns 0 without writing anything.

As a result, stats_count stays 0, so the "already filled" check at the
top of the print functions never short-circuits. Since v6.6, every
statistics message from the device runs the whole formatter again, and
each of its sysfs_emit_at() calls WARNs with a full backtrace from the
URB completion path:

  RIP: 0010:sysfs_emit_at+0x69/0xd0
  Call Trace:
   <IRQ>
   smsdvb_print_isdb_stats_ex+0xb7/0x670 [smsdvb]
   smsdvb_update_isdbt_stats_ex+0x30/0x880 [smsdvb]
   smsdvb_onresponse+0x2cc/0x740 [smsdvb]
   smscore_onresponse+0x8f/0x530 [smsmdtv]
   smsusb_onresponse+0xae/0x1a0 [smsusb]
   __usb_hcd_giveback_urb+0xac/0x130

Reads of the debugfs "stats" file also never return any data.

With a PX-S1UD (3275:0080) receiving ISDB-T, the reporter counted 536
warnings in 3 seconds and saw /var/log/syslog and kern.log each grow to
about 101 GB and fill the root file system. The reporter also sees
block noise and TS continuity errors that do not occur with the same
tuner on Windows, and another user attributes such TS packet drops to
the warning flood. Distribution kernels such as Ubuntu's enable
CONFIG_SMS_SIANO_DEBUGFS, so this hits ordinary users, not only
developers.

stats_data is not a sysfs buffer, so go back to scnprintf() bounded by
PAGE_SIZE - n, as the code did before.

Fixes: 2f7d0c94396e ("media: siano: Convert to use sysfs_emit_at() API")
Cc: stable@vger.kernel.org
Closes: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2162139
Signed-off-by: Ruk Doe <info@doany.io>
---
Compile tested only, with W=1, on top of media-committers next
(v7.4-rc1); I don't have the hardware. The patch is a plain revert and
restores the print functions to their exact state before 2f7d0c94396e.

This is a regression since v6.6, so please consider it for fixes.
---
 drivers/media/common/siano/smsdvb-debugfs.c | 334 ++++++++++++++++++----------
 1 file changed, 217 insertions(+), 117 deletions(-)

diff --git a/drivers/media/common/siano/smsdvb-debugfs.c b/drivers/media/common/siano/smsdvb-debugfs.c
index c482777e1..71517dd86 100644
--- a/drivers/media/common/siano/smsdvb-debugfs.c
+++ b/drivers/media/common/siano/smsdvb-debugfs.c
@@ -45,48 +45,89 @@ static void smsdvb_print_dvb_stats(struct smsdvb_debugfs *debug_data,
 
 	buf = debug_data->stats_data;
 
-	n += sysfs_emit_at(buf, n, "is_rf_locked = %d\n", p->is_rf_locked);
-	n += sysfs_emit_at(buf, n, "is_demod_locked = %d\n", p->is_demod_locked);
-	n += sysfs_emit_at(buf, n, "is_external_lna_on = %d\n", p->is_external_lna_on);
-	n += sysfs_emit_at(buf, n, "SNR = %d\n", p->SNR);
-	n += sysfs_emit_at(buf, n, "ber = %d\n", p->ber);
-	n += sysfs_emit_at(buf, n, "FIB_CRC = %d\n", p->FIB_CRC);
-	n += sysfs_emit_at(buf, n, "ts_per = %d\n", p->ts_per);
-	n += sysfs_emit_at(buf, n, "MFER = %d\n", p->MFER);
-	n += sysfs_emit_at(buf, n, "RSSI = %d\n", p->RSSI);
-	n += sysfs_emit_at(buf, n, "in_band_pwr = %d\n", p->in_band_pwr);
-	n += sysfs_emit_at(buf, n, "carrier_offset = %d\n", p->carrier_offset);
-	n += sysfs_emit_at(buf, n, "modem_state = %d\n", p->modem_state);
-	n += sysfs_emit_at(buf, n, "frequency = %d\n", p->frequency);
-	n += sysfs_emit_at(buf, n, "bandwidth = %d\n", p->bandwidth);
-	n += sysfs_emit_at(buf, n, "transmission_mode = %d\n", p->transmission_mode);
-	n += sysfs_emit_at(buf, n, "modem_state = %d\n", p->modem_state);
-	n += sysfs_emit_at(buf, n, "guard_interval = %d\n", p->guard_interval);
-	n += sysfs_emit_at(buf, n, "code_rate = %d\n", p->code_rate);
-	n += sysfs_emit_at(buf, n, "lp_code_rate = %d\n", p->lp_code_rate);
-	n += sysfs_emit_at(buf, n, "hierarchy = %d\n", p->hierarchy);
-	n += sysfs_emit_at(buf, n, "constellation = %d\n", p->constellation);
-	n += sysfs_emit_at(buf, n, "burst_size = %d\n", p->burst_size);
-	n += sysfs_emit_at(buf, n, "burst_duration = %d\n", p->burst_duration);
-	n += sysfs_emit_at(buf, n, "burst_cycle_time = %d\n", p->burst_cycle_time);
-	n += sysfs_emit_at(buf, n, "calc_burst_cycle_time = %d\n", p->calc_burst_cycle_time);
-	n += sysfs_emit_at(buf, n, "num_of_rows = %d\n", p->num_of_rows);
-	n += sysfs_emit_at(buf, n, "num_of_padd_cols = %d\n", p->num_of_padd_cols);
-	n += sysfs_emit_at(buf, n, "num_of_punct_cols = %d\n", p->num_of_punct_cols);
-	n += sysfs_emit_at(buf, n, "error_ts_packets = %d\n", p->error_ts_packets);
-	n += sysfs_emit_at(buf, n, "total_ts_packets = %d\n", p->total_ts_packets);
-	n += sysfs_emit_at(buf, n, "num_of_valid_mpe_tlbs = %d\n", p->num_of_valid_mpe_tlbs);
-	n += sysfs_emit_at(buf, n, "num_of_invalid_mpe_tlbs = %d\n", p->num_of_invalid_mpe_tlbs);
-	n += sysfs_emit_at(buf, n, "num_of_corrected_mpe_tlbs = %d\n",
-			   p->num_of_corrected_mpe_tlbs);
-	n += sysfs_emit_at(buf, n, "ber_error_count = %d\n", p->ber_error_count);
-	n += sysfs_emit_at(buf, n, "ber_bit_count = %d\n", p->ber_bit_count);
-	n += sysfs_emit_at(buf, n, "sms_to_host_tx_errors = %d\n", p->sms_to_host_tx_errors);
-	n += sysfs_emit_at(buf, n, "pre_ber = %d\n", p->pre_ber);
-	n += sysfs_emit_at(buf, n, "cell_id = %d\n", p->cell_id);
-	n += sysfs_emit_at(buf, n, "dvbh_srv_ind_hp = %d\n", p->dvbh_srv_ind_hp);
-	n += sysfs_emit_at(buf, n, "dvbh_srv_ind_lp = %d\n", p->dvbh_srv_ind_lp);
-	n += sysfs_emit_at(buf, n, "num_mpe_received = %d\n", p->num_mpe_received);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "is_rf_locked = %d\n", p->is_rf_locked);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "is_demod_locked = %d\n", p->is_demod_locked);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "is_external_lna_on = %d\n", p->is_external_lna_on);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "SNR = %d\n", p->SNR);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "ber = %d\n", p->ber);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "FIB_CRC = %d\n", p->FIB_CRC);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "ts_per = %d\n", p->ts_per);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "MFER = %d\n", p->MFER);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "RSSI = %d\n", p->RSSI);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "in_band_pwr = %d\n", p->in_band_pwr);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "carrier_offset = %d\n", p->carrier_offset);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "modem_state = %d\n", p->modem_state);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "frequency = %d\n", p->frequency);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "bandwidth = %d\n", p->bandwidth);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "transmission_mode = %d\n", p->transmission_mode);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "modem_state = %d\n", p->modem_state);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "guard_interval = %d\n", p->guard_interval);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "code_rate = %d\n", p->code_rate);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "lp_code_rate = %d\n", p->lp_code_rate);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "hierarchy = %d\n", p->hierarchy);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "constellation = %d\n", p->constellation);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "burst_size = %d\n", p->burst_size);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "burst_duration = %d\n", p->burst_duration);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "burst_cycle_time = %d\n", p->burst_cycle_time);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "calc_burst_cycle_time = %d\n",
+		      p->calc_burst_cycle_time);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "num_of_rows = %d\n", p->num_of_rows);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "num_of_padd_cols = %d\n", p->num_of_padd_cols);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "num_of_punct_cols = %d\n", p->num_of_punct_cols);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "error_ts_packets = %d\n", p->error_ts_packets);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "total_ts_packets = %d\n", p->total_ts_packets);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "num_of_valid_mpe_tlbs = %d\n", p->num_of_valid_mpe_tlbs);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "num_of_invalid_mpe_tlbs = %d\n", p->num_of_invalid_mpe_tlbs);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "num_of_corrected_mpe_tlbs = %d\n", p->num_of_corrected_mpe_tlbs);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "ber_error_count = %d\n", p->ber_error_count);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "ber_bit_count = %d\n", p->ber_bit_count);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "sms_to_host_tx_errors = %d\n", p->sms_to_host_tx_errors);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "pre_ber = %d\n", p->pre_ber);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "cell_id = %d\n", p->cell_id);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "dvbh_srv_ind_hp = %d\n", p->dvbh_srv_ind_hp);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "dvbh_srv_ind_lp = %d\n", p->dvbh_srv_ind_lp);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "num_mpe_received = %d\n", p->num_mpe_received);
 
 	debug_data->stats_count = n;
 	spin_unlock(&debug_data->lock);
@@ -107,49 +148,78 @@ static void smsdvb_print_isdb_stats(struct smsdvb_debugfs *debug_data,
 
 	buf = debug_data->stats_data;
 
-	n += sysfs_emit_at(buf, n, "statistics_type = %d\t", p->statistics_type);
-	n += sysfs_emit_at(buf, n, "full_size = %d\n", p->full_size);
-
-	n += sysfs_emit_at(buf, n, "is_rf_locked = %d\t\t", p->is_rf_locked);
-	n += sysfs_emit_at(buf, n, "is_demod_locked = %d\t", p->is_demod_locked);
-	n += sysfs_emit_at(buf, n, "is_external_lna_on = %d\n", p->is_external_lna_on);
-	n += sysfs_emit_at(buf, n, "SNR = %d dB\t\t", p->SNR);
-	n += sysfs_emit_at(buf, n, "RSSI = %d dBm\t\t", p->RSSI);
-	n += sysfs_emit_at(buf, n, "in_band_pwr = %d dBm\n", p->in_band_pwr);
-	n += sysfs_emit_at(buf, n, "carrier_offset = %d\t", p->carrier_offset);
-	n += sysfs_emit_at(buf, n, "bandwidth = %d\t\t", p->bandwidth);
-	n += sysfs_emit_at(buf, n, "frequency = %d Hz\n", p->frequency);
-	n += sysfs_emit_at(buf, n, "transmission_mode = %d\t", p->transmission_mode);
-	n += sysfs_emit_at(buf, n, "modem_state = %d\t\t", p->modem_state);
-	n += sysfs_emit_at(buf, n, "guard_interval = %d\n", p->guard_interval);
-	n += sysfs_emit_at(buf, n, "system_type = %d\t\t", p->system_type);
-	n += sysfs_emit_at(buf, n, "partial_reception = %d\t", p->partial_reception);
-	n += sysfs_emit_at(buf, n, "num_of_layers = %d\n", p->num_of_layers);
-	n += sysfs_emit_at(buf, n, "sms_to_host_tx_errors = %d\n", p->sms_to_host_tx_errors);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "statistics_type = %d\t", p->statistics_type);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "full_size = %d\n", p->full_size);
+
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "is_rf_locked = %d\t\t", p->is_rf_locked);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "is_demod_locked = %d\t", p->is_demod_locked);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "is_external_lna_on = %d\n", p->is_external_lna_on);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "SNR = %d dB\t\t", p->SNR);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "RSSI = %d dBm\t\t", p->RSSI);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "in_band_pwr = %d dBm\n", p->in_band_pwr);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "carrier_offset = %d\t", p->carrier_offset);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "bandwidth = %d\t\t", p->bandwidth);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "frequency = %d Hz\n", p->frequency);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "transmission_mode = %d\t", p->transmission_mode);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "modem_state = %d\t\t", p->modem_state);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "guard_interval = %d\n", p->guard_interval);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "system_type = %d\t\t", p->system_type);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "partial_reception = %d\t", p->partial_reception);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "num_of_layers = %d\n", p->num_of_layers);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "sms_to_host_tx_errors = %d\n", p->sms_to_host_tx_errors);
 
 	for (i = 0; i < 3; i++) {
 		if (p->layer_info[i].number_of_segments < 1 ||
 		    p->layer_info[i].number_of_segments > 13)
 			continue;
 
-		n += sysfs_emit_at(buf, n, "\nLayer %d\n", i);
-		n += sysfs_emit_at(buf, n, "\tcode_rate = %d\t", p->layer_info[i].code_rate);
-		n += sysfs_emit_at(buf, n, "constellation = %d\n", p->layer_info[i].constellation);
-		n += sysfs_emit_at(buf, n, "\tber = %-5d\t", p->layer_info[i].ber);
-		n += sysfs_emit_at(buf, n, "\tber_error_count = %-5d\t",
-				   p->layer_info[i].ber_error_count);
-		n += sysfs_emit_at(buf, n, "ber_bit_count = %-5d\n",
-				   p->layer_info[i].ber_bit_count);
-		n += sysfs_emit_at(buf, n, "\tpre_ber = %-5d\t", p->layer_info[i].pre_ber);
-		n += sysfs_emit_at(buf, n, "\tts_per = %-5d\n", p->layer_info[i].ts_per);
-		n += sysfs_emit_at(buf, n, "\terror_ts_packets = %-5d\t",
-				   p->layer_info[i].error_ts_packets);
-		n += sysfs_emit_at(buf, n, "total_ts_packets = %-5d\t",
-				   p->layer_info[i].total_ts_packets);
-		n += sysfs_emit_at(buf, n, "ti_ldepth_i = %d\n", p->layer_info[i].ti_ldepth_i);
-		n += sysfs_emit_at(buf, n, "\tnumber_of_segments = %d\t",
-				   p->layer_info[i].number_of_segments);
-		n += sysfs_emit_at(buf, n, "tmcc_errors = %d\n", p->layer_info[i].tmcc_errors);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\nLayer %d\n", i);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\tcode_rate = %d\t",
+			      p->layer_info[i].code_rate);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "constellation = %d\n",
+			      p->layer_info[i].constellation);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\tber = %-5d\t",
+			      p->layer_info[i].ber);
+		n += scnprintf(&buf[n], PAGE_SIZE - n,
+			      "\tber_error_count = %-5d\t",
+			      p->layer_info[i].ber_error_count);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "ber_bit_count = %-5d\n",
+			      p->layer_info[i].ber_bit_count);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\tpre_ber = %-5d\t",
+			      p->layer_info[i].pre_ber);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\tts_per = %-5d\n",
+			      p->layer_info[i].ts_per);
+		n += scnprintf(&buf[n], PAGE_SIZE - n,
+			      "\terror_ts_packets = %-5d\t",
+			      p->layer_info[i].error_ts_packets);
+		n += scnprintf(&buf[n], PAGE_SIZE - n,
+			      "total_ts_packets = %-5d\t",
+			      p->layer_info[i].total_ts_packets);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "ti_ldepth_i = %d\n",
+			      p->layer_info[i].ti_ldepth_i);
+		n += scnprintf(&buf[n], PAGE_SIZE - n,
+			      "\tnumber_of_segments = %d\t",
+			      p->layer_info[i].number_of_segments);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "tmcc_errors = %d\n",
+			      p->layer_info[i].tmcc_errors);
 	}
 
 	debug_data->stats_count = n;
@@ -171,50 +241,80 @@ static void smsdvb_print_isdb_stats_ex(struct smsdvb_debugfs *debug_data,
 
 	buf = debug_data->stats_data;
 
-	n += sysfs_emit_at(buf, n, "statistics_type = %d\t", p->statistics_type);
-	n += sysfs_emit_at(buf, n, "full_size = %d\n", p->full_size);
-
-	n += sysfs_emit_at(buf, n, "is_rf_locked = %d\t\t", p->is_rf_locked);
-	n += sysfs_emit_at(buf, n, "is_demod_locked = %d\t", p->is_demod_locked);
-	n += sysfs_emit_at(buf, n, "is_external_lna_on = %d\n", p->is_external_lna_on);
-	n += sysfs_emit_at(buf, n, "SNR = %d dB\t\t", p->SNR);
-	n += sysfs_emit_at(buf, n, "RSSI = %d dBm\t\t", p->RSSI);
-	n += sysfs_emit_at(buf, n, "in_band_pwr = %d dBm\n", p->in_band_pwr);
-	n += sysfs_emit_at(buf, n, "carrier_offset = %d\t", p->carrier_offset);
-	n += sysfs_emit_at(buf, n, "bandwidth = %d\t\t", p->bandwidth);
-	n += sysfs_emit_at(buf, n, "frequency = %d Hz\n", p->frequency);
-	n += sysfs_emit_at(buf, n, "transmission_mode = %d\t", p->transmission_mode);
-	n += sysfs_emit_at(buf, n, "modem_state = %d\t\t", p->modem_state);
-	n += sysfs_emit_at(buf, n, "guard_interval = %d\n", p->guard_interval);
-	n += sysfs_emit_at(buf, n, "system_type = %d\t\t", p->system_type);
-	n += sysfs_emit_at(buf, n, "partial_reception = %d\t", p->partial_reception);
-	n += sysfs_emit_at(buf, n, "num_of_layers = %d\n", p->num_of_layers);
-	n += sysfs_emit_at(buf, n, "segment_number = %d\t", p->segment_number);
-	n += sysfs_emit_at(buf, n, "tune_bw = %d\n", p->tune_bw);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "statistics_type = %d\t", p->statistics_type);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "full_size = %d\n", p->full_size);
+
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "is_rf_locked = %d\t\t", p->is_rf_locked);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "is_demod_locked = %d\t", p->is_demod_locked);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "is_external_lna_on = %d\n", p->is_external_lna_on);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "SNR = %d dB\t\t", p->SNR);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "RSSI = %d dBm\t\t", p->RSSI);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "in_band_pwr = %d dBm\n", p->in_band_pwr);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "carrier_offset = %d\t", p->carrier_offset);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "bandwidth = %d\t\t", p->bandwidth);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "frequency = %d Hz\n", p->frequency);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "transmission_mode = %d\t", p->transmission_mode);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "modem_state = %d\t\t", p->modem_state);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "guard_interval = %d\n", p->guard_interval);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "system_type = %d\t\t", p->system_type);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "partial_reception = %d\t", p->partial_reception);
+	n += scnprintf(&buf[n], PAGE_SIZE - n,
+		      "num_of_layers = %d\n", p->num_of_layers);
+	n += scnprintf(&buf[n], PAGE_SIZE - n, "segment_number = %d\t",
+		      p->segment_number);
+	n += scnprintf(&buf[n], PAGE_SIZE - n, "tune_bw = %d\n",
+		      p->tune_bw);
 
 	for (i = 0; i < 3; i++) {
 		if (p->layer_info[i].number_of_segments < 1 ||
 		    p->layer_info[i].number_of_segments > 13)
 			continue;
 
-		n += sysfs_emit_at(buf, n, "\nLayer %d\n", i);
-		n += sysfs_emit_at(buf, n, "\tcode_rate = %d\t", p->layer_info[i].code_rate);
-		n += sysfs_emit_at(buf, n, "constellation = %d\n", p->layer_info[i].constellation);
-		n += sysfs_emit_at(buf, n, "\tber = %-5d\t", p->layer_info[i].ber);
-		n += sysfs_emit_at(buf, n, "\tber_error_count = %-5d\t",
-				   p->layer_info[i].ber_error_count);
-		n += sysfs_emit_at(buf, n, "ber_bit_count = %-5d\n",
-				   p->layer_info[i].ber_bit_count);
-		n += sysfs_emit_at(buf, n, "\tpre_ber = %-5d\t", p->layer_info[i].pre_ber);
-		n += sysfs_emit_at(buf, n, "\tts_per = %-5d\n", p->layer_info[i].ts_per);
-		n += sysfs_emit_at(buf, n, "\terror_ts_packets = %-5d\t",
-				   p->layer_info[i].error_ts_packets);
-		n += sysfs_emit_at(buf, n, "total_ts_packets = %-5d\t",
-				   p->layer_info[i].total_ts_packets);
-		n += sysfs_emit_at(buf, n, "ti_ldepth_i = %d\n", p->layer_info[i].ti_ldepth_i);
-		n += sysfs_emit_at(buf, n, "\tnumber_of_segments = %d\t",
-				   p->layer_info[i].number_of_segments);
-		n += sysfs_emit_at(buf, n, "tmcc_errors = %d\n", p->layer_info[i].tmcc_errors);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\nLayer %d\n", i);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\tcode_rate = %d\t",
+			      p->layer_info[i].code_rate);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "constellation = %d\n",
+			      p->layer_info[i].constellation);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\tber = %-5d\t",
+			      p->layer_info[i].ber);
+		n += scnprintf(&buf[n], PAGE_SIZE - n,
+			      "\tber_error_count = %-5d\t",
+			      p->layer_info[i].ber_error_count);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "ber_bit_count = %-5d\n",
+			      p->layer_info[i].ber_bit_count);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\tpre_ber = %-5d\t",
+			      p->layer_info[i].pre_ber);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "\tts_per = %-5d\n",
+			      p->layer_info[i].ts_per);
+		n += scnprintf(&buf[n], PAGE_SIZE - n,
+			      "\terror_ts_packets = %-5d\t",
+			      p->layer_info[i].error_ts_packets);
+		n += scnprintf(&buf[n], PAGE_SIZE - n,
+			      "total_ts_packets = %-5d\t",
+			      p->layer_info[i].total_ts_packets);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "ti_ldepth_i = %d\n",
+			      p->layer_info[i].ti_ldepth_i);
+		n += scnprintf(&buf[n], PAGE_SIZE - n,
+			      "\tnumber_of_segments = %d\t",
+			      p->layer_info[i].number_of_segments);
+		n += scnprintf(&buf[n], PAGE_SIZE - n, "tmcc_errors = %d\n",
+			      p->layer_info[i].tmcc_errors);
 	}
 
 

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261107-siano-revert-4a1c130e4277

Best regards,
--  
Ruk Doe <info@doany.io>

