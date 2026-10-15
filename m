From: John Macias <dencity7@gmail.com>
Subject: [PATCH RFC ath-next 0/2] wifi: ath11k/ath12k: bound READY MAC
 address array reads
Date: Thu, 15 Oct 2026 13:55:23 -0700
Message-Id: <20261015-rdy-mac-array-bounds-v1-0-5de276b752a3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALs90WoC/yWMQQrCMBBFr1Jm7UASqAG3ggdwK11Mk9FGMJWZV
 FpK726qy/f5762gLIkVTs0Kwp+kacwV7KGBMFB+MKZYGZxxR2tsixIXfFFAEqEF+3HKUTGyN8H
 71jjroapv4Xuaf9kbXC/nfaMyYOa5QPc/6NQ/OZQ9Dtv2BdKfhwGJAAAA
X-Change-ID: 20261015-rdy-mac-array-bounds-de70c7750217
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, ath12k@lists.infradead.org, 
 John Macias <dencity7@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792097735; l=1380;
 i=dencity7@gmail.com; s=20261015; h=from:subject:message-id;
 bh=ReHuuM+HjdzYLwEJhUbU5VO8Ceo+V/a93dpA2WxkIYk=;
 b=qk3rH7i82oGLnWB/24kgq4kwfhaT5xl9p5uCpzh6HOY2aLvfidVKg+nmL1kF468n9NZkjKcaJ
 61byeB9jHX9C2be+01FH/DZMPfXf3byB1D3ZQvanz3y2pBmiD+WZvhM
X-Developer-Key: i=dencity7@gmail.com; a=ed25519;
 pk=z7cMHA0B6NULvJzsST/bbOOegMB6xCo9+/ytQure7B8=
X-Endpoint-Received: by B4 Relay for dencity7@gmail.com/20261015 with auth_id=1198
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_wmi_tlv_rdy_parse() and ath12k_wmi_rdy_parse() copy one MAC
address per radio from the READY event's fixed-struct array after
checking only the count advertised in the fixed record, not the array
TLV length. A firmware READY event with a short array makes the copy
read past the end of the TLV value.

These patches check the array length first and fall back to the
driver's default per-radio addresses when it is too short.

Found while bringing up an IPQ8074 v1 device with older firmware; the
issue is not specific to that hardware. Verified with a userspace harness
around the unmodified parsers under AddressSanitizer. Compile tested
only (ath-next, W=1); not tested on hardware with a malformed event.

Jeff, following your pointers on my earlier ath12k RX-ring RFC, these
carry a full-name sign-off, an Assisted-by tag, and state the testing
explicitly. This work was developed with AI assistance.

---
John Macias (2):
      wifi: ath11k: bound READY MAC address array reads
      wifi: ath12k: bound READY MAC address array reads

 drivers/net/wireless/ath/ath11k/wmi.c | 6 ++++++
 drivers/net/wireless/ath/ath12k/wmi.c | 6 ++++++
 2 files changed, 12 insertions(+)
---
base-commit: cd026e68fdbf88b9cc522b76c7a9d92c9a41f709
change-id: 20261015-rdy-mac-array-bounds-de70c7750217

Best regards,
--  
John Macias <dencity7@gmail.com>

