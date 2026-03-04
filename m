From: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
Date: Wed, 04 Mar 2026 09:25:22 +0100
Subject: [PATCH] HID: amd_sfh: don't log error when device discovery fails
 with -EOPNOTSUPP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260304-amd-sfh-suppress-eopnotsupp-err-v1-1-20214ca6a2f7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3NwQ6CMBCE4Vche2aTWgWBVyEeUKayB9tmF40J4
 d0tHr/kz8xGBhUYDdVGio+YpFhwqit6LFN8gmUuJu98687uwtNrZgsL2ztnhRkj5ZjWgwxVdnc
 0fXft4AOorJQoyPf/MN72/QeiMwdTcQAAAA==
X-Change-ID: 20260304-amd-sfh-suppress-eopnotsupp-err-0be59878e2fe
To: Basavaraj Natikar <basavaraj.natikar@amd.com>, 
 Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: Basavaraj Natikar <Basavaraj.Natikar@amd.com>, 
 linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Casey Croy <ccroy@bugzilla.kernel.org>, 
 Maximilian Pezzullo <maximilianpezzullo@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772612722; l=1508;
 i=maximilianpezzullo@gmail.com; s=20260303; h=from:subject:message-id;
 bh=4RsL24BR3KXhRnuTa8542w9vrQQZj4qOROEMdTRsAhw=;
 b=KNkHhoRSJq6pNaZcnJnLrPyWCUyMPxgAv2XwlUKg0l9E9fRGsZBqLNE5zCgXTR23gvaVoMIR/
 nejdBdVT0y9DC06omOIDUIr3LqSF6+zyo/6KswvdIHuHEKyICYXQpdS
X-Developer-Key: i=maximilianpezzullo@gmail.com; a=ed25519;
 pk=TRTR4c2Vb1IfluQvv5OUDPg7EE+pIzdPBND85UU559w=
X-Endpoint-Received: by B4 Relay for maximilianpezzullo@gmail.com/20260303 with auth_id=658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When sensor discovery fails on systems without AMD SFH sensors, the
code already emits a warning via dev_warn() in amd_sfh_hid_client_init().
The subsequent dev_err() in sfh_init_work() for the same -EOPNOTSUPP
return value is redundant and causes unnecessary alarm.

Suppress the dev_err() for -EOPNOTSUPP to avoid confusing users who
have no AMD SFH sensors.

Fixes: 2105e8e00da4 ("HID: amd_sfh: Improve boot time when SFH is available")
Reported-by: Casey Croy <ccroy@bugzilla.kernel.org>
Closes: https://bugzilla.kernel.org/show_bug.cgi?id=221099
Signed-off-by: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
---
 drivers/hid/amd-sfh-hid/amd_sfh_pcie.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/hid/amd-sfh-hid/amd_sfh_pcie.c b/drivers/hid/amd-sfh-hid/amd_sfh_pcie.c
index 1d9f955573aa..4b81cebdc335 100644
--- a/drivers/hid/amd-sfh-hid/amd_sfh_pcie.c
+++ b/drivers/hid/amd-sfh-hid/amd_sfh_pcie.c
@@ -413,7 +413,8 @@ static void sfh_init_work(struct work_struct *work)
 	rc = amd_sfh_hid_client_init(mp2);
 	if (rc) {
 		amd_sfh_clear_intr(mp2);
-		dev_err(&pdev->dev, "amd_sfh_hid_client_init failed err %d\n", rc);
+		if (rc != -EOPNOTSUPP)
+			dev_err(&pdev->dev, "amd_sfh_hid_client_init failed err %d\n", rc);
 		return;
 	}
 

---
base-commit: af4e9ef3d78420feb8fe58cd9a1ab80c501b3c08
change-id: 20260304-amd-sfh-suppress-eopnotsupp-err-0be59878e2fe

Best regards,
-- 
Maximilian Pezzullo <maximilianpezzullo@gmail.com>

