From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 31 Jul 2026 12:44:09 -0500
Subject: [PATCH 1/4] selinux: do not cancel a policy conversion that never
 started
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-b4-disp-d32e997b-v1-1-0341d038ee47@proton.me>
References: <20260731-b4-disp-d32e997b-v1-0-0341d038ee47@proton.me>
In-Reply-To: <20260731-b4-disp-d32e997b-v1-0-0341d038ee47@proton.me>
To: Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>
Cc: linux-kernel@vger.kernel.org, Ondrej Mosnacek <omosnace@redhat.com>, 
 Kees Cook <kees@kernel.org>, selinux@vger.kernel.org, 
 =?utf-8?q?Christian_G=C3=B6ttsche?= <cgzones@googlemail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785519848; l=1563;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=9Qq8XJedLiodysrUmiyu10hH6TBgjvkDd7Iu7+OmmI4=;
 b=NUCyDDPzA4NIDI3YaWpAh9+dO4rxlHCk0xPk72BtxXUpO72Odon7DAmg7Z7bg1req4rRK7fHx
 gQPQrKcumabCK6mMKbFuwvFY1n1AgvcLuY1JBX/FOLjXmjDEpf1gQH5
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sel_write_load() calls selinux_policy_cancel() when sel_make_policy_nodes()
fails, and that helper dereferences the outgoing policy to cancel its
sidtab conversion. On the first policy load there is no outgoing policy:
security_load_policy() returns early for that case, before it converts
anything, and state->policy is still NULL. A first load that fails while
building the selinuxfs tree therefore takes a NULL dereference in
selinux_policy_cancel(), reached from a write(2) to /sys/fs/selinux/load.

Skip the cancel when there is no old policy, mirroring the check
security_load_policy() already makes before it converts.

Fixes: 02a52c5c8c3b ("selinux: move policy commit after updating selinuxfs")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 security/selinux/ss/services.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/security/selinux/ss/services.c b/security/selinux/ss/services.c
index 2d828548f3db..90e81186cb2e 100644
--- a/security/selinux/ss/services.c
+++ b/security/selinux/ss/services.c
@@ -2221,7 +2221,9 @@ void selinux_policy_cancel(struct selinux_load_state *load_state)
 	oldpolicy = rcu_dereference_protected(state->policy,
 					lockdep_is_held(&state->policy_mutex));
 
-	sidtab_cancel_convert(oldpolicy->sidtab);
+	/* a first load has no outgoing policy and converted nothing */
+	if (oldpolicy)
+		sidtab_cancel_convert(oldpolicy->sidtab);
 	selinux_policy_free(load_state->policy);
 	kfree(load_state->convert_data);
 }

-- 
2.55.0

