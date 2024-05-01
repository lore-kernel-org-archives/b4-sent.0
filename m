From: Joel Granados <j.granados@samsung.com>
Date: Wed, 01 May 2024 11:29:27 +0200
Subject: [PATCH net-next v6 3/8] net: rds: Remove the now superfluous
 sentinel elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240501-jag-sysctl_remset_net-v6-3-370b702b6b4a@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1604;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=Yhw5Yxzxk2wGoyQtTfioNjf4XA/aQJR8HoqakSkFmW8=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYyC5vaKKwcVsjyo5fyyzaGv4yzNPxedXx6I
 0oz4J2bF3f16YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmMgubAAoJELqXzVK3
 lkFPAt8L/RvcZo67sV9/SAsIlFKCyMM+qMXV+vDZgycTjvVIA+SfdOd5Dt/cE8sPk2Vbd5m1zV0
 1bTYSIIzndwnYwNr0po+EDDom4Kh8mphlq63AcozIb3FtAE9gEijzxANbPT0uiZQiBdyGHfgd5L
 jUd9CESOohGjmih6u85i0nF0hV0zXXj4dyzliDaDl8C+vSQN5cHGJ3+wZn4J5SDRXGYrE7PGny8
 mpjgul+wUgIeWT+bmFhWlNgqlLFKEYCkRqXpa0KZRZmofIpFb05+j3enq7MzPkMkqjW7L7v/Oa0
 AHljkixYmiTw5qZOAz65zYrlPzu208TMOGpezXGMfAawyJc/HYbCL8AS/qZp8bwZCgrmeCcKeQ0
 VFBYUqpLr8VVDFTqEQA0YUb4s00REm2N6VViy20fU5WeR9chhD9M0JzPhaLi92OFmRKxY2g7HXs
 DWgQyhIZiES63sd2awdgqnweGvfHVA5sKmTulKSRHZjPttFiCIZTnmjBBO/sSry0ePsrsmzRot6
 aY=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

* Remove sentinel element from ctl_table structs.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 net/rds/ib_sysctl.c | 1 -
 net/rds/sysctl.c    | 1 -
 net/rds/tcp.c       | 1 -
 3 files changed, 3 deletions(-)

diff --git a/net/rds/ib_sysctl.c b/net/rds/ib_sysctl.c
index e4e41b3afce7..2af678e71e3c 100644
--- a/net/rds/ib_sysctl.c
+++ b/net/rds/ib_sysctl.c
@@ -103,7 +103,6 @@ static struct ctl_table rds_ib_sysctl_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec,
 	},
-	{ }
 };
 
 void rds_ib_sysctl_exit(void)
diff --git a/net/rds/sysctl.c b/net/rds/sysctl.c
index e381bbcd9cc1..025f518a4349 100644
--- a/net/rds/sysctl.c
+++ b/net/rds/sysctl.c
@@ -89,7 +89,6 @@ static struct ctl_table rds_sysctl_rds_table[] = {
 		.mode           = 0644,
 		.proc_handler   = proc_dointvec,
 	},
-	{ }
 };
 
 void rds_sysctl_exit(void)
diff --git a/net/rds/tcp.c b/net/rds/tcp.c
index 2dba7505b414..d8111ac83bb6 100644
--- a/net/rds/tcp.c
+++ b/net/rds/tcp.c
@@ -86,7 +86,6 @@ static struct ctl_table rds_tcp_sysctl_table[] = {
 		.proc_handler   = rds_tcp_skbuf_handler,
 		.extra1		= &rds_tcp_min_rcvbuf,
 	},
-	{ }
 };
 
 u32 rds_tcp_write_seq(struct rds_tcp_connection *tc)

-- 
2.43.0

