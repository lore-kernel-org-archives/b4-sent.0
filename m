From: Paul Sajna <sajattack@postmarketos.org>
Date: Fri, 27 Nov 2026 13:30:17 -0700
Subject: [PATCH] arm64: dts: qcom: sdm845-lg-judyln: Set
 regulator-always-on for ibb
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-judyln-ibb-always-on-v1-1-9e687e625afd@postmarketos.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ6CMBBA4auQWTsJrfwYr2JctJ0Bh5BiOiIQw
 t2tuvwW7+2gnIQVrsUOid+iMsUMcyogPFzsGYWywZa2Mca2OMy0jRHFe3Tj4jbFKSK1oaJwqc5
 U15DTZ+JO1t/2dv9bZz9weH1fcBwf8lCF1HgAAAA=
X-Change-ID: 20261127-judyln-ibb-always-on-d7c4dc843d55
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 stable@vger.kernel.org, Paul Sajna <sajattack@postmarketos.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811420; l=1748;
 i=sajattack@postmarketos.org; s=20250413; h=from:subject:message-id;
 bh=+pKkKHybW1iJ5KMQ7H1eBl6Hh5TX6R/S9mAl8MBd+AI=;
 b=R6MUGlBNXM9ybJeDKoWVCg7V9gzifYsRpCk6S/JdVlEeqn1bDMSytJ4hft/H4CqyzVFbVPQn/
 AlXOFCzYmiQAy+iJEpJmwiIT1s96rVTdTgST52bCX5R4aOhMuE2iwEv
X-Developer-Key: i=sajattack@postmarketos.org; a=ed25519;
 pk=ZFE/UBqiz9Wr8b+zBL27opOjw5x5ket5JFqks/VQGeM=
X-Endpoint-Received: by B4 Relay for sajattack@postmarketos.org/20250413 with auth_id=1505
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After resuming from long periods with the screen powered off,
the display develops hazy shadowy patterns at the edges, that may
even persist full reboots. It seems the current setup is temporarily
damaging the display.

This fix was previously proposed in [1], but rejected due to
battery/power concerns.

Since then, I have determined it matches the behaviour of the vendor
kernel. See downstream Lineage kernel [2].

I confirmed the linked line 816 that skips panel power-off is run
via adb logcat.

```
[Display][lge-dsi-panel:dsi_panel_power_off:816] [Display] Do not control LCD powers for LPWG mode
```
was logged.

[1]: https://lore.kernel.org/linux-arm-msm/20250916-judyln-dts-v2-13-5e16e60263af@postmarketos.org/#t
[2]: https://github.com/LineageOS/android_kernel_lge_sdm845/blob/16c83a1f965b45dc6707a5d5afdb0904b419aff2/drivers/gpu/drm/msm/lge/lge_dsi_panel.c#L816

Fixes: 2e7cdd400b6a ("arm64: dts: qcom: sdm845-lg-judyln: Add lab/ibb")

Signed-off-by: Paul Sajna <sajattack@postmarketos.org>
---
 arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts b/arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts
index 349faa123ff1..008c34fb1644 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts
@@ -120,6 +120,7 @@ &ibb {
 	regulator-over-current-protection;
 	regulator-pull-down;
 	regulator-soft-start;
+	regulator-always-on;
 	qcom,discharge-resistor-kohms = <300>;
 };
 

---
base-commit: a9c48428cbd8d96b26f92631d0db6f8519c5fcc5
change-id: 20261127-judyln-ibb-always-on-d7c4dc843d55

Best regards,
--  
Paul Sajna <sajattack@postmarketos.org>

