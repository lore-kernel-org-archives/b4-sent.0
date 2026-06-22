From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 22 Jun 2026 15:57:38 -0500
Subject: [PATCH] apparmor: mediate the implicit connect of TCP fast open
 sendmsg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-b4-disp-aba401c6-v1-1-9d74343c7ced@proton.me>
X-B4-Tracking: v=1; b=H4sIAMGhOWoC/x3MPQqAMAxA4atIZgM11Fq9ijj0J9UsKi2IIN7d4
 vgN7z1QOAsXmJoHMl9S5NgruraBsLl9ZZRYDaTIKEOEXmOUcqLzTqsuGEyKrKZgaRx6qNmZOcn
 9L+flfT/zOldgYgAAAA==
To: Ryan Lee <ryan.lee@canonical.com>, 
 John Johansen <john.johansen@canonical.com>
Cc: Mickael Salaun <mic@digikod.net>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>, 
 James Morris <jmorris@namei.org>, Matthieu Buffet <matthieu@buffet.re>, 
 linux-security-module@vger.kernel.org, 
 Mikhail Ivanov <ivanov.mikhail1@huawei-partners.com>, 
 "Serge E. Hallyn" <serge@hallyn.com>, linux-kernel@vger.kernel.org, 
 Paul Moore <paul@paul-moore.com>, apparmor@lists.ubuntu.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782161857; l=3633;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=e2t5bp4l0ZsG/vhIPuFXcseb3OvyeXAly/te6D921wY=;
 b=c2u7zxjk1psh1+GEDQpUgJx2ZUR+fEinuqAMbCLImRETnNGXUO1+VZ2sxlUo+UWeog5PgYsY0
 40TH6DrS5hzA01zjyU5PD0xy3IFNR/aO1+2Ampv+zvCzfZOAQugY6p0
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sendmsg()/sendto() with MSG_FASTOPEN is a combination of connect(2) and
write(2): it opens the connection in the SYN. apparmor_socket_sendmsg()
only checks AA_MAY_SEND, so a profile that grants send but denies connect
lets a confined task open an outbound TCP/MPTCP connection that connect(2)
would have refused, bypassing connect mediation.

Mediate the implicit connect when MSG_FASTOPEN is set and a destination
is supplied. Add it to apparmor_socket_sendmsg() (not the shared
aa_sock_msg_perm() helper, which recvmsg also uses) and call aa_sk_perm()
directly, mirroring the selinux and tomoyo fixes. sk_is_tcp() does not
cover MPTCP fast open, so the SOCK_STREAM/IPPROTO_MPTCP arm is explicit.

Fixes: cf60af03ca4e ("net-tcp: Fast Open client - sendmsg(MSG_FASTOPEN)")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
This is the patch and reproducer requested in [1]. A userspace regression test
(tests/regression/apparmor/net_inet_tcp_fastopen) follows separately to the
apparmor tree, as suggested.

Reproducer (behavioral; the bypassed value is policy, not bus state, so no special
hardware). Under a profile that grants inet/inet6 stream send but denies connect, on
the current Debian security kernel 6.12.94 (apparmor active):

  [TCP ] connect(2)=EACCES   sendto(MSG_FASTOPEN)=OK   -> connect bypassed (listener accepted)
  [TCP6] connect(2)=EACCES   sendto(MSG_FASTOPEN)=OK   -> connect bypassed

The kernel audit shows the connect(2) denial and no connect record for the fastopen
sendto:

  apparmor="DENIED" operation="connect" profile="egress_restricted" comm="lsm_tfo_ab"
    family="inet" sock_type="stream" protocol=6 requested_mask="connect" denied_mask="connect"

With this patch the fastopen sendto hits that same connect denial. Full reproducer
available on request.

Same-class fixes: selinux [2], tomoyo [3]; the original cross-LSM report (landlock,
the first instance) is [4].

[1] https://lore.kernel.org/r/20260619011138.264578-1-hexlabsecurity@proton.me
[2] https://lore.kernel.org/r/20260618175513.112443-2-stephen.smalley.work@gmail.com
[3] https://lore.kernel.org/r/20260619002207.61104-1-matthieu@buffet.re
[4] https://lore.kernel.org/r/20260616201615.275032-1-hexlabsecurity@proton.me
---
 security/apparmor/lsm.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/security/apparmor/lsm.c b/security/apparmor/lsm.c
index 3491e9f60194..e01efdf50efa 100644
--- a/security/apparmor/lsm.c
+++ b/security/apparmor/lsm.c
@@ -1422,7 +1422,21 @@ static int aa_sock_msg_perm(const char *op, u32 request, struct socket *sock,
 static int apparmor_socket_sendmsg(struct socket *sock,
 				   struct msghdr *msg, int size)
 {
-	return aa_sock_msg_perm(OP_SENDMSG, AA_MAY_SEND, sock, msg, size);
+	int error = aa_sock_msg_perm(OP_SENDMSG, AA_MAY_SEND, sock, msg, size);
+
+	if (error)
+		return error;
+
+	/* TCP fast open carries connect() semantics in sendmsg(); mediate
+	 * the implicit connect so it cannot bypass the connect permission.
+	 */
+	if ((msg->msg_flags & MSG_FASTOPEN) && msg->msg_name &&
+	    (sk_is_tcp(sock->sk) ||
+	     (sk_is_inet(sock->sk) && sock->sk->sk_type == SOCK_STREAM &&
+	      sock->sk->sk_protocol == IPPROTO_MPTCP)))
+		error = aa_sk_perm(OP_CONNECT, AA_MAY_CONNECT, sock->sk);
+
+	return error;
 }
 
 static int apparmor_socket_recvmsg(struct socket *sock,

---
base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
change-id: 20260622-b4-disp-aba401c6-f02842c82975

Best regards,
-- 
bryamzxz <hexlabsecurity@proton.me>

