From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Fri, 13 Nov 2026 20:14:21 +0100
Subject: [PATCH RFC wireless-next 2/2] wifi: wl18xx: Stop querying the
 firmware statistics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-upstream-wl18xx-fw-stats-v1-2-cbdf50739185@tsv-stahl-riesa.de>
References: <20261113-upstream-wl18xx-fw-stats-v1-0-cbdf50739185@tsv-stahl-riesa.de>
In-Reply-To: <20261113-upstream-wl18xx-fw-stats-v1-0-cbdf50739185@tsv-stahl-riesa.de>
To: linux-wireless@vger.kernel.org
Cc: Johannes Berg <johannes@sipsolutions.net>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-kernel@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794597278; l=20495;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=1wiF6aNv2p1N9mwscpVB5z2J4z5RrkOG2uKyYiPJFPE=;
 b=TJAdnm79wdhy9KbnOGat+F71zCdhPdBWkaTsNNIORyGahgQ/09qCVSVUT2s+rVj9lk6wAGSjj
 6yaKQ52QpnVDTqwnbEL1y+rzY/yS5vUpBEPGJWwNi0Owa8r7Kh/CnU8
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The firmware writes its answer to ACX_STATISTICS into the command
mailbox. struct wl18xx_acx_statistics is 1100 bytes, but the command
mailbox is only WL18XX_CMD_MAX_SIZE (740) bytes, and the two event
mailboxes of 180 bytes each follow right behind it. On a WL1801 with
firmware 8.9.0.0.83, reading the chip memory before and after one query
shows the response running through both event mailboxes, up to the end
of the second one:

  command mailbox  0xb007f8
  event mailbox A  0xb00adc  (+740)
  event mailbox B  0xb00b90  (+920)

Asking for only 740 bytes does not help, the firmware writes the whole
structure anyway.

If an event is waiting in a mailbox at that moment, the event handler
then reads statistics counters as the event vector and event data and
acts on them. With the firmware statistics read once a second through
debugfs during an iperf3 upload, there were 50 such bogus RSSI trigger
events in 600 seconds, and 24 when only 740 bytes were requested. With
a P2P device one of them crashed the driver in
wlcore_event_rssi_trigger().

The statistics have been bigger than the command mailbox since they
were resized for the new firmware API in 2012. Stop querying them: drop
the fw_stats debugfs files and clear_fw_stats, and leave fw_stats_len 0
so that wlcore neither allocates the buffer nor creates fw_stats_raw.

Fixes: c5d94169e818 ("wl18xx: use new fw stats structures")
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/net/wireless/ti/wl18xx/acx.c     |  24 ---
 drivers/net/wireless/ti/wl18xx/acx.h     |   5 -
 drivers/net/wireless/ti/wl18xx/debugfs.c | 333 +------------------------------
 drivers/net/wireless/ti/wl18xx/main.c    |   1 -
 4 files changed, 1 insertion(+), 362 deletions(-)

diff --git a/drivers/net/wireless/ti/wl18xx/acx.c b/drivers/net/wireless/ti/wl18xx/acx.c
index 07f3008cf727..15755e81da9b 100644
--- a/drivers/net/wireless/ti/wl18xx/acx.c
+++ b/drivers/net/wireless/ti/wl18xx/acx.c
@@ -73,30 +73,6 @@ int wl18xx_acx_set_checksum_state(struct wl1271 *wl)
 	return ret;
 }
 
-int wl18xx_acx_clear_statistics(struct wl1271 *wl)
-{
-	struct wl18xx_acx_clear_statistics *acx;
-	int ret = 0;
-
-	wl1271_debug(DEBUG_ACX, "acx clear statistics");
-
-	acx = kzalloc_obj(*acx);
-	if (!acx) {
-		ret = -ENOMEM;
-		goto out;
-	}
-
-	ret = wl1271_cmd_configure(wl, ACX_CLEAR_STATISTICS, acx, sizeof(*acx));
-	if (ret < 0) {
-		wl1271_warning("failed to clear firmware statistics: %d", ret);
-		goto out;
-	}
-
-out:
-	kfree(acx);
-	return ret;
-}
-
 int wl18xx_acx_peer_ht_operation_mode(struct wl1271 *wl, u8 hlid, bool wide)
 {
 	struct wlcore_peer_ht_operation_mode *acx;
diff --git a/drivers/net/wireless/ti/wl18xx/acx.h b/drivers/net/wireless/ti/wl18xx/acx.h
index cba195911978..e2a1e0ebff5b 100644
--- a/drivers/net/wireless/ti/wl18xx/acx.h
+++ b/drivers/net/wireless/ti/wl18xx/acx.h
@@ -282,10 +282,6 @@ struct wl18xx_acx_statistics {
 	struct wl18xx_dfs_stats			dfs;
 } __packed;
 
-struct wl18xx_acx_clear_statistics {
-	struct acx_header header;
-};
-
 enum wlcore_bandwidth {
 	WLCORE_BANDWIDTH_20MHZ,
 	WLCORE_BANDWIDTH_40MHZ,
@@ -390,7 +386,6 @@ int wl18xx_acx_host_if_cfg_bitmap(struct wl1271 *wl, u32 host_cfg_bitmap,
 				  u32 sdio_blk_size, u32 extra_mem_blks,
 				  u32 len_field_size);
 int wl18xx_acx_set_checksum_state(struct wl1271 *wl);
-int wl18xx_acx_clear_statistics(struct wl1271 *wl);
 int wl18xx_acx_peer_ht_operation_mode(struct wl1271 *wl, u8 hlid, bool wide);
 int wl18xx_acx_set_peer_cap(struct wl1271 *wl,
 			    struct ieee80211_sta_ht_cap *ht_cap,
diff --git a/drivers/net/wireless/ti/wl18xx/debugfs.c b/drivers/net/wireless/ti/wl18xx/debugfs.c
index ac756318e8ea..8f847b7806dc 100644
--- a/drivers/net/wireless/ti/wl18xx/debugfs.c
+++ b/drivers/net/wireless/ti/wl18xx/debugfs.c
@@ -18,163 +18,6 @@
 #include "cmd.h"
 #include "debugfs.h"
 
-#define WL18XX_DEBUGFS_FWSTATS_FILE(a, b, c) \
-	DEBUGFS_FWSTATS_FILE(a, b, c, wl18xx_acx_statistics)
-#define WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(a, b, c) \
-	DEBUGFS_FWSTATS_FILE_ARRAY(a, b, c, wl18xx_acx_statistics)
-
-
-WL18XX_DEBUGFS_FWSTATS_FILE(error, error_frame_non_ctrl, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, error_frame_ctrl, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, error_frame_during_protection, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, null_frame_tx_start, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, null_frame_cts_start, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, bar_retry, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, num_frame_cts_nul_flid, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, tx_abort_failure, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, tx_resume_failure, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, rx_cmplt_db_overflow_cnt, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, elp_while_rx_exch, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, elp_while_tx_exch, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, elp_while_tx, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, elp_while_nvic_pending, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, rx_excessive_frame_len, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, burst_mismatch, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(error, tbc_exch_mismatch, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_prepared_descs, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_cmplt, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_template_prepared, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_data_prepared, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_template_programmed, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_data_programmed, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_burst_programmed, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_starts, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_stop, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_start_templates, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_start_int_templates, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_start_fw_gen, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_start_data, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_start_null_frame, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_exch, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_retry_template, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_retry_data, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(tx, tx_retry_per_rate,
-				  NUM_OF_RATES_INDEXES);
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_exch_pending, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_exch_expiry, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_done_template, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_done_data, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_done_int_template, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_cfe1, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, tx_cfe2, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_called, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_mpdu_alloc_failed, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_init_called, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_in_process_called, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_tkip_called, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_key_not_found, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_need_fragmentation, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_bad_mblk_num, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_failed, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_cache_hit, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(tx, frag_cache_miss, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_beacon_early_term, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_out_of_mpdu_nodes, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_hdr_overflow, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_dropped_frame, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_done, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_defrag, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_defrag_end, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_cmplt, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_pre_complt, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_cmplt_task, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_phy_hdr, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_timeout, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_rts_timeout, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_timeout_wa, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, defrag_called, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, defrag_init_called, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, defrag_in_process_called, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, defrag_tkip_called, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, defrag_need_defrag, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, defrag_decrypt_failed, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, decrypt_key_not_found, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, defrag_need_decrypt, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_tkip_replays, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx, rx_xfr, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE(isr, irqs, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, missing_bcns_cnt, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, rcvd_bcns_cnt, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, connection_out_of_sync, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(pwr, cont_miss_bcns_spread,
-				  PWR_STAT_MAX_CONT_MISSED_BCNS_SPREAD);
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, rcvd_awake_bcns_cnt, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, sleep_time_count, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, sleep_time_avg, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, sleep_cycle_avg, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, sleep_percent, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, ap_sleep_active_conf, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, ap_sleep_user_conf, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pwr, ap_sleep_counter, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE(rx_filter, beacon_filter, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx_filter, arp_filter, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx_filter, mc_filter, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx_filter, dup_filter, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx_filter, data_filter, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx_filter, ibss_filter, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx_filter, protection_filter, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx_filter, accum_arp_pend_requests, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(rx_filter, max_arp_queue_dep, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(rx_rate, rx_frames_per_rates, 50);
-
-WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(aggr_size, tx_agg_rate,
-				  AGGR_STATS_TX_AGG);
-WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(aggr_size, tx_agg_len,
-				  AGGR_STATS_TX_AGG);
-WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(aggr_size, rx_size,
-				  AGGR_STATS_RX_SIZE_LEN);
-
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, hs_tx_stat_fifo_int, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, enc_tx_stat_fifo_int, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, enc_rx_stat_fifo_int, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, rx_complete_stat_fifo_int, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, pre_proc_swi, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, post_proc_swi, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, sec_frag_swi, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, pre_to_defrag_swi, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, defrag_to_rx_xfer_swi, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, dec_packet_in, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, dec_packet_in_fifo_full, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(pipeline, dec_packet_out, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(pipeline, pipeline_fifo_full,
-				  PIPE_STATS_HW_FIFO);
-
-WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(diversity, num_of_packets_per_ant,
-				  DIVERSITY_STATS_NUM_OF_ANT);
-WL18XX_DEBUGFS_FWSTATS_FILE(diversity, total_num_of_toggles, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE(thermal, irq_thr_low, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(thermal, irq_thr_high, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(thermal, tx_stop, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(thermal, tx_resume, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(thermal, false_irq, "%u");
-WL18XX_DEBUGFS_FWSTATS_FILE(thermal, adc_source_unexpected, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE_ARRAY(calib, fail_count,
-				  WL18XX_NUM_OF_CALIBRATIONS_ERRORS);
-WL18XX_DEBUGFS_FWSTATS_FILE(calib, calib_count, "%u");
-
-WL18XX_DEBUGFS_FWSTATS_FILE(roaming, rssi_level, "%d");
-
-WL18XX_DEBUGFS_FWSTATS_FILE(dfs, num_of_radar_detections, "%d");
-
 static ssize_t conf_read(struct file *file, char __user *user_buf,
 			 size_t count, loff_t *ppos)
 {
@@ -217,34 +60,6 @@ static const struct file_operations conf_ops = {
 	.llseek = default_llseek,
 };
 
-static ssize_t clear_fw_stats_write(struct file *file,
-			      const char __user *user_buf,
-			      size_t count, loff_t *ppos)
-{
-	struct wl1271 *wl = file->private_data;
-	int ret;
-
-	mutex_lock(&wl->mutex);
-
-	if (unlikely(wl->state != WLCORE_STATE_ON))
-		goto out;
-
-	ret = wl18xx_acx_clear_statistics(wl);
-	if (ret < 0) {
-		count = ret;
-		goto out;
-	}
-out:
-	mutex_unlock(&wl->mutex);
-	return count;
-}
-
-static const struct file_operations clear_fw_stats_ops = {
-	.write = clear_fw_stats_write,
-	.open = simple_open,
-	.llseek = default_llseek,
-};
-
 static ssize_t radar_detection_write(struct file *file,
 				     const char __user *user_buf,
 				     size_t count, loff_t *ppos)
@@ -399,155 +214,9 @@ static const struct file_operations radar_debug_mode_ops = {
 int wl18xx_debugfs_add_files(struct wl1271 *wl,
 			     struct dentry *rootdir)
 {
-	struct dentry *stats, *moddir;
+	struct dentry *moddir;
 
 	moddir = debugfs_create_dir(KBUILD_MODNAME, rootdir);
-	stats = debugfs_create_dir("fw_stats", moddir);
-
-	DEBUGFS_ADD(clear_fw_stats, stats);
-
-	DEBUGFS_FWSTATS_ADD(error, error_frame_non_ctrl);
-	DEBUGFS_FWSTATS_ADD(error, error_frame_ctrl);
-	DEBUGFS_FWSTATS_ADD(error, error_frame_during_protection);
-	DEBUGFS_FWSTATS_ADD(error, null_frame_tx_start);
-	DEBUGFS_FWSTATS_ADD(error, null_frame_cts_start);
-	DEBUGFS_FWSTATS_ADD(error, bar_retry);
-	DEBUGFS_FWSTATS_ADD(error, num_frame_cts_nul_flid);
-	DEBUGFS_FWSTATS_ADD(error, tx_abort_failure);
-	DEBUGFS_FWSTATS_ADD(error, tx_resume_failure);
-	DEBUGFS_FWSTATS_ADD(error, rx_cmplt_db_overflow_cnt);
-	DEBUGFS_FWSTATS_ADD(error, elp_while_rx_exch);
-	DEBUGFS_FWSTATS_ADD(error, elp_while_tx_exch);
-	DEBUGFS_FWSTATS_ADD(error, elp_while_tx);
-	DEBUGFS_FWSTATS_ADD(error, elp_while_nvic_pending);
-	DEBUGFS_FWSTATS_ADD(error, rx_excessive_frame_len);
-	DEBUGFS_FWSTATS_ADD(error, burst_mismatch);
-	DEBUGFS_FWSTATS_ADD(error, tbc_exch_mismatch);
-
-	DEBUGFS_FWSTATS_ADD(tx, tx_prepared_descs);
-	DEBUGFS_FWSTATS_ADD(tx, tx_cmplt);
-	DEBUGFS_FWSTATS_ADD(tx, tx_template_prepared);
-	DEBUGFS_FWSTATS_ADD(tx, tx_data_prepared);
-	DEBUGFS_FWSTATS_ADD(tx, tx_template_programmed);
-	DEBUGFS_FWSTATS_ADD(tx, tx_data_programmed);
-	DEBUGFS_FWSTATS_ADD(tx, tx_burst_programmed);
-	DEBUGFS_FWSTATS_ADD(tx, tx_starts);
-	DEBUGFS_FWSTATS_ADD(tx, tx_stop);
-	DEBUGFS_FWSTATS_ADD(tx, tx_start_templates);
-	DEBUGFS_FWSTATS_ADD(tx, tx_start_int_templates);
-	DEBUGFS_FWSTATS_ADD(tx, tx_start_fw_gen);
-	DEBUGFS_FWSTATS_ADD(tx, tx_start_data);
-	DEBUGFS_FWSTATS_ADD(tx, tx_start_null_frame);
-	DEBUGFS_FWSTATS_ADD(tx, tx_exch);
-	DEBUGFS_FWSTATS_ADD(tx, tx_retry_template);
-	DEBUGFS_FWSTATS_ADD(tx, tx_retry_data);
-	DEBUGFS_FWSTATS_ADD(tx, tx_retry_per_rate);
-	DEBUGFS_FWSTATS_ADD(tx, tx_exch_pending);
-	DEBUGFS_FWSTATS_ADD(tx, tx_exch_expiry);
-	DEBUGFS_FWSTATS_ADD(tx, tx_done_template);
-	DEBUGFS_FWSTATS_ADD(tx, tx_done_data);
-	DEBUGFS_FWSTATS_ADD(tx, tx_done_int_template);
-	DEBUGFS_FWSTATS_ADD(tx, tx_cfe1);
-	DEBUGFS_FWSTATS_ADD(tx, tx_cfe2);
-	DEBUGFS_FWSTATS_ADD(tx, frag_called);
-	DEBUGFS_FWSTATS_ADD(tx, frag_mpdu_alloc_failed);
-	DEBUGFS_FWSTATS_ADD(tx, frag_init_called);
-	DEBUGFS_FWSTATS_ADD(tx, frag_in_process_called);
-	DEBUGFS_FWSTATS_ADD(tx, frag_tkip_called);
-	DEBUGFS_FWSTATS_ADD(tx, frag_key_not_found);
-	DEBUGFS_FWSTATS_ADD(tx, frag_need_fragmentation);
-	DEBUGFS_FWSTATS_ADD(tx, frag_bad_mblk_num);
-	DEBUGFS_FWSTATS_ADD(tx, frag_failed);
-	DEBUGFS_FWSTATS_ADD(tx, frag_cache_hit);
-	DEBUGFS_FWSTATS_ADD(tx, frag_cache_miss);
-
-	DEBUGFS_FWSTATS_ADD(rx, rx_beacon_early_term);
-	DEBUGFS_FWSTATS_ADD(rx, rx_out_of_mpdu_nodes);
-	DEBUGFS_FWSTATS_ADD(rx, rx_hdr_overflow);
-	DEBUGFS_FWSTATS_ADD(rx, rx_dropped_frame);
-	DEBUGFS_FWSTATS_ADD(rx, rx_done);
-	DEBUGFS_FWSTATS_ADD(rx, rx_defrag);
-	DEBUGFS_FWSTATS_ADD(rx, rx_defrag_end);
-	DEBUGFS_FWSTATS_ADD(rx, rx_cmplt);
-	DEBUGFS_FWSTATS_ADD(rx, rx_pre_complt);
-	DEBUGFS_FWSTATS_ADD(rx, rx_cmplt_task);
-	DEBUGFS_FWSTATS_ADD(rx, rx_phy_hdr);
-	DEBUGFS_FWSTATS_ADD(rx, rx_timeout);
-	DEBUGFS_FWSTATS_ADD(rx, rx_rts_timeout);
-	DEBUGFS_FWSTATS_ADD(rx, rx_timeout_wa);
-	DEBUGFS_FWSTATS_ADD(rx, defrag_called);
-	DEBUGFS_FWSTATS_ADD(rx, defrag_init_called);
-	DEBUGFS_FWSTATS_ADD(rx, defrag_in_process_called);
-	DEBUGFS_FWSTATS_ADD(rx, defrag_tkip_called);
-	DEBUGFS_FWSTATS_ADD(rx, defrag_need_defrag);
-	DEBUGFS_FWSTATS_ADD(rx, defrag_decrypt_failed);
-	DEBUGFS_FWSTATS_ADD(rx, decrypt_key_not_found);
-	DEBUGFS_FWSTATS_ADD(rx, defrag_need_decrypt);
-	DEBUGFS_FWSTATS_ADD(rx, rx_tkip_replays);
-	DEBUGFS_FWSTATS_ADD(rx, rx_xfr);
-
-	DEBUGFS_FWSTATS_ADD(isr, irqs);
-
-	DEBUGFS_FWSTATS_ADD(pwr, missing_bcns_cnt);
-	DEBUGFS_FWSTATS_ADD(pwr, rcvd_bcns_cnt);
-	DEBUGFS_FWSTATS_ADD(pwr, connection_out_of_sync);
-	DEBUGFS_FWSTATS_ADD(pwr, cont_miss_bcns_spread);
-	DEBUGFS_FWSTATS_ADD(pwr, rcvd_awake_bcns_cnt);
-	DEBUGFS_FWSTATS_ADD(pwr, sleep_time_count);
-	DEBUGFS_FWSTATS_ADD(pwr, sleep_time_avg);
-	DEBUGFS_FWSTATS_ADD(pwr, sleep_cycle_avg);
-	DEBUGFS_FWSTATS_ADD(pwr, sleep_percent);
-	DEBUGFS_FWSTATS_ADD(pwr, ap_sleep_active_conf);
-	DEBUGFS_FWSTATS_ADD(pwr, ap_sleep_user_conf);
-	DEBUGFS_FWSTATS_ADD(pwr, ap_sleep_counter);
-
-	DEBUGFS_FWSTATS_ADD(rx_filter, beacon_filter);
-	DEBUGFS_FWSTATS_ADD(rx_filter, arp_filter);
-	DEBUGFS_FWSTATS_ADD(rx_filter, mc_filter);
-	DEBUGFS_FWSTATS_ADD(rx_filter, dup_filter);
-	DEBUGFS_FWSTATS_ADD(rx_filter, data_filter);
-	DEBUGFS_FWSTATS_ADD(rx_filter, ibss_filter);
-	DEBUGFS_FWSTATS_ADD(rx_filter, protection_filter);
-	DEBUGFS_FWSTATS_ADD(rx_filter, accum_arp_pend_requests);
-	DEBUGFS_FWSTATS_ADD(rx_filter, max_arp_queue_dep);
-
-	DEBUGFS_FWSTATS_ADD(rx_rate, rx_frames_per_rates);
-
-	DEBUGFS_FWSTATS_ADD(aggr_size, tx_agg_rate);
-	DEBUGFS_FWSTATS_ADD(aggr_size, tx_agg_len);
-	DEBUGFS_FWSTATS_ADD(aggr_size, rx_size);
-
-	DEBUGFS_FWSTATS_ADD(pipeline, hs_tx_stat_fifo_int);
-	DEBUGFS_FWSTATS_ADD(pipeline, enc_tx_stat_fifo_int);
-	DEBUGFS_FWSTATS_ADD(pipeline, enc_rx_stat_fifo_int);
-	DEBUGFS_FWSTATS_ADD(pipeline, rx_complete_stat_fifo_int);
-	DEBUGFS_FWSTATS_ADD(pipeline, pre_proc_swi);
-	DEBUGFS_FWSTATS_ADD(pipeline, post_proc_swi);
-	DEBUGFS_FWSTATS_ADD(pipeline, sec_frag_swi);
-	DEBUGFS_FWSTATS_ADD(pipeline, pre_to_defrag_swi);
-	DEBUGFS_FWSTATS_ADD(pipeline, defrag_to_rx_xfer_swi);
-	DEBUGFS_FWSTATS_ADD(pipeline, dec_packet_in);
-	DEBUGFS_FWSTATS_ADD(pipeline, dec_packet_in_fifo_full);
-	DEBUGFS_FWSTATS_ADD(pipeline, dec_packet_out);
-	DEBUGFS_FWSTATS_ADD(pipeline, pipeline_fifo_full);
-
-	DEBUGFS_FWSTATS_ADD(diversity, num_of_packets_per_ant);
-	DEBUGFS_FWSTATS_ADD(diversity, total_num_of_toggles);
-
-	DEBUGFS_FWSTATS_ADD(thermal, irq_thr_low);
-	DEBUGFS_FWSTATS_ADD(thermal, irq_thr_high);
-	DEBUGFS_FWSTATS_ADD(thermal, tx_stop);
-	DEBUGFS_FWSTATS_ADD(thermal, tx_resume);
-	DEBUGFS_FWSTATS_ADD(thermal, false_irq);
-	DEBUGFS_FWSTATS_ADD(thermal, adc_source_unexpected);
-
-	DEBUGFS_FWSTATS_ADD(calib, fail_count);
-
-	DEBUGFS_FWSTATS_ADD(calib, calib_count);
-
-	DEBUGFS_FWSTATS_ADD(roaming, rssi_level);
-
-	DEBUGFS_FWSTATS_ADD(dfs, num_of_radar_detections);
 
 	DEBUGFS_ADD(conf, moddir);
 	DEBUGFS_ADD(radar_detection, moddir);
diff --git a/drivers/net/wireless/ti/wl18xx/main.c b/drivers/net/wireless/ti/wl18xx/main.c
index d087d9c72f91..8bfb8358823d 100644
--- a/drivers/net/wireless/ti/wl18xx/main.c
+++ b/drivers/net/wireless/ti/wl18xx/main.c
@@ -1952,7 +1952,6 @@ static int wl18xx_setup(struct wl1271 *wl)
 	wl->hw_min_ht_rate = WL18XX_CONF_HW_RXTX_RATE_MCS0;
 	wl->fw_status_len = sizeof(struct wl18xx_fw_status);
 	wl->fw_status_priv_len = sizeof(struct wl18xx_fw_status_priv);
-	wl->stats.fw_stats_len = sizeof(struct wl18xx_acx_statistics);
 	wl->static_data_priv_len = sizeof(struct wl18xx_static_data_priv);
 
 	if (num_rx_desc_param != -1)

-- 
2.56.0

