From: Wesley Atwell <atwellwea@gmail.com>
Date: Fri, 27 Nov 2026 22:54:01 -0700
Subject: [PATCH] dm crypt: reject an integrity option without a profile
 delimiter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-dmcrypt-integrity-option-v1-1-1dc42a7be52a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MSwrDIBAA0KvIrJ0SpcTGq5Qu/EySWcTIKKUh5
 O6lfQd4JzQSpgZenSD05sZ7Aa+MVpDWUBZCzuAV2MGOxliHeUty1I5cOi3C/cC9dt4LjpM1NA0
 uPswMWkEVmvnzr58vrSCGRhgllLT+wryhu93hur62wNd9gwAAAA==
X-Change-ID: 20261127-dmcrypt-integrity-option-6921e907b81f
To: Mike Snitzer <snitzer@kernel.org>, 
 Mikulas Patocka <mpatocka@redhat.com>
Cc: linux-kernel@vger.kernel.org, Benjamin Marzinski <bmarzins@redhat.com>, 
 Alasdair Kergon <agk@redhat.com>, dm-devel@lists.linux.dev
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795845253; l=2162;
 i=atwellwea@gmail.com; s=20261127; h=from:subject:message-id;
 bh=J18/+zV/EaKtI4zWNPjGJ/UhgvJdrouclOkKfrVrgS4=;
 b=EdAgMGbBdCBC9RcaOp+gp4JM/8IxlumfnV53toaLD0yaxXzg1+jnUyTRvD4oy6tSimKydxswq
 PWlj3WJUpnQDPaCyriN78LxRp/lHPp5+NWaWTLaO43UbQ4j4ouPJySq
X-Developer-Key: i=atwellwea@gmail.com; a=ed25519;
 pk=Buny5Y3000rYoA3OYcxvjG5W3dpuSWh28lf8IVDjANo=
X-Endpoint-Received: by B4 Relay for atwellwea@gmail.com/20261127 with auth_id=1671
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An administrator creating an authenticated encrypted mapping with
dmsetup can omit the second colon from integrity:<bytes>:<type>. The
existing sscanf() conversion still reports one successful assignment
for integrity:16. The following strchr() then returns NULL; advancing
that pointer and passing it to strcasecmp() causes a kernel Oops and
kills dmsetup instead of rejecting the table.

Check for the required delimiter before advancing to the profile. Return
-EINVAL with the existing invalid-integrity error when it is absent.
Valid aead and none profiles continue to load normally.

OpenAI Codex identified the unchecked parser path during source review,
helped prepare the dmsetup/KVM reproducer, and proposed the guard.
Fedora dmsetup reproduced the Oops on the unmodified dm-7.4 tree. After
the change, a fully initialized dm-integrity and dm-crypt stack
completed read/write I/O, while integrity:16 returned -EINVAL without
an Oops.

Fixes: ef43aa38063a ("dm crypt: add cryptographic data integrity protection (authenticated encryption)")
Cc: stable@vger.kernel.org
Signed-off-by: Wesley Atwell <atwellwea@gmail.com>
---
 drivers/md/dm-crypt.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/md/dm-crypt.c b/drivers/md/dm-crypt.c
index 02038a9cd..8deba9d43 100644
--- a/drivers/md/dm-crypt.c
+++ b/drivers/md/dm-crypt.c
@@ -3145,8 +3145,13 @@ static int crypt_ctr_optional(struct dm_target *ti, unsigned int argc, char **ar
 				ti->error = "Invalid integrity arguments";
 				return -EINVAL;
 			}
+			sval = strchr(opt_string + strlen("integrity:"), ':');
+			if (!sval) {
+				ti->error = "Invalid integrity arguments";
+				return -EINVAL;
+			}
+			sval++;
 			cc->used_tag_size = val;
-			sval = strchr(opt_string + strlen("integrity:"), ':') + 1;
 			if (!strcasecmp(sval, "aead")) {
 				set_bit(CRYPT_MODE_INTEGRITY_AEAD, &cc->cipher_flags);
 			} else if (strcasecmp(sval, "none")) {

---
base-commit: e92cd41e8e5ee5616c6c7cd4378661d942f0a7c0
change-id: 20261127-dmcrypt-integrity-option-6921e907b81f

Best regards,
-- 
Wesley Atwell <atwellwea@gmail.com>

