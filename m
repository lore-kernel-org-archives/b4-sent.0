From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v10 0/2] Add initial dual front camera and rear flash
 support for Pixel 3 / 3 XL
Date: Thu, 17 Sep 2026 11:46:19 +0200
Message-Id: <20260917-pixel3-camera-v10-0-df631279b39d@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33SzW7CMAwH8FdBOa9TnE+b095j2iFpnRFpA9ayi
 g3x7kthEm2QOMbK72/L8kkM3GcexHp1Ej2Peci7bXmAfFqJdhO279zkrhSEkspJDbbZ5yN/6KY
 Nn9yHJhAhxWSRmEUx+55T+TAFvr6V9yYPh13/c8kfYapekwxAlTRCIxvlrXfSWbDRveRjPjy3v
 2LKGdVDq4o1EBEpxAimXVo9t6q2ulhWLkqSwQHIpTU364Fqa6a+2IYISju0amntQ2uLJbKkE8Q
 OuZrZzayStXXFhsQGKHIyvtqVn9u7XfliUXVa6da1tqtmxpsleWfxMnMCS4haG1xamltfWyo2A
 iGkqTnBzZ6vh9Pz13c5wMP/9ZzPf3zGyoKeAgAA
X-Change-ID: 20260315-pixel3-camera-a9989bf589ee
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3146; i=david@ixit.cz;
 h=from:subject:message-id; bh=Uvv+fZqSIFf6jNidbTCuLHrACtAw3kFSjvIsUFMpzQk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqq7btYerePyrnfPlipZdUJA2HzV9ha6vsm5Z3K
 yRGMN38OHWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqu27QAKCRBgAj/E00kg
 cmeYD/9puE3BY45GbBvNGPFlyAGfcA9XXS6a0HAAqPBHJa39ZVui1HEEC+mRYlIpifKyUBjH2zN
 85gNLCDOMC++eP91RyAoxylicRkpnz1swq78q2J52pqdogCE2rkcVvi9uiyhOF8LqA8hHRdvay4
 tUCzI8xNTGgrrabbR2T+WBT2bbXkNa1Qr4o/1iOSAlMs8DrMrjLODmLBufXZWKof2vDcX2cKunG
 TT23t7Gbw4ZaDTgU9rz+E00A/wqXa+H9x53SLI97CqqSWNxdDbA5VYM0mT/dkr9DUMYZmY2vdq9
 C0HMIV8ZkjGyRc3EC0ub4j/c6mXCrZ9SntE1PCV2bjLxU1inQT+bBr/Pl4nsrwS9xR4MX4TkNY1
 wrTKp7epKJYsVqh1kWwO3xOfjdE7ex3Tp+SAvGjKxbviU9hW7yID1tyS9gYQertrJPx4gKwh5O1
 OuiWt0VlWYaHbzdrhMSw6mlnCCAMIwynJnHvERDglUbn5AL44J5rPMsptbqGCoLjY9H7Cs0tXus
 FnB/Q+NotyUYvKT1OgmSpI0a8pT+QuIuo3HBen7IuVUw81AIw2Qw5fvybRXfSzHLejHxz7+3Zsh
 6zbjgj3UezkRkIDHhGCBP2x+5qgTpfrGsWuFzj2JbOdD1ZzifNQd1siIoWdZBr8jVHm8Jr3P3Pw
 dE27f+yVnSi5ugg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the dual front-facing IMX355 sensors (standard and wide)
and enable the PMI8998 flash LED with hardware-accurate limits.

This brings up the basic camera topology and flash support in DT.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v10:
- Removed the (not yet met) dependency. I'll apply fix after it gets
  merged. Feel free to pick between v10 and v9 for merging as what you
  think is the best way.
- Link to v9: https://patch.msgid.link/20260907-pixel3-camera-v9-0-b1981f2d3291@ixit.cz

Changes in v9:
- Dependency merged, no longer depends on anything.
- Link to v8: https://patch.msgid.link/20260901-pixel3-camera-v8-0-99f159883348@ixit.cz

Changes in v8:
- Fix ordering of includes. (Konrad)
- Link to v7: https://lore.kernel.org/r/20260721-pixel3-camera-v7-0-82d323c6c5d2@ixit.cz

Changes in v7:
- Depend on the
  https://lore.kernel.org/all/20260628-kbingham-orientation-v3-0-4ed92968aff8@ideasonboard.com/
  (Konrad)
- Sort the renamed regulators. Why Mr. Anderson, why. (Konrad)
- Link to v6: https://lore.kernel.org/r/20260720-pixel3-camera-v6-0-afe419bef476@ixit.cz

Changes in v6:
- Remove forgotten bias-pull-down property from cci0_sleep node.
  (dtbs_check)
- ..-regulator -> regulator-.. (Konrad)
- Rename camera -pin to -state and remove _pin from the labes. (Konrad,
  dtbs_check)
- Link to v5: https://lore.kernel.org/r/20260719-pixel3-camera-v5-0-99593f1bd8ec@ixit.cz

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

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 198 ++++++++++++++++++++-
 1 file changed, 197 insertions(+), 1 deletion(-)
---
base-commit: 944a035ecca915ae947905dcfb03f2b9dc6d032c
change-id: 20260315-pixel3-camera-a9989bf589ee

Best regards,
--  
David Heidelberg <david@ixit.cz>

