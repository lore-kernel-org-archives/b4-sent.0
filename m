From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] Enable DW9714V camera focus coil on SHIFT 6MQ
Date: Thu, 30 Jul 2026 00:20:11 +0200
Message-Id: <20260730-dw9714v-v2-0-d5da19e6c60b@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/z3MSw7CIBSF4a00dywGKAVx5D5MBxZu7Z20BhrsI
 +xdrInD/+Tk2yFiIIxwrXYImCjSNJaQpwrc8BifyMiXBsml5kpo5t/WCJWYarRWusEOjYfyfgX
 saTmke1t6oDhPYT3gJL7rzzDS/o0kGGe1U8Z2tesvjt9oofnsNmhzzh/xJ80hnAAAAA==
X-Change-ID: 20260416-dw9714v-4566465ebe7d
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Alexander Martinz <amartinz@shiftphones.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2286; i=david@ixit.cz;
 h=from:subject:message-id; bh=SM+C+4D3QII5K4h++lt5vXe7ftd2vOxIN2k+JJzztJ0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqanycnLGolyiutlmsXOJd3dXtTGWZMpljgVx3q
 RtH9RYBuumJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCamp8nAAKCRBgAj/E00kg
 cg4cD/4yTQNDna7oD8Rn6UG6yQ30o82SFpqRTn9yBWYJ/Ls9JNEVhfTqXLlRJKe6pL/AFU+TBxR
 V9g0mpIyz+RrhkRXQsDJzPkBXx38s53ZHylwZK7bdXDthglcHhPuFuTrm2fM3GJZ2oY2cKrWXgj
 KKDJ4TXYhmkJczi4FjuHX623zG4JJgME04DRFeoCjnzyl/KH+McwPzOttycIRbWbyEwQg5Xamos
 9VK/R//pGq6Bg8HMe1N1ILHA0uAhtwxBOgY6Dq+nGTLur4Q5z0EsQso0hMfZFVaxyDK3J6JFXrX
 8FPBV1Ywtc97CCuFvr0piCLUtDxEDqJsuKQE4blLL4EASK4FfrygHwezukOMQ3Vc7/sbpIMFPuy
 l57xWGWewRHJN9vrnRLVNTWbLsPRaqRP39kynkati1pvzPkpY9BZQcv+exXI9gMJ/CYbqZ8XFjo
 u5Vq0OEoo+YZhgNOYkXcSS18lJJU6wW2qhbg0zloEDiBWaO8Tyij5xrDLilpGikbyzOhJijfjaQ
 HAGl1MJbdda2zmsUnLg+oOsgFG0/FFFqQzN48h/usPBL/8EOzMumCb/6Rcw6CF2dn35Y28mY1hJ
 c6HWo37sfIwELWEQaMS8FG6ItgAfJHm/Gv7f5t9OFWwrkDC+E/rSw1g4UDkotIUujT/sDSSPYuc
 IcBLuUkYjZFDQQw==
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
Changes in v2:
- Address Sashiko findings.
- Link to v1: https://patch.msgid.link/20260729-dw9714v-v1-0-3c479b3cf8c0@ixit.cz

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

