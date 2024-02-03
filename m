From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 02 Feb 2024 18:26:46 -0600
Subject: [PATCH] powerpc/pseries/papr-sysparm: use u8 arrays for payloads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240202-papr-sysparm-ioblock-data-use-u8-v1-1-f5c6c89f65ec@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAEWIvWUC/x3NwQqDMAyA4VeRnBdoOxmyVxk7xDbO4GZLMsdEf
 HeLx+/y/xsYq7DBvdlA+Scmea7wlwbiSPOLUVI1BBdaF5zHQkXRViukH5Tcv3OcMNGXcDHGpUP
 vUuiusb8NPkLNFOVB/ufi8dz3A/sNfPdyAAAA
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: Tyrel Datwyler <tyreld@linux.ibm.com>, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706920010; l=1878;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=+IiR1yRnowpFFkAsHfmCVymG5bRT3lCVdavVDyidwnM=;
 b=dkaLfDQdV8zLrd0BgZdm3eqO/SRoJcTPUMef2TihkbahHtWB5r9V7yO/AIyyHpG8qwTVxcsi3
 i+bVg0AlAXKD0PIZAm7OZpz12n0raqnm6xZqIWAMmdQigh4+Vu9rRvJ
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some PAPR system parameter values are formatted by firmware as
nul-terminated strings (e.g. LPAR name, shared processor attributes).
But the values returned for other parameters, such as processor module
info and TLB block invalidate characteristics, are binary data with
parameter-specific layouts. So char[] isn't the appropriate type for
the general case. Use u8/__u8.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Fixes: 905b9e48786e ("powerpc/pseries/papr-sysparm: Expose character device to user space")
---
I'd like to get this in for v6.8 so the uapi header has the change for
its first point release.
---
 arch/powerpc/include/asm/papr-sysparm.h      | 2 +-
 arch/powerpc/include/uapi/asm/papr-sysparm.h | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/include/asm/papr-sysparm.h b/arch/powerpc/include/asm/papr-sysparm.h
index 0dbbff59101d..c3cd5b131033 100644
--- a/arch/powerpc/include/asm/papr-sysparm.h
+++ b/arch/powerpc/include/asm/papr-sysparm.h
@@ -32,7 +32,7 @@ typedef struct {
  */
 struct papr_sysparm_buf {
 	__be16 len;
-	char val[PAPR_SYSPARM_MAX_OUTPUT];
+	u8 val[PAPR_SYSPARM_MAX_OUTPUT];
 };
 
 struct papr_sysparm_buf *papr_sysparm_buf_alloc(void);
diff --git a/arch/powerpc/include/uapi/asm/papr-sysparm.h b/arch/powerpc/include/uapi/asm/papr-sysparm.h
index 9f9a0f267ea5..f733467b1534 100644
--- a/arch/powerpc/include/uapi/asm/papr-sysparm.h
+++ b/arch/powerpc/include/uapi/asm/papr-sysparm.h
@@ -14,7 +14,7 @@ enum {
 struct papr_sysparm_io_block {
 	__u32 parameter;
 	__u16 length;
-	char data[PAPR_SYSPARM_MAX_OUTPUT];
+	__u8 data[PAPR_SYSPARM_MAX_OUTPUT];
 };
 
 /**

---
base-commit: 44a1aad2fe6c10bfe0589d8047057b10a4c18a19
change-id: 20240201-papr-sysparm-ioblock-data-use-u8-10d283cb6f1c

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

