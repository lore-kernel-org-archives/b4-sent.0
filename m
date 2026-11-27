From: Ahmet Zeren <niko3x@proton.me>
Subject: [PATCH rtw-next 0/2] wifi: rtl8xxxu: fix two retry count overflows
Date: Fri, 27 Nov 2026 21:53:16 +0300
Message-Id: <20261127-b4-rtl8xxxu-retry-v1-0-b263ab1e0d1b@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6Xs2QUTrVZ/RTwk7VNXJMpmq5HSf
 zfqcRhmJspQQaZ9M5HiKVnuqYJbNNRfQjqDZahMfuk3zvktxzWr3bpSysgK0zfHXRewCi3aMFD
 tHoqTlN/zQGovTihGx7/JY7yit++S5vkDn3gGVX8AAAA=
X-Change-ID: 20261127-b4-rtl8xxxu-retry-b98ae3a5e5ad
To: Ping-Ke Shih <pkshih@realtek.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, Luka Gejak <luka.gejak@linux.dev>, 
 Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795805597; l=1488;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=C+fmUZhSRYASAFwtdzlDoSA24tjcNh9wx+DlbYnJRAQ=;
 b=N8E+2lRfJ/F7zWgcxQImZxhCDKs2NaCLgRYgpPmE3y+teyKgWuFlqpDQi5QsJZcDy+OkGqzJh
 zssMs423QpIAZjmjeFod2kwjFTw6irCDDox1NuOmuShCH1MQpQNrABP
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The retry count in mac80211's struct ieee80211_tx_rate is only 5 bits
wide, and rtl8xxxu overflows it in two places: max_rate_tries is set to
64, and the TX report passes up to 64 tries. I found these while porting
the injection changes to rtw88, as mentioned in the rtw88 thread.

Tested on RTL8192CU (0bda:8178) on 2.4 GHz, with injected frames to an
absent station and the retry count from the TX report:

                         before   after
  31 requested retries     16       30
  40 requested retries      8       30
  default limit (48)       16       30

(before, 31 retries fell back to the default limit, which the TX report
showed as 16.) checkpatch --strict, W=1 and sparse are clean.

AI tool use (Documentation/process/generated-content.rst): the patches
were written with help from Claude Code (Claude Opus 5.5). It was asked
to fix the overflow found in review and test the boundary values on
the RTL8192CU; that test showed the second one. I have reviewed and
tested the changes and take responsibility for them.

---
Ahmet Zeren (2):
      wifi: rtl8xxxu: limit max_rate_tries to what mac80211 can pass
      wifi: rtl8xxxu: limit the retry count in the TX report

 drivers/net/wireless/realtek/rtl8xxxu/core.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)
---
base-commit: ae6b9e98b9045e47f609ec2a8197a3f3109627cb
change-id: 20261127-b4-rtl8xxxu-retry-b98ae3a5e5ad

Best regards,
--  
Ahmet Zeren <niko3x@proton.me>

