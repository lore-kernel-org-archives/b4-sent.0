From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 06:32:42 +0000
Subject: [PATCH 6.6.y] nfsd: fix possible badness in FREE_STATEID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so5-nfsd-66-v1-1-2ae77e2e4983@certik.com>
X-B4-Tracking: v=1; b=H4sIAAkkCWsC/02NSw7CMAxEr1J5jUsTUUO5CmKRj0ODUILigkBV7
 04DG5bzNPNmBuESWeDYzFD4GSXmtAa1acCNJl0Yo18z6E6TUnqPkntMQTwSYa/tcHC7QEPnYV3
 cC4f4+tpOQC21bzj/sDzsld1UTbVojTDaYpIbKxJOfsr5hpVv/x5gWT692TfdogAAAA==
X-Change-ID: 20261127-so5-nfsd-66-52b98c4f690d
To: stable@vger.kernel.org
Cc: Olga Kornievskaia <okorniev@redhat.com>, linux-nfs@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795761161; l=2166;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=jwP/hO3okQ18uwZiBI2Bo8/D+D1SaDtOva3Z/IN1YhA=;
 b=9bTRfHpYoDSJjOyWaPD0dwexwSfC4PlGG26jRbGgfENMnoridzZCe0h7+2kksymHRDJvcx09h
 TaSlYwhEBbsCrcVlHQWAJeLG74lolKxLzaSh4g2O9U6elnyR4jPFcDw
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Olga Kornievskaia <okorniev@redhat.com>

commit c88c150a467fcb670a1608e2272beeee3e86df6e upstream.

When multiple FREE_STATEIDs are sent for the same delegation stateid,
it can lead to a possible either use-after-free or counter refcount
underflow errors.

In nfsd4_free_stateid() under the client lock we find a delegation
stateid, however the code drops the lock before calling nfs4_put_stid(),
that allows another FREE_STATE to find the stateid again. The first one
will proceed to then free the stateid which leads to either
use-after-free or decrementing already zeroed counter.

Fixes: 3f29cc82a84c ("nfsd: split sc_status out of sc_type")
Signed-off-by: Olga Kornievskaia <okorniev@redhat.com>
Reviewed-by: Benjamin Coddington <bcodding@redhat.com>
Reviewed-by: Jeff Layton <jlayton@kernel.org>
Signed-off-by: Chuck Lever <chuck.lever@oracle.com>
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.12.y and newer already have this fix.

Tested on v6.6.163:
- x86_64 allmodconfig W=1 build of fs/nfsd/nfs4state.o, base vs
  patched, no new warnings
- under QEMU/KVM, base and patched: mounted a loopback NFSv4.1 export
  and ran open, lock, write, read, close and unlink. FREE_STATEID on a
  revoked delegation wasn't exercised.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

fs/nfsd/nfs4state.c | 1 +
 1 file changed, 1 insertion(+)
---
 fs/nfsd/nfs4state.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/fs/nfsd/nfs4state.c b/fs/nfsd/nfs4state.c
index 1087ce23d499..73145f485995 100644
--- a/fs/nfsd/nfs4state.c
+++ b/fs/nfsd/nfs4state.c
@@ -7037,6 +7037,7 @@ nfsd4_free_stateid(struct svc_rqst *rqstp, struct nfsd4_compound_state *cstate,
 	switch (s->sc_type) {
 	case SC_TYPE_DELEG:
 		if (s->sc_status & SC_STATUS_REVOKED) {
+			s->sc_status |= SC_STATUS_CLOSED;
 			spin_unlock(&s->sc_lock);
 			dp = delegstateid(s);
 			list_del_init(&dp->dl_recall_lru);

---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261127-so5-nfsd-66-52b98c4f690d

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

