From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Subject: [PATCH 0/3] Add support and enable the debug UART in the Pixel 3a
 and Pixel 3a XL
Date: Sat, 28 Mar 2026 23:49:13 +0100
Message-Id: <20260328-pabloyoyoista-debug-uart-on-rdacayan-next-v1-0-0babf584acdb@postmarketos.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOlayGkC/32OS2rDMBCGr2K07hi9LDsmlN6jZDGSx65KLKeSX
 BJC7l7Z6bKUWQwf/K87SxQ9JdZXdxbp2ye/hALipWLuA8NE4IfCTHJpuJIdXNCel1s5nzLCQHa
 dYMWYYQkQB3R4wwCBrhnMQbZaNZ2jUbOSd4k0+uve9X56clrtJ7m8FfwqIn2tZUR+ypjFROCWe
 fa5rxo9HowZjbKq3eQzpYT7wr467gOlaDmXrepqoVSjNAiY0Z99mCIOHsPbtGFdAl//DlCC8+2
 bWhgt1H/+0+PxAyVagEM+AQAA
X-Change-ID: 20260328-pabloyoyoista-debug-uart-on-rdacayan-next-69274358cef4
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2201;
 i=pabloyoyoista@postmarketos.org; h=from:subject:message-id;
 bh=Bw62XKiLztflw/Q8k1Vk0tX6CpJo4mDwtAvso2G1Je0=;
 b=kA0DAAoBejQlZf9jX3kByyZiAGnIWuugX1IvvbIoQW1giGjL1ZlcZW6vbSZrGdhg69624MCYJ
 YkCMwQAAQoAHRYhBL0KF5RKLqj/KRMJono0JWX/Y195BQJpyFrrAAoJEHo0JWX/Y195XqYP/i+q
 FnzgTPyS9/qV1lBbWeS24iPrmXgNZrdyBq5wHJIOUnChI9piXbg+ouoUIvVeL0hHANaKuvLILQh
 tRYYdUFpxgkNjMOcISimpoUt7IonZr8HsArGd6TgJohu2FUPkbJXhlIIA3PqfRGl+90MKeoWRTE
 ReHrejVLA4TYb+rz2f9io53gTfilIodZ8a25EXvLK9y0LK1O4lWrgF5nAz2pg9YhKad1GjngWga
 8A3NffOM2Oqv1PIF86kRamo6YznFnljTPtHvduQ7BnDtkjf0nsRp1UbSdK7JNXLA0ymLJ49hcH9
 cWmqktyk6jZ/qEXHSa0+KQG7zdT6MrCpxBJsklg781MMo9rb8UwEBMNq4XaRwmNpc9sZz0WKYq6
 fJTGstnH7vFU/cKEuoR6atM9o5uyT3xz7T4Sy++tYBygdKM/cIAOOisbAhQ5/XntEs7yauq36bl
 zClXwaQ7YyG3pYbBocPw40ucTkletrWA0oLDRdX20coa+0EOtCJklvms/7dEK7HCIrCWkjxQBVK
 xX1cxBI853zbQ2tsGxG6V4zg3L2eYAisC7VN8n625ejYZJRqliOhtM81agNwx9qKEsE7pQeBdyp
 fFJVP6nz44mynbOd8dqYn3PRidpvu6lJNDPEhbgFGoFoJNV0e4FYFSjWnlyffswD/E4yarXRKQU
 2tJ48
X-Developer-Key: i=pabloyoyoista@postmarketos.org; a=openpgp;
 fpr=BD0A17944A2EA8FF291309A27A342565FF635F79
X-Endpoint-Received: by B4 Relay for pabloyoyoista@postmarketos.org/default with auth_id=698
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to get logs through the SBU pins in Google Pixel devices, it is
necessary to add support to the devicetree, and enable the corresponding
UART. With this code and an USB-Cereal board, I was able to get full kernel
logs through serial.

This series depends on the patch adding a sdm670-google-common dtsi for
dealing with both the Pixel 3a and Pixel 3a XL:
https://lore.kernel.org/all/20260310002606.16413-5-mailingradian@gmail.com/

This is my first patch sent to the kernel mailing list, so apologies ahead
if I missed something in the documentation.

Signed-off-by: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>
---
Pablo Correa Gómez (3):
      arm64: dts: qcom: sdm670: add default uart pinctrl nodes
      arm64: dts: qcom: sdm670: add debug uart soc node
      arm64: dts: qcom: sdm670-google-common: enabled debug uart

 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi |  18 +-
 arch/arm64/boot/dts/qcom/sdm670.dtsi               | 207 +++++++++++++++++++++
 2 files changed, 224 insertions(+), 1 deletion(-)
---
base-commit: 54f966f63b379d0c62bb044b7903319776443a4a
change-id: 20260328-pabloyoyoista-debug-uart-on-rdacayan-next-69274358cef4
prerequisite-message-id: <20260217002738.133534-1-mailingradian@gmail.com>
prerequisite-patch-id: aeaea0c438bff770d0c4c33d937db5706d642daf
prerequisite-patch-id: 11ce654ef61d48fdebf1c4e1d9d184cfb7bcaa59
prerequisite-patch-id: c6203c8a71fe103b983b6ba5fc99a22948118fb4
prerequisite-patch-id: f9ff17c7e4b4396850f51e45249d2f6e35df3725
prerequisite-patch-id: faab09f9fe421a6358e5512c6050dd70d3271273
prerequisite-patch-id: adb88e3ddcbe33db1e3fc60ea4cb195dac18a8b4
prerequisite-patch-id: 0c8f7fc0835cdda72529fcfa7b654bb97109fae4
prerequisite-message-id: <20260310002606.16413-1-mailingradian@gmail.com>
prerequisite-patch-id: eb2d2be6edae3d09973b49f3ff6c48fa0845e7e0
prerequisite-patch-id: e6d9e56eaeceddee68d56e2ec8ac20997bff52c9
prerequisite-patch-id: d5e2975adf904bf656827100df7989218ac9e963
prerequisite-patch-id: 04478351b1304dfe1357d176c8d0c235346ca40f
prerequisite-patch-id: a54db56ccdf1491c46158a84ac1cae70f74bb36c

Best regards,
--  
Pablo Correa Gómez <pabloyoyoista@postmarketos.org>

