From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/4] backlight: qcom-wled: Fix OVP IRQ imbalance and
 start from the hardware state
Date: Mon, 14 Sep 2026 20:14:13 +0200
Message-Id: <20260914-qcom-wled-backlight-v3-0-d69fe9843841@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NzQ6CMBAE4FchPbumtCDiyfcwHkq7wPoD2mJFC
 e8uxYMejMdJZr4ZmENL6NgmGphFT47aZgpyETFdq6ZCIDNlJrhY8Zyv4arbM9xPaKBQ+niiqu6
 gNHmaJVxkMpVsWl4sltTP6m7/zu5WHFB3gQqNmlzX2sd86+PQ+//gY4hBJ8YkqAqjeLalnrqlf
 rLge/ElxMlvQQAHNfkmF1JiLj/COI4vyqMPAggBAAA=
X-Change-ID: 20260908-qcom-wled-backlight-fd9574027353
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Helge Deller <deller@gmx.de>, 
 Kiran Gunda <quic_kgunda@quicinc.com>, 
 Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-fbdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2302; i=david@ixit.cz;
 h=from:subject:message-id; bh=BzNNDlBWbA+colU9cHYIGrzDI7xXs6eglG9+G3j4eW4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqqDl3L6sHmxx3RbQizlaqI6YKplobnHS/DSIcg
 sW1D/KZTICJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqg5dwAKCRBgAj/E00kg
 cszcD/9ERKvMkRVLn6ngBc7mKvxrcqi+6gNqjRnFXkQTvrusr1C6zjnAciQn5ey1ogPlr/9ANTo
 3+Weom2qtAdXqQ2mwOwCCJYdqu4Cu6X42RLUAqQFxlPhUxWd5Et2HBg5Lf68jWpVgl8hpnh4a/g
 P6hOzUD00MsvtBaYSRDTCyUwfqpEAFYnoxY2H9coTIQ9CKdv4hZv0Rir7cf6ojCjLL+qQ+kHoHE
 aKrjirirj02PKlFWCxFE3/MP7cDGLXAVq8pgbCNP361Fq4P74AGhopO1xUuOnTp4tlHtv77W7A0
 DbteXpyqVu7LSc7cJ3MeHnEVNSvdX8EUGgBC3hsOEQ/JUV2HyrKQDaRW1+NFU5AAY8DSXaTYiLL
 3AgM8U3BRxYziL16TvcRPbB/fb2gkWOcVExtcLDH7G2tscmf1f86n9J8wMUWgcCyWs0aLtTNBhE
 m57XpkLfwQKtqPrDDRF7Y9hqJ7PIexwWxS6ri+9JbQG+g0cL7cNJeEpciKyEamrO2If5me/e88f
 ugo0kX0++PpaPsOA1DnhzfOp+8pbzZC7C7X62a5b6tqqYbCEXeZYdK3L9mCy3pIik91ZzVeAsjn
 M+y+QBikj2EA7mw8gnvHx/x57bqJIGOfHYc74HLyOQ7vERR7yC7ndMIVwYF48S5zwWqBzN+3nu+
 OExcb3qi1qwy3mg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The qcom-wled OVP interrupt is enabled at probe whenever the module is
already on, but the driver still believes the backlight is off, so the
first brightness update re-enables the interrupt and trips "Unbalanced
enable for IRQ". sdm845-mainline has carried a workaround for years and
Joel posted a flag-based version last October [1], which Konrad and
Daniel asked to be replaced by something that does not track the IRQ
state by hand.

The first patch is unrelated and fell out of writing the readback: the
WLED3 brightness register stride has been one byte instead of two since
the 2019 restructuring, so multi-string pm8941 boards only program one
string correctly. Untested, I have no WLED3 board; it restores what
pm8941-wled.c did and matches the downstream leds-qpnp.c layout.

[1] https://lore.kernel.org/all/20251021-qcom-wled-fix-unbalanced-ovp-irq-enable-v2-1-7ff115b4ffe7@joelselvaraj.com/

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Fix typo 0x10 != 0b10. (Sashiko)
- Added fix for a unrelated issue, but since reported as critical, let's
  squeeze it:
  Missing platform_set_drvdata() in wled_probe() leads to a guaranteed NULL pointer dereference in wled_remove().
  (Sashiko)
- Link to v2: https://patch.msgid.link/20260914-qcom-wled-backlight-v2-0-a908d9233e93@ixit.cz

Changes in v2:
- Add a fix for the WLED3 brightness register stride.
- Add patch reading the programmed brightness back via
  backlight_ops.get_brightness. (Konrad)
- Note the brightness readback is done in the follow-up to the first
  patch.
- Link to v1: https://patch.msgid.link/20260908-qcom-wled-backlight-v1-1-c4dd4eabda07@ixit.cz

---
David Heidelberg (4):
      backlight: qcom-wled: Fix NULL pointer dereference in PM callbacks
      backlight: qcom-wled: Fix WLED3 brightness register stride
      backlight: qcom-wled: Fix unbalanced OVP IRQ enable at probe
      backlight: qcom-wled: Read back the programmed brightness at probe

 drivers/video/backlight/qcom-wled.c | 89 +++++++++++++++++++++++++++++++------
 1 file changed, 76 insertions(+), 13 deletions(-)
---
base-commit: 944a035ecca915ae947905dcfb03f2b9dc6d032c
change-id: 20260908-qcom-wled-backlight-fd9574027353

Best regards,
--  
David Heidelberg <david@ixit.cz>

