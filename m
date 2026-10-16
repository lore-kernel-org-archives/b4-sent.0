From: Shunsuke Nagashima <shunsuke@nagashi.ma>
Date: Fri, 16 Oct 2026 09:17:54 +0900
Subject: [PATCH ath-next 1/3] wifi: ath10k: set the PMF peer flag on
 WCN3990
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-ath10k-series-v1-send-v1-1-c847697b3558@nagashi.ma>
References: <20261016-ath10k-series-v1-send-v1-0-c847697b3558@nagashi.ma>
In-Reply-To: <20261016-ath10k-series-v1-send-v1-0-c847697b3558@nagashi.ma>
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Fabricio Akio <fabricioakio@gmail.com>, 
 Shunsuke Nagashima <shunsuke@nagashi.ma>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792109874; l=7214;
 i=shunsuke@nagashi.ma; s=20260927; h=from:subject:message-id;
 bh=LS0dN33RuQII2E3ET2H8miYH0T2mDMniGDkGdAT5148=;
 b=XyerowbkMXvHhhrHhJ9TPn4Ne64y4QjIayUbogWKKGAybIMyhyBbQUzOOLD377zgxV4Ri/ddi
 jfc8nafJtLbBun96uetmpToJexAP5dLYSVJzILo62nbkNo9MXIORLwf
X-Developer-Key: i=shunsuke@nagashi.ma; a=ed25519;
 pk=5WP8Bzifiy3DFoCeQ1lLy2osPmlNAkq71Un7ly9lbpk=
X-Endpoint-Received: by B4 Relay for shunsuke@nagashi.ma/20260927 with auth_id=1069
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath10k sets the PMF flag in the peer assoc command only when the
firmware file advertises ATH10K_FW_FEATURE_MFP_SUPPORT. That check came
with commit 90eceb3b5fb0 ("ath10k: set peer MFP flag in peer assoc
command"), because at that time "only firmwares 10.1.561 and above have
support for MFP". The WCN3990 firmware-5.bin files in linux-firmware do
not set that feature bit, so the flag is never sent on WCN3990, although
mac80211 negotiates PMF with the AP. ath11k and ath12k set the flag for
every MFP station.

On WCN3990 (firmware WLAN.HL.2.0.c10-00459) in station mode with PMF,
without the flag:

 - The firmware sends its ADDBA Request frames unprotected. The AP does
   not answer them, and no Block Ack agreement is set up, in both the
   2.4 GHz and the 5 GHz band. On a 5 GHz WPA3 AP, iperf3 to a wired
   host gave 22.6-31.6 Mbit/s up and 21.6-21.7 Mbit/s down, against
   280.2-283.0 / 264.5-272.3 Mbit/s with WPA2 on the same AP. A
   WPA2/WPA3 transition network gave the same low rate (23.4/22.7
   Mbit/s), because wpa_supplicant chose SAE with PMF there.

 - On 5 GHz, the protected Deauth sent at disconnect carried CCMP PN 0
   (56 of 56 in one capture). One AP dropped it, kept the old
   association and answered the next association with status 30, so a
   reconnect took 24.3-24.4 s instead of about 5 s. Another AP accepted
   the PN 0 Deauth. On 2.4 GHz the Deauth carried a live PN even
   without the flag. I could not tell whether the band or the AP's
   HT/VHT capability makes the difference.

With the flag set (this series, in a build without ath10k debug):

 - ADDBA Request frames were protected and Block Ack was used: on
   5 GHz with this series, and on 2.4 GHz with an earlier revision of
   it.
 - WPA3 on the same 5 GHz AP gave 264.2-279.0 Mbit/s up and
   236.8-246.2 Mbit/s down, and WPA2 283.4/261.7 Mbit/s. A 60-minute
   upload with 4 TCP streams averaged 277 Mbit/s, and a 30-minute
   download with 4 streams 230 Mbit/s.
 - Deauth frames carried a live PN, except when the Deauth was the first
   protected frame of the connection. With one MAC address, 100 of 100
   connect/disconnect cycles to the same AP connected, with no
   association rejection.
 - With an earlier revision of this series (the same code at run
   time): the transition network gave 276.9/249.6 Mbit/s, and in about
   8 hours of cycles, every association that followed an acknowledged
   Deauth with a current PN (not 0, and not older than a PN already
   used; about 1,300) got status 0.

The vendor driver for this firmware also sets the PMF peer flag for
every PMF connection. On the same device and firmware it reached
259.0-269.7 Mbit/s up with WPA3.

Add a hw_params flag and set it for WCN3990, so that the PMF peer flag
is set for MFP stations there as well. This also applies to MFP clients
when WCN3990 runs as an AP.

Tested-on: WCN3990 hw1.0 SNOC WLAN.HL.2.0.c10-00459-QCAHLSWMTPLZ-1

Assisted-by: LLM sparse
Signed-off-by: Shunsuke Nagashima <shunsuke@nagashi.ma>
---
Notes:

- Other WCN3990 firmware builds: WLAN.HL.2.0-01387 also sent the
  5 GHz Deauth with PN 0 (38 of 38). In a capture shared by
  WLAN.HL.2.0.c10-00236 and c10-00459, it was 60 of 60, and the AP
  answered 28 of 28 next associations with status 30. Setting the same
  peer flag (through a debug switch, not with this exact patch) gave
  the higher throughput with both builds. Protected ADDBA and Block Ack
  were seen in the 01387 capture and in the capture shared by
  c10-00236 and c10-00459.

- AP mode: with an earlier revision, a WPA2-PSK (CCMP) AP on 2.4 GHz
  with one phone (station dump MFP yes, ping 20 of 20); with this
  series, a 5 GHz WPA2-PSK AP with optional PMF and two phones for 30
  minutes (MFP yes and tx failed 0 for both phones in all 30 station
  dumps). Nothing more than that was tested in
  AP mode.

- Not changed by this patch: even with the flag, the first protected
  Action frame of almost every association still goes out with PN 0.
  The vendor driver on the same firmware shows the same, so I think
  this comes from the firmware (an inference from outside observation
  only).

- Related: David Heidelberg's RFC "wifi: ath10k: skip completion wait
  for pairwise key removal" (patchwork 14827446) adds another hw_params
  field at the same place: the end of the WCN3990 entry in core.c and
  the end of struct ath10k_hw_params in hw.h. The two changes do not
  depend on each other, but whichever goes in second needs a small
  rebase in both files (keep both new fields).

- Test kernel: a v7.2-based kernel on a comma four (SDM845) that also
  carries three out-of-tree ath10k patches (MAC address, in-order rx
  A-MSDU, SET_KEY wait). None of them touches the peer assoc flags.
  The results without the flag and the other-firmware results came
  from a debug build of that kernel.

AI-assistance disclosure:

I worked on this with Claude (mainly claude-opus-5-5 and
claude-fable-5-1) and Codex (gpt-6-astra). They helped go through the
logs and sniffer captures, draft the code changes and the debug builds,
and write the English of the commit messages. I reviewed the code. All
device tests ran on my own comma four, and the results above come from
those runs.
---
 drivers/net/wireless/ath/ath10k/core.c | 1 +
 drivers/net/wireless/ath/ath10k/hw.h   | 6 ++++++
 drivers/net/wireless/ath/ath10k/mac.c  | 5 +++--
 3 files changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/ath/ath10k/core.c b/drivers/net/wireless/ath/ath10k/core.c
index 7c2939cbde5f..c645f8d77ef3 100644
--- a/drivers/net/wireless/ath/ath10k/core.c
+++ b/drivers/net/wireless/ath/ath10k/core.c
@@ -746,6 +746,7 @@ static const struct ath10k_hw_params ath10k_hw_params_list[] = {
 		.use_fw_tx_credits = false,
 		.delay_unmap_buffer = true,
 		.mcast_frame_registration = false,
+		.peer_pmf_support = true,
 	},
 };
 
diff --git a/drivers/net/wireless/ath/ath10k/hw.h b/drivers/net/wireless/ath/ath10k/hw.h
index cd468b24bd33..88e48646be73 100644
--- a/drivers/net/wireless/ath/ath10k/hw.h
+++ b/drivers/net/wireless/ath/ath10k/hw.h
@@ -638,6 +638,12 @@ struct ath10k_hw_params {
 
 	/* The hardware support multicast frame registrations */
 	bool mcast_frame_registration;
+
+	/* The firmware handles PMF for a peer that has the PMF peer flag,
+	 * although the firmware file does not advertise
+	 * ATH10K_FW_FEATURE_MFP_SUPPORT.
+	 */
+	bool peer_pmf_support;
 };
 
 struct htt_resp;
diff --git a/drivers/net/wireless/ath/ath10k/mac.c b/drivers/net/wireless/ath/ath10k/mac.c
index 8e604697d6c2..b30cdd1888f4 100644
--- a/drivers/net/wireless/ath/ath10k/mac.c
+++ b/drivers/net/wireless/ath/ath10k/mac.c
@@ -2254,8 +2254,9 @@ static void ath10k_peer_assoc_h_crypto(struct ath10k *ar,
 	}
 
 	if (sta->mfp &&
-	    test_bit(ATH10K_FW_FEATURE_MFP_SUPPORT,
-		     ar->running_fw->fw_file.fw_features)) {
+	    (test_bit(ATH10K_FW_FEATURE_MFP_SUPPORT,
+		      ar->running_fw->fw_file.fw_features) ||
+	     ar->hw_params.peer_pmf_support)) {
 		arg->peer_flags |= ar->wmi.peer_flags->pmf;
 	}
 }

-- 
Git-157)

