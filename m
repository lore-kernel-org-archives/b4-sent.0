From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Fri, 13 Nov 2026 20:12:29 +0100
Subject: [PATCH wireless-next] wifi: wlcore: Don't report RSSI events on
 the P2P device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-upstream-wlcore-p2p-rssi-v1-1-754bd625daca@tsv-stahl-riesa.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0Q6CMBAEf4Xcs5dATdD6K8aHCquewdLcFSEh/
 LtV922ymVnJoAKjU7WS4i0mYyzQ7CrqHiHewdIXJle7tinjKVlWhBfPQzcqOLnEaiZ8DN6jdf5
 Q73sqelLcZPmlzzSLYoAZRyyZLv/bpusTXf7mads+Avpj6IsAAAA=
X-Change-ID: 20261111-upstream-wlcore-p2p-rssi-8a99e629703d
To: linux-wireless@vger.kernel.org
Cc: Johannes Berg <johannes@sipsolutions.net>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-kernel@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794597159; l=3844;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=HaLsB5FeE4e7mOdZ4s/ZKiZhR7ChbgmoXjUw6qN7ook=;
 b=2cHA0+InI1KT1A9ZFgrZG//bS45GCpNqhMjtHwb7EdWajV3IMaDEr63gN40QPqpd0ChS99Mq5
 lnMEF7NPN6+CbNrB2wihngbtumu4oHIEhEDZKbj+XdkT4rtVfTPEWBv
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A P2P device vif has no netdev, but wl12xx_init_vif_data() makes it
BSS_TYPE_STA_BSS, so wl12xx_for_each_wlvif_sta() in
wlcore_event_rssi_trigger() visits it as well. Its rssi_thold and
last_rssi_event stay 0, and 0 is NL80211_CQM_RSSI_THRESHOLD_EVENT_LOW.
A metric above 0 therefore looks like a change to HIGH, and
ieee80211_cqm_rssi_notify() ends in cfg80211_cqm_rssi_notify(), which
dereferences the NULL sdata->dev:

  Internal error: Oops: 5 [#1] SMP ARM
  PC is at cfg80211_cqm_rssi_notify+0x18/0x108
  LR is at wlcore_event_rssi_trigger+0x84/0xa0 [wlcore]
  Call trace:
   cfg80211_cqm_rssi_notify from wlcore_event_rssi_trigger
   wlcore_event_rssi_trigger from wl18xx_process_mailbox_events
   wl18xx_process_mailbox_events from wl1271_event_handle
   wl1271_event_handle from wlcore_irq_locked
   wlcore_irq_locked from wlcore_irq
   wlcore_irq from irq_thread_fn

The oops kills the IRQ thread with wl->mutex held, so the driver does
not recover: everything that takes the mutex hangs, and the interrupt
is disabled as unhandled.

A real RSSI trigger reports a negative value in dBm and does not take
this path. Here, on a WL1801 (Tegra Note 7) with wpa_supplicant running,
the metric was +54 because the event mailbox held firmware statistics
instead of event data: reading the firmware statistics through debugfs
once a second during an iperf3 upload overwrote the mailbox. That is a
separate problem, but any bogus metric above 0 crashes the same way.

Skip P2P device vifs. Connection quality monitoring does not apply to
them, and wlcore_event_beacon_loss() also leaves them out, by their
invalid role_id.

Fixes: 7845af35e0de ("wlcore: add p2p device support")
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
Tested on a Tegra Note 7 (WL1801, firmware 8.9.0.0.83,
wpa_supplicant with its P2P device) with v7.3 plus this patch; the
patched files are the same in v7.3 and wireless-next. Load was a 600 s
iperf3 upload at about 47 Mbit/s while the debugfs firmware statistics
were read once a second:

- without the patch: oops as above after about 285 s of upload,
  WLAN dead until reboot;
- with the patch: 86 RSSI trigger events with bogus positive metrics,
  no oops, upload ran to the end with 0 failed frames.

Without the statistics reads the same upload produced no RSSI trigger
event at all. I will send the fix for the overwritten event mailbox
separately, once I have checked it on the device.

I did not add Cc: stable, as I only know of the debugfs statistics as a
way to get a positive metric here.

Tool use (see Documentation/process/generated-content.rst): this patch,
its changelog and this note were prepared with an LLM coding assistant
(Claude Code). It found the cause from the oops registers and the
driver source and wrote the change and the texts from my logs and
instructions. I reviewed the change and ran the tests on the device.
---
 drivers/net/wireless/ti/wlcore/event.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/wireless/ti/wlcore/event.c b/drivers/net/wireless/ti/wlcore/event.c
index 6c3a8ea9613e..eb5db3c5ec27 100644
--- a/drivers/net/wireless/ti/wlcore/event.c
+++ b/drivers/net/wireless/ti/wlcore/event.c
@@ -117,6 +117,10 @@ void wlcore_event_rssi_trigger(struct wl1271 *wl, s8 *metric_arr)
 
 	/* TODO: check actual multi-role support */
 	wl12xx_for_each_wlvif_sta(wl, wlvif) {
+		/* A P2P device has no netdev to report the event on */
+		if (wlcore_is_p2p_mgmt(wlvif))
+			continue;
+
 		if (metric <= wlvif->rssi_thold)
 			event = NL80211_CQM_RSSI_THRESHOLD_EVENT_LOW;
 		else

---
base-commit: 5dbf2415ca9821a611d09308e3b29d2c37e7cd77
change-id: 20261111-upstream-wlcore-p2p-rssi-8a99e629703d

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

