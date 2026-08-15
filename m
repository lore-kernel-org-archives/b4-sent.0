From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 15 Aug 2026 10:43:02 -0500
Subject: [PATCH net] net/iucv: reconcile the socket state when connect()
 severs the path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-b4-disp-e1faf4b7-v1-1-2a8a143a0055@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6W8swtNaKz4K+KhyW50PcSSbUUo/
 XejHmdgZoNJVTGcuw1VXmr6LA3coUO6T+UmpNwYvvfH/uQCxYFYbSZxecpDHCkLM7swhpQ8WjZ
 Xyfr+LS8osuD6l7bGh6TlO8O+fwDkNDHQeQAAAA==
X-Change-ID: 20260815-b4-disp-e1faf4b7-feddd1575cc2
To: Eric Dumazet <edumazet@google.com>, Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>
Cc: Hidayath Khan <hidayath@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 linux-kernel@vger.kernel.org, Ursula Braun <ursula.braun@de.ibm.com>, 
 netdev@vger.kernel.org, linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786808581; l=2023;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=xg2T8X/93kYWUwtNOGjFli4SpGp2mm4ZLBCYx1XjSFA=;
 b=lSuE/MFy/O++A92aXw597sb0wJdNPWpSqh8l9FqDhTq89laeBcMKN1hnOeB55tTvLQH0qQ8HX
 pfvr1RVy8++Dl0IASIigHHL4T2zSBNbEvJEHvuVuQpl4zYPo5S+rT24
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A connack can land between iucv_sock_wait() returning an error and the
sever at the end of iucv_sock_connect(): iucv_callback_connack() writes
IUCV_CONNECTED from the iucv tasklet with no socket lock, and lock_sock()
does not exclude it. The sever clears iucv->path and leaves the state, so
connect() fails on a socket still claiming a connection it no longer has,
and a later sendmsg() reaches iucv->path->msglim through the NULL pointer
inside iucv_below_msglim(). The sever runs on every failed classic
connect, O_NONBLOCK included.

Reconcile only that case, so an ordinary failed connect still returns the
socket to its pre-connect state. The sever is a barrier against a later
connack: iucv_path_sever() clears the path from iucv_path_table[] under
the lock the tasklet holds across dispatch.

Fixes: 18becbc5479f ("af_iucv: avoid left over IUCV connections from failing connects")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/iucv/af_iucv.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index ea047bab65e7..6fb0041c4c98 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -778,8 +778,16 @@ static int iucv_sock_connect(struct socket *sock, struct sockaddr_unsized *addr,
 	if (sk->sk_state == IUCV_DISCONN || sk->sk_state == IUCV_CLOSED)
 		err = -ECONNREFUSED;
 
-	if (err && iucv->transport == AF_IUCV_TRANS_IUCV)
+	if (err && iucv->transport == AF_IUCV_TRANS_IUCV) {
 		iucv_sever_path(sk, 0);
+		/* A connack may have landed while the wait was unwinding; the
+		 * path is gone, so the socket must not still claim it.
+		 */
+		if (sk->sk_state == IUCV_CONNECTED) {
+			sk->sk_state = IUCV_DISCONN;
+			sk->sk_state_change(sk);
+		}
+	}
 
 done:
 	release_sock(sk);

---
base-commit: a59f57e2aa127c5354168d2ec4bac920df1be4f4
change-id: 20260815-b4-disp-e1faf4b7-feddd1575cc2

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

