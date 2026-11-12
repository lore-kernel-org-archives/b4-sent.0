From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 12 Nov 2026 10:04:48 +0000
Subject: [PATCH net 1/2] nfc: llcp: Clone LSM attributes to newly created
 child sockets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-nfc-v1-1-ab0ef166f382@gmail.com>
References: <20261112-nfc-v1-0-ab0ef166f382@gmail.com>
In-Reply-To: <20261112-nfc-v1-0-ab0ef166f382@gmail.com>
To: netdev@vger.kernel.org, david@ixit.cz
Cc: edumazet@kernel.org, kuba@kernel.org, horms@kernel.org, 
 oe-linux-nfc@lists.linux.dev, linux-kernel@vger.kernel.org, 
 pabeni@redhat.com, davem@davemloft.net
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794477891; l=2145;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=WtUcNIlZr5Of/JlHVB20yKuPFijC05MSrsd3vsPG3W8=;
 b=zMw8c+OS45UQNMuaqZc67YledF6y0cUGl05rZNtlvgXdt1L5mMoMp6tk96v8l8sV16YCN32KP
 70btJpatg0sDcOKNDDmKNvciQra+NiAFoZKiwGy6Wntc5uvinHafvfu
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

nfc_llcp_recv_connect() creates the child socket for an incoming
CONNECT and queues it for accept(), but never calls security_sk_clone():

    new_sk = nfc_llcp_sock_alloc(NULL, parent->sk_type, GFP_ATOMIC, 0);
    ...
    new_sock = nfc_llcp_sock(new_sk);

So the accepted socket doesn't inherit the LSM state of the listening
socket. With SELinux, its sock keeps the unlabeled SID. The
sock_has_perm() checks on it (sendmsg, recvmsg and so on) still run,
but against that SID instead of the server's. Depending on the policy,
this can deny a confined server on its own accepted sockets, or allow
something the server's own label wouldn't.

Call security_sk_clone() right after the child is allocated, before it
is set up and queued for accept(). Bluetooth, iucv and vsock fixed the
same problem the same way, in commit 6230c9b4f895 ("bluetooth: Properly
clone LSM attributes to newly created child connections"),
commit 02f06918156b ("iucv: properly clone LSM attributes to newly
created child sockets") and commit 1f935e8e72ec ("selinux: vsock: Set
SID for socket returned by accept()").

Found with a static analysis tool and checked by hand.

Fixes: d646960f7986 ("NFC: Initial LLCP support")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested only, I haven't tried it with an SELinux policy and a
real LLCP peer.
---
 net/nfc/llcp_core.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/net/nfc/llcp_core.c b/net/nfc/llcp_core.c
index 74bf817007cf..0f54548a47cc 100644
--- a/net/nfc/llcp_core.c
+++ b/net/nfc/llcp_core.c
@@ -10,6 +10,7 @@
 #include <linux/kernel.h>
 #include <linux/list.h>
 #include <linux/nfc.h>
+#include <linux/security.h>
 
 #include "nfc.h"
 #include "llcp.h"
@@ -1006,6 +1007,8 @@ static void nfc_llcp_recv_connect(struct nfc_llcp_local *local,
 		goto fail;
 	}
 
+	security_sk_clone(parent, new_sk);
+
 	new_sock = nfc_llcp_sock(new_sk);
 
 	new_sock->local = nfc_llcp_local_get(local);

-- 
2.34.1

