From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:09:49 -0400
Subject: [PATCH] efi: capsule: publish capsule_pending after efi_reset_type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-efi-capsule-v1-1-fbf2a2032afb@vt.edu>
X-B4-Tracking: v=1; b=H4sIAFzVsWoC/yWMSQ7CMAxFr1J5jVESENNVEAsndakRhMqmFVLVu
 5OU5fvDm8FYhQ0uzQzKk5i8cwG/aSD1lO+M0haG4MLBnYPHV0TuBBMNNj4ZW+99R84RnxyU06C
 l/a7C6+3PNsYHp0+11EUkY4xKOfU1WnE6bneoaQ/L8gN0ywjfkgAAAA==
X-Change-ID: 20260921-mb-efi-capsule-d111fa00ae80
To: Ard Biesheuvel <ardb@kernel.org>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: linux-efi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790039390; l=2172;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=X2iIHXM9aTbKg1eV8I2OGvi0jB5q+1pYYgIngrKjlno=;
 b=N0Wf9HRbb2qK1lTzYnhujeJojZ4fetClGgLlOK7cPCjWvx/PQ4SXMmdobgqMZwWa9MRgeS2tU
 puZV5CGtpGRCHsAs/8Fd/+QleDpINeY0fJpvcVK97D0rFE2y5PQ4agA
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

efi_capsule_update_locked() sets capsule_pending and then
efi_reset_type, both with plain stores. efi_capsule_pending() reads them
from the reboot path without capsule_mutex.

The comment above efi_capsule_pending() covers a caller that misses the
update entirely. It does not cover the other outcome: with neither the
stores nor the loads ordered, a caller can observe capsule_pending set
and efi_reset_type still -1, and the reboot path then acts on a capsule
with an invalid reset type.

Write efi_reset_type first and publish the flag with
smp_store_release(), paired with smp_load_acquire() in
efi_capsule_pending(). A caller that misses the update entirely still
behaves as documented.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/firmware/efi/capsule.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/firmware/efi/capsule.c b/drivers/firmware/efi/capsule.c
index dd6252638..2129007d8 100644
--- a/drivers/firmware/efi/capsule.c
+++ b/drivers/firmware/efi/capsule.c
@@ -50,7 +50,8 @@ static DEFINE_MUTEX(capsule_mutex);
  */
 bool efi_capsule_pending(int *reset_type)
 {
-	if (!capsule_pending)
+	/* Pairs with the smp_store_release() in efi_capsule_update_locked(). */
+	if (!smp_load_acquire(&capsule_pending))
 		return false;
 
 	if (reset_type)
@@ -173,8 +174,14 @@ efi_capsule_update_locked(efi_capsule_header_t *capsule,
 
 	status = efi.update_capsule(&capsule, 1, sglist_phys);
 	if (status == EFI_SUCCESS) {
-		capsule_pending = true;
 		efi_reset_type = reset;
+		/*
+		 * efi_capsule_pending() reads the flag without capsule_mutex
+		 * and then the reset type, which is stored above. Publish the
+		 * flag with release semantics so that a reader that sees it
+		 * also sees the matching reset type.
+		 */
+		smp_store_release(&capsule_pending, true);
 	}
 
 	return efi_status_to_err(status);

---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-efi-capsule-d111fa00ae80

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

