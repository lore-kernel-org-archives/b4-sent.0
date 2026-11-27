From: Ahmet Zeren <niko3x@proton.me>
Subject: [PATCH RFT rtw-next v2 0/2] wifi: rtw88: honour rate, retries and
 bandwidth of injected frames
Date: Fri, 27 Nov 2026 11:59:58 +0300
Message-Id: <20261127-b4-rtw88-inject-v2-0-f9701b9243a3@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WOOw7CMBBErxJtzaLYmHyoqDgAokMp8lkTR8KOb
 BOCotwdO9SUszNvdhZwZBU5OCULWJqUU0YHwXcJtH2tH4SqCxp4yjPGuMBGoPXvokClB2o9drI
 5yLTkXS0KCNRoSap5a7zD9XKLtwCgptlD9Qu4VxPZ2BvtXjlv7GfbMLEN/PtuYpiizMUxJ1FmJ
 Rfn0Rpv9P5JUK3r+gVtCf1t0QAAAA==
X-Change-ID: 20261124-b4-rtw88-inject-dfb3f092da48
To: Ping-Ke Shih <pkshih@realtek.com>
Cc: linux-wireless@vger.kernel.org, Luka Gejak <luka.gejak@linux.dev>, 
 Bitterblue Smith <rtl8821cerfe2@gmail.com>, linux-kernel@vger.kernel.org, 
 Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795770000; l=4068;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=XA6hvJ2ykDWPDMGyd8ghtclD+vX21M7Q2btfcMc/zWg=;
 b=SkF+LZWw+oSKSekGmsnlkDyGmKfQDA0ML7ycv/c0Kq9vqS4C+ptc4NsnYk1xrdBSf2iFt/el/
 HaHEbZcf9J2AT5ZXRE8FzzculImi5dK1tUNwKIxURvXbzPDS73wlUUF
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

One open question: Enver found that on rtw89 AX chips an unacked
unicast NO_ACK frame completes with "retry limit" rather than "done".
If rtw88 reports it the same way, such frames end up reported as failed
instead of IEEE80211_TX_STAT_NOACK_TRANSMITTED. Luka, could you check
the TX status of injected NO_ACK frames to an absent station? If they
come back as failed, I'll also treat that report as sent.

checkpatch --strict, W=1 and sparse are clean for each patch.

AI tool use (Documentation/process/generated-content.rst): the patches
were written with help from Claude Code (Claude Opus 5.5). It was asked
to apply the rtl8xxxu injection fixes to rtw88, using the rtw89
changes as a model, check the descriptor bits against rtl8xxxu, and
review the result. I have reviewed the changes and take responsibility
for them.

---
Changes in v2:
- Patch 2: program the radiotap retry count only when the frame has a
  usable radiotap rate (Luka).
- Patch 2: in the TX report, set IEEE80211_TX_STAT_NOACK_TRANSMITTED
  instead of IEEE80211_TX_STAT_ACK for NO_ACK frames that were sent,
  including group addressed frames (Luka).
- Patch 2: limit max_rate_tries by both the descriptor retry limit and
  IEEE80211_MAX_TX_RETRY.
- Patch 1: no change; DATA_SC stays zero, Luka's hardware test supports
  that REG_DATA_SC is used for frames narrower than the channel.
- Link to v1: https://patch.msgid.link/20261124-b4-rtw88-inject-v1-0-f7457e496924@proton.me

To: Ping-Ke Shih <pkshih@realtek.com>
Cc: linux-wireless@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Ahmet Zeren (2):
      wifi: rtw88: use the rate, bandwidth and GI of injected frames
      wifi: rtw88: honour the retry count and NO_ACK of injected frames

 drivers/net/wireless/realtek/rtw88/main.c |  1 +
 drivers/net/wireless/realtek/rtw88/main.h |  3 ++
 drivers/net/wireless/realtek/rtw88/tx.c   | 51 +++++++++++++++++++++++++++++--
 drivers/net/wireless/realtek/rtw88/tx.h   |  2 ++
 4 files changed, 55 insertions(+), 2 deletions(-)
---
base-commit: 8b29fd95e2d3cb80564eb7cb34248b844422ba1e
change-id: 20261124-b4-rtw88-inject-dfb3f092da48

Best regards,
--  
Ahmet Zeren <niko3x@proton.me>

