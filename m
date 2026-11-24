From: Ahmet Zeren <niko3x@proton.me>
Subject: [PATCH RFT rtw-next 0/2] wifi: rtw88: honour rate, retries and
 bandwidth of injected frames
Date: Tue, 24 Nov 2026 11:32:29 +0300
Message-Id: <20261124-b4-rtw88-inject-v1-0-f7457e496924@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ7CIBBFr9L8tZMUJAY9gAcw3RkXpQw6LtAAa
 pOmdxd0+X7+ewsyJ+GMQ7cg8VuyPGIFtekw3cZ4ZRJfGbrXO6W0IWcolY+1JPHOUyEf3Db0e+1
 HY1GtZ+Ig8694xuk4tK0KFHkuuPwP+eWa27pY1y8yCr2zhAAAAA==
X-Change-ID: 20261124-b4-rtw88-inject-dfb3f092da48
To: Ping-Ke Shih <pkshih@realtek.com>
Cc: linux-wireless@vger.kernel.org, Luka Gejak <luka.gejak@linux.dev>, 
 Bitterblue Smith <rtl8821cerfe2@gmail.com>, linux-kernel@vger.kernel.org, 
 Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795509151; l=2902;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=418Z9+5osAr5Zw2V0Hv6Br6WPMtAU3n8k5065gZHPgc=;
 b=mRUq7T0abH37TpK3Ri9sWXmIHYHnlOvjuV3C0QdBqgHJz1jhlGjbxCDSzw0oPS0A8I3TryjNd
 WtW+RjnefEpCchMEGCd1pYYpH8nfZ2QNPns3ZkVAKlrhUnxrfAf0nxv
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtw88 ignores most of the radiotap header of injected frames: the
firmware rate adaptation picks the rate, the frames are sent at 20 MHz,
and the radiotap retry count and NO_ACK have no effect. The same was
recently fixed in rtw89, and Ping-Ke agreed to take similar patches for
rtw88 in the thread "rtw88: injected frames ignore radiotap rate and
retry count".

Patch 1 uses the injected legacy, HT or VHT rate, bandwidth and guard
interval, without rate fallback.

Patch 2 programs the TX descriptor retry limit for injected frames, sets
max_rate_tries so the radiotap retry count is no longer clamped to zero,
and reports NO_ACK frames as such.

Non-injected frames are not affected. Injected frames without a radiotap
rate keep the current rate selection. Keeping the sequence number of
injected management frames (IEEE80211_TX_CTL_ASSIGN_SEQ, also done in
rtw89) is not covered here.

These are compile tested only, I have no rtw88 hardware. Luka offered to
test. A way to test, with the rtw88 device in monitor mode and a second
radio sniffing the same channel:
- inject data frames with a radiotap rate, HT MCS or VHT MCS, with and
  without short GI, and check they arrive at that rate
- set the monitor interface to a 40 or 80 MHz channel first (e.g.
  "iw dev wlan0 set freq 5180 80 5210"; mac80211 drops frames asking for
  more than the channel width), then inject frames asking for 40 or
  80 MHz and check the bandwidth on the sniffer
- inject unicast frames to an absent station with a radiotap rate and
  retries 0 and 6: the sniffer should see 1 and 7 copies of each frame
  (mac80211 ignores the retry count without a rate, and caps it at 30);
  with the NO_ACK flag it should see 1 copy
- a quick check that normal station mode still works
Please mention the chip, the bus and the band you tested.

checkpatch --strict, W=1 and sparse are clean for each patch.

AI tool use (Documentation/process/generated-content.rst): the patches
were written with help from Claude Code (Claude Opus 5.5). It was asked
to apply the rtl8xxxu injection fixes to rtw88, using the rtw89
changes as a model, check the descriptor bits against rtl8xxxu, and
review the result. I have reviewed the changes and take responsibility
for them.

---
Ahmet Zeren (2):
      wifi: rtw88: use the rate, bandwidth and GI of injected frames
      wifi: rtw88: honour the retry count and NO_ACK of injected frames

 drivers/net/wireless/realtek/rtw88/main.c |  1 +
 drivers/net/wireless/realtek/rtw88/main.h |  2 ++
 drivers/net/wireless/realtek/rtw88/tx.c   | 49 ++++++++++++++++++++++++++++++-
 drivers/net/wireless/realtek/rtw88/tx.h   |  2 ++
 4 files changed, 53 insertions(+), 1 deletion(-)
---
base-commit: 8b29fd95e2d3cb80564eb7cb34248b844422ba1e
change-id: 20261124-b4-rtw88-inject-dfb3f092da48

Best regards,
--  
Ahmet Zeren <niko3x@proton.me>

