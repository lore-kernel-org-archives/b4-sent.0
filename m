From: Joel Granados <j.granados@samsung.com>
Date: Thu, 14 Mar 2024 20:20:44 +0100
Subject: [PATCH 4/4] ax.25: Remove the now superfluous sentinel elements
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240314-jag-sysctl_remset_net-v1-4-aa26b44d29d9@samsung.com>
References: <20240314-jag-sysctl_remset_net-v1-0-aa26b44d29d9@samsung.com>
In-Reply-To: <20240314-jag-sysctl_remset_net-v1-0-aa26b44d29d9@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1667;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=ejJiyRhNOC9Xg5jx2v5IBc5vVgg4IABN6nfDRl2m3bQ=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBl804YOT/y4oh7cSp7OlPw2zS5Tl/S3d+XSL1dZ
 qcQXL+fOt2JAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZfNOGAAKCRC6l81St5ZB
 T7kQC/wK2/wTeTZeTM0MnPlpRdOOBc8cyUMgjDVKpxvMyRI8yAICvkYuT5X3I/JIAiSTlnoPRNs
 T8czt4a9El8kn3rzJrUnWqslVgijCjQNu75mhVIl5h2Hx0DeyF7xXzvxP9a7qpRBsrxGFsJOzlr
 xIV+BECnckb1ymuqG9Nx5TcTYFUef2eHx6R1NahoOJ2eaJkT8NbMr+4d+IxeEVNv1KCngJcTLhn
 j2ODJJt9OJ/W5k8gAyqvJZWLCnlIAPZIYzhOEGBu3D7BYhmVa/L2Ea74K76U054rZeBIbg4Xt5R
 IKEbNBeLmErLYVin2F8ZzAgSWEbtolh545+BB7/t6fTEkwctvzvj3d5+JqxdaTvb2lKfRReRxEJ
 h7dTo0Ikttkj4V+cjftwKAmFSNVE4NYWhCGfwn1M+onp2ZzZzdn79m3lY7nJW4z4KsIXo+z5ghP
 LzdpG1ie5IRBI09mzaVoxDs4mkjlmc8NlDUaMqjjP1vM1VYLgMKXI9Jn1NE4Y1Ws1QRok=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

When we remove the sentinel from ax25_param_table a buffer overflow
shows its ugly head. The sentinel's data element used to be changed when
CONFIG_AX25_DAMA_SLAVE was not defined. This did not have any adverse
effects as we still stopped on the sentinel because of its null
procname. But now that we do not have the sentinel element, we are
careful to check ax25_param_table's size.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 net/ax25/sysctl_net_ax25.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/net/ax25/sysctl_net_ax25.c b/net/ax25/sysctl_net_ax25.c
index db66e11e7fe8..2ee375a6a69c 100644
--- a/net/ax25/sysctl_net_ax25.c
+++ b/net/ax25/sysctl_net_ax25.c
@@ -141,8 +141,7 @@ static const struct ctl_table ax25_param_table[] = {
 		.extra2		= &max_ds_timeout
 	},
 #endif
-
-	{ }	/* that's all, folks! */
+/* that's all, folks! */
 };
 
 int ax25_register_dev_sysctl(ax25_dev *ax25_dev)
@@ -155,7 +154,7 @@ int ax25_register_dev_sysctl(ax25_dev *ax25_dev)
 	if (!table)
 		return -ENOMEM;
 
-	for (k = 0; k < AX25_MAX_VALUES; k++)
+	for (k = 0; k < AX25_MAX_VALUES && k < ARRAY_SIZE(ax25_param_table); k++)
 		table[k].data = &ax25_dev->values[k];
 
 	snprintf(path, sizeof(path), "net/ax25/%s", ax25_dev->dev->name);

-- 
2.43.0

