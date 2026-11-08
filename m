From: Alban Munari <alban.kernel@gmail.com>
Date: Sun, 08 Nov 2026 18:05:39 +0000
Subject: [PATCH] tpm: Fix the value of TPM2_SE_TRIAL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-tpm-se-trial-v1-1-492218f9de41@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwML3ZKCXN3iVN2SoszEHF1TC4Ok1DTLJJM0Q3MloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loA2450enAAAAA=
X-Change-ID: 20261108-tpm-se-trial-580bef9b4f17
To: Peter Huewe <peterhuewe@gmx.de>, Jarkko Sakkinen <jarkko@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>, 
 James Bottomley <James.Bottomley@HansenPartnership.com>, 
 Ard Biesheuvel <ardb@kernel.org>
Cc: linux-integrity@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alban Munari <alban.kernel@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794161265; l=1447;
 i=alban.kernel@gmail.com; s=hephaestus; h=from:subject:message-id;
 bh=oXjBD4XWIC/ZjW4m/+tswgFBCuflIPHtvzC/8fbK08o=;
 b=rnhjKXXFmP/oNAF4G5smGF3owTZwVYlv7Fam4wDkci8AXwYUuHEwnNgwdB2Qzu9kQsIdWedUA
 j6B8RlB09pACHIdSJWu10IRT+c6fJ1mVZYTKQnJAydA6WGepGio0RLJ
X-Developer-Key: i=alban.kernel@gmail.com; a=ed25519;
 pk=E4gTLxHRk8yuKicoDcjhUfRHnlctgbnlV9dmOwM5338=
X-Endpoint-Received: by B4 Relay for alban.kernel@gmail.com/hephaestus with auth_id=1455
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TPM 2.0 Library specification, Part 2: Structures, defines the
session types (TPM_SE) as TPM_SE_HMAC = 0x00, TPM_SE_POLICY = 0x01 and
TPM_SE_TRIAL = 0x03. TPM2_SE_TRIAL is defined as 0x02, which is not a
session type: TPM2_StartAuthSession with it fails with TPM_RC_VALUE on
the sessionType parameter, as swtpm 0.11.0 shows.

No code in the kernel uses TPM2_SE_TRIAL, so nothing changes at run
time. The TPM 2.0 selftests already define it as 0x03 in
tools/testing/selftests/tpm2/tpm2.py.

This change was found and written with an AI coding assistant (Claude
Opus 5.5, Anthropic), while building trial sessions on an AMD fTPM with
the value 0x03.

Fixes: 699e3efd6c64 ("tpm: Add HMAC session start and end functions")
Signed-off-by: Alban Munari <alban.kernel@gmail.com>
---
 include/linux/tpm_command.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/tpm_command.h b/include/linux/tpm_command.h
index fc446a1282e2..076ee8ce816c 100644
--- a/include/linux/tpm_command.h
+++ b/include/linux/tpm_command.h
@@ -171,7 +171,7 @@ struct tpm1_get_random_out {
 enum tpm2_session_types {
 	TPM2_SE_HMAC	= 0x00,
 	TPM2_SE_POLICY	= 0x01,
-	TPM2_SE_TRIAL	= 0x02,
+	TPM2_SE_TRIAL	= 0x03,
 };
 
 enum tpm2_timeouts {

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261108-tpm-se-trial-580bef9b4f17

Best regards,
--  
Alban Munari <alban.kernel@gmail.com>

