From: Abhinav Saxena <xandfury@gmail.com>
Date: Thu, 19 Jun 2025 20:18:19 -0600
Subject: [PATCH SECURITY 2/2] selinux: add capability checks for TIOCSTI
 ioctl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250619-toicsti-bug-v1-2-e02c73a55bcd@gmail.com>
References: <20250619-toicsti-bug-v1-0-e02c73a55bcd@gmail.com>
In-Reply-To: <20250619-toicsti-bug-v1-0-e02c73a55bcd@gmail.com>
To: security@kernel.org
Cc: Abhinav Saxena <xandfury@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750385902; l=1144;
 i=xandfury@gmail.com; s=20250614; h=from:subject:message-id;
 bh=9xfet8eJ550FD+VM4prV+To9hyXpve5cMIcZSM+Qk2A=;
 b=PjVu7P1O2pCUIEJ/MUkbh5qAty6t1yOZte1cxffqMFBZkfS5G4h8FZsRMpUH62u+rKdF4Ke7+
 VgEU2hp/GdPCbmdMciGmaRr340KdtTQoYgHfdCUM06bEq+oFdTSZioE
X-Developer-Key: i=xandfury@gmail.com; a=ed25519;
 pk=YN6w7WNet8skqvMWxhG5BlAmtd1SQmo8If6Mofh4k44=
X-Endpoint-Received: by B4 Relay for xandfury@gmail.com/20250614 with auth_id=436
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TIOCSTI ioctl currently only checks the current process's
credentials, creating a TOCTOU vulnerability where an unprivileged
process can open a TTY fd and pass it to a privileged process via
SCM_RIGHTS.

Fix by requiring BOTH the file opener (file->f_cred) AND the current
process to have CAP_SYS_ADMIN. This prevents privilege escalation
while ensuring legitimate use cases continue to work.

Link: https://github.com/KSPP/linux/issues/156

Signed-off-by: Abhinav Saxena <xandfury@gmail.com>
---
 security/selinux/hooks.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/security/selinux/hooks.c b/security/selinux/hooks.c
index 595ceb314aeb..a628551873ab 100644
--- a/security/selinux/hooks.c
+++ b/security/selinux/hooks.c
@@ -3847,6 +3847,12 @@ static int selinux_file_ioctl(struct file *file, unsigned int cmd,
 					    CAP_OPT_NONE, true);
 		break;
 
+	case TIOCSTI:
+		if (!file_ns_capable(file, &init_user_ns, CAP_SYS_ADMIN) ||
+		    !capable(CAP_SYS_ADMIN))
+			error = -EPERM;
+		break;
+
 	case FIOCLEX:
 	case FIONCLEX:
 		if (!selinux_policycap_ioctl_skip_cloexec())

-- 
2.43.0

