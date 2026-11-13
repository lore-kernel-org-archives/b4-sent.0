From: Suyuan Wang <shyckless@gmail.com>
Date: Fri, 13 Nov 2026 13:51:06 +0000
Subject: [PATCH] misc: genwqe: Require CAP_SYS_ADMIN for flash access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-genwqe-v1-1-75e064a19068@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMoV92oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Nj3fTUvPLCVF3TpCTj1BSz5FQLIzMloOKCotS0zAqwQdGxEH5xaVJ
 WanIJSLdSbS0AYOrb+GoAAAA=
X-Change-ID: 20261113-genwqe-5bb3ed6ce826
To: gregkh@linuxfoundation.org, haver@linux.ibm.com, arnd@arndb.de
Cc: linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794577866; l=2975;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=2IDS6cWesHgEyQ0y9gHSZmaX8tXkBSHw4f0W7fyXhNk=;
 b=TE+beaQCQz1FaapfPVum3t1xHPsVCLUHh2ruJxVBjTVxH9Pcsx+YPEDBWjPUxDQQyneHcOvs7
 7a1mzWEAdE9D9oaz+FMyTw+FMusqeHv5e3ecD0madxhfN38otJ4pObv
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

GenWQE device nodes are created with mode 0666 since commit
5ed22cebbacc ("GenWQE: Change default access rights for device node"),
so that normal users can use the accelerator. The ioctls that write
card registers and GENWQE_EXECUTE_RAW_DDCB check capable(CAP_SYS_ADMIN),
but the flash ioctls don't:

    case GENWQE_SLU_UPDATE: {
            ...
            if (!genwqe_is_privileged(cd))
                    return -EPERM;

genwqe_is_privileged() checks the privileges of the device function,
not those of the caller. So any local user who can open the node of a
privileged function can overwrite the card's bitstream partitions or
VPD in flash with GENWQE_SLU_UPDATE, and read them with GENWQE_SLU_READ.
The new contents stay in flash and can leave the card unusable after
the next reload.

The same SLCMD_MOVE_FLASH command can also be sent with
GENWQE_EXECUTE_DDCB. That path translates the buffer addresses but
passes the functional unit and command from userspace on to the card.

Require CAP_SYS_ADMIN for both flash ioctls, and for SLCMD_MOVE_FLASH
to the service layer through GENWQE_EXECUTE_DDCB. Other commands on
that path, which is what applications use, are not affected.

Found with a static analysis tool and checked by hand.

Fixes: eaf4722d4645 ("GenWQE Character device and DDCB queue")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
On GENWQE_EXECUTE_DDCB I only blocked SLCMD_MOVE_FLASH, the one service
layer command in the UAPI header besides SLCMD_ECHO_SYNC.

Compile tested only, I don't have a GenWQE card.
---
 drivers/misc/genwqe/card_dev.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/misc/genwqe/card_dev.c b/drivers/misc/genwqe/card_dev.c
index 5a07e8403e97..13adcf17df7d 100644
--- a/drivers/misc/genwqe/card_dev.c
+++ b/drivers/misc/genwqe/card_dev.c
@@ -998,6 +998,11 @@ static int genwqe_execute_ddcb(struct genwqe_file *cfile,
 	struct file *filp = cfile->filp;
 	struct ddcb_requ *req = container_of(cmd, struct ddcb_requ, cmd);
 
+	/* Same flash access as GENWQE_SLU_UPDATE and GENWQE_SLU_READ */
+	if (cmd->acfunc == DDCB_ACFUNC_SLU && cmd->cmd == SLCMD_MOVE_FLASH &&
+	    !capable(CAP_SYS_ADMIN))
+		return -EPERM;
+
 	rc = ddcb_cmd_fixups(cfile, req);
 	if (rc != 0)
 		return rc;
@@ -1150,6 +1155,9 @@ static long genwqe_ioctl(struct file *filp, unsigned int cmd,
 	case GENWQE_SLU_UPDATE: {
 		struct genwqe_bitstream load;
 
+		if (!capable(CAP_SYS_ADMIN))
+			return -EPERM;
+
 		if (!genwqe_is_privileged(cd))
 			return -EPERM;
 
@@ -1171,6 +1179,9 @@ static long genwqe_ioctl(struct file *filp, unsigned int cmd,
 	case GENWQE_SLU_READ: {
 		struct genwqe_bitstream load;
 
+		if (!capable(CAP_SYS_ADMIN))
+			return -EPERM;
+
 		if (!genwqe_is_privileged(cd))
 			return -EPERM;
 



