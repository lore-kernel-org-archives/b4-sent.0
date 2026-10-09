From: Vincent Jardin <vjardin@free.fr>
Date: Fri, 09 Oct 2026 02:00:58 +0200
Subject: [PATCH net v2 3/3] ptp: qoriq: fix support for PTP_EXTTS_REQUEST2
 ioctl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-for-upstream-qoriq-ptp-extts-flags-v2-3-0f4eeff2295d@free.fr>
References: <20261009-for-upstream-qoriq-ptp-extts-flags-v2-0-0f4eeff2295d@free.fr>
In-Reply-To: <20261009-for-upstream-qoriq-ptp-extts-flags-v2-0-0f4eeff2295d@free.fr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791504062; l=1943;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=JAWE65GgAHfz2hlc0tfit/bmnoQ51Nw8aZJscKk9C/0=;
 b=C51hq5Nnlv2F0qfnE1JmLIfhgUQ/bfgqhPbfGhj5KKkVrKGmI/3KhCZjX4tuhM90gBmQpafej
 7KYGe2LzAO5A0XBlrwLEEKjsTkE2bEJUC5N/pzg9o43utXQgltDwSV9
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 7c571ac57d9d ("net: ptp: introduce .supported_extts_flags to
ptp_clock_info") moved the validation of the external timestamp request
flags into the PTP core. A driver that does not set
.supported_extts_flags still accepts the legacy PTP_EXTTS_REQUEST ioctl,
but every PTP_EXTTS_REQUEST2 request is rejected with -EOPNOTSUPP, since
the core always adds PTP_STRICT_FLAGS to it.

ptp_qoriq_init() programs TMR_CTRL with ETEP1 and ETEP2 cleared, so the
timer timestamps the rising edge of its external trigger inputs. Declare
that, with PTP_STRICT_FLAGS, so that a falling edge request is rejected
instead of being timestamped on the rising edge.

This also makes the legacy PTP_EXTTS_REQUEST ioctl strict: a request for
the falling edge, or for both edges, now fails with -EOPNOTSUPP instead
of being timestamped on the rising edge. That cannot be avoided: the core
adds PTP_STRICT_FLAGS to every PTP_EXTTS_REQUEST2 request, so a driver
has to declare it to accept them, and once declared it applies to both
ioctls. Commit 3200fdd4021d ("broadcom: fix support for
PTP_EXTTS_REQUEST2 ioctl") made the same change for bcm-phy-ptp.

Fixes: 7c571ac57d9d ("net: ptp: introduce .supported_extts_flags to ptp_clock_info")
Reviewed-by: Jacob Keller <jacob.e.keller@intel.com>
Reviewed-by: Kory Maincent <kory.maincent@bootlin.com>
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/ptp/ptp_qoriq.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/ptp/ptp_qoriq.c b/drivers/ptp/ptp_qoriq.c
index 76272e5ac5b8..bcd29104effe 100644
--- a/drivers/ptp/ptp_qoriq.c
+++ b/drivers/ptp/ptp_qoriq.c
@@ -355,6 +355,7 @@ static const struct ptp_clock_info ptp_qoriq_caps = {
 	.n_per_out	= 0,
 	.n_pins		= 0,
 	.pps		= 1,
+	.supported_extts_flags = PTP_RISING_EDGE | PTP_STRICT_FLAGS,
 	.adjfine	= ptp_qoriq_adjfine,
 	.adjtime	= ptp_qoriq_adjtime,
 	.gettime64	= ptp_qoriq_gettime,

-- 
2.43.0

