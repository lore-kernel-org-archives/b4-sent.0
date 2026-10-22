From: John Macias <dencity7@gmail.com>
Subject: [PATCH ath-next v2 0/2] wifi: ath11k/ath12k: bound READY MAC
 address array reads
Date: Wed, 21 Oct 2026 23:42:36 -0700
Message-Id: <20261021-rdy-mac-array-bounds-v2-0-cf7f45f868dd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFyw2WoC/32OwQ6CMBBEf8Xs2TVtTWniyf8wHEq7Qo20ZlsIh
 PDvAt49TmbezCyQiQNluJ0WYBpDDiluQp1P4DobW8LgNw1KqEoKqZH9jL11aJntjE0aos/oyQh
 njBZKGtjQD9MzTEftA2zpMNJUoP45eWhe5Mreume7kEvi+XgwyoP4PzZKFKg9KVM1Rit7vbe9D
 e+LSz3U67p+AcxXqDnUAAAA
X-Change-ID: 20261015-rdy-mac-array-bounds-de70c7750217
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, ath12k@lists.infradead.org, 
 John Macias <dencity7@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792651359; l=1870;
 i=dencity7@gmail.com; s=20261015; h=from:subject:message-id;
 bh=x634za5mpA5H7Frs7sJ8rHx/6pRCwtwzuVGuauUUndo=;
 b=yaLCM504EmJZP6hNt0Myf5YCfZ1kgaq5TM0OZFN40E16PNsE/PADW/nPDvEmFiNMFcHI0nUoy
 Zddlo9Wx0AuBQV544WoGKR0KpxRpo+LvEDRx9GlO+z2AjEbrcDfMVNj
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
on ath-next (W=1). The ath11k change has also run on an IPQ8074 hw1.0
board on every boot since 16 Oct; its firmware sends a well-formed
array, so that covers the normal path only. The ath12k change is
compile tested only. Neither has been tested on hardware with a
malformed event.

Jeff, following your pointers on my earlier ath12k RX-ring RFC, these
carry a full-name sign-off, an Assisted-by tag, and state the testing
explicitly. This work was developed with AI assistance.

---
Changes in v2:
- Drop RFC.
- ath11k: note the hardware run and add a Tested-on tag; no code change.
- v1 was accidentally sent twice; apologies for the duplicate.
- Link to v1: https://patch.msgid.link/20261015-rdy-mac-array-bounds-v1-0-5de276b752a3@gmail.com

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

