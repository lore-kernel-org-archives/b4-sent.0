From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/2] Enable DW9714V camera focus coil on SHIFT 6MQ
Date: Mon, 03 Aug 2026 11:50:24 +0200
Message-Id: <20260803-dw9714v-v3-0-8e10278dcd0d@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02Myw6CMBQFf4V0bU1ftNaV/2Fc0PYidwOmJRUl/
 LsFE3E5J2dmJgkiQiLnaiYRMiYc+gLyUBHfNf0dKIbCRDChmeKahqc1XGWqaq2VrsGBCaS8HxF
 anLbS9Va4wzQO8bWFM1/Xb8MI+2tkThmVXhnrpG9Pnl1wwvHo32QtZPFnSbZbolihDg23oL1mb
 reWZfkA0prp+NIAAAA=
X-Change-ID: 20260416-dw9714v-4566465ebe7d
To: Alexander Martinz <amartinz@shiftphones.com>, 
 Bjorn Andersson <andersson@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2805; i=david@ixit.cz;
 h=from:subject:message-id; bh=cVzOXoqHWElvHxAsyTqe++YltZpP6gxzcvGwKwDVAO8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqcGRh6tl1Gk+pFiuCo5FeWsAI4Ka1hJ5TnYL0j
 8+soCx4pRSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCanBkYQAKCRBgAj/E00kg
 cgsQEACJxN+IMjwWvkp4req9uh2S2MOWV+8vR9o85eTzMZI5agjk7l3J4y30rpoEm95erfA/Kv+
 0mzZGycenajJ+Hv+sfprIh/9DNzWi1mis//pjsh3TsnN6jk1N0Aw1AdyReUPzfqDyVTxHTuKsAW
 cG0AwdkiDzgvZdU3a3l9kwaxW61nOYAvkYGzGVqkJDlcZWxLBAlRlQwLuGYf3KmJqI6FG/ZbbE+
 qkF2gEUb0Rciav1lGH3bTASmeNpRwLzZZnQN5T4/Z1CZW+XSCk95W9YDRqo8Tg9jRm7RQ+U9Vta
 Um1grW+ciCjvOSkf09qmrQEg82rC7ATmtafGrqYJ9o/GricFGd50oLxQm3LXPyfRKO41v1Rat2t
 +2dZwC/l/Ae+xTdkz1+MnrFSNqtn1Swgv8mApaMy+4CVkx0wahPytbrnoajBN5109TYVWGo39t6
 iTaIo8Nmcrq+YNViEbUxU9Sw1u0fCkHrJR65iD7CKkSIFMu/l81V0afkiqYGeoD2CM2YNvcFnoI
 mUZnm+u55jAO+7caXFdlmY+HptSXqqGU91IvFerHH25LNAzrhIaObNjx+lkoMFstNw2aI46nwdd
 sQkiIjr+vl8El6hZ786CZTAzwmUD//1eka032n+XgcnU/xxge2Z8DaQ3uZjr2D8lUdKo/g/rMGi
 ykUvmQ524rLLu7A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implements wiring for:
 - SGM2036 linear regulator used to turn on the focus coil [1]
 - Dongwoon 9714V focus coil used by IMX519 camera sensor [2]

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
David Heidelberg (2):
      dt-bindings: media: i2c: dongwoon,dw9714: Document DW9714A and V variant
      arm64: dts: qcom: sdm845-shift-axolotl: Add actuator for main rear camera

 .../bindings/media/i2c/dongwoon,dw9714.yaml        | 14 +++++--
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  | 48 ++++++++++++++++++++++
 2 files changed, 59 insertions(+), 3 deletions(-)
---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260416-dw9714v-4566465ebe7d

Best regards,
--  
David Heidelberg <david@ixit.cz>

