From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] Add initial dual front camera and rear flash
 support for Pixel 3 / 3 XL
Date: Sat, 11 Apr 2026 12:12:01 +0200
Message-Id: <20260411-pixel3-camera-v2-0-41b889abb14c@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHEe2mkC/13MQQ6CMBCF4auQWTumLbZQV97DsCh1kEkUSEsIS
 np3i+5c/pN53waRAlOEc7FBoIUjj0MOdSjA9264E/ItNyihjCilxolXepTo3ZOCQ2dtbdtO15Y
 I8mYK1OWH3bs2uXuO8xheX36R+/UnnaT8kxaJAlWlKyOMlro1F155Pvo3NCmlD4dHHG+oAAAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=890; i=david@ixit.cz;
 h=from:subject:message-id; bh=DLOxbxkuhfRrndcN7Pp5N2eb7duuklgQrYckDIDbI0s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp2h5yHbY9dH0lvE0VfYTk/4S24aBifMgf50F0+
 1ojp091LzWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadoecgAKCRBgAj/E00kg
 ctlKEACG0RG2U5WBXLLDbuCpUaNeRVOiZvCkIRRBRJxM9QQzTEthaaa7wq8hItNc/AiKNmO+hSv
 T6nFnV2w8xzhaZjilYfgAs2dNGti5YJrViyfCfOm2GSp1eOGtC7RxJeO/ECNnXVipvrA3EEv/KC
 +V0ydCoVNRIxHyoK3R7LLqEOw46GvSK6mMHbCNUFmqU6ciapKcl4tlTw08S/18ZrptmU8Z9uRUj
 wpKvmvCVuAdA2exbiL7kV7KIFnTkfTp2liGDs57AG3EKjY7n1jdAIExaMb8VrRyKrMH0wMD6zk4
 J7k3fmsj0RgHziQn0aEgKBaJwnEaDVv4I3kdEq4L9iWKovaKLmiXs4X5F5timOyZYtqvwUyrOir
 pCkY/zDIeaNsxhZHcC+2mfFCjOe7DflVgRJMUsE6eRM4igFnKhQ3jHlQT5OilVT0kRDQQ7iBmLm
 iWaWJcl2Bh+QB7MPqh5tovRaryafO3EQ+bU/bKtNDYi2nJ+aW+jZ72TTbQmQq1GFtzqlYbZqG/y
 Qq8diq53lVy8IGDW2v0D3vME9nRc/7jpE9/kZxSpr/e5wVR0o5CbvaWPbOsfTxmTaF9LjNI3qMv
 WPXnWPw0YV2aLAr4Q3WPnK+cdMbjJfEJOihk6YiqxT3jX3i5sACx3/0reZvmPexzXICVitjthF9
 o2okzcb/6dMfKcw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the dual front-facing IMX355 sensors (standard and wide)
and enable the PMI8998 flash LED with hardware-accurate limits.

This brings up the basic camera topology and flash support in DT.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- leds.h include escaped the initial submission. Fixed.
- Link to v1: https://lore.kernel.org/r/20260411-pixel3-camera-v1-0-2757606515b6@ixit.cz

---
David Heidelberg (2):
      arm64: dts: qcom: sdm845-google: Add dual front IMX355 cameras
      arm64: dts: qcom: sdm845-google: Enable PMI8998 camera flash LED

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 201 ++++++++++++++++++++-
 1 file changed, 200 insertions(+), 1 deletion(-)
---
base-commit: db7efce4ae23ad5e42f5f55428f529ff62b86fab
change-id: 20260315-pixel3-camera-a9989bf589ee

Best regards,
-- 
David Heidelberg <david@ixit.cz>

