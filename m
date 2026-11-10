From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH net-next 0/2] net: stmmac: dwmac-sun8i: Jumbo frames and an
 RX_TH fix
Date: Tue, 10 Nov 2026 06:03:34 +0000
Message-Id: <20261110-sun8i-emac-jumbo-v1-0-84bf00e9ffa3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBAAvyJ77oJRkaRfKT3EdNUVXEs2EUH8e
 9P2OAwzJyhFJoV7dUKknZU3KWBuFYTZy0TIr8LQ1E1vjKlRs1hGWn3AJa/Dhp1t3ehs53vvoGT
 vSCMfv+UDhBIKHQmef6N5WCik7xGu6wO3KepFfgAAAA==
X-Change-ID: 20261110-sun8i-emac-jumbo-4839f984a6a9
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>
Cc: netdev@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-stm32@st-md-mailman.stormreply.com, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794290614; l=1822;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=fve8G7g52w2v6vFX62vTvr/RCrFjlLHllgVlfUFu2aI=;
 b=yiASFtAaGQrGGu4XHXlG2h+pF+Hzb/UBBEhAtLY9NC58E0ylgDSaZ1CZuUKHzwRDxRzWB69fK
 xYjfYUjP8yuCPmZ059HUcJ++lca+DRT9JEoJp5/2I9MfGgy3MpRZQmU
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sun8i EMAC advertises a maximum MTU of 3712, but drops every frame
longer than 1518 bytes. Patch 2 sets the receiver's jumbo frame enable
bit and limits the MTU to what fits in one normal descriptor buffer
(2018). Patch 1 corrects two swapped RX threshold values; it has no
effect on current configurations, hence no Fixes: tag.

Tested on an Orange Pi Zero2 (H616, RTL8211F over RGMII) at 1 Gbit/s,
with a 7.3 kernel carrying both patches:
- MTU 2000 and 2018: pings with DF set up to the full MTU pass in both
  directions, iperf3 gives 955 Mbit/s to the board and 905 Mbit/s from
  it, and the rx_length and rx_crc_errors counters stay at 0.
- Setting MTU 2019 is refused.
- At MTU 1500, a 90 minute run (bulk transfers up to 256 MiB both ways,
  iperf3 853/873 Mbit/s, 1000 pings each of 56, 1472 and 8000 bytes)
  had no loss and no new error counters.

In that 7.3 kernel, frames longer than 2044 bytes were dropped by a
local norm_desc change; v7.4-rc2 does the same through commit
834ec9530832 ("net: stmmac: drop split frames on AF_XDP zero-copy RX"),
which patch 2 now relies on.

These patches were developed with Claude (Anthropic) as a coding
assistant. It investigated the problem and wrote the code and the commit
messages; I reviewed them, and they were tested on an Orange Pi Zero2
(H616) as described above.

---
Arun Iyengar (2):
      net: stmmac: dwmac-sun8i: Fix the RX_TH threshold encoding
      net: stmmac: dwmac-sun8i: Enable jumbo frames up to MTU 2018

 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 29 +++++++++++++++++++++--
 1 file changed, 27 insertions(+), 2 deletions(-)
---
base-commit: d26955e57475434b59d43ba372b2a50d33d5e0ed
change-id: 20261110-sun8i-emac-jumbo-4839f984a6a9

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

