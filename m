From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH net v2 0/2] net: stmmac: Limit the MTU of normal
 descriptors to one buffer
Date: Sun, 22 Nov 2026 09:13:46 +0000
Message-Id: <20261122-sun8i-emac-mtu-limit-v2-0-c4081e5b83cf@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQ6CMBBEf8Xs2TV0wQY8+R+GQy0rrKHFtIVoC
 P8u4N3jTN68mSFyEI5wOcwQeJIog18DHQ9gO+NbRmnWDJSRVooUxtGXguyMRZdG7MVJQq1Nlet
 MF5U+wzp9BX7Ie9fewHOC+lfG8f5kmzbhhnUS0xA++/mkdvj/z6RQIVFRUVlQk6vy2joj/ckOD
 uplWb5MwuRAzwAAAA==
X-Change-ID: 20261121-sun8i-emac-mtu-limit-66a936064965
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 LABBE Corentin <clabbe.montjoie@gmail.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Russell King <rmk+kernel@armlinux.org.uk>, 
 Nicolai Buchwitz <nb@tipi-net.de>, Arun Iyengar <aiyengar1990@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795338826; l=1350;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=kUraPmsF3SOADB98zBKEXqM+wCmjpNaCBs9zDZNC9kc=;
 b=qYu87ckoyu+x7liUiYyq0MXj1k2T7Vca4KtNr/pGvuSjubWuT7K+bG8H2WVr7bcPTUrzmXjrs
 KpaYmvmMxdNDs8x9mNsZ8yqhoeyIclhzmbCokYm9yZ5AKE12rFJBY2l
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Normal descriptors take frames of at most one 2047-byte buffer, but
max_mtu allows 3712 on arm64. Patch 1 limits it in the core, patch 2
limits dwmac-sun8i further to the 2044 bytes its RX DMA fills.

Tested on an Orange Pi Zero2 (H616) on net/main. Without the patches,
MTU 2029 to 2100 is accepted and ping gets no reply. With patch 1 the
maximum is 2021, with both 2018. UDP and ping are lossless up to the
maximum, and larger MTUs are refused. Ring mode and other cores are
untested.

Claude (AI) helped write these patches; I reviewed and tested them.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v2:
- Limit normal descriptors in the core (patch 1, Andrew Lunn, Maxime
  Chevallier), keep the lower sun8i limit as patch 2
- Link to v1: https://patch.msgid.link/20261121-sun8i-emac-mtu-limit-v1-1-22492842d318@gmail.com

---
Arun Iyengar (2):
      net: stmmac: Limit the MTU of normal descriptors to one buffer
      net: stmmac: dwmac-sun8i: Limit the MTU to 2018

 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 1 +
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 3 +++
 2 files changed, 4 insertions(+)
---
base-commit: 890f23ba87a7ca1aba97c8320770a686e3b689fb
change-id: 20261121-sun8i-emac-mtu-limit-66a936064965

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

