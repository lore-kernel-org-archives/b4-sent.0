From: Cedric Jehasse <cedric.jehasse@luminex.be>
Date: Thu, 04 Jun 2026 10:30:14 +0200
Subject: [PATCH net-next 1/2] net: dsa: add support for dcb pcp app
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-net-next-mv88e6xxx-pcp-prio-v1-1-f9d10fe6cdc8@luminex.be>
References: <20260604-net-next-mv88e6xxx-pcp-prio-v1-0-f9d10fe6cdc8@luminex.be>
In-Reply-To: <20260604-net-next-mv88e6xxx-pcp-prio-v1-0-f9d10fe6cdc8@luminex.be>
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luke Howard <lukeh@padl.com>, Cedric Jehasse <cedric.jehasse@gmail.com>, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780561819; l=7081;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=vAbt2oUZwh/Xl1VBsXEixbjizxp0CkUnxtZsJliOylM=;
 b=fRYhAMUUjGItSLgK1KBvFXTrF64mRPvaT/fHSgkT2XMW6s1snlpMsIo7J1q7Ion/DSLUt+pBH
 k2FIxzWGT9iASVhBQiI+cGU5+BGe5UlCvFmDY1GE0VdFzizo2cyskR+
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set/get of dscp-prio map is already supported by dsa.
This adds support for set/get of pcp-prio map in a similar way.

Signed-off-by: Cedric Jehasse <cedric.jehasse@luminex.be>
---
 include/net/dsa.h |  10 +++++
 net/dsa/user.c    | 126 +++++++++++++++++++++++++++++++++++++++++++++++++++---
 2 files changed, 129 insertions(+), 7 deletions(-)

diff --git a/include/net/dsa.h b/include/net/dsa.h
index 8b6d34e8a6f0..05428c555ccd 100644
--- a/include/net/dsa.h
+++ b/include/net/dsa.h
@@ -447,6 +447,11 @@ struct dsa_switch {
 	 */
 	u32			dscp_prio_mapping_is_global:1;
 
+	/* Drivers that have global PCP mapping settings must set this to
+	 * true to automatically apply the settings to all ports.
+	 */
+	u32			pcp_prio_mapping_is_global:1;
+
 	/* Listener for switch fabric events */
 	struct notifier_block	nb;
 
@@ -970,6 +975,11 @@ struct dsa_switch_ops {
 				      u8 prio);
 	int	(*port_del_dscp_prio)(struct dsa_switch *ds, int port, u8 dscp,
 				      u8 prio);
+	int	(*port_get_pcp_prio)(struct dsa_switch *ds, int port, u8 pcp);
+	int	(*port_add_pcp_prio)(struct dsa_switch *ds, int port, u8 pcp,
+				     u8 prio);
+	int	(*port_del_pcp_prio)(struct dsa_switch *ds, int port, u8 pcp,
+				     u8 prio);
 	int	(*port_set_apptrust)(struct dsa_switch *ds, int port,
 				     const u8 *sel, int nsel);
 	int	(*port_get_apptrust)(struct dsa_switch *ds, int port, u8 *sel,
diff --git a/net/dsa/user.c b/net/dsa/user.c
index c4bd6fe90b45..aa6d030968b9 100644
--- a/net/dsa/user.c
+++ b/net/dsa/user.c
@@ -2238,11 +2238,11 @@ dsa_user_dcbnl_set_default_prio(struct net_device *dev, struct dcb_app *app)
 	return 0;
 }
 
-/* Update the DSCP prio entries on all user ports of the switch in case
- * the switch supports global DSCP prio instead of per port DSCP prios.
+/* Update the APP entries on all user ports of the switch in case
+ * the switch supports global prio settings instead of per port prios.
  */
-static int dsa_user_dcbnl_ieee_global_dscp_setdel(struct net_device *dev,
-						  struct dcb_app *app, bool del)
+static int dsa_user_dcbnl_ieee_global_setdel(struct net_device *dev,
+					     struct dcb_app *app, bool del)
 {
 	int (*setdel)(struct net_device *dev, struct dcb_app *app);
 	struct dsa_port *dp = dsa_user_to_port(dev);
@@ -2284,7 +2284,7 @@ static int dsa_user_dcbnl_ieee_global_dscp_setdel(struct net_device *dev,
 
 		restore_err = setdel(user, app);
 		if (restore_err)
-			netdev_err(user, "Failed to restore DSCP prio entry configuration\n");
+			netdev_err(user, "Failed to restore APP entry configuration\n");
 	}
 
 	return err;
@@ -2324,7 +2324,7 @@ dsa_user_dcbnl_add_dscp_prio(struct net_device *dev, struct dcb_app *app)
 	if (!ds->dscp_prio_mapping_is_global)
 		return 0;
 
-	err = dsa_user_dcbnl_ieee_global_dscp_setdel(dev, app, false);
+	err = dsa_user_dcbnl_ieee_global_setdel(dev, app, false);
 	if (err) {
 		if (ds->ops->port_del_dscp_prio)
 			ds->ops->port_del_dscp_prio(ds, port, dscp, new_prio);
@@ -2335,6 +2335,54 @@ dsa_user_dcbnl_add_dscp_prio(struct net_device *dev, struct dcb_app *app)
 	return 0;
 }
 
+static int __maybe_unused
+dsa_user_dcbnl_add_pcp_prio(struct net_device *dev, struct dcb_app *app)
+{
+	struct dsa_port *dp = dsa_user_to_port(dev);
+	struct dsa_switch *ds = dp->ds;
+	unsigned long mask, new_prio;
+	int err, port = dp->index;
+	u8 pcp = app->protocol;
+
+	if (!ds->ops->port_add_pcp_prio)
+		return -EOPNOTSUPP;
+
+	if (app->priority >= IEEE_8021QAZ_MAX_TCS)
+		return -EINVAL;
+
+	if (pcp >= 16) {
+		netdev_err(dev, "PCP APP entry with protocol value %u is invalid\n",
+			   pcp);
+		return -EINVAL;
+	}
+
+	err = dcb_ieee_setapp(dev, app);
+	if (err)
+		return err;
+
+	mask = dcb_ieee_getapp_mask(dev, app);
+	new_prio = __fls(mask);
+
+	err = ds->ops->port_add_pcp_prio(ds, port, pcp, new_prio);
+	if (err) {
+		dcb_ieee_delapp(dev, app);
+		return err;
+	}
+
+	if (!ds->pcp_prio_mapping_is_global)
+		return 0;
+
+	err = dsa_user_dcbnl_ieee_global_setdel(dev, app, false);
+	if (err) {
+		if (ds->ops->port_del_pcp_prio)
+			ds->ops->port_del_pcp_prio(ds, port, pcp, new_prio);
+		dcb_ieee_delapp(dev, app);
+		return err;
+	}
+
+	return 0;
+}
+
 static int __maybe_unused dsa_user_dcbnl_ieee_setapp(struct net_device *dev,
 						     struct dcb_app *app)
 {
@@ -2349,6 +2397,8 @@ static int __maybe_unused dsa_user_dcbnl_ieee_setapp(struct net_device *dev,
 		break;
 	case IEEE_8021QAZ_APP_SEL_DSCP:
 		return dsa_user_dcbnl_add_dscp_prio(dev, app);
+	case DCB_APP_SEL_PCP:
+		return dsa_user_dcbnl_add_pcp_prio(dev, app);
 	default:
 		return -EOPNOTSUPP;
 	}
@@ -2405,7 +2455,7 @@ dsa_user_dcbnl_del_dscp_prio(struct net_device *dev, struct dcb_app *app)
 	if (!ds->dscp_prio_mapping_is_global)
 		return 0;
 
-	err = dsa_user_dcbnl_ieee_global_dscp_setdel(dev, app, true);
+	err = dsa_user_dcbnl_ieee_global_setdel(dev, app, true);
 	if (err) {
 		if (ds->ops->port_add_dscp_prio)
 			ds->ops->port_add_dscp_prio(ds, port, dscp,
@@ -2417,6 +2467,42 @@ dsa_user_dcbnl_del_dscp_prio(struct net_device *dev, struct dcb_app *app)
 	return 0;
 }
 
+static int __maybe_unused
+dsa_user_dcbnl_del_pcp_prio(struct net_device *dev, struct dcb_app *app)
+{
+	struct dsa_port *dp = dsa_user_to_port(dev);
+	struct dsa_switch *ds = dp->ds;
+	int err, port = dp->index;
+	u8 pcp = app->protocol;
+
+	if (!ds->ops->port_del_pcp_prio)
+		return -EOPNOTSUPP;
+
+	err = dcb_ieee_delapp(dev, app);
+	if (err)
+		return err;
+
+	err = ds->ops->port_del_pcp_prio(ds, port, pcp, app->priority);
+	if (err) {
+		dcb_ieee_setapp(dev, app);
+		return err;
+	}
+
+	if (!ds->pcp_prio_mapping_is_global)
+		return 0;
+
+	err = dsa_user_dcbnl_ieee_global_setdel(dev, app, true);
+	if (err) {
+		if (ds->ops->port_add_pcp_prio)
+			ds->ops->port_add_pcp_prio(ds, port, pcp,
+						   app->priority);
+		dcb_ieee_setapp(dev, app);
+		return err;
+	}
+
+	return 0;
+}
+
 static int __maybe_unused dsa_user_dcbnl_ieee_delapp(struct net_device *dev,
 						     struct dcb_app *app)
 {
@@ -2431,6 +2517,8 @@ static int __maybe_unused dsa_user_dcbnl_ieee_delapp(struct net_device *dev,
 		break;
 	case IEEE_8021QAZ_APP_SEL_DSCP:
 		return dsa_user_dcbnl_del_dscp_prio(dev, app);
+	case DCB_APP_SEL_PCP:
+		return dsa_user_dcbnl_del_pcp_prio(dev, app);
 	default:
 		return -EOPNOTSUPP;
 	}
@@ -2486,6 +2574,30 @@ static int dsa_user_dcbnl_init(struct net_device *dev)
 		}
 	}
 
+	if (ds->ops->port_get_pcp_prio) {
+		int protocol;
+
+		for (protocol = 0; protocol < 16; protocol++) {
+			struct dcb_app app = {
+				.selector = DCB_APP_SEL_PCP,
+				.protocol = protocol,
+			};
+			int prio;
+
+			prio = ds->ops->port_get_pcp_prio(ds, port, protocol);
+			if (prio == -EOPNOTSUPP)
+				continue;
+			if (prio < 0)
+				return prio;
+
+			app.priority = prio;
+
+			err = dcb_ieee_setapp(dev, &app);
+			if (err)
+				return err;
+		}
+	}
+
 	return 0;
 }
 

-- 
2.43.0

