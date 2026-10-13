From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 13 Oct 2026 15:45:01 -0500
Subject: [PATCH net] net/smc: queue the copied chunk when smc_tx_sendmsg()
 faults
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-disp-872a3689-v1-1-2a4c63b04761@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBAAv0L27Ca0JWv1K8YDSxddD5V0wZAQ/
 k7V40wys4FJUTG4NhsU+ajpO1dwpwaGZ58fgpoqg289udYF5A6T2oTx7PtA8YJjR0QcUmRiqNl
 UZNT1t7xBlhnuf2kLv2SYvzPY9wNUdrzQeQAAAA==
X-Change-ID: 20261013-b4-disp-872a3689-f4666b3d8b6b
To: Jakub Kicinski <kuba@kernel.org>, Dust Li <dust.li@linux.alibaba.com>, 
 Paolo Abeni <pabeni@redhat.com>, Eric Dumazet <edumazet@kernel.org>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>
Cc: netdev@vger.kernel.org, Ursula Braun <ubraun@linux.ibm.com>, 
 linux-s390@vger.kernel.org, Wen Gu <guwen@linux.alibaba.com>, 
 Simon Horman <horms@kernel.org>, linux-rdma@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>, Tony Lu <tonylu@linux.alibaba.com>, 
 linux-kernel@vger.kernel.org, Wenjia Zhang <wenjia@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791924301; l=3122;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=13RwGW0dDAPWxeUlfGtVlTSciyAdMNnB565v31SH+hk=;
 b=O4fPAG1rRyI/jynY0h6qPbx02I4pwLVmVkVeJMBnRk7zfzney6SQTvpjqHkzUlyBWwIwxaCQH
 euojhKjcMi6A76DPIyyHc55dRGJ9vdHuuJ6dgs1UKQivysvPi1AmvI4
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a send wraps the end of the send buffer, smc_tx_sendmsg() copies
the data in two chunks. If memcpy_from_msg() faults on the second one,
smc_tx_sendmsg() returns send_done, which already counts the first
chunk, but leaves tx_curs_prep and sndbuf_space as they were. send()
reports bytes the peer never receives, and the next send() overwrites
them. Any caller can hit this on its own stream with a buffer whose
tail is unreadable.

On a fault in the second chunk, queue the first one. The next pass
retries the rest and returns send_done if it faults again, so send()
reports only what it queued, as TCP does.

Fixes: e6727f39004b ("smc: send data (through RDMA)")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Repro on v7.3-rc6 with KASAN (its smc_tx.c is the same as net's),
SMC-D loopback: send 33000 bytes, wait until the peer has read them
and SIOCOUTQ is 0, then send(S, MSG_DONTWAIT) from a buffer whose
first S - 500 bytes are readable and whose next page is PROT_NONE.
The 65504-byte sndbuf wraps after 32504 bytes, so at S = 65504 and
65536 the fault hits the second chunk:

  unpatched: send() returns 32504, SIOCOUTQ stays 0, and the peer
             gets only the 100-byte marker sent next.
  patched:   send() returns 32504 and the peer gets those bytes,
             intact, then the marker.

The 12 other sizes (16352 to 1048576) fault in the first chunk or not
at all, and give the same result on both kernels: -EFAULT, or 65504
sent and delivered. With the whole buffer readable, both deliver what
send() reports at every size. TCP at S = 65504 on the faulting buffer
returns 47616 and delivers exactly that. No KASAN splat. Logs on
request.

The rx side has the same shape: smc_rx_recvmsg() returns the first
chunk without moving the cursor when memcpy_to_msg() faults on the
second. Hidayath said in [1] that his v2 will fix it along with the
splice path, so this only touches smc_tx.c. It applies to net as is
and on top of [2], whose 3/4 also changes smc_tx_sendmsg(); the repro
gives the same results there.

[1] https://lore.kernel.org/all/7a174d1f-80d8-4294-ae66-829c9dacd662@linux.ibm.com/
[2] https://lore.kernel.org/all/20261013-b4-disp-f345196c-v7-0-ef3dddfbfa68@proton.me/
---
 net/smc/smc_tx.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/net/smc/smc_tx.c b/net/smc/smc_tx.c
index 3144b4b1fe29..495fb1354728 100644
--- a/net/smc/smc_tx.c
+++ b/net/smc/smc_tx.c
@@ -249,6 +249,13 @@ int smc_tx_sendmsg(struct smc_sock *smc, struct msghdr *msg, size_t len)
 			rc = memcpy_from_msg(sndbuf_base + chunk_off,
 					     msg, chunk_len);
 			if (rc) {
+				if (chunk) {
+					/* send_done counts the first chunk:
+					 * queue it and retry the rest
+					 */
+					copylen -= chunk_len;
+					break;
+				}
 				smc_sndbuf_sync_sg_for_device(conn);
 				if (send_done)
 					return send_done;

---
base-commit: 513444cc62e231a11c9b15ea88de0890da9b2b4f
change-id: 20261013-b4-disp-872a3689-f4666b3d8b6b

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

