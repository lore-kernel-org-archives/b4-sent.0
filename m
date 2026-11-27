From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 06:37:47 +0000
Subject: [PATCH 6.6.y] rds: tcp: unregister sysctl before tearing down
 listen socket
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so5-rds-66-v1-1-1abb4e9ce92b@certik.com>
X-B4-Tracking: v=1; b=H4sIADolCWsC/0WNSw7CMAxEr1J5jUsTwKhcBXWRj6FBKEFxqUBV7
 04CC5bzNPNmAeEcWODULJB5DhJSLEFtGnCjiVfG4EsG3WlSSh9R0gGzFyTC3rne7vZkvO+gDB6
 ZL+H1lZ2BWmrfMPywPO2N3VRFtWiNMNpsohsrEo5+SumOlW//B7CuH844CQqgAAAA
X-Change-ID: 20261127-so5-rds-66-9cc9b346add0
To: stable@vger.kernel.org
Cc: Cen Zhang <blbllhy@gmail.com>, netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795761466; l=2888;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=eX75dksd+0Eq/c6Duq5vPiGvUbIGB0rYF3qmdTVxvX8=;
 b=BLV0tpHTjpwxzWlawloS8nPZzByn15w+p/yUa9RcglQDfGguxqgH0yPyz2x/FuI4GXYh4kywc
 i71OQrCJHG1DgqyX9MeUJZbA9yS1hu1Jxn6eIGtXSHNxfo6V+R8TIqX
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Cen Zhang (Microsoft)" <blbllhy@gmail.com>

commit 167e54c703ccd4fa028feb568b0d1002020cff86 upstream.

rds_tcp_exit_net() frees the per-netns RDS TCP listen socket via
rds_tcp_kill_sock() before unregistering the per-netns sysctl table.  Since
rds_tcp_skbuf_handler() derives the netns from
rtn->rds_tcp_listen_sock->sk, a concurrent sysctl write can race with
netns teardown and dereference the freed socket/sk.

KASAN reports the race as:

  BUG: KASAN: slab-use-after-free in rds_tcp_skbuf_handler+0x2aa/0x2e0
  rds_tcp_skbuf_handler              net/rds/tcp.c:721
  proc_sys_call_handler              fs/proc/proc_sysctl.c
  vfs_write                          fs/read_write.c
  __x64_sys_pwrite64                 fs/read_write.c

Fix this by unregistering the RDS TCP sysctl table before calling
rds_tcp_kill_sock().  unregister_net_sysctl_table() prevents new sysctl
handlers from starting and waits for in-flight handlers to finish, so
the listen socket can then be released safely. The fix was tested
against the linked reproducer.

Fixes: 7f5611cbc487 ("rds: sysctl: rds_tcp_{rcv,snd}buf: avoid using current->nsproxy")
Reported-by: AutonomousCodeSecurity@microsoft.com
Link: https://lore.kernel.org/all/20260719203718.9680-1-blbllhy@gmail.com
Reviewed-by: Allison Henderson <achender@kernel.org>
Signed-off-by: Cen Zhang (Microsoft) <blbllhy@gmail.com>
Link: https://patch.msgid.link/20260719210357.10179-1-blbllhy@gmail.com
Signed-off-by: Jakub Kicinski <kuba@kernel.org>
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.12.y and newer already have this fix.

Tested on v6.6.163:
- x86_64 allmodconfig W=1 build of net/rds/tcp.o, base vs patched, no
  new warnings
- under QEMU/KVM, base and patched: loaded rds_tcp, read both TCP buffer
  sysctls in a new network namespace and tore the namespace down with
  no warnings in dmesg. I didn't run a race test.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

net/rds/tcp.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
---
 net/rds/tcp.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/net/rds/tcp.c b/net/rds/tcp.c
index 80d0e4c5b6aa..76cdea73a906 100644
--- a/net/rds/tcp.c
+++ b/net/rds/tcp.c
@@ -711,13 +711,13 @@ static void __net_exit rds_tcp_exit_net(struct net *net)
 {
 	struct rds_tcp_net *rtn = net_generic(net, rds_tcp_netid);
 
-	rds_tcp_kill_sock(net);
-
 	if (rtn->rds_tcp_sysctl)
 		unregister_net_sysctl_table(rtn->rds_tcp_sysctl);
 
 	if (net != &init_net)
 		kfree(rtn->ctl_table);
+
+	rds_tcp_kill_sock(net);
 }
 
 static struct pernet_operations rds_tcp_net_ops = {

---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261127-so5-rds-66-9cc9b346add0

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

