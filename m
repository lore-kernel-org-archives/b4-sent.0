From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net 0/2] net/iucv: fix the recvmsg window update
Date: Sat, 15 Aug 2026 11:04:44 -0500
Message-Id: <20260815-b4-disp-8a791503-v1-0-fbae9a511144@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMzQ6CMBAGX4V8Zzdpy0/BVyEcSll1PVTSRWNCe
 HerHmeSmR3KWVhxrnZkfonKIxWwpwrxFtKVSZbCcMZ1prctzQ0toiv1wQ+2NTUZ58MQmug661G
 yNfNF3r/liMQbpr/U53znuH1nOI4P5MXkrnkAAAA=
X-Change-ID: 20260815-b4-disp-8a791503-027a9a4c2617
To: Paolo Abeni <pabeni@redhat.com>, Jakub Kicinski <kuba@kernel.org>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>
Cc: netdev@vger.kernel.org, Ursula Braun <ursula.braun@de.ibm.com>, 
 linux-s390@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786809884; l=1404;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=lxCJFVEWw4OrMoY95QwH9gqQaRnelqKQW25ZWcmYKfI=;
 b=LAoLU1jM2OVywsGUP/5QozfGXtCPTOKKvzHf/BHkIx2+DCrG17ARrv10YsCnkiKw5wcrllMzr
 uGmnPdRK7pFAEibifId3sRBVCFjcN20wUTyFaZ6t4gLK0EiJAmTEljW
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two independent defects at the same call site, found while accounting for the
socket-locking rework and kept apart because they fail differently.

The first is a missing transport test: recvmsg sends AF_IUCV_FLAG_WIN, which
only exists on HiperSockets, without checking that the socket is on that
transport. Reaching it takes an application that sets SO_MSGLIMIT to 1 on its
own socket, so it is a correctness fix rather than a security one, and it is
first only because the second patch reads better on top of it.

The second is a sleeping allocation under spin_lock_bh: iucv_send_ctrl()
allocates with sk->sk_allocation, which is GFP_KERNEL for these sockets, inside
a section whose other allocation uses GFP_ATOMIC for exactly that reason.

By inspection; not reproduced. Compile-tested for s390x. Both are tagged
for stable: the second's context comes from the first, so tagging only
the second would hand the stable team a patch that does not apply.

---
Bryam Vargas (2):
      net/iucv: only send the window update on HiperSockets sockets
      net/iucv: send the window update outside message_q.lock

 net/iucv/af_iucv.c | 20 ++++++++++++--------
 1 file changed, 12 insertions(+), 8 deletions(-)
---
base-commit: a59f57e2aa127c5354168d2ec4bac920df1be4f4
change-id: 20260815-b4-disp-8a791503-027a9a4c2617

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

