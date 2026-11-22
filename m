From: Ahmet Zeren <niko3x@proton.me>
Subject: [PATCH rtw-next v2 0/3] wifi: rtl8xxxu: honour rate, retries and
 bandwidth of injected frames
Date: Sun, 22 Nov 2026 08:59:28 +0300
Message-Id: <20261122-b4-inject-v2-0-0ee720fe706d@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NwQ6CMBBEf4Xs2TVtIVU88R+GA61bWRNb0lbEE
 P5dwKvHybx5M0OiyJTgUswQaeTEwa9BHQqwfefvhHxbMyihtJRKoKmQ/YNsRqddZez5VJa1gpU
 fIjmedtcVYn6jpylD+2vSy2yjTbWxPacc4me/HeW++PMwShQoSeq67Jyw2jRDDDn445OgXZblC
 37YnY2+AAAA
X-Change-ID: 20261120-b4-inject-f6f4bc873392
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795327172; l=2971;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=lWc6DKtgjxLILVy0Q8VxPg5yRszEjJKsrK5kKIhso0E=;
 b=wPMBny5Tjwt0nQN3TpuEGo6SSCgj19tBysD9Uhi5ZdScsErgzDziQEtgKb/g5yHO4/hjpjmki
 /I7goFXSzYZDreMz8PHPcbntyHJ8nzXeb4mD8AR3Udj51KyGChLFBwf
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtl8xxxu ignores most of the radiotap header of injected frames. On a
RTL8192CU every injected frame went out at MCS 7 and 20 MHz whatever was
requested, the retry count was ignored, and NOACK frames were retried up
to 48 times. That makes the driver unusable for tools that rely on
fixed-rate injection.

Patch 1 makes gen1 chips (RTL8188CU, RTL8192CU, RTL8723AU) use the
injected rate and guard interval, without rate fallback.

Patch 2 makes the radiotap retry count and NOACK work. max_rate_tries is
0 today, so mac80211 clamps injected retries to zero, and the hardware
default of 48 retries is used instead: unicast frames to an absent
station then stalled injection for over 100 s in my tests.

Patch 3 sends injected frames at 40 MHz when they ask for it. Only QoS
data frames get the 40 MHz descriptor bits today.

Frames without radiotap rate information are not affected.

Gen2 chips and the RTL8188EU use other descriptor formats. Patches for
them follow as a separate RFT series, since I cannot test them.

Testing, all on RTL8192CU (0bda:8178) in monitor mode, received by a
second radio:
- 1, 5.5, 6 and 54 Mbps and MCS 0/7/8/15 with long and short GI arrive
  at the requested rate (stock driver: all MCS 7).
- Unicast frames to an absent station: drain time grows with the
  requested retry count, NOACK frames are sent once.
- Channel 6 HT40+ and HT40-: MCS 0 and 7 requested at 40 MHz arrive at
  40 MHz (stock driver: 20 MHz).
- checkpatch --strict, W=1 and sparse are clean for each patch.

AI tool use (Documentation/process/generated-content.rst): the patches
were written with help from Claude Code (Claude Opus 5.5). It was asked
to find why injected frames ignore the radiotap rate, retry count and
bandwidth, write the fixes, and run the over-the-air tests above. I have
reviewed and tested the changes and take responsibility for them.

---
Changes in v2:
- Patch 1: drop the comment above rtl8xxxu_tx_rate_inject().
- Patch 2: set the retry limit together with the management frame
  case, so the field is no longer cleared and set twice; use
  le32_encode_bits(); add TXDESC32_RETRY_LIMIT_MAX for max_rate_tries.
- Patch 3: declare bw40 on its own line.
- Collect Reviewed-by and Acked-by from Ping-Ke.
- Link to v1: https://patch.msgid.link/20261120-b4-inject-v1-0-1e1693af0c6b@proton.me

---
Ahmet Zeren (3):
      wifi: rtl8xxxu: honour the rate of injected frames on gen1 chips
      wifi: rtl8xxxu: honour the retry count of injected frames on gen1 chips
      wifi: rtl8xxxu: honour the bandwidth of injected frames on gen1 chips

 drivers/net/wireless/realtek/rtl8xxxu/core.c     | 76 +++++++++++++++++++++---
 drivers/net/wireless/realtek/rtl8xxxu/rtl8xxxu.h |  1 +
 2 files changed, 68 insertions(+), 9 deletions(-)
---
base-commit: 0bdc579dbfc251a6b6838ee9459b6771b948c617
change-id: 20261120-b4-inject-f6f4bc873392

Best regards,
--  
Ahmet Zeren <niko3x@proton.me>

