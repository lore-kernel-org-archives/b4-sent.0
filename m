From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Enable DW9714V camera focus coil on SHIFT 6MQ
Date: Wed, 29 Jul 2026 23:53:08 +0200
Message-Id: <20260729-dw9714v-v1-0-3c479b3cf8c0@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDE0Mz3ZRyS3NDkzJdE1MzMxMz09SkVPMUJaDqgqLUtMwKsEnRsbW1AA0
 HLx5ZAAAA
X-Change-ID: 20260416-dw9714v-4566465ebe7d
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2151; i=david@ixit.cz;
 h=from:subject:message-id; bh=oYUP+Vnff20ntgLnvHo60QOZ87WDo1RjdNjMn2rOI/s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqanZGT4yuviAXM6et2q4veAeQvdBVKomBvYnWx
 3h7Dpd0gqyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCamp2RgAKCRBgAj/E00kg
 chWNEACN7rsLP2gi4i+3pyVwXWd1subptuyXbin6eiSrR5h4Dh82gTnjoDA+4rW5wEedPhWcn0/
 KSU/OESMA8nRVZ0Avj0ko1n0pFmMzLZgsk3yu2zOdC5xncGJ7DOIb3g4SmVgvDCNlk/y+qobXxw
 d0ymhh9pwdaJGd8XvTGqkrcEbiJm52qbvBTzHVkbkLSqsgfkPTh5xZs/SSRq7co+B4neRcbAyV5
 Ss46dhNYpLX8m32iQAwIok6DWcOceZsHj6YyyXQ38ROirLr9KUxffz9PwsjnH7luzRqbs/7Q6Ht
 Ts4LIXYn0mVvTS7KEaYe1Qjzd+DOVEF7N10PKL+DMgbIPSJ2R9ySdgBofDMX8TR9q064e0S2U/S
 wRDzuoaLSm3N3up3A5Ug2K8FeAGTqhYiy0/TX++lsFGo5qMi9BRteeexJUPERaUYGr5jUku3L+N
 xhS0DdnpPwBMhtKOh/5G7aiRwjvI7NOgbCKHMKZzea2duYqvARvz7OkOoYVR8UBi4zIJT5ukM0L
 LI5PZLpq2GoQzC5F5hTI1DZVhDkKdDVC0mEyXaEWyt1LFlqvzyhA2YvUjKudH8HnzEjsfcRvUeQ
 1LBgK3lrubpe3Tz5I18T53m9Oqe+YqOb/UY+50GKn+g9chME+NQ4av2bOyjvmX1N+NzpbqLzM1p
 K1eWLO12M4OQ79A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implements wiring for:
 - SGM2036 linear regulator used by the cci i2c camera module [1]
 - Dongwoon 9714V focus coil used by IMX519 camera sensor [2]

[1] https://www.sg-micro.com/rect/assets/efa85993-263c-41aa-9274-b488f59f85d5/SGM2036.pdf
[2] https://datasheet4u.com/pdf/1247146/DW9714V.pdf

Open question for future work: modeling the I2C bus supply.

Like many similar chips, the DW9714 has a single VDD supply, but its I2C
lines go through a level shifter to a 1.8V rail, and there is currently no
place in DT to describe that rail so it gets enabled during I2C access to
the device. As a stopgap, this series models it as an always-on fixed
regulator (see the TODO in the cam_bus_2p8 node).

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
David Heidelberg (2):
      dt-bindings: media: i2c: dongwoon,dw9714: Document DW9714A and V variant
      arm64: dts: qcom: sdm845-shift-axolotl: Add actuator for main rear camera

 .../bindings/media/i2c/dongwoon,dw9714.yaml        | 10 +++-
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  | 61 ++++++++++++++++++++++
 2 files changed, 70 insertions(+), 1 deletion(-)
---
base-commit: 78bc8af4affb9a732504eb22eeac7d1e50883853
change-id: 20260416-dw9714v-4566465ebe7d

Best regards,
--  
David Heidelberg <david@ixit.cz>

