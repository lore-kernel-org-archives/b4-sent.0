From: Alban Munari <alban.kernel@gmail.com>
Date: Sun, 08 Nov 2026 20:05:12 +0000
Subject: [PATCH v2] tpm: Remove enum tpm2_session_types
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-tpm-se-trial-v2-1-92c2090351d7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0Jm7RimQQVX3MOwKDCFMZSSthIN4
 e4Crl2+5P33FwjshQPckwU8zxLEjRuoUwJNr8eOUdqNQaXqSpTmGCeLgTF60QNe8rRmU9SZoRt
 sk8mzkfeRe1Q/Dq/6yU3cG7vRS4jOf46/mXbvT3omJMwKpSg3RcsZlZ3VMpwbZ6Fa1/UL9ajHA
 LoAAAA=
X-Change-ID: 20261108-tpm-se-trial-580bef9b4f17
To: Peter Huewe <peterhuewe@gmx.de>, Jarkko Sakkinen <jarkko@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>, 
 James Bottomley <James.Bottomley@HansenPartnership.com>, 
 Ard Biesheuvel <ardb@kernel.org>
Cc: linux-integrity@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alban Munari <alban.kernel@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794168332; l=2277;
 i=alban.kernel@gmail.com; s=hephaestus; h=from:subject:message-id;
 bh=FiL44ygx4KhhpPRDazZwhl0/A0dCZenHQ3H9IagOC6Q=;
 b=X0eopT0lIsvtKricO5oVDqirkfAmYyAILXvY63PUg5+af7w6HbF4DfZC2LAiqWKAcIppx2ncj
 jcPliS4jvUJACDva0p4Vc8DnyhDSbCu2Qx/PKA7/vbc9mbs9GB6eD3V
X-Developer-Key: i=alban.kernel@gmail.com; a=ed25519;
 pk=E4gTLxHRk8yuKicoDcjhUfRHnlctgbnlV9dmOwM5338=
X-Endpoint-Received: by B4 Relay for alban.kernel@gmail.com/hephaestus with auth_id=1455
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TPM2_SE_TRIAL is defined as 0x02, while the TPM 2.0 Library
specification, Part 2: Structures, revision 01.83, section 6.11, Table
21, defines TPM_SE_TRIAL as 0x03.

The only user of enum tpm2_session_types is tpm2_start_auth_session(),
which starts an HMAC session. Remove the enum and pass the session type
there as a literal, rather than fix a constant that nothing uses.

Suggested-by: Jarkko Sakkinen <jarkko@kernel.org>
Signed-off-by: Alban Munari <alban.kernel@gmail.com>
---
Changes in v2:
- Remove the enum instead of fixing TPM2_SE_TRIAL (Jarkko).
- Refer to the section of the TCG specification.
- Drop the Fixes tag: no code used the wrong value.
- Link to v1: https://patch.msgid.link/20261108-tpm-se-trial-v1-1-492218f9de41@gmail.com

To: Peter Huewe <peterhuewe@gmx.de>
To: Jarkko Sakkinen <jarkko@kernel.org>
To: Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-integrity@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 drivers/char/tpm/tpm2-sessions.c | 2 +-
 include/linux/tpm_command.h      | 6 ------
 2 files changed, 1 insertion(+), 7 deletions(-)

diff --git a/drivers/char/tpm/tpm2-sessions.c b/drivers/char/tpm/tpm2-sessions.c
index ca1e2bf424e1..63e1dd596bc5 100644
--- a/drivers/char/tpm/tpm2-sessions.c
+++ b/drivers/char/tpm/tpm2-sessions.c
@@ -1043,7 +1043,7 @@ int tpm2_start_auth_session(struct tpm_chip *chip)
 		return rc;
 	}
 	/* session type (HMAC, audit or policy) */
-	tpm_buf_append_u8(buf, TPM2_SE_HMAC);
+	tpm_buf_append_u8(buf, 0x00 /* HMAC */);
 
 	/* symmetric encryption parameters */
 	/* symmetric algorithm */
diff --git a/include/linux/tpm_command.h b/include/linux/tpm_command.h
index fc446a1282e2..c9988fcff916 100644
--- a/include/linux/tpm_command.h
+++ b/include/linux/tpm_command.h
@@ -168,12 +168,6 @@ struct tpm1_get_random_out {
 /* TPM2 specific constants. */
 #define TPM2_SPACE_BUFFER_SIZE		16384 /* 16 kB */
 
-enum tpm2_session_types {
-	TPM2_SE_HMAC	= 0x00,
-	TPM2_SE_POLICY	= 0x01,
-	TPM2_SE_TRIAL	= 0x02,
-};
-
 enum tpm2_timeouts {
 	TPM2_TIMEOUT_A		= 750,
 	TPM2_TIMEOUT_B		= 4000,

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261108-tpm-se-trial-580bef9b4f17

Best regards,
--  
Alban Munari <alban.kernel@gmail.com>

