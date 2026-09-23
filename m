From: Kim Wooseok <5mghybrid@khu.ac.kr>
Subject: [PATCH net-next v2 0/3] net: macb: Rework hardware timestamp
 configuration
Date: Wed, 23 Sep 2026 18:13:24 +0900
Message-Id: <20260923-macb-hwtstamp-rework-v2-0-75c909b2676d@khu.ac.kr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12Oyw6CMBBFf8XM2lGoSoIr/8OwmJbRVkJL2vIwh
 n+XYmKiyztz7uMFgb3hAOfNCzwPJhhnFyG2G1Ca7J3R1IsGkYkiK4XAlpREPcYQqe3Q8+h8g+J
 E8kiCC1keYbF2nm9mWmOvYDmi5SlC9fmEXj5YxZSaWEmBUXqySqeTcjVP+9+WhCRUmxCdf65jh
 3wN/+5afX/rlqbWRBxyzLCsc5JEp4Moi0uj+x2pXeOhmuf5Da69/7UFAQAA
X-Change-ID: 20260922-macb-hwtstamp-rework-25ab4a2e6b94
To: netdev@vger.kernel.org, 
 =?utf-8?q?Th=C3=A9o_Lebrun?= <theo.lebrun@bootlin.com>, 
 Rafal Ozieblo <rafalo@cadence.com>
Cc: Conor Dooley <conor.dooley@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Nicolai Buchwitz <nb@tipi-net.de>, linux-kernel@vger.kernel.org, 
 Kim Wooseok <5mghybrid@khu.ac.kr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790154804; l=2844;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=Q+uqszN6bHLsWyywZim/j02cJONFOD6N5+Iw0UrUCe0=;
 b=RmETYOfb5kImrjTdbxpSIwITAlSUtVyvOOxXFxz9W9qFhnzUj7Lnw4VZbUcd62wWElptcH46L
 FDYtEWNnmRxCRQp+56D1U0zpTUAhe8yMXA3Tk6kQVITdwVJWFE7WroI
X-Developer-Key: i=5mghybrid@khu.ac.kr; a=ed25519;
 pk=1az/6lC8Tmd6BcvyarPc8FWoSxsV/WRr5NLs1v+kjlE=
X-Endpoint-Received: by B4 Relay for 5mghybrid@khu.ac.kr/kernel-20260913 with auth_id=1028
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This started with two problems I found while using PTP hardware
timestamping on a Raspberry Pi 5. A rejected RX filter could still
change the TX one-step setting, and the PTPv1 Sync and Delay_Req filters
returned success without enabling RX timestamps.

This series reworks gem_set_hwtst() to validate the whole request before
programming the hardware. It calculates the settings locally, then
updates the registers and saved configuration under bp->lock. With the
register writes now in the setter, the two helpers are no longer needed.

The remaining patches use the existing ALL fallback for the specific
PTPv1 filters and clear SRTSM when switching away from a PTPv2 filter.
Each change is kept in its own patch.

For v1, I compared the old and new behavior on the Pi 5. When I
requested a TX mode change together with an invalid RX filter, the
patched driver rejected the request without changing the saved settings
or NCR. I also checked transitions between PTPv2 RX and the other
receive filters. SRTSM followed the selected RX filter without changing
unrelated NCR bits.

For the PTPv1 filters, I checked the effect by sending Sync and Delay_Req
packets over Ethernet. Before the change, the packets arrived without
hardware timestamps. With the patches, the driver returned ALL and I
could read the hardware timestamps from the received packets. PTPv2
multicast reception continued to provide hardware timestamps, and
selecting NONE disabled timestamping. I ran these tests with the changes
backported to the Pi's existing Linux 6.18.46 RT kernel.

On net-next, I built v1 with ARM64 allyesconfig and allmodconfig,
both with W=1. Sparse reported no diagnostics in macb_ptp.c.
For v2, I rebuilt macb_ptp.o with W=1.

Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
Changes in v2:
- Drop v1 patch 3/4 and retain the existing TX_OFF handling.
- Rebase the SRTSM cleanup onto the remaining patches, preserving
  its RX behavior.
- Reorder local variables to follow reverse Christmas tree ordering
  and handle each TX mode explicitly instead of using fallthrough.
- Add Reviewed-by and Tested-by tags.
- No other functional changes.
- Link to v1: https://patch.msgid.link/20260922-codex-macb-hwtstamp-submit-v1-0-9d1abaa53296@khu.ac.kr

---
Kim Wooseok (3):
      net: macb: Preserve timestamp settings on rejected requests
      net: macb: Enable RX timestamping for specific PTPv1 filters
      net: macb: Clear SRTSM outside PTPv2 receive filters

 drivers/net/ethernet/cadence/macb_ptp.c | 62 +++++++++++++--------------------
 1 file changed, 24 insertions(+), 38 deletions(-)
---
base-commit: 8830e65ed46de41f849eefb8ba227d4852c460f6
change-id: 20260922-macb-hwtstamp-rework-25ab4a2e6b94

Best regards,
--  
Kim Wooseok <5mghybrid@khu.ac.kr>

