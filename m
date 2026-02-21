From: Satish Kharat <satishkh@cisco.com>
Subject: [PATCH 0/2] net:ethernet:enic: add VIC ids and link modes
Date: Sat, 21 Feb 2026 10:16:58 -0800
Message-Id: <20260221-enic-cscwi36355-v1-0-5a01a6046d5e@cisco.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJr2mWkC/x3MQQqAIBBA0avErBNGRaOuEi1Kx5qNhUIF4t2Tl
 m/xf4FMiSnD1BVIdHPmMzbIvgN3rHEnwb4ZFCqLSqGgyE647B7WVhsjhuARNzMGkgituhIFfv/
 jvNT6Ae3wD9NhAAAA
To: netdev@vger.kernel.org
Cc: Satish Kharat <satishkh@cisco.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771697893; l=687;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=UfDNKpDb/dwweC33U6JoY4SpY1Q5JaNKwn/41UrKx2A=;
 b=E138a4JkR3wEgSdZl0KLO5LE1B3LTYiHO+36w0Gt6yIu63nAsq/ms5hBlwmjEliHoKFuNBIfr
 jtaY/PsSqEjCk4Jmv/nJuR12uZKRGVB5xDbm2k4uBqSCuV5p6Wvqje2
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add VIC subsystem ids and their supported/advertised media types so ethtool
reflects the hardware capabilities for the VIC variants.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
Satish Kharat (2):
      net:ethernet:enic: add VIC subsystem ids
      net:ethernet:enic: map ethtool link modes by VIC type

 drivers/net/ethernet/cisco/enic/enic.h         |  39 +++++
 drivers/net/ethernet/cisco/enic/enic_ethtool.c | 229 ++++++++++++++++++++++++-
 2 files changed, 261 insertions(+), 7 deletions(-)
---
base-commit: 8bf22c33e7a172fbc72464f4cc484d23a6b412ba
change-id: 20260220-enic-cscwi36355-7fd00b59fe10

Best regards,
-- 
Satish Kharat <satishkh@cisco.com>

