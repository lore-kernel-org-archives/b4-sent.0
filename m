From: Yongjian Wang <echoowall@gmail.com>
Date: Tue, 03 Nov 2026 15:09:41 +0800
Subject: [PATCH net-next 1/4] tcp: sync MSS after enabling MTU probing on
 passive connections
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-mtu-probing-series-v1-1-a2809e725aaa@gmail.com>
References: <20261103-mtu-probing-series-v1-0-a2809e725aaa@gmail.com>
In-Reply-To: <20261103-mtu-probing-series-v1-0-a2809e725aaa@gmail.com>
To: ncardwell@google.com, horms@kernel.org, edumazet@kernel.org, 
 kuba@kernel.org, kuniyu@google.com, shuah@kernel.org, davem@davemloft.net, 
 pabeni@redhat.com
Cc: netdev@vger.kernel.org, panweiping3@gmail.com, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yongjian Wang <echoowall@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793689782; l=1710;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=tSHTvLLOgSct9GANl8Ovs5A8DeUQK9fuisCWedGxu7I=;
 b=7Tuc9x9qlwRRMrOUN0q9KpwoW68HcV6dbFfC2aK1nOFsRzIcMveRC6d6Yba8chy9dxCbiOYrf
 CLZ90SfAumHDbF19G781Pw4knGykv4OSB7nuki5fSKx96gysjQBgGev
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tcp_v4_syn_recv_sock() and tcp_v6_syn_recv_sock() call tcp_sync_mss()
before MTU probing is enabled, and tcp_init_transfer() enables it later
without syncing the MSS again.

With net.ipv4.tcp_mtu_probing=2, a passive connection therefore starts
at the full MSS instead of tcp_base_mss as documented, while an active
connection starts at tcp_base_mss. This has two visible effects, shown
here with tcp_base_mss=1024:

 - The MSS drops when the first probe is acknowledged, from 1460 to 1242,
   although that probe has just shown the path can carry more.

 - On a black hole path the MSS never tries tcp_base_mss. It goes from
   1460 straight to 512, since MTU probing is already enabled when black
   hole detection triggers.

Sync the MSS right after tcp_mtup_init(). tcp_sync_mss() only applies
search_low when MTU probing is enabled, so the other tcp_mtu_probing
values keep their behaviour.

The Fixes commit kept tcp_mtup_init() in a single place on purpose, so
sync the MSS next to it instead of moving it back into the
syn_recv_sock() handlers.

Fixes: 4d83e1773031 ("tcp: delete redundant calls of tcp_mtup_init()")
Signed-off-by: Yongjian Wang <echoowall@gmail.com>
---
 net/ipv4/tcp_input.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/net/ipv4/tcp_input.c b/net/ipv4/tcp_input.c
index e1f2d9765..c13f005b2 100644
--- a/net/ipv4/tcp_input.c
+++ b/net/ipv4/tcp_input.c
@@ -6760,6 +6760,7 @@ void tcp_init_transfer(struct sock *sk, int bpf_op, struct sk_buff *skb)
 	struct tcp_sock *tp = tcp_sk(sk);
 
 	tcp_mtup_init(sk);
+	tcp_sync_mss(sk, icsk->icsk_pmtu_cookie);
 	icsk->icsk_af_ops->rebuild_header(sk);
 	tcp_init_metrics(sk);
 

-- 
Git-157)

