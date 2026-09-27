From: Shunsuke Nagashima <shunsuke@nagashi.ma>
Date: Sun, 27 Sep 2026 21:10:53 +0900
Subject: [PATCH ath-next] wifi: ath10k: fix status of bundled mgmt tx
 completions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-ath10k-bundle-status-v1-1-a1eea048ada9@nagashi.ma>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QrCMAwAf2Xk2UDTyab+iuyh3aKLSpUmlcHYv
 1v18TjuVlDOwgqnZoXMb1F5pgq0a2CcQ7oyylQZvPOdO/oeg83k7hhLmh6MasGKot8TtUR97A4
 t1PSV+SLLb3uGWmDixWD4Gy3xxqN9r7BtH49IqaaCAAAA
X-Change-ID: 20260927-ath10k-bundle-status-24113117b683
To: Jeff Johnson <jjohnson@kernel.org>
Cc: Kalle Valo <kvalo@kernel.org>, linux-wireless@vger.kernel.org, 
 ath10k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Shunsuke Nagashima <shunsuke@nagashi.ma>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790511053; l=4037;
 i=shunsuke@nagashi.ma; s=20260927; h=from:subject:message-id;
 bh=QVBqzIPmQp3OWeyU/QcVzxRKR56mMIsg5DYITxXG7a0=;
 b=Xh9i1dtS2Uvv2kkPH5bVj24nVno/K5pjBuHO5R5bjTsNGn3jtXkxMz5Ub6h8qHADFnMhUw8tt
 gtPPLvNDl8gABQCrDEXZowB+aHiKTWfUjrIxiX/hSsVvGcS1LYXmIfm
X-Developer-Key: i=shunsuke@nagashi.ma; a=ed25519;
 pk=5WP8Bzifiy3DFoCeQ1lLy2osPmlNAkq71Un7ly9lbpk=
X-Endpoint-Received: by B4 Relay for shunsuke@nagashi.ma/20260927 with auth_id=1069
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath10k_wmi_event_mgmt_tx_bundle_compl() takes the completion status of
each report from desc_ids[i] instead of status[i]. Any non-zero status
is handled as "not acked", so a bundled report is marked as acked if
and only if its descriptor id is 0, whatever status the firmware
returned.

The bundle handler read status[i] when it was added in
commit cc123fac978f ("ath10k: Handle bundled tx completion for
management frames"). The commit named in the Fixes tag replaced it
with desc_ids[i].

Seen on WCN3990 in station mode with a WPA3-SAE AP. This firmware
advertises mgmt-tx-by-reference and completes some management frames
in bundles. A debug build printed status[] for each bundled report and
could switch between the old and the fixed line. A sniffer watched the
AP channel. The firmware status[] matched the capture in all 39
bundled reports (15 with the old line, 24 with the fixed one): the 30
frames with status[] 1 were never seen on that channel, and the 9
frames with status[] 0 were acked.

With the old line, 6 of the 15 reports gave mac80211 the wrong ack
result:

 - 4 frames that were never seen on the air were reported as acked.
   Each report arrived after mac80211 had already timed out the
   authentication, so they had no visible effect in these runs.
 - 2 SAE commit frames that were acked on the air were reported as not
   acked. They were the second and third of three tries. mac80211 gave
   up on the authentication 239 us after the last report, although the
   AP's SAE replies came about 5 to 8 ms later, so that connection
   attempt failed.

Take the status from status[i].

Tested-on: WCN3990 hw1.0 SNOC WLAN.HL.2.0.c10-00459-QCAHLSWMTPLZ-1

Fixes: 4b816f170b1f ("ath10k: add support for ack rssi value of management tx packets")
Cc: stable@vger.kernel.org
Assisted-by: LLM sparse
Signed-off-by: Shunsuke Nagashima <shunsuke@nagashi.ma>
---
Tested on a comma four (WCN3990) with a v7.2-based kernel
(7.2.0-vamos-7626c37). It also carries three out-of-tree ath10k
patches (MAC address, in-order rx A-MSDU, SET_KEY wait); none of
them touch wmi.c or wmi-tlv.c.

- Debug build that prints status[] per bundled report and can switch
  between the old and the fixed line, with a sniffer on the AP
  channel: 6 connect/reconnect runs (5 WPA3-SAE, 1 WPA2-PSK),
  39 bundled reports.
- Build with only this patch: 6 connect/reconnect runs (5 WPA3-SAE,
  1 WPA2-PSK), no debug output. No warnings, no firmware crashes.
  One first connect failed and one reconnect was slow, for a
  different reason that was also seen with the old line: the AP did
  not ack, and the firmware held back some Auth frames.

Not tested: status 2 or 3 inside a bundle (only 0 and 1 were seen),
AP mode, other chips and firmware versions.

I worked on this with Claude (claude-opus-5-5) and Codex
(gpt-6-astra). They helped go through the logs and sniffer captures,
write the debug build, and write the English of this changelog. I ran
the tests on the device and reviewed the change myself.
---
 drivers/net/wireless/ath/ath10k/wmi.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath10k/wmi.c b/drivers/net/wireless/ath/ath10k/wmi.c
index e57588c19..67be6e817 100644
--- a/drivers/net/wireless/ath/ath10k/wmi.c
+++ b/drivers/net/wireless/ath/ath10k/wmi.c
@@ -2512,7 +2512,7 @@ int ath10k_wmi_event_mgmt_tx_bundle_compl(struct ath10k *ar, struct sk_buff *skb
 	for (i = 0; i < num_reports; i++) {
 		memset(&param, 0, sizeof(struct mgmt_tx_compl_params));
 		param.desc_id = __le32_to_cpu(arg.desc_ids[i]);
-		param.status = __le32_to_cpu(arg.desc_ids[i]);
+		param.status = __le32_to_cpu(arg.status[i]);
 
 		if (test_bit(WMI_SERVICE_TX_DATA_ACK_RSSI, ar->wmi.svc_map))
 			param.ack_rssi = __le32_to_cpu(arg.ack_rssi[i]);

---
base-commit: 753baa59527f8e606c49eac25692b8b08918a3a9
change-id: 20260927-ath10k-bundle-status-24113117b683

Best regards,
--  
Shunsuke Nagashima <shunsuke@nagashi.ma>

