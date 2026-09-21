From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v4 0/4] backlight: qcom-wled: Fix OVP IRQ imbalance and
 start from the hardware state
Date: Mon, 21 Sep 2026 12:46:21 +0200
Message-Id: <20260921-qcom-wled-backlight-v4-0-bab8c7ef73cb@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43Nyw6CMBQE0F8xXXtNXwJ15X8YF6W9yPWFUsRX+
 HcLLtTEGJeTzJy5s4A1YWCz0Z3V2FKgah+DHo+YK+1+hUA+Zia5TLjhGRxdtYPzFj3k1m22tCo
 bKLyZpprLVE0Vi8tDjQVdBnWxfOZwytfomp7qGyWFpqqvw20r+t7vh1aAAKe912hzb3k6pws1E
 3djvd/KN0Ho74IEDjb63kil0KhPQf0hqCj4xBRoMq0yLV5C13UPinWQCUoBAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2942; i=david@ixit.cz;
 h=from:subject:message-id; bh=dswMCVWk69SqXPG+rhoT9B3P5QaoF6XoSY5Y1WH7cc0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqsQr++Qskohu/NoPUViM/Xnk4ZG3uJpJuUybj5
 yyYXTm1AsOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarEK/gAKCRBgAj/E00kg
 cpH9EACra0QFYoHrS1Yjszh/axxwX/h6rI35LsVlMTojnr38RvSmntCUM3j4CeQJLiXp/2jFlyl
 KsENmnXSftVWoCAvvrFrMu+zAG1W+/BeX9LsjDkToTqv6JL9TJ06IBMQA9Dep8jcf/DAdpf5S1u
 bA+Xs/XRP4wsHoar3vZeFjlIrpNLJwStYokEcC6fjm5RM3xH3lOp5Lwo/MZJSjdsglMHJuvHwfH
 NMgQA4eXKMR9nsVAYeOkSCBSna/DmJxYTIbOQ7TYABSN5dYYXphi++t49lRnWAix7uNA9seCbbh
 6u/EdmWUUQ1hZnTT3o3ezcR1c0UBd6Y1P+fANrRhTfEwD+Mp1cr9LvCWYwW4ZVQGiBpeBQsPpas
 D7R/wmFqgFTmf03DM02XKvnseeZ00sk+wDM3Lb8ZUzBGqoOSFwU38g+NxSfiJQOS16qggWNIDPP
 468gVzzN9JKu3y0eD+nGVy5S4eG5WEujnasCrpqSGAS+6SDYXEW4gIPdUc5LzMDni/t6qxA4uMz
 xaYdN/aVqngpUneD1F0MDGFsFDrKqI+iFcORfWK1r5TMHKvBRXXs+iomkxosx0xtDZfOZdaBzLg
 xUX/j3y2i0z7tnO21jkrK84rJQ8e0/1Opu1xv0YoFdgoQqBXQ5kIWsjIfFcQ4GewGRr79eA60Ha
 tfxlKl0In9XBo8Q==
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

Patch 1 is the drvdata fix I said I would drop after v3. The objection
was that it stored the wrong object, not that the fix was wrong, so it
is back with the right one stored.

Patch 2 is unrelated too and fell out of writing the readback: the WLED3
brightness register stride has been one byte instead of two since the
2019 restructuring, so multi-string pm8941 boards only program one
string correctly. Untested, I have no WLED3 board; it restores what
pm8941-wled.c did and matches the downstream leds-qpnp.c layout.

[1] https://lore.kernel.org/all/20251021-qcom-wled-fix-unbalanced-ovp-irq-enable-v2-1-7ff115b4ffe7@joelselvaraj.com/

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v4:
- I applied the 0x10 fix too late, now it's fixed in the right commit.
  (Konrad)
- Right object stored in the drvdata. (Konrad)
- Set the drvdata next to the other wled fields instead  of next to the
  backlight device registration.
- Reworded the drvdata commit, the NULL dereference is in wled_remove(),
  the driver has no PM callbacks.
- Link to v3: https://patch.msgid.link/20260914-qcom-wled-backlight-v3-0-d69fe9843841@ixit.cz

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
      backlight: qcom-wled: Fix NULL pointer dereference in wled_remove()
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

