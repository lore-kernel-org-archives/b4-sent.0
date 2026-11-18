From: Suyuan Wang <shyckless@gmail.com>
Date: Wed, 18 Nov 2026 14:53:31 +0000
Subject: [PATCH] xen/pvcalls: return -EINTR from recvmsg when the wait is
 interrupted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-xen-pvcalls-v1-1-5e9d662900a0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOq7/WoC/yXMQQqDMBBG4avIrBvIBBHxKtKFib86ElLJtCKId
 29ql9/ivZMUWaDUVSdl7KLySgX8qCgsQ5phZCwmZ13DzK05kMy2hyFGNfCTr4Mdwd5RKbaMSY7
 71j//1o9fEd6/BV3XF046lM9vAAAA
X-Change-ID: 20261118-xen-pvcalls-ebfb4c0de1b2
To: sstabellini@kernel.org, jgross@suse.com
Cc: oleksandr_tyshchenko@epam.com, xen-devel@lists.xenproject.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795013611; l=2573;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=JS0N2by4izL7XI6U/P5YKixzFBa9rEd0luLKdyK1x98=;
 b=8hmEpcRcMvT3FgZ8jhjQzuy6IWqP2SSP25b2VY+7+Za5wAoI5L6TaM8tQaT4ccyBoc61ubOsj
 qWwMBB2oqy8CsaiwHbH+gXaG7fcVtJyGssZTqMFDNLJySiPErW/J6DP
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

pvcalls_front_recvmsg() waits for data in a loop and ignores what
wait_event_interruptible() returns:

    while (!(flags & MSG_DONTWAIT) && !pvcalls_front_read_todo(map)) {
            wait_event_interruptible(map->active.inflight_conn_req,
                                     pvcalls_front_read_todo(map));
    }

Once a signal is pending, wait_event_interruptible() returns
-ERESTARTSYS right away without sleeping, and the loop calls it again.
The caller then spins with map->active.in_mutex held until data arrives
or the backend reports an error. The signal can't be handled while it
spins, so the task can't be killed either, and other readers of the
socket block on in_mutex.

Return -EINTR when the wait is interrupted, as pvcalls_front_accept()
already does for its interruptible waits. Jump to the end of the
function so that in_mutex is released and pvcalls_exit_sock() is
called.

Found with a static analysis tool and checked by hand.

Fixes: ae0d04052e07 ("xen/pvcalls: implement recvmsg")
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
There are no in-tree callers of pvcalls_front_recvmsg(), so this only
matters to code built on the exported frontend API. That's why I left
out Cc: stable.

Compile tested only (x86_64 with CONFIG_XEN_PVCALLS_FRONTEND=y, W=1 and
sparse show no new warnings). I haven't run it in a Xen guest.
---
 drivers/xen/pvcalls-front.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/xen/pvcalls-front.c b/drivers/xen/pvcalls-front.c
index 3e7aa807c317..5d6c8ba66849 100644
--- a/drivers/xen/pvcalls-front.c
+++ b/drivers/xen/pvcalls-front.c
@@ -693,8 +693,11 @@ int pvcalls_front_recvmsg(struct socket *sock, struct msghdr *msg, size_t len,
 		len = XEN_FLEX_RING_SIZE(PVCALLS_RING_ORDER);
 
 	while (!(flags & MSG_DONTWAIT) && !pvcalls_front_read_todo(map)) {
-		wait_event_interruptible(map->active.inflight_conn_req,
-					 pvcalls_front_read_todo(map));
+		if (wait_event_interruptible(map->active.inflight_conn_req,
+					     pvcalls_front_read_todo(map))) {
+			ret = -EINTR;
+			goto out;
+		}
 	}
 	ret = __read_ring(map->active.ring, &map->active.data,
 			  &msg->msg_iter, len, flags);
@@ -706,6 +709,7 @@ int pvcalls_front_recvmsg(struct socket *sock, struct msghdr *msg, size_t len,
 	if (ret == -ENOTCONN)
 		ret = 0;
 
+out:
 	mutex_unlock(&map->active.in_mutex);
 	pvcalls_exit_sock(sock);
 	return ret;



