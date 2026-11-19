From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 21:39:02 +0000
Subject: [PATCH net] tipc: restore write readiness when a socket's group
 goes away
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-tipc-group-open-v1-1-cb725145da51@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHVs/2oC/yWMwQqDMBAFf0X23AVXaKv+SulBt692PSQhiVIQ/
 93YHmdgZqOEaEjUVxtFrJbMuwJyqUg/g5vA9ipMTd3cRKTjbEF5in4J7AMcDxC93ttuFCiVKkS
 87fs7Psgh0/Mv0zLO0Hy+aN8PJ2NuN3gAAAA=
X-Change-ID: 20261119-tipc-group-open-ae1c5789b1ec
To: davem@davemloft.net, kuba@kernel.org, edumazet@kernel.org, 
 jmaloy@redhat.com, pabeni@redhat.com
Cc: horms@kernel.org, tipc-discussion@lists.sourceforge.net, 
 tung.quang.nguyen@est.tech, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795124342; l=3659;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=d+WQVJYdbAe7xs4W7Iq+DJKoNtE/VFiuVnisFS9O1rY=;
 b=1zji59NQqSj+Iubp+nmQx9B8FQKfMd8sXkpS3yVFOcBxV/yVNJqbc6VmHYQKqtKS+PbZY+AjA
 G1xWZIXdo5+AtE3O9rrxhkFCCoZxrgVSgqqERHfpf7SCUkMIfNqB3SH
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

tipc_group_create() sets tsk->group_is_open to false, and tipc_poll()
only reports EPOLLOUT for a socket in TIPC_OPEN state when that flag is
true. Commit 1b22bcad7e39 ("tipc: correct initial value for group
congestion flag") made sure the flag is true for sockets that never
join a group, since otherwise "SOCK_RDM/DGRAM sockets sending datagrams
never receive POLLOUT".

The flag is not set back when the group goes away again, though:

- tipc_group_create() clears the flag and then fails when the topology
  subscription cannot be created, for example when TIPC_MAX_SUBSCR
  subscriptions exist already;
- tipc_sk_join() deletes the new group when tipc_sk_publish() fails,
  for example when the node's publication limit is reached;
- tipc_sk_leave() deletes the group while the flag may still be false,
  e.g. because of group congestion, or because the group has no other
  members yet.

In all three cases the socket is back to an ordinary RDM/DGRAM socket,
but poll() never reports EPOLLOUT for it again. Before commit
60c253069632 ("tipc: fix race between poll() and setsockopt()"),
tipc_poll() also reported EPOLLOUT when tsk->group was NULL, so
deleting the group was enough; since then the flag has to be reset.

Set tsk->group_is_open to true in these three places, as it is for a
socket that never had a group, and call sk_write_space() so that a
task already waiting for EPOLLOUT is woken up, as tipc_sk_filter_rcv()
does when a group becomes open again.

Found with a static analysis tool and checked by hand.

Fixes: 60c253069632 ("tipc: fix race between poll() and setsockopt()")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested in QEMU (x86_64, KASAN), on next-20261109 (net/tipc/ is the same
as in net):
- empty group, no loopback: JOIN, a thread waits in epoll_wait() for
  EPOLLOUT, then TIPC_GROUP_LEAVE. Before: no EPOLLOUT, the waiter times
  out. After: the waiter is woken and poll() reports POLLOUT.
- 65535 topology subscriptions open, then TIPC_GROUP_JOIN fails with
  -ENOMEM: no POLLOUT before, POLLOUT after.
- bind until the publication limit, then TIPC_GROUP_JOIN fails with
  -EINVAL: no POLLOUT before, POLLOUT after.
---
 net/tipc/socket.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/net/tipc/socket.c b/net/tipc/socket.c
index 65cc0c4964b3..26771a98dc7a 100644
--- a/net/tipc/socket.c
+++ b/net/tipc/socket.c
@@ -3096,8 +3096,12 @@ static int tipc_sk_join(struct tipc_sock *tsk, struct tipc_group_req *mreq)
 	if (grp)
 		return -EACCES;
 	grp = tipc_group_create(net, tsk->portid, mreq, &tsk->group_is_open);
-	if (!grp)
+	if (!grp) {
+		/* tipc_group_create() may have cleared it before failing */
+		tsk->group_is_open = true;
+		tsk->sk.sk_write_space(&tsk->sk);
 		return -ENOMEM;
+	}
 	tsk->group = grp;
 	msg_set_lookup_scope(hdr, mreq->scope);
 	msg_set_nametype(hdr, mreq->type);
@@ -3109,6 +3113,8 @@ static int tipc_sk_join(struct tipc_sock *tsk, struct tipc_group_req *mreq)
 	if (rc) {
 		tipc_group_delete(net, grp);
 		tsk->group = NULL;
+		tsk->group_is_open = true;
+		tsk->sk.sk_write_space(&tsk->sk);
 		return rc;
 	}
 	/* Eliminate any risk that a broadcast overtakes sent JOINs */
@@ -3132,7 +3138,9 @@ static int tipc_sk_leave(struct tipc_sock *tsk)
 	ua.scope = scope;
 	tipc_group_delete(net, grp);
 	tsk->group = NULL;
+	tsk->group_is_open = true;
 	tipc_sk_withdraw(tsk, &ua);
+	tsk->sk.sk_write_space(&tsk->sk);
 	return 0;
 }
 



