From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 04:08:00 +0000
Subject: [PATCH] rapidio: Use file_ns_capable() when checking config space
 read access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-rio-v1-1-3cf63c5198ff@gmail.com>
X-B4-Tracking: v=1; b=H4sIAB92/moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0NL3aLMfN3EJMskw+TENOPEVAMloMqCotS0zAqwKdGxEH5xaVJWanI
 JSKtSbS0AK9jEn2cAAAA=
X-Change-ID: 20261119-rio-ab9b1caf3ae0
To: alex.bou9@gmail.com, akpm@linux-foundation.org, 
 mporter@kernel.crashing.org
Cc: linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795061279; l=1965;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=1vmJ+AEFgVNlqvJElz4DQk/2859VN6iyvuAYe32lGnE=;
 b=WTxN/On1aehsM0yOUsELqO3xfJyZhV+gLVBo1eoMIWTf02HJ8MOCml2d/5AY1w/VXZTc5nMmZ
 y4h6LMh+T85AC6xkPBSS8uUiB9S1l5aM+yjmqvqpGNO5nANOcZudJht
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

rio_read_config() limits reads to the first 256 bytes unless
capable(CAP_SYS_ADMIN) succeeds. That checks the credentials of the
task doing the read, not those of the task that opened the file.

The config attribute is mode 0644, so any user can open it. If such a
descriptor is later read by a task that has CAP_SYS_ADMIN, the read
covers the full maintenance space. The allowed range follows whoever
happens to read the descriptor instead of the credentials it was
opened with.

Use file_ns_capable() with init_user_ns so the check is made against
the credentials saved in the file at open() time. A descriptor opened
without CAP_SYS_ADMIN then stays limited to 256 bytes whoever reads it,
and a privileged opener can still hand the descriptor to another task.

This matches pci_read_config() in PCI sysfs, and the PCI procfs change
in commit f82f53e75eff ("PCI/proc: Use file_ns_capable() when checking
config space read access").

Found with a static analysis tool and checked by hand.

Fixes: 394b701ce4fb ("[PATCH] RapidIO support: core base")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on x86_64 (W=1, no new warnings). I don't have RapidIO
hardware; the fix is by inspection.
---
 drivers/rapidio/rio-sysfs.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/rapidio/rio-sysfs.c b/drivers/rapidio/rio-sysfs.c
index 0949c869b2f1..a85b73939a9e 100644
--- a/drivers/rapidio/rio-sysfs.c
+++ b/drivers/rapidio/rio-sysfs.c
@@ -123,7 +123,7 @@ rio_read_config(struct file *filp, struct kobject *kobj,
 	u8 *data = (u8 *) buf;
 
 	/* Several chips lock up trying to read undefined config space */
-	if (capable(CAP_SYS_ADMIN))
+	if (file_ns_capable(filp, &init_user_ns, CAP_SYS_ADMIN))
 		size = RIO_MAINT_SPACE_SZ;
 
 	if (off >= size)



