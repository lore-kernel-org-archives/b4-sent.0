From: Ahmet Zeren <niko3x@proton.me>
Subject: [PATCH rtw-next 0/2] wifi: rtl8xxxu: report real TX status on
 RTL8188CU/RTL8192CU
Date: Fri, 20 Nov 2026 01:12:44 +0300
Message-Id: <20261120-b4-tx-status-v1-0-abdab21c77fe@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDQAwAvyI5N+AGUexXpIdVY5setrKJuiD+3
 dUeh2FmB+UorPAsdoi8isovZHCPAoaPD29GGTMDlVQ7RyX2FVpCNW+L4jhVDRG3ddN6yMkceZJ
 07zqItmHgZPD6G136Lw923eA4TlNriPR6AAAA
X-Change-ID: 20261120-b4-tx-status-df4722e9679a
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795126366; l=2295;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=dhmD0zEeKlt6Ioj3kwSa/s223Wn1BvOadJNjregLYJE=;
 b=As6aklSKEMYj4fWzqI7IwN3azINEWhqHcTC0j0DnWM8PuhFrWjw0zO95cwrNMNPAdw6dRfR9U
 I5LcErYazzlCVBCYkdSHw7oKxBn3Xop/+YUWpamFV2PQ7/gEZV/NEWz
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtl8xxxu reports every frame as acked as soon as its USB transfer
completes, so mac80211 and userspace never learn that a frame was lost.

Patch 1 stops reporting frames sent with IEEE80211_TX_CTL_NO_ACK as
acked.

Patch 2 uses the CCX TX report of the RTL8188CU/RTL8192CU firmware to
report the real ACK status and retry count. These chips post C2H events
in the REG_C2HEVT_MSG_NORMAL mailbox, which has to be polled, and the
report does not identify the frame, so only one frame at a time requests
a report. Other frames are reported as before. The vendor driver uses
the same report (C2H_CCX_TX_RPT, struct txrpt_ccx_8192c); the firmware
in linux-firmware (v88.2) sends it.

Gen2 chips and the RTL8188EU have their own report formats and are not
covered here.

Testing on RTL8192CU (0bda:8178), by injecting unicast frames and reading
the TX status mac80211 hands back to a monitor interface: frames to a
present station are reported acked, with the retries that happened;
frames to an absent station are reported failed with the hardware's
retry count, including when the retries take seconds; frames sent right
after are not confused with an earlier report. Interface down/up and
module removal with a report pending were also tested. checkpatch --strict,
W=1 and sparse are clean for each patch.

AI tool use (Documentation/process/generated-content.rst): the patches
were written with help from Claude Code (Claude Opus 5.5). It was asked
to research how these chips report TX status (vendor driver, rtlwifi,
rtw88), confirm the report format on the hardware, write the patches
and run the tests above. I have reviewed and tested the changes and take
responsibility for them.

---
Ahmet Zeren (2):
      wifi: rtl8xxxu: don't report frames sent without ACK as acked
      wifi: rtl8xxxu: report real TX status on RTL8188CU/RTL8192CU

 drivers/net/wireless/realtek/rtl8xxxu/8192c.c    |   1 +
 drivers/net/wireless/realtek/rtl8xxxu/core.c     | 128 ++++++++++++++++++++++-
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |  17 +++
 3 files changed, 144 insertions(+), 2 deletions(-)
---
base-commit: 0bdc579dbfc251a6b6838ee9459b6771b948c617
change-id: 20261120-b4-tx-status-df4722e9679a

Best regards,
--  
Ahmet Zeren <niko3x@proton.me>

