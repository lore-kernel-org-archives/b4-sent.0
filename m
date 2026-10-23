From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 22 Oct 2026 22:00:39 -0500
Subject: [PATCH RFC net-next v2 2/2] net/iucv: return EOF to a reader
 parked at the HiperSockets peer's FIN
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-b4-disp-1d26b87a-v2-2-7ee1264d812a@proton.me>
References: <20261022-b4-disp-1d26b87a-v2-0-7ee1264d812a@proton.me>
In-Reply-To: <20261022-b4-disp-1d26b87a-v2-0-7ee1264d812a@proton.me>
To: Paolo Abeni <pabeni@redhat.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Eric Dumazet <edumazet@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, Jakub Kicinski <kuba@kernel.org>
Cc: Nagamani PV <nagamani@linux.ibm.com>, netdev@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-kernel@vger.kernel.org, 
 linux-s390@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792724438; l=1759;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=Ytt4rdgE3BbqtAZEFC0wW/x24kWLpDfDP1W/jHpd3jI=;
 b=wsmhQiDrtMkx6fzxvVixsY08gIHWJdFxewlSlNNNKLBPs0Ql5HZRBInijiCOiqnmAtLEpcofs
 5C9pHQxg6X0D3Xq7v9qenCgPlc0RBKODhV/HcjsPfwBCpTPYmvszwAb
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After the peer's FIN only sk_state says the receive side is done.
Before the previous patch a reader parked at the FIN returned -ENOTCONN
(Hidayath Khan: 14151 of 14151 cycles between two z/VM guests); it now
returns 0 by the IUCV_DISCONN test, while poll() still reports no
EPOLLRDHUP for the peer's close.

Set RCV_SHUTDOWN where the FIN is applied, as TCP does: poll() reports
EPOLLRDHUP, and recvmsg() ends the stream by the test it already uses
for the peer's SHT.

Reported-by: Hidayath Khan <hidayath@linux.ibm.com>
Closes: https://lore.kernel.org/netdev/82691101-92d7-4838-b16e-2e41a83f65d0@linux.ibm.com/
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
On its own this covers the HiperSockets FIN; the z/VM sever reaches the
sleeping reader through 1/2's wait loop. After 1/2 the write is under
sk_lock.slock in every path (the owner's release_cb, or the softirq
with no owner), where shutdown() writes the same field.

Measured in the emulated setup: poll() on the parked reader reports
EPOLLRDHUP at the FIN with this patch, not without it (1/2 alone gives
the reader EOF but no RDHUP; net-next and v1 give -ENOTCONN).
---
 net/iucv/af_iucv.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/net/iucv/af_iucv.c b/net/iucv/af_iucv.c
index 15ce99e90c5b..f1a7bfa5a4b5 100644
--- a/net/iucv/af_iucv.c
+++ b/net/iucv/af_iucv.c
@@ -2074,6 +2074,10 @@ static void afiucv_hs_synfin(struct sock *sk)
 static void afiucv_hs_fin(struct sock *sk)
 {
 	sk->sk_state = IUCV_DISCONN;
+	/* as TCP's FIN: a reader asleep here wakes to EOF, not -ENOTCONN,
+	 * and poll() reports EPOLLRDHUP
+	 */
+	WRITE_ONCE(sk->sk_shutdown, sk->sk_shutdown | RCV_SHUTDOWN);
 	sk->sk_state_change(sk);
 }
 

-- 
2.56.0

