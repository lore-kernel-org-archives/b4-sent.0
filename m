From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH net 0/3] net: freescale: fix PTP_EXTTS_REQUEST2 for QorIQ
 1588
Date: Tue, 06 Oct 2026 15:34:49 +0200
Message-Id: <20261006-for-upstream-qoriq-ptp-extts-flags-v1-0-b4a161b92832@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPn4xGoC/x3NwQqDMAyA4VeRnBdoHXSwVxk7FJtqYGtrkokgv
 vuKx+/y/wcoCZPCczhAaGPlWjr8bYBpiWUm5NQNoxuDdy5groK/piYUv7hW4RWbNaTdTDF/4qz
 op5DT4+5TCBl6qAll3q/JCwoZvM/zDwEKjqt5AAAA
To: Yangbo Lu <yangbo.lu@nxp.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Jacob Keller <jacob.e.keller@intel.com>, 
 Kory Maincent <kory.maincent@bootlin.com>, 
 Claudiu Manoil <claudiu.manoil@nxp.com>, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, Wei Fang <wei.fang@nxp.com>, 
 Clark Wang <xiaoning.wang@nxp.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, Ioana Ciornei <ioana.ciornei@nxp.com>, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791293703; l=1256;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=N61tQOxTMC2LBXGugG3ji/4JgbnLcxTpSZkR/jWKgM4=;
 b=hwjXxIdv1DQkqRX60jcCXDonlt4EW5N8GrY38a4HR7bpMQeY0x4rwgJuLOrIc0R7cZBFVoP1F
 B2dx9y+T1L/Dn1T4gfnfclAjajHuUAEAlmgFksqX5uxJSWIUgLb0TV7
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 7c571ac57d9d ("net: ptp: introduce .supported_extts_flags
to ptp_clock_info"), the PTP core rejects every PTP_EXTTS_REQUEST2
request for a driver that does not set .supported_extts_flags. The three
users of the QorIQ 1588 (dpaa2-ptp, enetc, ptp_qoriq),
so linuxptp ts2phc cannot arm their external timestamp inputs.

The timer timestamps the rising edge only, since ptp_qoriq_init() clears
ETEP1 and ETEP2. Each patch declares PTP_RISING_EDGE | PTP_STRICT_FLAGS
for one driver.

Patch 1 fixes the failure seen on an LX2160A board.
Patches 2 and 3 are build-tested/code review only.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Vincent Jardin (3):
      dpaa2-ptp: fix support for PTP_EXTTS_REQUEST2 ioctl
      net: enetc: fix support for PTP_EXTTS_REQUEST2 ioctl
      ptp: qoriq: fix support for PTP_EXTTS_REQUEST2 ioctl

 drivers/net/ethernet/freescale/dpaa2/dpaa2-ptp.c | 1 +
 drivers/net/ethernet/freescale/enetc/enetc_ptp.c | 1 +
 drivers/ptp/ptp_qoriq.c                          | 1 +
 3 files changed, 3 insertions(+)
---
base-commit: d5a007b9b457c915ab1a53227e8939e4018aa97a
change-id: 20261006-for-upstream-qoriq-ptp-extts-flags-1c6fd731d66f

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

