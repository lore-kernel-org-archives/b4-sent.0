From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net v2 0/3] net/iucv: fix the recvmsg window update
Date: Fri, 21 Aug 2026 06:17:30 -0500
Message-Id: <20260821-b4-disp-3a6e8695-v2-0-37597ff723a8@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBAAvyJ77kIS7WL8SukhxrXdHqJktQji3
 03tcQZmdlDOwgpdtUPmr6hMqYC7VRDfIb0YZSgMzjgyrbPYNziIzlgH4pb8HaMdm0CGvCUPJZs
 zj7JdywckXuD5l7r2H47LbwbHcQLabbVqeQAAAA==
X-Change-ID: 20260821-b4-disp-3a6e8695-c1f4a6069169
To: Eric Dumazet <edumazet@google.com>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>, Alexandra Winter <wintera@linux.ibm.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>
Cc: Hidayath Khan <hidayath@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-s390@vger.kernel.org, Ursula Braun <ursula.braun@de.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787311050; l=2736;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=Nu2JeDV/y1/Xw7IaWFoFTL48x7/HeuqtMJGkdk7Z1rg=;
 b=6ZEmyByWVIMrRZ5NfFmULHfnVb0bK9PeBX9ZZzBzfGFXAS8H+w85W2ofKlz64n4bBIEOFZTfq
 SdvxNj3fMIlBg0G9cxq0EDS8/JvSh2dmoAac/KXWr+UHqs5kqrr4GGA
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v2 answers Jakub's reviews of v1 with changes rather than replies.

1/3 keeps its hunk and states the impact properly. SO_MSGLIMIT accepts 1,
which makes msglimit / 2 zero, and msg_recv never leaves zero on a classic
socket, so the NULL read is one recvmsg() away for an unprivileged process
on a socket of its own. With relocate_lowcore it faults.

Its Fixes: tag was wrong as well. The unconditional send does date to
3881ac441f64, but iucv_send_ctrl() sized the skb with a constant ETH_HLEN
until 238965b71b96, so before that it just returned -ENODEV. Backport
window is v5.3, not v3.1.

2/3 is new. v1 admitted it widened the msg_recv race and left it open,
which isn't good enough under Cc: stable. afiucv_hs_send() samples the
counter and settles it after dev_queue_xmit(); sendmsg reaches that under
lock_sock() and recvmsg reaches it under no socket lock, so the two don't
exclude each other and both can subtract the same value. Negative counter,
WARN_ON, and the same credit advertised twice to a peer whose
afiucv_hs_callback_win() subtracts the wire value from msg_sent unchecked.

Taking the socket lock around the deferred send would close it too, since
recvmsg is the only unlocked side. I didn't: recvmsg has never held that
lock, and making it do so changes the receive path for every caller. That
belongs in the locking rework, not in a stable fix.

The claim sits after the last error exit rather than in the header build,
so the counter reads zero only while the transmit is in flight, and a
concurrent sender isn't talked out of its own update.

3/3 is v1's patch, and it must not be applied without 2/3: hoisting the
send out of message_q.lock drops the serialisation that lock gave two
concurrent recvmsg(). Backported alone it recreates what 2/3 fixes. Both
changelogs say so.

Litmus test under LKMM: the counter reaches -2 before 2/3 and cannot after.
No hardware run; I have no IBM Z, and CONFIG_AFIUCV is s390-only.

The unlocked hs_dev and sk_shutdown window, the unbounded backlog_skb_q and
the WARN_ON a flooding peer can reach are pre-existing and wider than this
series. They belong with the locking rework Alexandra has open.

Thanks for the reviews.

---
Bryam Vargas (3):
      net/iucv: only send the window update on HiperSockets sockets
      net/iucv: claim the receive credit atomically
      net/iucv: send the window update outside message_q.lock

 net/iucv/af_iucv.c | 42 +++++++++++++++++++++++++-----------------
 1 file changed, 25 insertions(+), 17 deletions(-)
---
base-commit: 746fc0787f616da418ffc04a110296fe95d53491
change-id: 20260821-b4-disp-3a6e8695-c1f4a6069169

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

