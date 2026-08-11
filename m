From: Cedric Jehasse <cedric.jehasse@luminex.be>
Date: Tue, 11 Aug 2026 13:45:47 +0200
Subject: [PATCH net-next v8 1/3] net/sched: cbs: add extack to struct
 tc_cbs_qopt_offload
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-net-next-mv88e6xxx-cbs-v8-1-10d0baab2905@luminex.be>
References: <20260811-net-next-mv88e6xxx-cbs-v8-0-10d0baab2905@luminex.be>
In-Reply-To: <20260811-net-next-mv88e6xxx-cbs-v8-0-10d0baab2905@luminex.be>
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Russell King <linux@armlinux.org.uk>, 
 Jamal Hadi Salim <jhs@mojatatu.com>, Jiri Pirko <jiri@resnulli.us>, 
 Vinicius Costa Gomes <vinicius.gomes@intel.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luke Howard <lukeh@padl.com>, 
 =?utf-8?q?Marek_Beh=C3=BAn?= <kabel@kernel.org>, 
 Cedric Jehasse <cedric.jehasse@gmail.com>, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786448754; l=1288;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=aNoIWhFNHrFQcCZfGOBB7BByzBoikUxu5dgW0xHObus=;
 b=eYcjP2tH+oPltczi2zPEVpvlrxZi/b8CgfAogNIgpdatuzALLD0WbWedHb6jOGXVpbqfJGUVu
 6mW+tPhQHM2BcZLq2xEmw7eudDCM5o27KlNkVJa09M0qjQ4Waiow9jA
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To be able to report reason for rejection when cbs offloading fails.

Signed-off-by: Cedric Jehasse <cedric.jehasse@luminex.be>
---
 include/net/pkt_sched.h | 1 +
 net/sched/sch_cbs.c     | 4 +++-
 2 files changed, 4 insertions(+), 1 deletion(-)

diff --git a/include/net/pkt_sched.h b/include/net/pkt_sched.h
index 18a419cd9d949..d35c87004c279 100644
--- a/include/net/pkt_sched.h
+++ b/include/net/pkt_sched.h
@@ -150,6 +150,7 @@ struct tc_cbs_qopt_offload {
 	s32 locredit;
 	s32 idleslope;
 	s32 sendslope;
+	struct netlink_ext_ack *extack;
 };
 
 struct tc_etf_qopt_offload {
diff --git a/net/sched/sch_cbs.c b/net/sched/sch_cbs.c
index 1c93469c56e3d..87c2eda108c8c 100644
--- a/net/sched/sch_cbs.c
+++ b/net/sched/sch_cbs.c
@@ -307,10 +307,12 @@ static int cbs_enable_offload(struct net_device *dev, struct cbs_sched_data *q,
 	cbs.locredit = opt->locredit;
 	cbs.idleslope = opt->idleslope;
 	cbs.sendslope = opt->sendslope;
+	cbs.extack = extack;
 
 	err = ops->ndo_setup_tc(dev, TC_SETUP_QDISC_CBS, &cbs);
 	if (err < 0) {
-		NL_SET_ERR_MSG(extack, "Specified device failed to setup cbs hardware offload");
+		NL_SET_ERR_MSG_WEAK(extack,
+				    "Specified device failed to setup cbs hardware offload");
 		return err;
 	}
 

-- 
2.43.0

