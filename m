From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 29 Mar 2026 17:17:33 +0200
Subject: [PATCH] boot/bootm: Disable interrupts after loading the image
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260329-bootm-wdt-v1-1-f46b3bc6d50e@posteo.net>
X-B4-Tracking: v=1; b=H4sIAIxCyWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYyNL3aT8/JJc3fKUEt1kU0NDC3MzQ4tUMyMloPqCotS0zAqwWdGxtbU
 AwHozGFsAAAA=
X-Change-ID: 20260329-bootm-wdt-c51187618e62
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Sughosh Ganu <sughosh.ganu@arm.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 =?utf-8?q?=E7=89=9B_=E5=BF=97=E5=AE=8F?= <Zone.Niuzh@hotmail.com>, 
 Benjamin ROBIN <dev@benjarobin.fr>, Aristo Chen <jj251510319013@gmail.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774797455; l=1473;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=zPsGfFMuExAJidkBX5RFyv2C7XhSoz2IUlILWWWBH5I=;
 b=hO2Zorae2qOXNp3SbKtYEfFtCH2IWBWMFI86shCJ6CW/qDgH3lHIJ6ZBH51mMLY5/IvlAfFXL
 BLpKWgwlzkCA5P5K9t6ReTTduMMwvJpkFlDs9zZeLYEcOYzXZ/Z42If
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Interrupts need to be disabled before we jump into the OS, but currently
they're already disabled before we load/uncompress the image. This has
the inconvenient side effect of taking up a part of the watchdog time
budget, which can be rather large when the image is big. Ideally, we
want to leave a full watchdog time slice for the OS, so that it has
enough time to initialize its own watchdog driver. To ease the pressure,
disable interrupts (and with it, a timer interrupt that could service
the watchdog) after loading/uncompressing the OS image.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 boot/bootm.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/boot/bootm.c b/boot/bootm.c
index 4bdca22ea8c..fa4b53050b7 100644
--- a/boot/bootm.c
+++ b/boot/bootm.c
@@ -1015,7 +1015,6 @@ int bootm_run_states(struct bootm_info *bmi, int states)
 
 	/* Load the OS */
 	if (!ret && (states & BOOTM_STATE_LOADOS)) {
-		iflag = bootm_disable_interrupts();
 		ret = bootm_load_os(images, 0);
 		if (ret && ret != BOOTM_ERR_OVERLAP)
 			goto err;
@@ -1044,6 +1043,8 @@ int bootm_run_states(struct bootm_info *bmi, int states)
 	}
 #endif
 
+	iflag = bootm_disable_interrupts();
+
 	/* From now on, we need the OS boot function */
 	if (ret)
 		return ret;

---
base-commit: eb95914b9f5886b7ca0eaa2dbcd8a66bb8e5f81a
change-id: 20260329-bootm-wdt-c51187618e62

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

