From: Joel Granados <j.granados@samsung.com>
Date: Wed, 01 May 2024 11:29:32 +0200
Subject: [PATCH net-next v6 8/8] ax.25: x.25: Remove the now superfluous
 sentinel elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240501-jag-sysctl_remset_net-v6-8-370b702b6b4a@samsung.com>
References: <20240501-jag-sysctl_remset_net-v6-0-370b702b6b4a@samsung.com>
In-Reply-To: <20240501-jag-sysctl_remset_net-v6-0-370b702b6b4a@samsung.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Alexander Aring <alex.aring@gmail.com>, 
 Stefan Schmidt <stefan@datenfreihafen.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, David Ahern <dsahern@kernel.org>, 
 Steffen Klassert <steffen.klassert@secunet.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>, Ralf Baechle <ralf@linux-mips.org>, 
 Remi Denis-Courmont <courmisch@gmail.com>, 
 Allison Henderson <allison.henderson@oracle.com>, 
 David Howells <dhowells@redhat.com>, Marc Dionne <marc.dionne@auristor.com>, 
 Marcelo Ricardo Leitner <marcelo.leitner@gmail.com>, 
 Xin Long <lucien.xin@gmail.com>, Wenjia Zhang <wenjia@linux.ibm.com>, 
 Jan Karcher <jaka@linux.ibm.com>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, Wen Gu <guwen@linux.alibaba.com>, 
 Trond Myklebust <trond.myklebust@hammerspace.com>, 
 Anna Schumaker <anna@kernel.org>, Chuck Lever <chuck.lever@oracle.com>, 
 Jeff Layton <jlayton@kernel.org>, Neil Brown <neilb@suse.de>, 
 Olga Kornievskaia <kolga@netapp.com>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Tom Talpey <tom@talpey.com>, Jon Maloy <jmaloy@redhat.com>, 
 Ying Xue <ying.xue@windriver.com>, Martin Schiller <ms@dev.tdt.de>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, 
 Jozsef Kadlecsik <kadlec@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Roopa Prabhu <roopa@nvidia.com>, Nikolay Aleksandrov <razor@blackwall.org>, 
 Simon Horman <horms@verge.net.au>, Julian Anastasov <ja@ssi.bg>, 
 Joerg Reuter <jreuter@yaina.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Kees Cook <keescook@chromium.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 dccp@vger.kernel.org, linux-wpan@vger.kernel.org, mptcp@lists.linux.dev, 
 linux-hams@vger.kernel.org, linux-rdma@vger.kernel.org, 
 rds-devel@oss.oracle.com, linux-afs@lists.infradead.org, 
 linux-sctp@vger.kernel.org, linux-s390@vger.kernel.org, 
 linux-nfs@vger.kernel.org, tipc-discussion@lists.sourceforge.net, 
 linux-x25@vger.kernel.org, netfilter-devel@vger.kernel.org, 
 coreteam@netfilter.org, bridge@lists.linux.dev, lvs-devel@vger.kernel.org, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-2d940
X-Developer-Signature: v=1; a=openpgp-sha256; l=3832;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=AuUMNVULwdRpc7MqK6QxuNKeT/f1k5AlEkDFZpyU2BQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYyC55+jATyuag2cMz+nAfHl+HL6F0qL73yQ
 it9OOI3ZHMdqIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmMgueAAoJELqXzVK3
 lkFPeOEL/jPjta+dOJSZPZOjLVWcJG08CJUC7rYb1k0PNtxO7S/21gaMJjENoVcIEVGESaFX22i
 7CGruN2yxgicXlNg5nTRv1ZrlzybcKiPH06JFYreKEgLe6CJ4UsTGS/jXsMpupMDpSw3FsLRf2b
 p0RiEVHZlB5v+TY5XZVLfYuni9WBamS0CWyHo/YP4Cpt7BFk7Z400iRHZtp8Mm3BbernP88WLsI
 tu+949SFzqw3fVIsjFSrmWoCP3O1O3XbWbwn1jbbvjMMcwEoQ5HtlVMe4wofVUgR58+Qo4dxmMg
 cnk4INgUh0IkD/gez2ewL7bnlZDDKjRA1wtR25xIqsxCmxeamUeFFjWs1856xfEwNa8w48gn3q6
 jKggb0B5t38jUi1rgISS3kB5+IDwZsSmZLV7SdEBgZTQoA0WntUu/A6QzpK/dm4yw4JHktCZeyb
 G7zXpWgiGYiuhdcJC4yBMyJcFqQUYM71xk7umchoPq1It2qt5P/Iwgk1NCdtrg06W7Bz3uHXL76
 mk=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Avoid a buffer overflow when traversing the ctl_table by ensuring that
AX25_MAX_VALUES is the same as the size of ax25_param_table. This is
done with a BUILD_BUG_ON where ax25_param_table is defined and a
CONFIG_AX25_DAMA_SLAVE guard in the unnamed enum definition as well as
in the ax25_dev_device_up and ax25_ds_set_timer functions.

The overflow happened when the sentinel was removed from
ax25_param_table. The sentinel's data element was changed when
CONFIG_AX25_DAMA_SLAVE was undefined. This had no adverse effects as it
still stopped on the sentinel's null procname but needed to be addressed
once the sentinel was removed.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 include/net/ax25.h         | 2 ++
 net/ax25/ax25_dev.c        | 3 +++
 net/ax25/ax25_ds_timer.c   | 1 +
 net/ax25/sysctl_net_ax25.c | 3 +--
 net/x25/sysctl_net_x25.c   | 1 -
 5 files changed, 7 insertions(+), 3 deletions(-)

diff --git a/include/net/ax25.h b/include/net/ax25.h
index 0d939e5aee4e..eb9cee8252c8 100644
--- a/include/net/ax25.h
+++ b/include/net/ax25.h
@@ -139,7 +139,9 @@ enum {
 	AX25_VALUES_N2,		/* Default N2 value */
 	AX25_VALUES_PACLEN,	/* AX.25 MTU */
 	AX25_VALUES_PROTOCOL,	/* Std AX.25, DAMA Slave, DAMA Master */
+#ifdef CONFIG_AX25_DAMA_SLAVE
 	AX25_VALUES_DS_TIMEOUT,	/* DAMA Slave timeout */
+#endif
 	AX25_MAX_VALUES		/* THIS MUST REMAIN THE LAST ENTRY OF THIS LIST */
 };
 
diff --git a/net/ax25/ax25_dev.c b/net/ax25/ax25_dev.c
index 282ec581c072..0bc682ffae9c 100644
--- a/net/ax25/ax25_dev.c
+++ b/net/ax25/ax25_dev.c
@@ -78,7 +78,10 @@ void ax25_dev_device_up(struct net_device *dev)
 	ax25_dev->values[AX25_VALUES_N2]        = AX25_DEF_N2;
 	ax25_dev->values[AX25_VALUES_PACLEN]	= AX25_DEF_PACLEN;
 	ax25_dev->values[AX25_VALUES_PROTOCOL]  = AX25_DEF_PROTOCOL;
+
+#ifdef CONFIG_AX25_DAMA_SLAVE
 	ax25_dev->values[AX25_VALUES_DS_TIMEOUT]= AX25_DEF_DS_TIMEOUT;
+#endif
 
 #if defined(CONFIG_AX25_DAMA_SLAVE) || defined(CONFIG_AX25_DAMA_MASTER)
 	ax25_ds_setup_timer(ax25_dev);
diff --git a/net/ax25/ax25_ds_timer.c b/net/ax25/ax25_ds_timer.c
index c4f8adbf8144..c50a58d9e368 100644
--- a/net/ax25/ax25_ds_timer.c
+++ b/net/ax25/ax25_ds_timer.c
@@ -55,6 +55,7 @@ void ax25_ds_set_timer(ax25_dev *ax25_dev)
 	ax25_dev->dama.slave_timeout =
 		msecs_to_jiffies(ax25_dev->values[AX25_VALUES_DS_TIMEOUT]) / 10;
 	mod_timer(&ax25_dev->dama.slave_timer, jiffies + HZ);
+	return;
 }
 
 /*
diff --git a/net/ax25/sysctl_net_ax25.c b/net/ax25/sysctl_net_ax25.c
index e0128dc9def3..68753aa30334 100644
--- a/net/ax25/sysctl_net_ax25.c
+++ b/net/ax25/sysctl_net_ax25.c
@@ -141,8 +141,6 @@ static const struct ctl_table ax25_param_table[] = {
 		.extra2		= &max_ds_timeout
 	},
 #endif
-
-	{ }	/* that's all, folks! */
 };
 
 int ax25_register_dev_sysctl(ax25_dev *ax25_dev)
@@ -155,6 +153,7 @@ int ax25_register_dev_sysctl(ax25_dev *ax25_dev)
 	if (!table)
 		return -ENOMEM;
 
+	BUILD_BUG_ON(ARRAY_SIZE(ax25_param_table) != AX25_MAX_VALUES);
 	for (k = 0; k < AX25_MAX_VALUES; k++)
 		table[k].data = &ax25_dev->values[k];
 
diff --git a/net/x25/sysctl_net_x25.c b/net/x25/sysctl_net_x25.c
index e9802afa43d0..643f50874dfe 100644
--- a/net/x25/sysctl_net_x25.c
+++ b/net/x25/sysctl_net_x25.c
@@ -71,7 +71,6 @@ static struct ctl_table x25_table[] = {
 		.mode = 	0644,
 		.proc_handler = proc_dointvec,
 	},
-	{ },
 };
 
 int __init x25_register_sysctl(void)

-- 
2.43.0

