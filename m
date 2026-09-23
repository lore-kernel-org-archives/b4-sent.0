From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH net-next 0/2] dpaa2-eth: devlink port number from the DPMAC
Date: Wed, 23 Sep 2026 14:57:59 +0200
Message-Id: <20260923-for-upstream-dpaa2_ports-v1-0-b59c865edd00@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANfMs2oC/x3MQQqDMBBA0avIrDuQJqK2VymlJHWis2gSZtIii
 Hc3dPkW/++gJEwK924HoR8r59RwvXTwXn1aCHluBmvsYG7WYcyC36JVyH9wLt7bV8lSFU1vpjE
 4F8IUoeVFKPL2Xz8gUcVEW4XncZyrmw4TdAAAAA==
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Ioana Ciornei <ioana.ciornei@nxp.com>, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790168286; l=1396;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=5pNfbU4tVij2R4/+mEJuS3A2gb4SCB4DZw+rw+oOaCs=;
 b=NSSeihn4C6BNXOpN2tdySGlRBWLAWLBfPs/0a/WW6inrzYeEoFahCHQSv6CdoIp5QJRHWVMYo
 YFO3N5ya4cVDaLYkaVl7OFbKyUE7ebm0pbOQGAfiufzmSqLt3ccNF5t
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dpaa2-eth registers every DPNI as a physical devlink port without a
port number, so all the DPAA2 interfaces report the same
phys_port_name "p0", including the DPNIs that have no DPMAC behind
them.

Patch 1 uses the DPMAC id as the physical port number. The attributes
of a registered devlink port cannot change, so when the DPNI endpoint
changes at runtime a warning says the number is stale until the DPNI
is rebound.

Patch 2 registers the DPNIs without a DPMAC as virtual ports. They
have no phys_port_name, so "p<dpmac id>" is unique.

With both patches, udev can name an interface using its DPMAC, for
instance:

  SUBSYSTEM=="net", ACTION=="add", DRIVERS=="fsl_dpaa2_eth", \
    ATTR{phys_port_name}=="p3", NAME="dpmac3"

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Vincent Jardin (2):
      dpaa2-eth: use the DPMAC id as the devlink physical port number
      dpaa2-eth: DPNIs without a DPMAC should be virtual devlink ports

 .../ethernet/freescale/dpaa2/dpaa2-eth-devlink.c   | 35 +++++++++++++++++++++-
 drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.c   |  2 ++
 drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.h   |  1 +
 3 files changed, 37 insertions(+), 1 deletion(-)
---
base-commit: 944ae66642b726bd6b25ae71b1e9ff88a0e0bdb0
change-id: 20260923-for-upstream-dpaa2_ports-04087b33bb8f

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

