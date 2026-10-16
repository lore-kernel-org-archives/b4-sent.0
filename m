From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v6 0/3] Enable DW9714V camera focus coils on SHIFT 6MQ
Date: Fri, 16 Oct 2026 19:38:32 +0200
Message-Id: <20261016-dw9714v-v6-0-ae730c77bfb1@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13NTW7CMBCG4asgr2s0Hv+z6j0qFvGMU7yBKkEuB
 eXuNVTCoctv5Of1Tcx5KnkWu81NTLmWuZyObbi3jaDDcPzMsnDbAgEdGOUkf0evTJXGOmeczSl
 7Fu3115THcnmUPvZtH8p8Pk0/j3BV9+tfw2N8NqqSIDUZH5OmMRC8l0s5b+kq7oWKK6WhK2yKL
 Q8qZkcO0qvSXQXQXemmQlaAPjAx8KsyK6VWf5mmBkRPSTHG9E/ZlULsyjZlARP50egUxq6WZfk
 FlYHCU3QBAAA=
X-Change-ID: 20260416-dw9714v-4566465ebe7d
To: Alexander Martinz <amartinz@shiftphones.com>, 
 Bjorn Andersson <andersson@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3525; i=david@ixit.cz;
 h=from:subject:message-id; bh=5H1QB9WYNnigf90mqDI+c2B6y+uJDPLiS/IlgQY/w5o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq0mEZ8UQ+4RL2AikkjWdXtquhcBnRaJnKgalWS
 QCsqMfRkOGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCatJhGQAKCRBgAj/E00kg
 cnIUD/4y8iHJrDyCNg70PhzEudvGq7lWcxnCbBywUdLMouQbfTdO6ThVHYyZfoBX2SXYinnPdmF
 vYzOXtV3TAvU81SxwCnSChHYR78yH/WDORFjqHhztCK2e1xbm7ehpRJZKhAoEoXFKWwupdbBtzc
 ctJZ8HT7O8PacF42xqp8C4m/dYikPhSV8zM7dxlHRgi33F0RYfM0RSIcbyfSm09Thp1re1xXjwo
 3tWndzoabLQF3wgss9KJvis2VU6k914OW1HMd7TZIBIwQjCEVZPYTdlqJnYuTXYy6OMDxZlp3Jn
 Gr3zdNWgQ29+19MAnA4hLsSCwZW7rAdaxlzmQTHStOf+YukWVEkaTBXky+1cyDIsFtgVkfo7pwY
 tIUh1c4BmiZQXnwKLpFYA+F+/E6ParcYIa64R71Nh8qNIVuNF+t6NE/thxXwUQxBYwFFO8hpJOw
 I2+NZdeyR9prM99JzolG9s71CxD36XxJC4OWSQO24Np6B1kut0QzNIq3gjnJhESS+ZME+pbBdRc
 r1wyRMikXYu0AZAAcnwJm3/2eKeZHsB3fObMAg52j7VjYZyzPOGtdtIc7i4vqMDJxMRv//M34a4
 YbtIgHMwUV/eds8BPYrTaKgb7ioe6qS8hhT0wlG7fFxuiGk/FOPiDGPpOvGaYnEAO6/EKwiTVVP
 KU3H6UBrqDBpdnw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implements wiring for:
 - SGM2036 linear regulator used to turn on the focus coils [1]
 - Dongwoon 9714V focus coil used by IMX519 camera sensor [2]
 - Dongwoon 9714V focus coil used by S5K2X7SP camera sensor

[1] https://www.sg-micro.com/rect/assets/efa85993-263c-41aa-9274-b488f59f85d5/SGM2036.pdf
[2] https://datasheet4u.com/pdf/1247146/DW9714V.pdf

Open question for future work: modeling the I2C bus supply.

Like many similar chips, the DW9714 has a single VDD supply, but its I2C
lines go through a level shifter to a 1.8V rail, and there is currently no
place in DT to describe that rail so it gets enabled during I2C access to
the device. As a stopgap, this series models it as an always-on, see the
comment in the vreg_lvs1a_1p8 node).

Direction agreed with Rob Herring and Mark Brown on IRC:

 - Modeling the level shifter itself is overkill as long as it is just a
   supply; modeling the connector would come first if needed.
 - Since each side of the shifter has its own supply, the proper solution
   is a generic 'bus-supply' property valid in both the I2C controller and
   device nodes.
 - Defining it per-device-schema would ideally use an I2C equivalent of
   spi-peripheral-props.yaml, which does not exist yet. The pragmatic
   interim is to define bus-supply in i2c-controller.yaml for both places
   and add 'bus-supply: true' to schemas that need it now (dw9714),
   deferring the peripheral-props question until more shared device
   properties accumulate.

Once bus-supply exists, the regulator-always-on workaround in this DTS can
be dropped.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v6:
- Mostly resend, rebased against next-20261016.
- Link to v5: https://patch.msgid.link/20260822-dw9714v-v5-0-502bc7f43b8f@ixit.cz

Changes in v5:
- There is secondary rear camera with the same AF. Tested with the
  camera (not upstreamed yet).
- Verified the both rear cameras i2c addresses, added comment about it.
- Link to v4: https://patch.msgid.link/20260810-dw9714v-v4-0-a227cb1d29bd@ixit.cz

Changes in v4:
- Updated DT bindings commit description. (Sakari)
- Link to v3: https://patch.msgid.link/20260803-dw9714v-v3-0-8e10278dcd0d@ixit.cz

Changes in v3:
- Multiline compatible. (Konrad)
- Dropped output-low from avdd_cam pinctrl. (Konrad)
- Then dropped whole sleep pinctrl state, as it's same as default.
- Reworded the TODO. (Konrad)
- Dropped camss node. (claude)
- Moved before cdsp_pas (sort)
- Dropped unused regulator label.
- Switched the i2c bus shifter with the regulator VDD, as previously it
  was incorrectly wired and keep always-on on the i2c bus shifter.
- Link to v2: https://patch.msgid.link/20260730-dw9714v-v2-0-d5da19e6c60b@ixit.cz

Changes in v2:
- Address Sashiko findings.
- Link to v1: https://patch.msgid.link/20260729-dw9714v-v1-0-3c479b3cf8c0@ixit.cz

---
David Heidelberg (3):
      dt-bindings: media: i2c: dongwoon,dw9714: Document DW9714A and V variant
      arm64: dts: qcom: sdm845-shift-axolotl: Add actuator for main rear camera
      arm64: dts: qcom: sdm845-shift-axolotl: Add actuator for second rear camera

 .../bindings/media/i2c/dongwoon,dw9714.yaml        | 14 +++-
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  | 89 ++++++++++++++++++++++
 2 files changed, 100 insertions(+), 3 deletions(-)
---
base-commit: 2efb7a11f1aa4d2dc285fe2680cca22cb9f72f64
change-id: 20260416-dw9714v-4566465ebe7d

Best regards,
--  
David Heidelberg <david@ixit.cz>

