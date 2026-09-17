From: David Heidelberg <david@ixit.cz>
Date: Fri, 18 Sep 2026 00:14:11 +0200
Subject: [PATCH] serial: qcom-geni: power the console back up on system
 resume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-qcom-geni-pm-v1-1-cb587e215607@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02PS47CMBBErxL1mpb8iRM7V0Es/GkzRsQEO0EjI
 e4+DsyCZUnVr14/oVJJVGHqnlDokWq65Rb4oQP/Y/OZMIWWQTAxMMM13v1txjPlhMuMxGJU2hh
 veg3tZCkU0+8bdzx9ct3chfy6M/4bhe5b21k/NXC2EjbonNapk0HLUeleCqdooGAUGxVjVo0UH
 YvSxp4TjQG+/abubaeFxv0be/2SbDq4ZWevNnsKWJr07jQTat7TIJkUgzPTg8Pp9foDLOvDZw4
 BAAA=
X-Change-ID: 20260918-qcom-geni-pm-e0ff5899c948
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Praveen Talari <praveen.talari@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Abel Vesa <abel.vesa@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2417; i=david@ixit.cz;
 h=from:subject:message-id; bh=WIgNFxV6Tu+/jmP1IZkjh/Ghxyf29pITtAMmGeHwlW8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqrGY2dYAyGFUApgIgLXfN7/jif5pN/x5B+6nh2
 EDJxYq6rh+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqxmNgAKCRBgAj/E00kg
 cjbNEACDh7xH9ppjPnlAzA9NpKasaWLELT92Y8OAMRxtEDgxX98FJl1NuQ22PttccQ3U07NXGh4
 SO8N/DYuLZaQHyuiL7JdnAucdIyibcOkSDCV5JKep4LfxkOumQNTOLTHvPfjvJE7Qlu3RJL2PkP
 DGQ6F25vOekkJuYfyDQJscKGQXAPVfHMBTsGJ0fPVde4qDwKnCDSutMe5eC32IUm6bXFgpzTrFv
 /p+pUC4ODEmJv7KSNjw7Tkv7HvRxykVTKZAnfUkIPXLdGIW8+yKJf6IIXJy/adu3jyFJ8JAYYvO
 ZvEubWjx3pIOo1lHlVrK41R2iR+V5Arv1tKfZYSZrhFy3IcZF3hsh0ue2VCSmfABcmvUsXwkDPI
 yNVuOFz9T9n3mGPRpubMTkx8Xs3vqIsBUSrnJVqwchaq0vVYh0pMLVD/lwF/NsfrUaxaF0yiEWD
 nCYXpKMk9jWaFtoJp4OtJqHouJDr+yeP6HnoAPM/KP07NZ0PHzsMEIbjzycKw2gjn1Ftnk8dqLa
 PERsPUf8zBmLZSeExcAQwZA1gKT0JQtTn5sUazLmUjVtlnS+J1UR+rLaR1rtARv3BxpNUuGE9qE
 6MNky24ZPtzMNax0mY8e59UXEoxD2ps7N0yrjeNzxOci++6EHtlW1aEOz5QbWNDa52f4ctqPEA6
 Bd8piCsM63knbAA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The console holds a runtime PM reference on its port, which keeps the
port powered while the tty is closed. On system suspend
pm_runtime_force_suspend() powers the port down regardless, but a single
reference makes pm_runtime_need_not_resume() report the port as not in
use, so it is marked runtime suspended instead of being flagged for
pm_runtime_force_resume(). On system resume the port therefore stays
powered down while uart_resume_port() goes on to program the termios
settings and re-enable the console.

If the tty has been opened before, uart_resume_port() ends up in
startup(), whose runtime PM reference powers the port up again, and only
the register writes made before that are lost. If the tty has never been
opened (no getty on the port, /dev/console backed by another console),
nothing powers the port back up and the console stays dead after the
first suspend.

Resume the port explicitly before uart_resume_port() when the console
was force suspended.

Assisted-by: LLM
Fixes: aee1f94dab13 ("serial: qcom-geni: remove .pm callback, use runtime PM in startup/shutdown")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/tty/serial/qcom_geni_serial.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/tty/serial/qcom_geni_serial.c b/drivers/tty/serial/qcom_geni_serial.c
index a180a00c9e23d..0c9164a1fccda 100644
--- a/drivers/tty/serial/qcom_geni_serial.c
+++ b/drivers/tty/serial/qcom_geni_serial.c
@@ -2100,16 +2100,22 @@ static int qcom_geni_serial_resume(struct device *dev)
 	struct qcom_geni_private_data *private_data = uport->private_data;
 
 	if (console_suspend_enabled || !uart_console(uport)) {
 		ret = pm_runtime_force_resume(dev);
 		if (ret)
 			return ret;
 	}
 
+	if (console_suspend_enabled && uart_console(uport)) {
+		ret = pm_runtime_resume(dev);
+		if (ret < 0)
+			return ret;
+	}
+
 	ret = uart_resume_port(private_data->drv, uport);
 	if (uart_console(uport)) {
 		geni_icc_set_tag(&port->se, QCOM_ICC_TAG_ALWAYS);
 		geni_icc_set_bw(&port->se);
 	}
 	return ret;
 }
 

---
base-commit: 3d83758432b5e6ed9507500a57efb0f3af41ee7d
change-id: 20260918-qcom-geni-pm-e0ff5899c948
prerequisite-change-id: 20260828-serial-qcom-geni-fix-unbalanced-rpm-resume-814e630326b9:v1
prerequisite-patch-id: a2666a59a68190a3f438cec8aa167111c21dc8ca

Best regards,
--  
David Heidelberg <david@ixit.cz>

