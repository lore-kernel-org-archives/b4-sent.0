From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v7 0/2] Speakers for Pixel 3 / 3 XL
Date: Wed, 11 Nov 2026 18:41:19 +0100
Message-Id: <20261111-pixel3-audio-v7-0-ecf28efc5c33@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33Py27DIBAF0F+JWJcKGMDQVf+j6oLH0CBVcYIdl
 If878WN1NhedHkHnTvDnQxYMg7kbXcnBWsecn9ooXvZkbB3hy+kObZMBBOaaQ70mC/4DdSdY+6
 pjz55adEw6Egjx4Kpvc91H5+PXPB0bq3jc7jPw9iX6+/Kyufpo71jat1eOWUUvNYJwCib+Hu+5
 PE13MhcU8WTWrY5rIpGuyAERsuVsBsKCyrkhkKjKjItNUvBOLum8j8qGzXKq8gBnFO4pmpJt39
 V88EpeRDBGubTmuo/yhnXG6ob5TwYI6Xx4Bdbp2n6AUTZpIbiAQAA
X-Change-ID: 20260613-pixel3-audio-bdbfb49e8037
To: Srinivas Kandagatla <srini@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Viken Dadhaniya <viken.dadhaniya@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3488; i=david@ixit.cz;
 h=from:subject:message-id; bh=reyRd4l1Oh4ajFZmaaOwLVE50anXb8RwYNR93+iRoag=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq9KjBbezIplsv8LDE+sCR+2qh6J8tl6L5Pzemk
 id3lNTlbBeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavSowQAKCRBgAj/E00kg
 cqT/D/wNbkhzbY0XtcRIFnJYf3bSS8AyERfjToVHhnn7bM0DLR3fSo0HrxukEWB+i7clWq8Lb6i
 FgCm+fI1pUMuwe8ZLXjpZNDDgR8CvX3FSnZY2RjUqNoi5CSra5nxIF/LOik7/xWSz5y/NuFlQ0S
 OvHUY6g0PNSdfPt6/VWHjjGlP8QAKK2JEGZ8upRroVmbjHPVZwL19FLU/OdhCrsr2Nf4ocHhX4N
 GFl3c6m1wFR1a6WWzEXhSWC+C+WKHJ0ju48non4hOWluMbQyVJvRO9FyCKWfRQC9bNrIolF3jJU
 sJvS72xe6gM9ELiHRc4/el0aT7O+r1ee5/gevckuvXi/ipGfaD4Dvv/IRuE30sx6WIItAbvlTek
 aW+cuDjrf4k9qvr5bbfDQdLYHg+d32wkS5J/jNEcGvh0MjMmeQoeFVMxF/0ODpZssqFb7+oobzq
 6gDdGv2cz7VIo8AGJyEl5L97uD+Nn5pxvnQt66TcKY1CMHxMLjVfGCHnUUz+vCoC4VmgxpfOOTE
 0egNU/piFaNz38LTC0Wl5Bn2tAFGiexmziKTKxTD+WdenQ2eKoeGWXgpse56mbEhH+QRkl93r0E
 F4OsDVrYMEHULmV+wq1gyaKiypr+wPFCrJohqwVVWRGLClI9dzQJr/hgo+CFotmOV/kB+Av0Nbi
 6L6Bg8eep6sNESg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series address:

--- merged
0. demistify the hex to BIT() macro and add left/right rx spk
1. most likely wrongly set DSP_B in sdm845.c
   my guess this is because TDM was never used in the mainline with
   sdm845
2. applying correct mask to left/right speaker for the TDM in sdm845.c,
   so both speakers can work simultaneusly
3. setting sysclk at startups, which some codecs need (such as cs35l36)
4. setting proper tdm slot in the cs35l36 driver
--- remains:
5. device-tree wiring for Pixel 3 / 3 XL speakers
6. same for microphone.

As per previous discussion not seding patch removing the "Input Mux"
which now interferes with TDM callback. If wanted, I can send it as a
follow-up.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v7:
- Edited swm node disable comment.
- Rebased on top of next-20261110 (small conflict resolved).
- Link to v6: https://patch.msgid.link/20261016-pixel3-audio-v6-0-11c88448b3be@ixit.cz

Changes in v6:
- Everything expect device-tree changes got merged. Rebased on top of
  latest next-20261016.
- Link to v5: https://patch.msgid.link/20260925-pixel3-audio-v5-0-7ffb32c980bf@ixit.cz

Changes in v5:
- Dropped
  `slimbus: qcom-ngd-ctrl: Remove data channels on stream disable`
  in favor of now merged
  `slimbus: qcom-ngd-ctrl: Implement disable_stream callback`
- Applied R-bs.
- Small clarifications in the commit messages and comments blocks.
- Link to v4: https://patch.msgid.link/20260924-pixel3-audio-v4-0-85b5d133aa5e@ixit.cz

Changes in v4:
- Rebase on top of d4d1619ebd55 ("ASoC: codecs: cs35l*: use .auto_selectable_formats") (Mark)
- Link to v3: https://patch.msgid.link/20260924-pixel3-audio-v3-0-5d06460fc8a9@ixit.cz

Changes in v3:
- De-RFC, applied Reviewed-by tag.
- Link to v2: https://patch.msgid.link/20260903-pixel3-audio-v2-0-7c22ed915291@ixit.cz

Changes in v2:
- Device-tree name sorting, with exception keeping mm1-dai-link in it's
  place. (Konrad)
- Make set_tdm_slot cleaner and less leveled. (Konrad)
- Added TDM MIC defines in sdm845.c.
  Should we in capture use speaker mask?
- Renamed model from 'Google Pixel 3' to 'blueline', I would love to
  hear feedback on this one.
- Link to v1: https://lore.kernel.org/r/20260705-pixel3-audio-v1-0-3b66f33859f1@ixit.cz

To: Srinivas Kandagatla <srini@kernel.org>
To: Liam Girdwood <lgirdwood@gmail.com>
To: Mark Brown <broonie@kernel.org>
To: Jaroslav Kysela <perex@perex.cz>
To: Takashi Iwai <tiwai@suse.com>
To: David Rhodes <david.rhodes@cirrus.com>
To: Richard Fitzgerald <rf@opensource.cirrus.com>
To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Abel Vesa <abelvesa@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-sound@vger.kernel.org
Cc: linux-arm-msm@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: patches@opensource.cirrus.com
Cc: devicetree@vger.kernel.org

---
David Heidelberg (2):
      arm64: dts: qcom: sdm845-google: Add basic audio support
      arm64: dts: qcom: sdm845-google: Add WCD9340 codec and microphone capture

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 188 ++++++++++++++++++++-
 1 file changed, 186 insertions(+), 2 deletions(-)
---
base-commit: 793807ca13bf3072fc6d16ce6d90e9ab9beff2a5
change-id: 20260613-pixel3-audio-bdbfb49e8037

Best regards,
--  
David Heidelberg <david@ixit.cz>

