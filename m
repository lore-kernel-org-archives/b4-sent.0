From: Joel Granados <j.granados@samsung.com>
Date: Fri, 26 Apr 2024 12:46:59 +0200
Subject: [PATCH v5 7/8] appletalk: Remove the now superfluous sentinel
 elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240426-jag-sysctl_remset_net-v5-7-e3b12f6111a6@samsung.com>
References: <20240426-jag-sysctl_remset_net-v5-0-e3b12f6111a6@samsung.com>
In-Reply-To: <20240426-jag-sysctl_remset_net-v5-0-e3b12f6111a6@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1016;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=7ZWigRPsHTDXgTA/blt/ZK1/GcOosAKMfp6DXoN0Jik=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYrhis/GfBl/QAzY0/b2l0ldoM4PPD7O0pRy
 HGmmijvFqiLOokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmK4YrAAoJELqXzVK3
 lkFPHocL/3iD0apTCZzmC0CbwdFHCbRP25d8gZFTHdGMM/KL9f6DjLospfYYiLAlpKhy6YHCPAJ
 lJZl7q3uCKPpfm+2MIdko8Gj93sXJMD5wa15zHrvVYjAevZ0t2bIG3XH3tyMfIjGy4W7HIofdr4
 Y7CsEsjFa70WEOybNatos0RR1gLi8eOdBuxoscF/rIQBzKOYNhVUiJJ3UsY3uA03K8/4+u009UZ
 sYRI3kCOMxtczqGQhxLx9PIN9YnjFFvUO++GfRar3QaDKuHYWhpSazmUuG4pyufCG+68QEFVZj4
 xvfS26uNpIYtePdiG/LwlSVQarX13rR7Bmv497FHksSosQKqV8aB/1Z33T4JvJ/TV6/uPGuepT1
 OnYqQe0W5vn7rfnOGjYsPnH8b1ytJzRkNKov5Ikad8FGQklpiFMqg3mOP9VuTQBAr45AVETwSgR
 /DiW+B8AKRMYQ5Dl7aDyp8Yz8q+PUPh1+48TDYUrupv05j1wxueAi79UIrbOMK3f2SlutfbVi95
 20=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which will
reduce the overall build time size of the kernel and run time memory
bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel from atalk_table ctl_table array.

Acked-by: Kees Cook <keescook@chromium.org> # loadpin & yama
Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 net/appletalk/sysctl_net_atalk.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/net/appletalk/sysctl_net_atalk.c b/net/appletalk/sysctl_net_atalk.c
index d945b7c0176d..7aebfe903242 100644
--- a/net/appletalk/sysctl_net_atalk.c
+++ b/net/appletalk/sysctl_net_atalk.c
@@ -40,7 +40,6 @@ static struct ctl_table atalk_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec_jiffies,
 	},
-	{ },
 };
 
 static struct ctl_table_header *atalk_table_header;

-- 
2.43.0

