From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/2] Add initial dual front camera and rear flash
 support for Pixel 3 / 3 XL
Date: Sun, 12 Apr 2026 18:35:35 +0200
Message-Id: <20260412-pixel3-camera-v3-0-e26b090a6110@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANfJ22kC/32MwQ6CMBAFf4X0bE23UGg9+R/GQ1sX2USBtKRBC
 f9u0YOJB4/z8mYWFjEQRnYoFhYwUaShz1DuCuY721+R0yUzk0LWogTFR5rxVnJv7xgst8Zo41q
 lDSLLzhiwzYetdzpn7ihOQ3i88wm29VOqAH5KCbjgslFNLWoFytVHmmna+yfbOkn+dWV2K3BaG
 +scVP7rruv6AilfuTjkAAAA
X-Change-ID: 20260315-pixel3-camera-a9989bf589ee
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1098; i=david@ixit.cz;
 h=from:subject:message-id; bh=deJQpNs6ALPeKIlykEXREju1UIhgKemiktnv501SrPk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp28nXBFQ5zHFQaWkVRpBHA23Fh/2PO2mpxgWZW
 jvDgRaQG+eJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadvJ1wAKCRBgAj/E00kg
 cuz+D/0SS0eSY2cFa8oDl98LdvWSsh46+KqVtoaslS7Fg63HoXsJnDxpjRJHFX/v+TKgWM4/Hab
 V/f8mg/so646QfOpyBlpOM4PoZkpSdflBoR791EPWbYhAT7oEU7qZkKiRhWSrEwT3ceUUroyc7E
 eMv8X+zhkeISMjTUhiql7HPxEtjS7Zis2nzOuuS56Ih4HoZkYjVDlKw4gwgtekzZKHd2jBY86Ry
 l//7ictBJ9Z//zUO31DRrwByv8WyVmIILLXvaHISBuJuXwEHDitthtFdWEnDmhJw3OPuvW7YZbb
 /qWtTjmBoBgdYN1aArbeKLABUIN4wOJV09YElgRwJbeH5Lkr7cUCnHIqGrYXLi3hXXGU7PgZ0E4
 QvY3jVVXhPf1ypQnfT8CqL7vuSgbyVrYiM3D5z+ahXRGeNx+AnKk9f62ZqBqX1FmKKLSiavTxgc
 tc1yaQVvZSXlZ1uA1tqrd1b549C9nZR3TuxN6kdjjnwTyFEYN2hp+OduXEhbZY3xkpCGDrqO3nt
 V1Idd/ACam8ME1buPKLxcYLD78kXDqdaeJlUk4E+VGimRtx6DFJnL6KSZtHTHK0scdO5TCXSL5a
 +71OBGIfmiw8T7mO6ZyaEb2GNZpc5juLVlOZyXLnjc3OZ5QhFUFCHO35XeU9dCqfl8KiNDNT4+F
 wgrYQehnsW5ZCAQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the dual front-facing IMX355 sensors (standard and wide)
and enable the PMI8998 flash LED with hardware-accurate limits.

This brings up the basic camera topology and flash support in DT.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
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
      arm64: dts: qcom: sdm845-google: Enable PMI8998 camera flash LED

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 207 ++++++++++++++++++++-
 1 file changed, 206 insertions(+), 1 deletion(-)
---
base-commit: 66672af7a095d89f082c5327f3b15bc2f93d558e
change-id: 20260315-pixel3-camera-a9989bf589ee

Best regards,
-- 
David Heidelberg <david@ixit.cz>

