From: Kim Wooseok <5mghybrid@khu.ac.kr>
Subject: [PATCH net-next 0/4] net: macb: Rework hardware timestamp
 configuration
Date: Tue, 22 Sep 2026 18:10:48 +0900
Message-Id: <20260922-codex-macb-hwtstamp-submit-v1-0-9d1abaa53296@khu.ac.kr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNTQ6CMBCFr0Jm7UScIAlexbiYltGOSQtpq5IQ7
 m6LK5fv73srJIkqCS7NClHemnQKRZwODVjH4SGoY9FALfXtQIR2GmVBz9ag++SU2c+YXsZrRjq
 z6ZikN0MHBTBHueuyw68QJGOQJcPtl5TNU2yu7No1nARN5GBdtfaX4/9LrcC2fQFNbsejswAAA
 A==
X-Change-ID: 20260922-codex-macb-hwtstamp-submit-25ab4a2e6b94
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790068248; l=2436;
 i=5mghybrid@khu.ac.kr; s=kernel-20260913; h=from:subject:message-id;
 bh=++NArL2q0a8Rq+zt75joMwHyZFnjjRheWuposG1DMl8=;
 b=wQXn2eJM2sexqJSEKmc4voyyNCPbXLXtHOOAZmQmoGY+F/omgQx6vr6b5ZUGxcMC8xMue+Ixf
 tNVHJpQzOLJAg8jV1zrFtGr9d/Yc1GvshBJPzH/KwnfQi2p3NhiGEdw
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
PTPv1 filters, turn off one-step mode for TX_OFF, and clear SRTSM when
switching away from a PTPv2 filter. Each change is kept in its own patch.

I compared the old and new behavior on the Pi 5. When I requested a TX
mode change together with an invalid RX filter, the patched driver
rejected the request without changing the saved settings or NCR. I
also switched from one-step TX and PTPv2 RX to other settings and back.
Only the relevant bits changed, and restoring the original settings
restored NCR.

For the PTPv1 filters, I checked the effect by sending Sync and Delay_Req
packets over Ethernet. Before the change, the packets arrived without
hardware timestamps. With the patches, the driver returned ALL and I
could read the hardware timestamps from the received packets. PTPv2
multicast reception continued to provide hardware timestamps, and
selecting NONE disabled timestamping. I ran these tests with the changes
backported to the Pi's existing Linux 6.18.46 RT kernel.

On net-next, I built the series with ARM64 allyesconfig and allmodconfig,
both with W=1. Sparse reported no diagnostics in macb_ptp.c.

Assisted-by: GPT-6 Astra
Signed-off-by: Kim Wooseok <5mghybrid@khu.ac.kr>
---
Kim Wooseok (4):
      net: macb: Preserve timestamp settings on rejected requests
      net: macb: Enable RX timestamping for specific PTPv1 filters
      net: macb: Disable one-step mode when TX timestamping is off
      net: macb: Clear SRTSM outside PTPv2 receive filters

 drivers/net/ethernet/cadence/macb_ptp.c | 63 ++++++++++++---------------------
 1 file changed, 23 insertions(+), 40 deletions(-)
---
base-commit: 8830e65ed46de41f849eefb8ba227d4852c460f6
change-id: 20260922-codex-macb-hwtstamp-submit-25ab4a2e6b94

Best regards,
--  
Kim Wooseok <5mghybrid@khu.ac.kr>

