From: Suyuan Wang <shyckless@gmail.com>
Date: Wed, 18 Nov 2026 14:21:32 +0000
Subject: [PATCH] crypto: ccp: Require a writable file for SNP_COMMIT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-ccp-sev-v1-1-76894536031f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGu0/WoC/yXMQQ5AMBCF4avIrDUxFY24ilhUOxiLkg4iEXdXL
 L/kf+8Cocgk0GQXRDpYeAkJmGfgJhtGUuyTQRfaIGKtnFuV0KG0NThUtiy99pDqNdLA5/fUdr9
 l72dy2zuH+34AflBYUGsAAAA=
X-Change-ID: 20261118-ccp-sev-2a61f5a33d2d
To: ashish.kalra@amd.com, john.allen@amd.com, thomas.lendacky@amd.com
Cc: linux-kernel@vger.kernel.org, linux-crypto@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795011692; l=2406;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=VKFek2Cxcwj/7D3tXDWOWVgjXPInUg0klOAhSzwecgE=;
 b=+OHDlxSfZBlZh69PJgFU3Irr+Jrmo/H7dszuT3XwQFpZqz+ny+Y4d06cUPs2uDai+BvmZSiLj
 OYdqI430KAmCmo0I7CZxSPnmgXg6/gx9VQv9Xhai42CsFqXhotWZHmn
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

sev_ioctl() works out whether the file was opened for writing and passes
that down to every command that changes platform state:

	bool writable = file->f_mode & FMODE_WRITE;
	...
	case SNP_SET_CONFIG:
		ret = sev_ioctl_do_snp_set_config(&input, writable);

SNP_COMMIT is the exception. sev_ioctl_do_snp_commit() takes no writable
argument and runs SEV_CMD_SNP_COMMIT unconditionally, so a process that
opened /dev/sev read-only can still commit the SNP firmware version.
Committing the current firmware updates the committed version and the
reported TCB, and prevents rolling back to a previously committed
firmware version -- the kind of state change the FMODE_WRITE check
exists to gate.

Pass writable to sev_ioctl_do_snp_commit() and reject the command with
-EPERM on a read-only file, like the other state-changing commands
(reset, PEK/PDH gen, PEK import, SNP_SET_CONFIG, VLEK_LOAD).

Found with a static analysis tool and checked by hand.

Fixes: fad133c79afa ("crypto: ccp: Add the SNP_COMMIT command")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested only (x86_64, W=1 and sparse show no new warnings). I
don't have an SEV-SNP platform.
---
 drivers/crypto/ccp/sev-dev.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/crypto/ccp/sev-dev.c b/drivers/crypto/ccp/sev-dev.c
index 52fb208b71ab..9d1c40a371e3 100644
--- a/drivers/crypto/ccp/sev-dev.c
+++ b/drivers/crypto/ccp/sev-dev.c
@@ -2666,11 +2666,14 @@ static int sev_ioctl_do_snp_platform_status(struct sev_issue_cmd *argp)
 	return ret;
 }
 
-static int sev_ioctl_do_snp_commit(struct sev_issue_cmd *argp)
+static int sev_ioctl_do_snp_commit(struct sev_issue_cmd *argp, bool writable)
 {
 	struct sev_data_snp_commit buf;
 	int ret;
 
+	if (!writable)
+		return -EPERM;
+
 	buf.len = sizeof(buf);
 
 	mutex_lock(&sev_cmd_mutex);
@@ -2796,7 +2799,7 @@ static long sev_ioctl(struct file *file, unsigned int ioctl, unsigned long arg)
 		ret = sev_ioctl_do_snp_platform_status(&input);
 		break;
 	case SNP_COMMIT:
-		ret = sev_ioctl_do_snp_commit(&input);
+		ret = sev_ioctl_do_snp_commit(&input, writable);
 		break;
 	case SNP_SET_CONFIG:
 		ret = sev_ioctl_do_snp_set_config(&input, writable);



