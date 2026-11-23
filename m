From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v11 0/2] Add initial dual front camera and rear flash
 support for Pixel 3 / 3 XL
Date: Mon, 23 Nov 2026 14:28:09 +0100
Message-Id: <20261123-pixel3-camera-v11-0-d00195d180dc@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33SzW7CMAwH8FdBPa9TnE+b095j2iFJnRFpA9ayi
 g3x7kthEm2QOMbK72/L8qkZuM88NOvVqel5zEPebcsD4GnVxI3fvnObu1JopJBWKDDtPh/5Q7X
 Rf3LvW0+EFJJBYm6K2fecyocp8PWtvDd5OOz6n0v+CFP1mqQBqqQRWtFKZ5wV1oAJ9iUf8+E5/
 jZTzigfWlmshoBIPgTQcWnV3MraqmJZ2iBIeAsgllbfrAOqrZ76YvQBpLJo5NKah9YUS2RIJQg
 dcjWznVkpamuL9Yk1UOCkXbUrN7d3u3LFouyUVNFG01Uz482SuLN4mTmBIUSlNC4tza2rLRUbg
 BDS1JxgaUHMMNxhEEV3ySqQjoKi7qbP17Pr+eu7nO/h//bO5z85gaYN3AIAAA==
X-Change-ID: 20260315-pixel3-camera-a9989bf589ee
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Abel Vesa <abel.vesa@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3355; i=david@ixit.cz;
 h=from:subject:message-id; bh=DnyxK+CH29aGE0/NgvGyExF9hEYwCx25ThxaJ/VBTS4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBD9rd1lGXz5HexqJr0ncrOeM9r6BGzvaYBGtI
 iRDuFXj8a2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawQ/awAKCRBgAj/E00kg
 cugPD/98BJK3uoN4L489lXay+FaAzYEZyJbWMnHZdXjaSq68CTxlrQ620F6xg8DIoZ1MwKJggBr
 gO2EBkhO2+lDSXVPZ+Skkq0AYH2jycQqsbdWdNh/eTq+ERHbmQfuF3nReYrF0D1u1jnqX88G/r6
 6sBq0WOfi9piwPWTSFRgFMSX6AKhEOj55O0vPdx7PhHOKMlpsCkwY1rVg3NLhTjHWsCKhF5JrHT
 CI/rHlmC5TCJAuPgvKRG2VzE9JlNWLH3yJfUNSU4MHp5w4qhGVyDEfh+81M1Abmo66pQJwFCgbb
 q6VMjtRfQgfmXt/RYJXE70mONsda2VMVi4H+TB+0yfew7Co0f3Nes6pVxnwfE0xVTc6fWDXHfDP
 APv/5uWwb6VU3CoMbEbXXtUNO0rLWLqAoq2IMoIfU8SAlUYE/PKUn0FURCPruBQFWoOhddI8mCF
 W8MLgNfaBDoZ74l1vYuiaAHFg+zD2kXrIsFD3YLZJA5sLG9zwNTt5Woo5D/75NBqpFeN5LnDmtw
 EaAZv5qwDsNGpZC5qzCZfcvOh58vfGD7bFP2f+9E0BM+e4L36uj+NcDyWcyLqDqZU+KdyZYH0gb
 unw9sF2e2/WBE7+e7UpRE/vNXEeIJM1RjywJq5zY/bR8sQOBAyOiiAgHswQ27BzCRWs2Av6mseE
 e7X6WdwWF+2tfXQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the dual front-facing IMX355 sensors (standard and wide)
and enable the PMI8998 flash LED with hardware-accurate limits.

This brings up the basic camera topology and flash support in DT.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v11:
- Reverted to the v9 (as the merging didn't occured yet, and now header
  file is in the place).
- Link to v10: https://patch.msgid.link/20260917-pixel3-camera-v10-0-df631279b39d@ixit.cz

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

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 199 ++++++++++++++++++++-
 1 file changed, 198 insertions(+), 1 deletion(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20260315-pixel3-camera-a9989bf589ee

Best regards,
--  
David Heidelberg <david@ixit.cz>

