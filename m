From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 23 Nov 2026 00:31:20 +0000
Subject: [PATCH net] net/x25: inherit the listening socket's security label
 on accept
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-x25-v1-1-4432d3892f8b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFeJA2sC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNj3QojU11DC7NUM3PjRAtDoxQloMqCotS0zAqwKdFKeaklSrEQweL
 SpKzU5BKQfqXaWgD+ODVGbAAAAA==
X-Change-ID: 20261123-x25-186e673a812d
To: davem@davemloft.net, kuba@kernel.org, ms@dev.tdt.de, 
 edumazet@kernel.org, pabeni@redhat.com
Cc: netdev@vger.kernel.org, linux-x25@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-security-module@vger.kernel.org, 
 paul@paul-moore.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795393879; l=1370;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=XGoRm9Gpljgv4Y+6YNOH8RsisuTKbd1tc1zo4DvuC1o=;
 b=hnXxtrPN9egbQpZkz6j8eAD4973y57RXC/IPXVBw3HgfYsXcxTW/dYanVAypab2fkZJf5DoEk
 h8c4yugbM3IDu8UzdmiOMbP2e90i/qZPKMxaMYYZdoRsRIPbNtdc/qi
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

x25_make_new() creates the socket that accept() returns by copying
fields from the listening socket, but it never clones the listening
socket's LSM security state -- there is no security_sk_clone(osk, sk).
The accepted socket therefore keeps the security state that was newly
allocated for it in x25_alloc_socket(), instead of inheriting the
listening socket's security state.

Other accept paths (bluetooth, tipc, vsock, iucv) call
security_sk_clone() for this. Do the same for X.25.

Found with a static analysis tool and checked by hand.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on x86_64 (W=1, no new warnings). I don't have X.25
hardware; the fix is by inspection.
---
 net/x25/af_x25.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/net/x25/af_x25.c b/net/x25/af_x25.c
index f45c9ec7d2c6..802688d5ad56 100644
--- a/net/x25/af_x25.c
+++ b/net/x25/af_x25.c
@@ -598,6 +598,7 @@ static struct sock *x25_make_new(struct sock *osk)
 	sk->sk_state       = TCP_ESTABLISHED;
 	sk->sk_backlog_rcv = osk->sk_backlog_rcv;
 	sock_copy_flags(sk, osk);
+	security_sk_clone(osk, sk);
 
 	ox25 = x25_sk(osk);
 	x25->t21        = ox25->t21;



