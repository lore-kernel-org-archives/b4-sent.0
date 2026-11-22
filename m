From: Suyuan Wang <shyckless@gmail.com>
Date: Sun, 22 Nov 2026 08:17:26 +0000
Subject: [PATCH net] net: reuseport: honour SO_LOCK_FILTER in
 SO_DETACH_REUSEPORT_BPF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-reuseport-lock-filter-v1-1-a3e5324c8d55@gmail.com>
X-B4-Tracking: v=1; b=H4sIABWlAmsC/yWMQQrCMBBFr1Jm7UAzC0WvIi7a+KOjJSkzqQild
 zcq/M378N5KDlM4nbqVDC91LblB2HUU70O+gfXamKSXfQgibFgcc7HKU4lPTjpVGPfD8dAGSWO
 k5s6GpO9f90wZlS7/05fxgVi/Rdq2D9MIuAV+AAAA
X-Change-ID: 20261122-reuseport-lock-filter-0a97a97e2fbc
To: pabeni@redhat.com, edumazet@kernel.org, davem@davemloft.net, 
 kuba@kernel.org, kuniyu@google.com, willemb@google.com
Cc: netdev@vger.kernel.org, bpf@vger.kernel.org, martin.lau@linux.dev, 
 linux-kernel@vger.kernel.org, horms@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795335446; l=1823;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=mUix/dSzrnbiMpxouGrm26+4a6yRQiNkofJT/Rp0r4M=;
 b=C1HoG1h2Yi2qB7Kdc+loDObrbf9S1VJqaIK5MIwN6f++LFKuMYPoKCW2ZkeSJiVs9NmNBGxi0
 mtivHQUnok/AMsBnjA4qQrkHfDt9B432CJehtFfaLM26ZDiEE7c7I55
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

SO_LOCK_FILTER lets a process lock the filters on a socket before
handing it to a less privileged one. Once it is set, the existing attach
and detach paths reject changes to the socket's BPF filters with -EPERM,
but SO_DETACH_REUSEPORT_BPF does not check SOCK_FILTER_LOCKED. So an
unprivileged process that receives a locked socket can still remove the
reuseport program, which then changes how packets and connections are
spread over the whole reuseport group.

Return -EPERM from reuseport_detach_prog() when the filter is locked,
like sk_detach_filter() does.

Found with a static analysis tool and checked by hand.

Fixes: 99f3a064bc2e ("bpf: net: Add SO_DETACH_REUSEPORT_BPF")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested in QEMU (x86_64): root binds a UDP socket with SO_REUSEPORT,
attaches a reuseport cBPF program and sets SO_LOCK_FILTER, then a child
running as nobody uses the inherited socket.

Before:
  SO_ATTACH_REUSEPORT_CBPF: EPERM
  SO_DETACH_FILTER:         EPERM
  SO_DETACH_REUSEPORT_BPF:  succeeds, the program is gone

After:

SO_DETACH_REUSEPORT_BPF: EPERM as well
---
 net/core/sock_reuseport.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/net/core/sock_reuseport.c b/net/core/sock_reuseport.c
index b9e5648fa4c5..cdff61161a70 100644
--- a/net/core/sock_reuseport.c
+++ b/net/core/sock_reuseport.c
@@ -727,6 +727,9 @@ int reuseport_detach_prog(struct sock *sk)
 	struct sock_reuseport *reuse;
 	struct bpf_prog *old_prog;
 
+	if (sock_flag(sk, SOCK_FILTER_LOCKED))
+		return -EPERM;
+
 	old_prog = NULL;
 	spin_lock_bh(&reuseport_lock);
 	reuse = rcu_dereference_protected(sk->sk_reuseport_cb,



