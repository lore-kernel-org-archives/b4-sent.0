From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 10 Nov 2026 23:44:27 -0500
Subject: [PATCH RFC net v3 2/7] net/iucv: fail sendmsg() with EPIPE once
 sending is shut down
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-b4-disp-2a6b4364-v3-2-35677b68e697@proton.me>
References: <20261110-b4-disp-2a6b4364-v3-0-35677b68e697@proton.me>
In-Reply-To: <20261110-b4-disp-2a6b4364-v3-0-35677b68e697@proton.me>
To: "David S. Miller" <davem@davemloft.net>, 
 Paolo Abeni <pabeni@redhat.com>, Jakub Kicinski <kuba@kernel.org>, 
 Eric Dumazet <edumazet@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Hidayath Khan <hidayath@linux.ibm.com>
Cc: linux-kernel@vger.kernel.org, Thorsten Winkler <twinkler@linux.ibm.com>, 
 Nagamani PV <nagamani@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 netdev@vger.kernel.org, linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794372266; l=3220;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=7649mWdFyPHHdznp9ibYDQHg6sWSCfctd7MGqW+sc1A=;
 b=i7P/l0LC962NTn0Fm3gYmrcALMUuHVrQ1hbwWls5Cz9PfsuKudOUOg0naDAJydSSgNCs4+9Xf
 tyUMcD6oLtYC6DNDxv+166xH2+WbC2mFjaeFEd/enIv2kAOscxzhikq
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sendmsg() tests SEND_SHUTDOWN on entry only, then waits for the peer's
window without the socket lock. When sending is shut down during that
wait, by shutdown(SHUT_WR) in another thread or by the peer's quiesce
over z/VM, the wait does not end and the call does not fail: the writer
waits out SO_SNDTIMEO, or, when the window opens first, sends its
record after the socket's SHT and the peer reads data after EOF. With
the peer's FIN in as well it returns -ECONNRESET for a stream its own
socket shut down.

End the wait when sending is shut down and test SEND_SHUTDOWN again
after it, ahead of the sk_state test, so the call fails with -EPIPE as
it does on entry.

Fixes: 0ea920d211e0 ("af_iucv: Return -EAGAIN if iucv msg limit is exceeded")
Cc: stable@vger.kernel.org # 6.18.x
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
New in v3 as a patch of its own: the new condition of sendmsg()'s
window wait and the test after it, placed ahead of the state test, were
in the lock patch. It goes before 3/7, which lets sendmsg() wait for
send memory without the socket lock and would otherwise open the same
gap a second time.

Three of the 53 default tests are about this, and net fails all three.
A writer parked on a full window sends its record after the socket's
own SHT when the window opens, so the peer reads data after EOF; it
waits out SO_SNDTIMEO when the window stays shut; and with the peer's
FIN in as well it gets -ECONNRESET. With this patch the first and the
third pass and the second returns -EPIPE; that test still fails, as its
SHT finds no room in sk_sndbuf (one of the five in the cover letter).
With only the wait changed the writer sends after the shutdown in the
first two and gets -ECONNRESET in the third; with only the test after
it, it waits out SO_SNDTIMEO again; with the test placed after the
state test it gets -ECONNRESET again.

Not changed: iucv_send_ctrl() still clears SEND_SHUTDOWN while it
allocates a control frame, so a caller without the socket lock can make
the new test miss a shutdown. On a connected socket there are two:
recvmsg()'s window update, until 3/7 puts recvmsg() under the lock, and
the NETDEV_GOING_DOWN notifier, which sets IUCV_DISCONN right after, so
the call then fails with -ECONNRESET.
---
 net/iucv/af_iucv.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 657c61161dbd..133c1d1886b2 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -1055,10 +1055,16 @@ static int iucv_sock_sendmsg(struct socket *sock, struct msghdr *msg,
 
 	/* wait if outstanding messages for iucv path has reached */
 	timeo = sock_sndtimeo(sk, noblock);
-	err = iucv_sock_wait(sk, iucv_below_msglim(sk), timeo);
+	err = iucv_sock_wait(sk, iucv_below_msglim(sk) ||
+			     (sk->sk_shutdown & SEND_SHUTDOWN), timeo);
 	if (err)
 		goto fail;
 
+	/* return -EPIPE if sending has been shut down meanwhile */
+	if (sk->sk_shutdown & SEND_SHUTDOWN) {
+		err = -EPIPE;
+		goto fail;
+	}
 	/* return -ECONNRESET if the socket is no longer connected */
 	if (sk->sk_state != IUCV_CONNECTED) {
 		err = -ECONNRESET;

-- 
2.56.0

