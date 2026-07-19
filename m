From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v5 0/2] Add initial dual front camera and rear flash
 support for Pixel 3 / 3 XL
Date: Sun, 19 Jul 2026 20:03:51 +0200
Message-Id: <20260719-pixel3-camera-v5-0-99593f1bd8ec@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIcRXWoC/33Qyw7CIBAF0F8xrMUww6Pgyv8wLgBHJfFJa+Mj/
 XepmqhduLwTziW5d1ZTTlSz6ejOMrWpTod9CXo8YnHj92viaVkyQ4FGSND8mC60lTz6HWXPvXP
 WhZW2jogVc8y0Kg/6vvmi5E2qm0O+Putb6K+vJgUwaGqBC46VrowwGnQws3RJzSTeWN/T4l+Lx
 SoI1jofAqj4a+W3xaGVxRKaIJzwBkD8WvWxFbihVf2/NvoAKI3V+LHda4xMp3PZtHkv0nUPoOZ
 ef3EBAAA=
X-Change-ID: 20260315-pixel3-camera-a9989bf589ee
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1946; i=david@ixit.cz;
 h=from:subject:message-id; bh=9IK7s2pPNUfDsWJGspBxUn6AiQyUzX4A9mk6XW5ob/I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqXRGK6x+kS5ZKp+BykqFFaTFnPKfntJ9N+eyRL
 ZfM8iS7uK+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCal0RigAKCRBgAj/E00kg
 cljrD/0atHf6ROhLCReAiBODQvK9PYgrzTDheFfwThVEdTTBsw6Ov+B383VnOEscKme2KWFo/LT
 faQ5p37yJ9imksgQlWy5DsshIauT04emgd3K8sVTG0mHBVSE8LswD+d2IQIWxJUDZz1Ku56y5qG
 Dnuj61Z9SkSJPYiEX4urTO5ViGY/LndSYLkB1qym5CgZjRqeXGnwFl85bdsZy6rg1UUIyvs0+XW
 812EBozUrikO5CfyXiULYXK27keLs+2Nzn+MH2j4qi7wa5FpSZ8qIQGtTxvEfldDOlZVmS5DFU0
 Uj/d7ySPcAEUHtZ526IxMcc0gDeX/szSXBFupZ2Adi7xxmGJt868FhPAzJPpDe5dsQA7T6vVSJ7
 btzXcDn2GbXfIVmuGOp2IWLwRFxZswL57BZfugtbwBDzeVZL9N2zvm2M3NfeEf9q4ILbyJ/O8ct
 gf7WKhiTJoyVN+Gh2E2+r59Pgvwg6JeCjxGzaFghULh2OqH3dfcIkzunlFeZ1JEvKZGao6fSK5m
 4XY23yJlht1/wToxmqySB25dzan5wUCXrJZIwj/3PfGKhLEe/bHaeKrXxIM5VOHeCSILtRPA6mi
 IAL5bKgl3CSlBYlGNvg3zVhZvSLxnkKfT8zvS3Ic9tORj9OzmB6VEjAATYtI4ymn/akyOn3zfaK
 0OtBkrifVYPKkRw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the dual front-facing IMX355 sensors (standard and wide)
and enable the PMI8998 flash LED with hardware-accurate limits.

This brings up the basic camera topology and flash support in DT.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v5:
- Added function-enumarator to flash LEDs. (Sashiko)
- Dropped l22a regulator needed only for NFOV actuator. (Sashiko)
- Dropped vdda-csi[0-2]-supply, as it was unused. (Sashiko).
- Added previously omited cam_mclk2_sleep sleep state.
- Link to v4: https://lore.kernel.org/r/20260719-pixel3-camera-v4-0-48cab1236852@ixit.cz

Changes in v4:
- Use 24 MHz ext clock for the cameras, as the downstream does, since
  the upstream driver can now support it.
- Added additional LED, as the phone contains two separately controlled
  white LEDs flash (upper and bottom, in one module).
- Increase flash-max-microamp, as I took wrong "flash" from the
  downstream sources and dropped Dmitry R-b.
- Address formatting issues. (Konrad)
- Link to v3: https://lore.kernel.org/r/20260412-pixel3-camera-v3-0-e26b090a6110@ixit.cz

Changes in v3:
- Dropped cam_vio label. (Dmitry)
- Move the MCLK2 pinctrl from cameras to common camss. (Dmitry)
- Link to v2: https://lore.kernel.org/r/20260411-pixel3-camera-v2-0-41b889abb14c@ixit.cz

Changes in v2:
- leds.h include escaped the initial submission. Fixed.
- Link to v1: https://lore.kernel.org/r/20260411-pixel3-camera-v1-0-2757606515b6@ixit.cz

---
David Heidelberg (2):
      arm64: dts: qcom: sdm845-google: Add dual front IMX355 cameras
      arm64: dts: qcom: sdm845-google: Enable PMI8998 camera flash LEDs

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 197 ++++++++++++++++++++-
 1 file changed, 196 insertions(+), 1 deletion(-)
---
base-commit: 0718283ab28bc3907e10b61a6b4be6fefa1cbb2f
change-id: 20260315-pixel3-camera-a9989bf589ee

Best regards,
-- 
David Heidelberg <david@ixit.cz>

