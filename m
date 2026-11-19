From: Ahmet Zeren <niko3x@proton.me>
Subject: [PATCH rtw-next 0/3] wifi: rtl8xxxu: honour rate, retries and
 bandwidth of injected frames
Date: Fri, 20 Nov 2026 01:09:27 +0300
Message-Id: <20261120-b4-inject-v1-0-1e1693af0c6b@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMMQ6DMBAEv4K2zknYIAj5SpQiNme4FCayHUBC/
 D0GytHuzIbIQTjiUWwIPEuUyWdQtwJ2fPuBSfrM0KVulNIlmZrEf9gmco2rjb23VdVp5P83sJP
 1bD0R0kKe14TXtcSfOaQjhX3/AzUvjSp3AAAA
X-Change-ID: 20261120-b4-inject-f6f4bc873392
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795126169; l=2447;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=wIWSBvsZagGyK7K273K72Z/OcMBhty/IqhzJyzOyBko=;
 b=U3R2Pco+Xmj2bsVNtdyeC5YzFxciqXsIvMCA9n6bMXQ5sdbxrZFdNciMSslAs3hDRiYThUjuS
 AzKpAyYQ95OBt05gufLlm5wxDi+5I/mgnAJRo0fhS9q4Yrb8R1OEDE8
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
Ahmet Zeren (3):
      wifi: rtl8xxxu: honour the rate of injected frames on gen1 chips
      wifi: rtl8xxxu: honour the retry count of injected frames on gen1 chips
      wifi: rtl8xxxu: honour the bandwidth of injected frames on gen1 chips

 drivers/net/wireless/realtek/rtl8xxxu/core.c | 78 +++++++++++++++++++++++++---
 1 file changed, 70 insertions(+), 8 deletions(-)
---
base-commit: 0bdc579dbfc251a6b6838ee9459b6771b948c617
change-id: 20261120-b4-inject-f6f4bc873392

Best regards,
--  
Ahmet Zeren <niko3x@proton.me>

